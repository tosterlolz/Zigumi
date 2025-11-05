// Userland library for Zigumi OS
// Provides high-level wrappers around syscalls

pub const Syscall = enum(u32) {
    Exit = 0,
    Write = 1,
    Read = 2,
    Open = 3,
    Close = 4,
    GetPid = 5,
    Sleep = 6,
};

// Make syscalls directly
// TODO: For now using direct calls until IDT is implemented
const syscalls = @import("../kernel/syscalls.zig");

pub fn exit(code: u32) noreturn {
    syscalls.sys_exit(code);
    unreachable;
}

pub fn write(fd: u32, buffer: []const u8) u32 {
    return syscalls.sys_write(fd, buffer.ptr, @as(u32, @intCast(buffer.len)));
}

pub fn read(fd: u32, buffer: []u8) u32 {
    return syscalls.sys_read(fd, buffer.ptr, @as(u32, @intCast(buffer.len)));
}

pub fn print(text: []const u8) void {
    _ = write(1, text);
}

pub fn println(text: []const u8) void {
    print(text);
    print("\n");
}

pub fn getPid() u32 {
    return syscalls.sys_getpid();
}

pub fn sleep(milliseconds: u32) void {
    syscalls.sys_sleep(milliseconds);
}

// Simple string formatting helpers
pub fn printInt(value: u32) void {
    var buffer: [32]u8 = undefined;
    const str = intToString(value, &buffer);
    print(str);
}

fn intToString(value: u32, buffer: []u8) []const u8 {
    if (value == 0) {
        buffer[0] = '0';
        return buffer[0..1];
    }

    var n = value;
    var i: usize = 0;

    while (n > 0) : (i += 1) {
        buffer[i] = @as(u8, @intCast((n % 10) + '0'));
        n /= 10;
    }

    // Reverse the string
    var j: usize = 0;
    while (j < i / 2) : (j += 1) {
        const temp = buffer[j];
        buffer[j] = buffer[i - 1 - j];
        buffer[i - 1 - j] = temp;
    }

    return buffer[0..i];
}

// String utilities
pub fn strlen(str: [*:0]const u8) usize {
    var len: usize = 0;
    while (str[len] != 0) : (len += 1) {}
    return len;
}

pub fn strcmp(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;

    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (a[i] != b[i]) return false;
    }

    return true;
}

pub fn readLine(buffer: []u8) []u8 {
    const bytes_read = read(0, buffer);
    return buffer[0..bytes_read];
}
