const VGA_WIDTH: usize = 80;
const VGA_HEIGHT: usize = 25;
const VGA_BUFFER: [*]volatile u16 = @ptrFromInt(0xB8000);

pub const Color = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    Yellow = 14,
    White = 15,
};

pub const Writer = struct {
    row: usize = 0,
    col: usize = 0,
    fg: Color = .White,
    bg: Color = .Black,

    pub fn init() Writer {
        var writer = Writer{};
        writer.clear();
        return writer;
    }

    pub fn clear(self: *Writer) void {
        const blank = self.makeEntry(' ');
        var i: usize = 0;
        while (i < VGA_WIDTH * VGA_HEIGHT) : (i += 1) {
            VGA_BUFFER[i] = blank;
        }
        self.row = 0;
        self.col = 0;
    }

    fn makeEntry(self: *Writer, char: u8) u16 {
        const color: u8 = (@intFromEnum(self.bg) << 4) | @intFromEnum(self.fg);
        return (@as(u16, color) << 8) | @as(u16, char);
    }

    fn putCharAt(self: *Writer, char: u8, row: usize, col: usize) void {
        const index = row * VGA_WIDTH + col;
        VGA_BUFFER[index] = self.makeEntry(char);
    }

    fn newline(self: *Writer) void {
        self.col = 0;
        if (self.row + 1 < VGA_HEIGHT) {
            self.row += 1;
        } else {
            self.scroll();
        }
    }

    fn scroll(self: *Writer) void {
        // Move all rows up by one
        var row: usize = 1;
        while (row < VGA_HEIGHT) : (row += 1) {
            const src_start = row * VGA_WIDTH;
            const dest_start = (row - 1) * VGA_WIDTH;
            var col: usize = 0;
            while (col < VGA_WIDTH) : (col += 1) {
                VGA_BUFFER[dest_start + col] = VGA_BUFFER[src_start + col];
            }
        }

        // Clear the last row
        const blank = self.makeEntry(' ');
        const last_row_start = (VGA_HEIGHT - 1) * VGA_WIDTH;
        var col: usize = 0;
        while (col < VGA_WIDTH) : (col += 1) {
            VGA_BUFFER[last_row_start + col] = blank;
        }
        self.row = VGA_HEIGHT - 1;
    }

    pub fn putChar(self: *Writer, char: u8) void {
        switch (char) {
            '\n' => self.newline(),
            '\r' => self.col = 0,
            '\x08' => {
                // Backspace - move cursor back if not at start of line
                if (self.col > 0) {
                    self.col -= 1;
                } else if (self.row > 0) {
                    // Move to end of previous line
                    self.row -= 1;
                    self.col = VGA_WIDTH - 1;
                }
            },
            else => {
                self.putCharAt(char, self.row, self.col);
                self.col += 1;
                if (self.col >= VGA_WIDTH) {
                    self.newline();
                }
            },
        }
        // Mirror output to serial (COM1) so messages are visible on -serial stdio
        serial_write_char(char);
    }

    pub fn write(self: *Writer, text: []const u8) void {
        for (text) |char| {
            self.putChar(char);
        }
    }

    pub fn setColor(self: *Writer, fg: Color, bg: Color) void {
        self.fg = fg;
        self.bg = bg;
    }

    pub fn writeAt(self: *Writer, row: usize, col: usize, text: []const u8) void {
        var i: usize = 0;
        while (i < text.len) : (i += 1) {
            const ch = text[i];
            const idx = row * VGA_WIDTH + col + i;
            if (row < VGA_HEIGHT and col + i < VGA_WIDTH) {
                const color: u8 = (@intFromEnum(self.bg) << 4) | @intFromEnum(self.fg);
                VGA_BUFFER[idx] = (@as(u16, color) << 8) | @as(u16, ch);
                serial_write_char(ch);
            }
        }
    }

    pub fn drawWindow(self: *Writer, top: usize, left: usize, width: usize, height: usize, title: []const u8) void {
        if (width < 2 or height < 2) return;
        // Clip to screen
        const max_w = if (left + width <= VGA_WIDTH) width else VGA_WIDTH - left;
        const max_h = if (top + height <= VGA_HEIGHT) height else VGA_HEIGHT - top;

        const corner: u8 = '+';
        const hor: u8 = '-';
        const ver: u8 = '|';

        // Top border
        if (max_h > 0) {
            const top_row = top;
            // left corner
            VGA_BUFFER[top_row * VGA_WIDTH + left] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, corner);
            var x: usize = 1;
            while (x + 1 < max_w) : (x += 1) {
                VGA_BUFFER[top_row * VGA_WIDTH + left + x] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, hor);
            }
            if (max_w > 1) {
                VGA_BUFFER[top_row * VGA_WIDTH + left + max_w - 1] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, corner);
            }
        }

        // Middle rows
        var ry: usize = 1;
        while (ry + 1 < max_h) : (ry += 1) {
            const row = top + ry;
            // left border
            VGA_BUFFER[row * VGA_WIDTH + left] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, ver);
            // fill
            var cx: usize = 1;
            while (cx + 1 < max_w) : (cx += 1) {
                VGA_BUFFER[row * VGA_WIDTH + left + cx] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, ' ');
            }
            // right border
            if (max_w > 1) {
                VGA_BUFFER[row * VGA_WIDTH + left + max_w - 1] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, ver);
            }
        }

        // Bottom border
        if (max_h > 1) {
            const bot_row = top + max_h - 1;
            VGA_BUFFER[bot_row * VGA_WIDTH + left] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, corner);
            var x2: usize = 1;
            while (x2 + 1 < max_w) : (x2 += 1) {
                VGA_BUFFER[bot_row * VGA_WIDTH + left + x2] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, hor);
            }
            if (max_w > 1) {
                VGA_BUFFER[bot_row * VGA_WIDTH + left + max_w - 1] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, corner);
            }
        }

        // Title (if any) — write starting at left+2 on top border
        if (title.len > 0 and width > 4) {
            var i: usize = 0;
            var pos = left + 2;
            while (i < title.len and pos < left + max_w - 2) : (i += 1) {
                VGA_BUFFER[(top) * VGA_WIDTH + pos] = (@as(u16, (@intFromEnum(self.bg) << 4 | @intFromEnum(self.fg))) << 8) | @as(u16, title[i]);
                pos += 1;
            }
        }
    }
};

fn serial_write_char(c: u8) void {
    // Write a single byte to COM1 (0x3F8). Use the same inline asm style as ATA driver.
    const port: u16 = 0x03F8;
    asm volatile ("outb %[val], %[port]"
        :
        : [val] "{al}" (c),
          [port] "{dx}" (port),
    );
}
