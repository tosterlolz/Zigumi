// PS/2 Keyboard Driver for Zigumi OS

const vga = @import("../term/vga.zig");

// PS/2 Keyboard ports
const PS2_DATA_PORT: u16 = 0x60;
const PS2_STATUS_PORT: u16 = 0x64;
const PS2_COMMAND_PORT: u16 = 0x64;

// Keyboard scan codes to ASCII (US layout, unshifted)
const SCANCODE_TO_ASCII = [_]u8{
    0, 27, '1', '2', '3', '4', '5', '6', // 0x00-0x07
    '7', '8', '9', '0', '-', '=', '\x08', '\t', // 0x08-0x0F (backspace, tab)
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', // 0x10-0x17
    'o', 'p', '[', ']', '\n', 0, 'a', 's', // 0x18-0x1F (enter, ctrl, a, s)
    'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', // 0x20-0x27
    '\'', '`', 0, '\\', 'z', 'x', 'c', 'v', // 0x28-0x2F (shift)
    'b', 'n', 'm', ',', '.', '/', 0, '*', // 0x30-0x37 (shift, *)
    0, ' ', 0, 0, 0, 0, 0, 0, // 0x38-0x3F (alt, space, caps)
    0, 0, 0, 0, 0, 0, 0, '7', // 0x40-0x47 (F-keys, numpad 7)
    '8', '9', '-', '4', '5', '6', '+', '1', // 0x48-0x4F (numpad)
    '2', '3', '0', '.', // 0x50-0x53 (numpad)
} ++ [_]u8{0} ** (128 - 0x54); // Fill rest with zeros

// Shifted characters
const SCANCODE_TO_ASCII_SHIFT = [_]u8{
    0, 27, '!', '@', '#', '$', '%', '^', // 0x00-0x07
    '&', '*', '(', ')', '_', '+', '\x08', '\t', // 0x08-0x0F
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', // 0x10-0x17
    'O', 'P', '{', '}', '\n', 0, 'A', 'S', // 0x18-0x1F
    'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', // 0x20-0x27
    '"', '~', 0, '|', 'Z', 'X', 'C', 'V', // 0x28-0x2F
    'B', 'N', 'M', '<', '>', '?', 0, '*', // 0x30-0x37
    0, ' ', 0, 0, 0, 0, 0, 0, // 0x38-0x3F
    0, 0, 0, 0, 0, 0, 0, '7', // 0x40-0x47
    '8', '9', '-', '4', '5', '6', '+', '1', // 0x48-0x4F
    '2', '3', '0', '.', // 0x50-0x53
} ++ [_]u8{0} ** (128 - 0x54);

// Special scan codes
const SCANCODE_LEFT_SHIFT: u8 = 0x2A;
const SCANCODE_RIGHT_SHIFT: u8 = 0x36;
const SCANCODE_CAPS_LOCK: u8 = 0x3A;
const SCANCODE_RELEASE_OFFSET: u8 = 0x80;

pub const Keyboard = struct {
    shift_pressed: bool = false,
    caps_lock: bool = false,
    ctrl_pressed: bool = false,
    alt_pressed: bool = false,

    pub fn init() Keyboard {
        return Keyboard{};
    }

    pub fn readScancode(_: *Keyboard) ?u8 {
        // Check if data is available
        const status = inb(PS2_STATUS_PORT);
        if ((status & 0x01) == 0) {
            return null;
        }

        // Read scancode
        const scancode = inb(PS2_DATA_PORT);
        return scancode;
    }

    pub fn handleScancode(self: *Keyboard, scancode: u8) ?u8 {
        // Check for key release (bit 7 set)
        if (scancode >= SCANCODE_RELEASE_OFFSET) {
            const key = scancode - SCANCODE_RELEASE_OFFSET;
            if (key == SCANCODE_LEFT_SHIFT or key == SCANCODE_RIGHT_SHIFT) {
                self.shift_pressed = false;
            }
            return null;
        }

        // Handle special keys
        switch (scancode) {
            SCANCODE_LEFT_SHIFT, SCANCODE_RIGHT_SHIFT => {
                self.shift_pressed = true;
                return null;
            },
            SCANCODE_CAPS_LOCK => {
                self.caps_lock = !self.caps_lock;
                return null;
            },
            0x1D => { // Left Ctrl
                self.ctrl_pressed = true;
                return null;
            },
            0x38 => { // Left Alt
                self.alt_pressed = true;
                return null;
            },
            else => {},
        }

        // Convert scancode to ASCII
        if (scancode < SCANCODE_TO_ASCII.len) {
            var ascii: u8 = undefined;

            if (self.shift_pressed) {
                ascii = SCANCODE_TO_ASCII_SHIFT[scancode];
            } else {
                ascii = SCANCODE_TO_ASCII[scancode];
            }

            // Apply caps lock for letters
            if (self.caps_lock and ascii >= 'a' and ascii <= 'z') {
                ascii = ascii - 32; // Convert to uppercase
            } else if (self.caps_lock and ascii >= 'A' and ascii <= 'Z' and !self.shift_pressed) {
                // Caps lock is on but shift is not pressed
                // Do nothing, already uppercase
            } else if (self.caps_lock and ascii >= 'A' and ascii <= 'Z' and self.shift_pressed) {
                // Caps lock is on AND shift is pressed - make lowercase
                ascii = ascii + 32;
            }

            if (ascii != 0) {
                return ascii;
            }
        }

        return null;
    }

    pub fn waitAndRead(self: *Keyboard) u8 {
        while (true) {
            if (self.readScancode()) |scancode| {
                if (self.handleScancode(scancode)) |ascii| {
                    return ascii;
                }
            }
        }
    }

    // Non-blocking getChar for syscalls
    pub fn getChar(self: *Keyboard) ?u8 {
        if (self.readScancode()) |scancode| {
            return self.handleScancode(scancode);
        }
        return null;
    }
};

// Port I/O functions
fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}
