const vga = @import("term/vga.zig");

pub fn panic(message: []const u8, _: ?*@import("builtin").StackTrace, _: ?usize) noreturn {
    var writer = vga.Writer.init();
    writer.setColor(.Red, .Black);
    writer.write("PANIC: ");

    // Print the panic message character by character
    for (message) |char| {
        writer.putChar(char);
    }

    writer.write("\n");

    while (true) {
        asm volatile ("hlt");
    }
}
