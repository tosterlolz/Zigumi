// System call interface for Zigumi OS

pub const Syscall = enum(u32) {
    Exit = 0,
    Write = 1,
    Read = 2,
    Open = 3,
    Close = 4,
    GetPid = 5,
    Sleep = 6,
};

pub const SyscallError = error{
    InvalidSyscall,
    InvalidParameter,
    PermissionDenied,
    NotImplemented,
};

const vga = @import("../term/vga.zig");
const keyboard = @import("../drivers/keyboard.zig");

var writer: *vga.Writer = undefined;
var kbd: *keyboard.Keyboard = undefined;

pub fn init(vga_writer: *vga.Writer, keyboard_driver: *keyboard.Keyboard) void {
    writer = vga_writer;
    kbd = keyboard_driver;
}

// Syscall handler called from assembly interrupt
pub export fn syscall_handler(
    syscall_num: u32,
    arg1: u32,
    arg2: u32,
    arg3: u32,
) u32 {
    const syscall = @as(Syscall, @enumFromInt(syscall_num));

    const result = handleSyscall(syscall, arg1, arg2, arg3) catch {
        return @as(u32, @bitCast(@as(i32, -1)));
    };

    return result;
}

fn handleSyscall(syscall: Syscall, arg1: u32, arg2: u32, arg3: u32) !u32 {
    switch (syscall) {
        .Exit => {
            // For now, just halt
            while (true) {
                asm volatile ("hlt");
            }
        },

        .Write => {
            // arg1 = fd, arg2 = buffer ptr, arg3 = length
            return sys_write(arg1, @as([*]const u8, @ptrFromInt(arg2)), arg3);
        },

        .Read => {
            // arg1 = fd, arg2 = buffer ptr, arg3 = max length
            return sys_read(arg1, @as([*]u8, @ptrFromInt(arg2)), arg3);
        },

        .GetPid => {
            return 1; // Always return PID 1 for now
        },

        .Sleep => {
            // arg1 = milliseconds
            sys_sleep(arg1);
            return 0;
        },

        else => return SyscallError.NotImplemented,
    }

    return 0;
}

pub fn sys_exit(code: u32) noreturn {
    _ = code;
    writer.write("\n[System halted]\n");
    while (true) {
        asm volatile ("hlt");
    }
}

pub fn sys_getpid() u32 {
    return 1; // Always return PID 1 for now
}

pub fn sys_write(fd: u32, buffer_ptr: [*]const u8, length: u32) u32 {
    _ = fd;

    if (length == 0) return 0;

    const buffer = buffer_ptr[0..length];
    writer.write(buffer);

    return length;
}

pub fn sys_read(fd: u32, buffer_ptr: [*]u8, max_length: u32) u32 {
    _ = fd;

    if (max_length == 0) return 0;

    const buffer = buffer_ptr[0..max_length];
    var index: usize = 0;

    while (index < max_length) {
        if (kbd.getChar()) |char| {
            // Handle backspace
            if (char == '\x08') {
                if (index > 0) {
                    index -= 1;
                    writer.putChar('\x08'); // Move cursor back
                    writer.putChar(' '); // Clear character
                    writer.putChar('\x08'); // Move cursor back again
                }
                continue;
            }

            // Echo the character to screen
            writer.putChar(char);

            buffer[index] = char;
            index += 1;

            // Break on newline
            if (char == '\n') {
                break;
            }
        }
    }

    return @as(u32, @intCast(index));
}

pub fn sys_sleep(milliseconds: u32) void {
    // Simple busy wait for now
    var i: u32 = 0;
    while (i < milliseconds * 1000) : (i += 1) {
        asm volatile ("nop");
    }
} // Assembly wrapper for making syscalls from userland
pub const syscall_asm =
    \\.global _syscall
    \\_syscall:
    \\    mov %edi, %eax
    \\    mov %esi, %ebx
    \\    mov %edx, %ecx
    \\    mov %ecx, %edx
    \\    int $0x80
    \\    ret
;
