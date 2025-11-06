// Minimal runtime support for freestanding kernel
// Provides essential functions that the Zig compiler expects

export fn memcpy(dest: [*]u8, src: [*]const u8, len: usize) [*]u8 {
    var i: usize = 0;
    while (i < len) : (i += 1) {
        dest[i] = src[i];
    }
    return dest;
}

export fn memmove(dest: [*]u8, src: [*]const u8, len: usize) [*]u8 {
    if (@intFromPtr(dest) < @intFromPtr(src)) {
        // Copy forward
        var i: usize = 0;
        while (i < len) : (i += 1) {
            dest[i] = src[i];
        }
    } else {
        // Copy backward to avoid overlap
        var i: i32 = @as(i32, @intCast(len)) - 1;
        while (i >= 0) : (i -= 1) {
            dest[@as(usize, @intCast(i))] = src[@as(usize, @intCast(i))];
        }
    }
    return dest;
}

export fn memset(dest: [*]u8, byte: i32, len: usize) [*]u8 {
    var i: usize = 0;
    const b: u8 = @truncate(@as(u32, @bitCast(byte)));
    while (i < len) : (i += 1) {
        dest[i] = b;
    }
    return dest;
}

// 128-bit unsigned division
export fn __udivti3(a: u128, b: u128) u128 {
    if (b == 0) return 0;
    if (a == 0) return 0;

    var remainder: u128 = a;
    var quotient: u128 = 0;
    var divisor = b;
    var bit: u7 = 127;

    while (divisor <= remainder) {
        divisor <<= 1;
    }

    while (true) {
        divisor >>= 1;

        if (divisor <= remainder) {
            remainder -= divisor;
            quotient |= @as(u128, 1) << bit;
        }

        if (bit == 0) break;
        bit -= 1;
    }

    return quotient;
}

// 128-bit unsigned modulo
export fn __umodti3(a: u128, b: u128) u128 {
    if (b == 0) return 0;
    return a - ((__udivti3(a, b)) * b);
}

// Float to long double conversion (stub)
export fn __extenddftf2(x: f64) f128 {
    return @floatCast(x);
}

// Extended precision float to long double conversion (stub)
export fn __extendxftf2(x: f80) f128 {
    return @floatCast(x);
}
