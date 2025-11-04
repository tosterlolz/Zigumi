const std = @import("std");

const PAGE_SIZE = 4096;
const PAGE_TABLE_SIZE = 512;
const PAGE_DIRECTORY_SIZE = 512;

const PAGE_PRESENT = 1 << 0;
const PAGE_WRITE = 1 << 1;
const PAGE_USER = 1 << 2;

pub const PageTable = extern struct {
    entries: [PAGE_TABLE_SIZE]u64,
};

pub const PageDirectory = extern struct {
    entries: [PAGE_DIRECTORY_SIZE]u64,
};

pub fn init() void {
    // Initialize the page directory and page tables here
}

fn map_page(directory: *PageDirectory, virtual_addr: u64, physical_addr: u64, flags: u64) void {
    const index = (virtual_addr >> 12) & 0x1FF;
    if (directory.entries[index] == 0) {
        // Allocate a new page table
        const new_table = @ptrCast(*PageTable, std.heap.page_allocator.alloc(PageTable, 1));
        directory.entries[index] = @ptrToInt(new_table) | PAGE_PRESENT | PAGE_WRITE;
    }
    const table = @ptrCast(*PageTable, directory.entries[index] & 0xFFFFFFFFFFFFF000);
    table.entries[(virtual_addr >> 21) & 0x1FF] = physical_addr | flags;
}

fn unmap_page(directory: *PageDirectory, virtual_addr: u64) void {
    const index = (virtual_addr >> 12) & 0x1FF;
    const table = @ptrCast(*PageTable, directory.entries[index] & 0xFFFFFFFFFFFFF000);
    table.entries[(virtual_addr >> 21) & 0x1FF] = 0;
}

fn switch_page_directory(directory: *PageDirectory) void {
    @asm("mov %0, %%cr3" : : "r"(directory));
}

fn enable_paging() void {
    const cr0: u64 = @asm("mov %%cr0, %0" : "=r"(0));
    @asm("mov %0, %%cr0" : : "r"(cr0 | 0x80000000));
}