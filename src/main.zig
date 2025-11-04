const std = @import("std");
const kernel = @import("kernel/kernel.zig");
const framebuffer = @import("drivers/framebuffer.zig");
const ps2 = @import("drivers/ps2.zig");
const shell = @import("shell/shell.zig");

pub fn main() !void {
    // Initialize the framebuffer
    const fb = framebuffer.init() catch |err| {
        std.debug.print("Framebuffer initialization failed: {}\n", .{err});
        return err;
    };

    // Initialize the PS/2 keyboard
    const keyboard = ps2.init() catch |err| {
        std.debug.print("PS/2 keyboard initialization failed: {}\n", .{err});
        return err;
    };

    // Initialize the kernel
    kernel.init(fb, keyboard);

    // Start the interactive shell
    shell.start();
}
