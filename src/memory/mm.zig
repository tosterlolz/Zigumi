const std = @import("std");

const PAGE_SIZE = 4096;

pub fn allocate(size: usize) !*u8 {
    if (size == 0) {
        return null;
    }
    
    const aligned_size = (size + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
    const ptr = std.heap.page_allocator.alloc(aligned_size) catch |err| {
        return err;
    };
    
    return ptr;
}

pub fn deallocate(ptr: *u8, size: usize) void {
    if (ptr == null or size == 0) {
        return;
    }
    
    const aligned_size = (size + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
    std.heap.page_allocator.free(ptr, aligned_size);
}