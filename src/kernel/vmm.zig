// Virtual Memory Manager

pub const VMM = struct {
    initialized: bool,
    pub fn init(self: *VMM) void {
        self.initialized = true;
    }

    pub fn map(self: *VMM, _virt: u32, _phys: u32) bool {
        // Minimal stub: no real paging yet. Accept mappings and pretend success.
        _ = _virt;
        _ = _phys;
        _ = self;
        return true;
    }

    pub fn unmap(self: *VMM, _virt: u32) bool {
        _ = _virt;
        _ = self;
        return true;
    }
};

var vmm: VMM = VMM{ .initialized = false };

pub fn init() void {
    vmm.init();
}

pub fn map(virt: u32, phys: u32) bool {
    return vmm.map(virt, phys);
}

pub fn unmap(virt: u32) bool {
    return vmm.unmap(virt);
}
