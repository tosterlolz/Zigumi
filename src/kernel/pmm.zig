// Physical Memory Manager
const std = @import("std");

pub const PMM = struct {
    // 4 KB frames
    const FRAME_SIZE: usize = 4096;
    const MAX_FRAMES: usize = 4096; // Manage up to 16 MB by default

    frames: [MAX_FRAMES]u8,
    base_phys: u32,
    frame_count: usize,

    pub fn init(self: *PMM, base_phys: u32, mem_size_bytes: usize) void {
        self.base_phys = base_phys;
        self.frame_count = mem_size_bytes / FRAME_SIZE;
        if (self.frame_count > MAX_FRAMES) self.frame_count = MAX_FRAMES;
        // 0 = free, 1 = used
        for (self.frames[0..self.frame_count]) |*f| f.* = 0;
    }

    pub fn alloc_frame(self: *PMM) ?u32 {
        var i: usize = 0;
        while (i < self.frame_count) : (i += 1) {
            if (self.frames[i] == 0) {
                self.frames[i] = 1;
                return @as(u32, self.base_phys + @as(u32, i * FRAME_SIZE));
            }
        }
        return null;
    }

    pub fn free_frame(self: *PMM, phys: u32) bool {
        if (phys < self.base_phys) return false;
        const offset = phys - self.base_phys;
        if ((offset % FRAME_SIZE) != 0) return false;
        const index = @as(usize, offset) / FRAME_SIZE;
        if (index >= self.frame_count) return false;
        self.frames[index] = 0;
        return true;
    }
};

var pmm: PMM = PMM{
    .frames = undefined,
    .base_phys = 0x0010_0000, // default 1MB
    .frame_count = 0,
};

pub fn init() void {
    // Reserve 8 MB for now (2048 frames)
    pmm.init(0x0010_0000, 8 * 1024 * 1024);
}

pub fn alloc() ?u32 {
    return pmm.alloc_frame();
}

pub fn free(phys: u32) bool {
    return pmm.free_frame(phys);
}
