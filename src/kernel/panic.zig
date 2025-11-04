const std = @import("std");

pub fn panic(message: []const u8) noreturn {
    const stdout = std.io.getStdOut().writer();
    const _ = stdout.print("Kernel Panic: {}\n", .{message});
    
    // Halt the CPU
    while (true) {}
}