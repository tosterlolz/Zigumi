const std = @import("std");
const framebuffer = @import("../drivers/framebuffer.zig");
const ps2 = @import("../drivers/ps2.zig");

const MAX_COMMAND_LENGTH = 128;

fn print_help() void {
    framebuffer.print("Zigumi OS Shell\n");
    framebuffer.print("Available commands:\n");
    framebuffer.print("  echo <message> - Print a message to the screen\n");
    framebuffer.print("  clear - Clear the screen\n");
    framebuffer.print("  help - Show this help message\n");
}

fn execute_command(command: []const u8) void {
    if (std.mem.startsWith(u8, command, "echo ")) {
        const message = command[5..];
        framebuffer.print(message);
        framebuffer.print("\n");
    } else if (std.mem.eql(u8, command, "clear")) {
        framebuffer.clear();
    } else if (std.mem.eql(u8, command, "help")) {
        print_help();
    } else {
        framebuffer.print("Unknown command: ");
        framebuffer.print(command);
        framebuffer.print("\n");
    }
}

pub fn run_shell() void {
    var command_buffer: [MAX_COMMAND_LENGTH]u8 = undefined;
    while (true) {
        framebuffer.print("> ");
        const input_length = ps2.read_input(command_buffer);
        if (input_length > 0) {
            command_buffer[input_length] = 0; // Null-terminate the string
            execute_command(command_buffer[0..input_length]);
        }
    }
}