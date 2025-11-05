// FAT32 Filesystem driver for Zigumi OS

const diskman = @import("../drivers/diskman.zig");
const vfs = @import("vfs.zig");
const std = @import("std");

const BootSector = extern struct {
    _jmp: [3]u8,
    _oem: [8]u8,
    bytes_per_sector: u16,
    sectors_per_cluster: u8,
    reserved_sectors: u16,
    fat_count: u8,
    root_entries: u16,
    total_sectors16: u16,
    _media: u8,
    sectors_per_fat16: u16,
    _sectors_per_track: u16,
    _heads: u16,
    hidden_sectors: u32,
    total_sectors32: u32,
    sectors_per_fat32: u32,
    _flags: u16,
    _version: u16,
    root_cluster: u32,
    fs_info: u16,
    backup_boot_sector: u16,
    _reserved: [12]u8,
    drive_num: u8,
    _reserved1: u8,
    boot_sig: u8,
    volume_id: u32,
    volume_label: [11]u8,
    fs_type: [8]u8,
};

pub const DirectoryEntry = struct {
    name: [11]u8,
    attributes: u8,
    reserved: u8,
    creation_time_tenth: u8,
    creation_time: u16,
    creation_date: u16,
    access_date: u16,
    cluster_high: u16,
    write_time: u16,
    write_date: u16,
    cluster_low: u16,
    file_size: u32,
};

pub const FAT32Error = error{
    NotMounted,
    DriveNotFound,
    FileNotFound,
    ReadError,
};

var current_fs: ?*FAT32FS = null;

pub fn mount(drive: *diskman.Drive) !void {
    const fs = switch (drive.letter) {
        'A', 'a' => &fat32fs_a,
        'B', 'b' => &fat32fs_b,
        else => return FAT32Error.DriveNotFound,
    };
    try fs.mount();
}

pub fn changeDrive(letter: u8) bool {
    const dm = diskman.getManager();
    const drive = dm.getDrive(letter) catch return false;
    if (!drive.mounted) {
        dm.mountDrive(letter) catch return false;
    }
    return true;
}

pub fn changeDir(path: []const u8) bool {
    var letter: u8 = 'A';
    var actual_path: []const u8 = path;

    // Check for drive letter in path
    if (path.len > 1 and path[1] == ':') {
        letter = path[0];
        actual_path = path[2..];
    }

    const fs = getFilesystem(letter) orelse return false;
    _ = fs; // fs is used in real implementation to traverse directories

    // For now, just verify directory exists by listing it
    _ = listDir(actual_path) catch return false;
    return true;
}

