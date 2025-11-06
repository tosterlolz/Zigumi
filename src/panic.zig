const vga = @import("term/vga.zig");

fn serial_write_char(c: u8) void {
    // Directly write to COM1 (0x3F8) so panic messages appear on -serial stdio
    const port: u16 = 0x03F8;
    // Use inline asm to write the byte to the port
    asm volatile ("outb %[val], %[port]"
        :
        : [val] "{al}" (c),
          [port] "{dx}" (port),
    );
}

pub fn panic(message: []const u8, _: ?*@import("builtin").StackTrace, _: ?usize) noreturn {
    var writer = vga.Writer.init();
    writer.setColor(.Red, .Black);
    writer.write("PANIC: ");

    // Print the panic message character by character and mirror to serial
    for (message) |char| {
        writer.putChar(char);
        serial_write_char(char);
    }

    writer.write("\n");
    serial_write_char('\n');

    while (true) {
        asm volatile ("hlt");
    }
}
