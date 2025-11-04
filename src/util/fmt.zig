const std = @import("std");

pub fn print_string(buffer: *u8, str: []const u8) void {
    const len = str.len;
    for (len) |i| {
        buffer[i] = str[i];
    }
}

pub fn print_number(buffer: *u8, num: u32) void {
    var i: usize = 0;
    var n = num;
    while (n != 0) {
        const digit = n % 10;
        buffer[i] = '0' + digit;
        n /= 10;
        i += 1;
    }
    // Reverse the digits
    for (i / 2) |j| {
        const temp = buffer[j];
        buffer[j] = buffer[i - j - 1];
        buffer[i - j - 1] = temp;
    }
    buffer[i] = 0; // Null-terminate the string
}

pub fn format_string(buffer: *u8, format: []const u8, args: []const u32) void {
    var arg_index: usize = 0;
    var buffer_index: usize = 0;

    for (format) |c| {
        if (c == '%') {
            arg_index += 1;
            if (arg_index <= args.len) {
                const num = args[arg_index - 1];
                print_number(buffer[buffer_index..], num);
                buffer_index += 10; // Assuming max number length is 10
            }
        } else {
            buffer[buffer_index] = c;
            buffer_index += 1;
        }
    }
    buffer[buffer_index] = 0; // Null-terminate the string
}