// FAT12/16 Filesystem Driver for Zigumi OS

const vga = @import("../term/vga.zig");

// FAT Boot Sector structure
const BootSector = extern struct {
    jmp: [3]u8,
    oem: [8]u8,
    bytes_per_sector: u16,
    sectors_per_cluster: u8,
    reserved_sectors: u16,
    fat_count: u8,
    root_entries: u16,
    total_sectors_16: u16,
    media_type: u8,
    sectors_per_fat: u16,
    sectors_per_track: u16,
    heads: u16,
    hidden_sectors: u32,
    total_sectors_32: u32,
    drive_number: u8,
    reserved: u8,
    signature: u8,
    volume_id: u32,
    volume_label: [11]u8,
    fs_type: [8]u8,
};

// FAT Directory Entry
pub const DirEntry = packed struct {
    name: [11]u8,
    attributes: u8,
    reserved: u8,
    creation_time_ms: u8,
    creation_time: u16,
    creation_date: u16,
    access_date: u16,
    cluster_high: u16,
    modify_time: u16,
    modify_date: u16,
    cluster_low: u16,
    file_size: u32,

    pub fn isLongName(self: *const DirEntry) bool {
        return self.attributes == 0x0F;
    }

    pub fn isDirectory(self: *const DirEntry) bool {
        return (self.attributes & 0x10) != 0;
    }

    pub fn isDeleted(self: *const DirEntry) bool {
        return self.name[0] == 0xE5;
    }

    pub fn isEmpty(self: *const DirEntry) bool {
        return self.name[0] == 0x00;
    }

    pub fn getCluster(self: *const DirEntry) u32 {
        return (@as(u32, self.cluster_high) << 16) | @as(u32, self.cluster_low);
    }
};

pub const FAT = struct {
    boot_sector: BootSector,
    fat_start: u32,
    data_start: u32,
    root_start: u32,
    root_sectors: u32,

    pub fn init() !FAT {
        // For now, assume disk is at 0x7E00 (after bootloader)
        // In a real implementation, we'd read from disk
        var fat: FAT = undefined;

        // Placeholder - would need actual disk I/O
        fat.fat_start = 1;
        fat.data_start = 33;
        fat.root_start = 19;
        fat.root_sectors = 14;

        return fat;
    }

    pub fn readRootDir(self: *const FAT, writer: *vga.Writer) void {
        writer.write("FAT Filesystem:\n");
        writer.write("- FAT Start: ");
        printNum(writer, self.fat_start);
        writer.write("\n- Data Start: ");
        printNum(writer, self.data_start);
        writer.write("\n- Root Start: ");
        printNum(writer, self.root_start);
        writer.write("\n");
    }

    pub fn listFiles(self: *const FAT, writer: *vga.Writer) void {
        _ = self;
        writer.write("\nRoot Directory:\n");
        writer.write("(Disk I/O not yet implemented)\n");
        // TODO: Implement actual disk reading
        // For now, just show placeholder
        writer.write("  README.TXT      1024 bytes\n");
        writer.write("  KERNEL.BIN     8192 bytes\n");
    }
};

fn printNum(writer: *vga.Writer, num: u32) void {
    var buffer: [10]u8 = undefined;
    var n = num;
    var i: usize = 0;

    if (n == 0) {
        writer.write("0");
        return;
    }

    while (n > 0) {
        buffer[i] = @as(u8, @intCast((n % 10) + '0'));
        n /= 10;
        i += 1;
    }

    while (i > 0) {
        i -= 1;
        writer.putChar(buffer[i]);
    }
}
