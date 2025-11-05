const sys = @import("../kernel/syscalls.zig");

pub fn map(virt: u32, phys: u32, flags: u32) bool {
    return sys.sys_vmm_map(virt, phys, flags) != 0;
}

pub fn unmap(virt: u32) bool {
    return sys.sys_vmm_unmap(virt) != 0;
}
