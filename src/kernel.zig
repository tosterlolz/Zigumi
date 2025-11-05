const vga = @import("term/vga.zig");
const keyboard = @import("drivers/keyboard.zig");
const syscalls = @import("kernel/syscalls.zig");
const scheduler = @import("kernel/scheduler.zig");
const tty = @import("term/tty.zig");
const diskman = @import("drivers/diskman.zig");
const fat32 = @import("fs/fat32.zig");
const panic_handler = @import("panic.zig");

pub export fn _start() noreturn {
    var writer = vga.Writer.init();
    var kbd = keyboard.Keyboard.init();

    // Initialize subsystems
    syscalls.init(&writer, &kbd);
    scheduler.init();
    tty.init();
    // Initialize physical and virtual memory managers
    const pmm = @import("kernel/pmm.zig");
    const vmm = @import("kernel/vmm.zig");
    pmm.init();
    vmm.init();
    diskman.init(); // Initialize disk manager
    // Defer FAT32 probing to on-demand changeDrive to avoid early I/O
    fat32.init(); // Initialize FAT32 (no auto-mount)

    writer.setColor(.Yellow, .Black);
    writer.write("Zigumi OS v0.5\n");

    writer.setColor(.White, .Black);
    writer.write("Kernel loaded successfully!\n");
    writer.write("Initializing subsystems...\n");

    writer.setColor(.Green, .Black);
    writer.write("[OK] Syscall interface\n");
    writer.write("[OK] Task scheduler\n");
    writer.write("[OK] TTY driver\n");
    writer.write("[OK] Disk manager\n");
    writer.write("[OK] FAT32 (lazy mount)\n");
    // Attempt to mount A: once for convenience
    const mounted_a = fat32.changeDrive('A');
    if (mounted_a and fat32.isMounted('A')) {
        writer.write("[OK] FAT32 on A: mounted\n");
    } else {
        writer.setColor(.Yellow, .Black);
        writer.write("[WARN] No FAT32 on A: (use B: if you attached a data disk)\n");
        writer.setColor(.Green, .Black);
    }
    writer.write("\n");

    // Setup interrupt for syscalls (int 0x80)
    // Initialize IDT and default interrupt handlers so exceptions don't triple-fault
    const interrupts = @import("kernel/interrupts.zig");
    interrupts.init();

    writer.setColor(.Cyan, .Black);
    writer.write("Starting userland shell...\n\n");

    // Jump to userland shell
    jumpToUserland();

    // Should never reach here
    panic_handler.panic("Kernel: Reached unreachable code after jumpToUserland", null, null);
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
