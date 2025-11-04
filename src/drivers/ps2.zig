const std = @import("std");

pub const PS2Key = enum {
    None,
    Esc,
    One,
    Two,
    Three,
    // Add more keys as needed
};

pub const PS2Keyboard = struct {
    // Buffer for storing keypresses
    buffer: [256]u8,
    buffer_index: usize,

    pub fn init() PS2Keyboard {
        return PS2Keyboard{
            .buffer = undefined,
            .buffer_index = 0,
        };
    }

    pub fn read_key(self: *PS2Keyboard) PS2Key {
        if (self.buffer_index == 0) {
            return PS2Key.None;
        }
        const key = self.buffer[self.buffer_index - 1];
        self.buffer_index -= 1;
        return @intCast(PS2Key, key);
    }

    pub fn handle_keypress(self: *PS2Keyboard, key: u8) void {
        if (self.buffer_index < self.buffer.len) {
            self.buffer[self.buffer_index] = key;
            self.buffer_index += 1;
        }
    }
};

pub fn init() void {
    // Initialize the PS/2 keyboard here
}

pub fn is_key_pressed(key: PS2Key) bool {
    // Check if a specific key is pressed
    return false; // Placeholder
}