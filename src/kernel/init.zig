const std = @import("std");
const framebuffer = @import("drivers/framebuffer.zig");
const ps2 = @import("drivers/ps2.zig");
const memory = @import("memory/mm.zig");

pub fn init() void {
    // Initialize memory management
    memory.init();

    // Initialize the framebuffer with pastel colors
    framebuffer.init();

    // Initialize PS/2 keyboard support
    ps2.init();
}