pub const FAT32FS = struct {
    boot_sector: BootSector,
    mounted: bool,
    drive_letter: u8,
    drive: ?*diskman.Drive,
    bytes_per_sector: u32,
    sectors_per_cluster: u32,
    reserved_sectors: u32,
    fat_offset: u32,
    fat_size: u32,
    num_fats: u32,
    root_cluster: u32,
    data_offset: u32,
    boot_buffer: [512]u8,

    pub fn init(letter: u8) FAT32FS {
        return FAT32FS{
            .boot_sector = undefined,
            .mounted = false,
            .drive_letter = letter,
            .drive = null,
            .bytes_per_sector = 512,
            .sectors_per_cluster = 8,
            .reserved_sectors = 32,
            .fat_offset = 0,
            .fat_size = 2048,
            .num_fats = 2,
            .root_cluster = 2,
            .data_offset = 0,
            .boot_buffer = [_]u8{0} ** 512,
        };
    }

    pub fn mount(self: *FAT32FS) !void {
        const dm = diskman.getManager();
        const mounted_drive = try dm.getDrive(self.drive_letter);
        self.drive = mounted_drive;

        try mounted_drive.readSector(0, &self.boot_buffer);

        const bs = @as(*const BootSector, @ptrCast(@alignCast(&self.boot_buffer))).*;
        self.bytes_per_sector = @as(u32, bs.bytes_per_sector);
        self.sectors_per_cluster = @as(u32, bs.sectors_per_cluster);
        self.reserved_sectors = @as(u32, bs.reserved_sectors);
        self.fat_size = @as(u32, bs.sectors_per_fat32);
        self.num_fats = @as(u32, bs.fat_count);
        self.root_cluster = bs.root_cluster;

        // Calculate important offsets
        self.fat_offset = self.reserved_sectors;
        self.data_offset = self.fat_offset + (self.num_fats * self.fat_size);

        self.mounted = true;
    }

    pub fn readCluster(self: *FAT32FS, cluster: u32, buffer: [*]u8) !void {
        if (!self.mounted) return FAT32Error.NotMounted;
        const drive = self.drive orelse return FAT32Error.NotMounted;

        const first_sector = self.data_offset + ((cluster - 2) * self.sectors_per_cluster);
        var i: u32 = 0;
        while (i < self.sectors_per_cluster) : (i += 1) {
            try drive.readSector(first_sector + i, buffer + (i * self.bytes_per_sector));
        }
    }

    pub fn getNextCluster(self: *FAT32FS, cluster: u32) !u32 {
        if (!self.mounted) return FAT32Error.NotMounted;
        const drive = self.drive orelse return FAT32Error.NotMounted;

        const fat_sector = self.fat_offset + (cluster * 4) / 512;
        const entry_offset = (cluster * 4) % 512;

        var fat_buffer: [512]u8 = undefined;
        try drive.readSector(fat_sector, &fat_buffer);

        const fat_entry = @as(*const u32, @ptrCast(@alignCast(&fat_buffer[entry_offset])));
        return fat_entry.* & 0x0FFFFFFF;
    }

    pub fn listRootDirectory(self: *FAT32FS) ![]DirectoryEntry {
        if (!self.mounted) return FAT32Error.NotMounted;

        var cluster_buffer: [8192]u8 = undefined;
        try self.readCluster(self.root_cluster, &cluster_buffer);

        var entries: [256]DirectoryEntry = undefined;
        var entry_count: usize = 0;

        var i: usize = 0;
        while (i < cluster_buffer.len and entry_count < 256) : (i += 32) {
            const entry = @as(*const DirectoryEntry, @ptrCast(@alignCast(&cluster_buffer[i])));
            if (entry.name[0] == 0) break;
            if (entry.name[0] == 0xE5) continue;

            entries[entry_count] = entry.*;
            entry_count += 1;
        }

        return entries[0..entry_count];
    }

    pub fn readFileData(self: *FAT32FS, cluster: u32, size: u32) ![]u8 {
        if (!self.mounted) return FAT32Error.NotMounted;

        var buffer: [8192]u8 = undefined;
        var bytes_read: u32 = 0;
        var current_cluster = cluster;

        while (bytes_read < size and current_cluster < 0x0FFFFFF8) {
            const to_read = @min(self.sectors_per_cluster * self.bytes_per_sector, size - bytes_read);

            try self.readCluster(current_cluster, @as([*]u8, @ptrCast(&buffer)) + bytes_read);
            bytes_read += to_read;

            current_cluster = try self.getNextCluster(current_cluster);
        }

        return buffer[0..bytes_read];
    }
};

var fat32fs_a: FAT32FS = undefined;
var fat32fs_b: FAT32FS = undefined;
var initialized: bool = false;

pub fn init() void {
    fat32fs_a = FAT32FS.init('A');
    fat32fs_b = FAT32FS.init('B');

    // Try mounting both drives
    fat32fs_a.mount() catch {};
    fat32fs_b.mount() catch {};

    initialized = true;
}

pub fn getFilesystem(letter: u8) ?*FAT32FS {
    return switch (letter) {
        'A', 'a' => &fat32fs_a,
        'B', 'b' => &fat32fs_b,
        else => null,
    };
}

pub fn isInitialized() bool {
    return initialized;
}

pub fn isMounted(letter: u8) bool {
    if (getFilesystem(letter)) |fs| {
        return fs.mounted;
    }
    return false;
}

pub fn listDir(path: []const u8) ![]DirectoryEntry {
    // Default to A: if no drive letter specified
    var letter: u8 = 'A';
    var actual_path: []const u8 = path;

    // Check for drive letter in path
    if (path.len > 1 and path[1] == ':') {
        letter = path[0];
        actual_path = path[2..];
    }

    const fs = getFilesystem(letter) orelse return FAT32Error.DriveNotFound;

    // For now, just list root directory
    // TODO: Add support for subdirectories
    return fs.listRootDirectory();
}

pub fn readFile(path: []const u8, name: []const u8) ![]u8 {
    // Default to A: if no drive letter specified
    var letter: u8 = 'A';
    if (path.len > 1 and path[1] == ':') {
        letter = path[0];
    }

    const fs = getFilesystem(letter) orelse return FAT32Error.DriveNotFound;
    const entries = try fs.listRootDirectory();

    // Find file in directory entries
    for (entries) |entry| {
        if (entry.name[0] == 0) break;

        // Simple 8.3 name matching
        var match = true;
        for (0..name.len) |i| {
            if (i >= 11) break;
            if (entry.name[i] != name[i]) {
                match = false;
                break;
            }
        }

        if (match) {
            const cluster = (@as(u32, entry.cluster_high) << 16) | entry.cluster_low;
            return fs.readFileData(cluster, entry.file_size);
        }
    }

    return FAT32Error.FileNotFound;
}
