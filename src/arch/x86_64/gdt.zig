const std = @import("std");

pub const GDTEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: u8,
    flags: u8,
    base_high: u8,
    limit_high: u16,
    reserved: u8,
};

pub const GDTDescriptor = packed struct {
    limit: u16,
    base: u32,
};

const GDT_SIZE = 3;

var gdt: [GDT_SIZE]GDTEntry = undefined;
var gdt_descriptor: GDTDescriptor = GDTDescriptor{ .limit = (GDT_SIZE * @sizeOf(GDTEntry) - 1) as u16, .base = @ptrToInt(&gdt) };

pub fn init() void {
    gdt[0] = GDTEntry{ .limit_low = 0, .base_low = 0, .base_middle = 0, .access = 0, .flags = 0, .base_high = 0, .limit_high = 0, .reserved = 0 }; // Null descriptor
    gdt[1] = GDTEntry{ .limit_low = 0xFFFF, .base_low = 0, .base_middle = 0, .access = 0b10011010, .flags = 0b11001111, .base_high = 0, .limit_high = 0xF }; // Code segment
    gdt[2] = GDTEntry{ .limit_low = 0xFFFF, .base_low = 0, .base_middle = 0, .access = 0b10010010, .flags = 0b11001111, .base_high = 0, .limit_high = 0xF }; // Data segment

    // Load the GDT
    @asm("lgdt [{}]", &gdt_descriptor);
    @asm("mov ax, 0x10"); // Load data segment selector
    @asm("mov ds, ax");
    @asm("mov es, ax");
    @asm("mov fs, ax");
    @asm("mov gs, ax");
    @asm("mov ss, ax");
    @asm("jmp 0x08:main"); // Jump to code segment
}