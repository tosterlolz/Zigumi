const std = @import("std");

// 64-bit IDT entry for x86_64
pub const IDTEntry = packed struct {
    offset_low: u16,
    selector: u16,
    ist: u8,
    type_attr: u8,
    offset_middle: u16,
    offset_high: u32,
    zero: u32,
};

var idt: [256]IDTEntry = undefined;

const CODE_SEG_SELECTOR: u16 = 0x08;

// Must be static/global so memory persists after function returns
var idtr: [10]u8 = undefined;

pub fn set_gate(vec: usize, handler_addr: usize, flags: u8) void {
    const addr = @as(u64, handler_addr);
    idt[vec].offset_low = @as(u16, @truncate(addr & 0xFFFF));
    idt[vec].selector = CODE_SEG_SELECTOR;
    idt[vec].ist = 0;
    idt[vec].type_attr = flags;
    idt[vec].offset_middle = @as(u16, @truncate((addr >> 16) & 0xFFFF));
    idt[vec].offset_high = @as(u32, @truncate((addr >> 32) & 0xFFFFFFFF));
    idt[vec].zero = 0;
}

pub fn load_idt() void {
    const limit: u16 = @as(u16, @sizeOf(@TypeOf(idt)) - 1);
    idtr[0] = @as(u8, limit & 0xFF);
    idtr[1] = @as(u8, (limit >> 8) & 0xFF);
    const base = @as(usize, @intFromPtr(&idt));
    // write 8-byte base little-endian into idtr[2..10]
    // Write 8-byte little-endian base into idtr[2..10]
    const base64 = @as(u64, base);
    idtr[2] = @as(u8, @truncate(base64 & 0xFF));
    idtr[3] = @as(u8, @truncate((base64 >> 8) & 0xFF));
    idtr[4] = @as(u8, @truncate((base64 >> 16) & 0xFF));
    idtr[5] = @as(u8, @truncate((base64 >> 24) & 0xFF));
    idtr[6] = @as(u8, @truncate((base64 >> 32) & 0xFF));
    idtr[7] = @as(u8, @truncate((base64 >> 40) & 0xFF));
    idtr[8] = @as(u8, @truncate((base64 >> 48) & 0xFF));
    idtr[9] = @as(u8, @truncate((base64 >> 56) & 0xFF));

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
        set_gate(i, handler_addr, 0x8E); // present, DPL=0, interrupt gate
    }

    load_idt();
}
