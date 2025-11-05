const ata = @import("ata.zig");

pub const DriveError = error{
    DriveNotFound,
    NotMounted,
    AlreadyMounted,
    MountFailed,
    DiskError,
};

pub const Drive = struct {
    letter: u8,
    ata_index: u8,
    mounted: bool,
    sector_count: u32,

    pub fn read(self: *const Drive, lba: u32, buffer: []u8) !void {
        if (!self.mounted) return DriveError.NotMounted;
        try ata.read_sectors(self.ata_index, lba, 1, buffer.ptr, @intCast(buffer.len / 512));
    }

    pub fn readSector(self: *const Drive, sector: u32, buffer: [*]u8) !void {
        if (!self.mounted) return DriveError.NotMounted;
        try ata.read_sectors(self.ata_index, sector, 1, buffer, 1);
    }
};

var global_disk_manager: DiskManager = undefined;

pub fn getManager() *DiskManager {
    return &global_disk_manager;
}

pub const DiskManager = struct {
    drives: [4]Drive,
    drive_count: u8,

    pub fn getManager() *DiskManager {
        return &global_disk_manager;
    }

    pub fn registerDrive(self: *DiskManager, letter: u8, ata_index: u8) void {
        if (self.drive_count >= self.drives.len) return;
        self.drives[self.drive_count] = Drive{
            .letter = letter,
            .ata_index = ata_index,
            .mounted = false,
            .sector_count = 0, // Will be set on mount
        };
        self.drive_count += 1;
    }

    pub fn getDrive(self: *DiskManager, letter: u8) !*Drive {
        var i: u8 = 0;
        while (i < self.drive_count) : (i += 1) {
            if (self.drives[i].letter == letter) {
                return &self.drives[i];
            }
        }
        return DriveError.DriveNotFound;
    }

    pub fn mountDrive(self: *DiskManager, letter: u8) !void {
        const drive = try self.getDrive(letter);
        if (drive.mounted) return;

        // In a real implementation, we would detect the filesystem type.
        // For now, we assume FAT32.
        const fat32 = @import("../fs/fat32.zig");
        try fat32.mount(drive);
        drive.mounted = true;
    }
};

pub fn init() void {
    global_disk_manager = DiskManager{
        .drives = undefined,
        .drive_count = 0,
    };
    global_disk_manager.registerDrive('A', 0); // hda
    global_disk_manager.registerDrive('B', 1); // hdb
}
