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
};
