const std = @import("std");

pub const IDTEntry = packed struct {
    offset_low: u16,
    selector: u16,
    zero: u8,
    flags: u8,
    offset_high: u16,
};

var idt: [256]IDTEntry = [_]IDTEntry{IDTEntry{
    .offset_low = 0,
    .selector = 0,
    .zero = 0,
    .flags = 0,
    .offset_high = 0,
}} ** 256;

const CODE_SEG_SELECTOR: u16 = 0x08;

// Must be static/global so memory persists after function returns
var idtr: [6]u8 = undefined;

pub fn set_gate(vec: usize, handler_addr: usize, flags: u8) void {
    idt[vec].offset_low = @as(u16, @truncate(@as(u32, handler_addr) & 0xFFFF));
    idt[vec].selector = CODE_SEG_SELECTOR;
    idt[vec].zero = 0;
    idt[vec].flags = flags;
    idt[vec].offset_high = @as(u16, @truncate((@as(u32, handler_addr) >> 16) & 0xFFFF));
}

pub fn load_idt() void {
    const limit: u16 = @as(u16, @sizeOf(@TypeOf(idt)) - 1);
    idtr[0] = @as(u8, limit & 0xFF);
    idtr[1] = @as(u8, (limit >> 8) & 0xFF);
    const base = @as(u32, @intFromPtr(&idt));
    idtr[2] = @as(u8, @truncate(base & 0xFF));
    idtr[3] = @as(u8, @truncate((base >> 8) & 0xFF));
    idtr[4] = @as(u8, @truncate((base >> 16) & 0xFF));
    idtr[5] = @as(u8, @truncate((base >> 24) & 0xFF));

    // Load IDT using a register operand that points to our idtr buffer
    asm volatile ("lidt (%[ptr])"
        :
        : [ptr] "r" (&idtr),
        : .{ .memory = true });
}

pub fn isr_default() noreturn {
    asm volatile ("cli; 1: hlt; jmp 1b;");
    unreachable;
}

pub fn init() void {
    const handler_addr = @intFromPtr(&isr_default);
    var i: usize = 0;
    while (i < idt.len) : (i += 1) {
        set_gate(i, handler_addr, 0x8E); // present, DPL=0, 32-bit interrupt gate
    }

    load_idt();
}
