// TTY (Teletypewriter) Driver for Zigumi OS

const vga = @import("vga.zig");
const keyboard = @import("../drivers/keyboard.zig");

const TTY_COUNT = 4;
const BUFFER_SIZE = 2048;

pub const TTY = struct {
    id: u8,
    active: bool,

    // Input buffer
    input_buffer: [BUFFER_SIZE]u8,
    input_pos: usize,

    // Output buffer (screen content)
    screen_buffer: [80 * 25]u16, // VGA text mode cells (char + color)
    cursor_x: u8,
    cursor_y: u8,

    // Colors
    fg_color: vga.Color,
    bg_color: vga.Color,

    pub fn init(id: u8) TTY {
        return TTY{
            .id = id,
            .active = false,
            .input_buffer = [_]u8{0} ** BUFFER_SIZE,
            .input_pos = 0,
            .screen_buffer = [_]u16{0x0720} ** (80 * 25), // Space with gray on black
            .cursor_x = 0,
            .cursor_y = 0,
            .fg_color = .White,
            .bg_color = .Black,
        };
    }

    pub fn write(self: *TTY, text: []const u8) void {
        for (text) |c| {
            self.putChar(c);
        }
    }

    pub fn putChar(self: *TTY, c: u8) void {
        if (c == '\n') {
            self.cursor_x = 0;
            self.cursor_y += 1;
            if (self.cursor_y >= 25) {
                self.scroll();
                self.cursor_y = 24;
            }
            return;
        }

        if (c == '\r') {
            self.cursor_x = 0;
            return;
        }

        const pos = @as(usize, self.cursor_y) * 80 + @as(usize, self.cursor_x);
        const color = (@as(u16, @intFromEnum(self.bg_color)) << 12) |
            (@as(u16, @intFromEnum(self.fg_color)) << 8);
        self.screen_buffer[pos] = color | @as(u16, c);

        self.cursor_x += 1;
        if (self.cursor_x >= 80) {
            self.cursor_x = 0;
            self.cursor_y += 1;
            if (self.cursor_y >= 25) {
                self.scroll();
                self.cursor_y = 24;
            }
        }
    }

    fn scroll(self: *TTY) void {
        // Move all lines up by one
        var y: usize = 0;
        while (y < 24) : (y += 1) {
            var x: usize = 0;
            while (x < 80) : (x += 1) {
                const src_pos = (y + 1) * 80 + x;
                const dst_pos = y * 80 + x;
                self.screen_buffer[dst_pos] = self.screen_buffer[src_pos];
            }
        }

        // Clear the last line
        var x: usize = 0;
        while (x < 80) : (x += 1) {
            const pos = 24 * 80 + x;
            self.screen_buffer[pos] = 0x0720; // Space with gray on black
        }
    }

    pub fn clear(self: *TTY) void {
        for (&self.screen_buffer) |*cell| {
            cell.* = 0x0720;
        }
        self.cursor_x = 0;
        self.cursor_y = 0;
    }

    pub fn setColor(self: *TTY, fg: vga.Color, bg: vga.Color) void {
        self.fg_color = fg;
        self.bg_color = bg;
    }
};

var ttys: [TTY_COUNT]TTY = undefined;
var current_tty: u8 = 0;

pub fn init() void {
    var i: u8 = 0;
    while (i < TTY_COUNT) : (i += 1) {
        ttys[i] = TTY.init(i);
    }
    ttys[0].active = true;
}

pub fn getCurrentTTY() *TTY {
    return &ttys[current_tty];
}

pub fn switchTTY(tty_id: u8) void {
    if (tty_id >= TTY_COUNT) return;

    ttys[current_tty].active = false;
    current_tty = tty_id;
    ttys[current_tty].active = true;

    // Restore the screen from the TTY's buffer
    restoreScreen();
}

pub fn restoreScreen() void {
    const tty = getCurrentTTY();
    var writer = vga.Writer.init();

    // Copy TTY buffer to VGA memory
    var y: usize = 0;
    while (y < 25) : (y += 1) {
        var x: usize = 0;
        while (x < 80) : (x += 1) {
            const pos = y * 80 + x;
            const cell = tty.screen_buffer[pos];
            const ch = @as(u8, @truncate(cell & 0xFF));
            const color_attr = @as(u8, @truncate((cell >> 8) & 0xFF));

            // Write directly to VGA buffer
            const vga_pos = y * 80 + x;
            const vga_ptr: [*]volatile u16 = @ptrFromInt(0xB8000);
            vga_ptr[vga_pos] = (@as(u16, color_attr) << 8) | @as(u16, ch);
        }
    }

    // Update cursor position
    writer.row = tty.cursor_y;
    writer.col = tty.cursor_x;
}

pub fn getTTYCount() u8 {
    return TTY_COUNT;
}
