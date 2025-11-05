const vga = @import("term/vga.zig");
const keyboard = @import("drivers/keyboard.zig");
const syscalls = @import("kernel/syscalls.zig");
const scheduler = @import("kernel/scheduler.zig");
const tty = @import("term/tty.zig");
const vfs = @import("fs/vfs.zig");

pub export fn _start() noreturn {
    var writer = vga.Writer.init();
    var kbd = keyboard.Keyboard.init();

    // Initialize subsystems
    syscalls.init(&writer, &kbd);
    scheduler.init();
    tty.init();
    vfs.init();

    writer.setColor(.Yellow, .Black);
    writer.write("Zigumi OS v0.5\n");

    writer.setColor(.White, .Black);
    writer.write("Kernel loaded successfully!\n");
    writer.write("Initializing subsystems...\n");

    writer.setColor(.Green, .Black);
    writer.write("[OK] Syscall interface\n");
    writer.write("[OK] Task scheduler\n");
    writer.write("[OK] TTY driver\n");
    writer.write("[OK] Virtual filesystem\n");
    writer.write("\n");

    // Setup interrupt for syscalls (int 0x80)
    setupSyscallInterrupt();

    writer.setColor(.Cyan, .Black);
    writer.write("Starting userland shell...\n\n");

    // Jump to userland shell
    jumpToUserland();

    // Should never reach here
    while (true) {
        asm volatile ("hlt");
    }
}

fn setupSyscallInterrupt() void {
    // For now, syscalls will work via software interrupt 0x80
    // In a real OS, we'd setup IDT entry here
    // This is a placeholder - the actual interrupt handling
    // will be done through inline assembly in the syscall
}

fn jumpToUserland() noreturn {
    // For now, just call the shell directly without switching to user mode
    // TODO: Implement proper user mode switching and IDT for syscalls
    const shell = @import("userland/shell.zig");
    shell.start();

    // If shell somehow returns, halt
    while (true) {
        asm volatile ("hlt");
    }
}
