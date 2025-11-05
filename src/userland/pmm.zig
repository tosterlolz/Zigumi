const sys = @import("../kernel/syscalls.zig");

pub fn alloc() ?u32 {
    const phys = sys.sys_pmm_alloc();
    if (phys == 0) return null;
    return phys;
}

pub fn free(phys: u32) bool {
    return sys.sys_pmm_free(phys) != 0;
}
