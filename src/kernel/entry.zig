const std = @import("std");
const kernel = @import("kernel.zig");
const init = @import("init.zig");

pub fn main() !void {
    // Initialize the kernel
    try init.initialize();

    // Enter the main kernel loop
    kernel.mainLoop();
}