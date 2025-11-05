// ATA/IDE Disk Driver for Zigumi OS
// Supports reading sectors from QEMU virtual drives

pub const ATACommand = enum(u8) {
    ReadSectors = 0x20,
    ReadSectorsExt = 0x24,
    WriteSectors = 0x30,
    WriteSectorsExt = 0x34,
    IdentifyDevice = 0xEC,
};

pub const ATAPort = struct {
    pub const DataPort = 0x1F0;
    pub const ErrorPort = 0x1F1;
    pub const SectorCountPort = 0x1F2;
    pub const LBALowPort = 0x1F3;
    pub const LBAMidPort = 0x1F4;
    pub const LBAHighPort = 0x1F5;
    pub const DrivePort = 0x1F6;
    pub const CommandPort = 0x1F7;
    pub const ControlPort = 0x3F6;
    pub const AltStatusPort = 0x3F6;
};

pub const ATADrive = enum(u8) {
    Master = 0xA0,
    Slave = 0xB0,
};

pub const ATA = struct {
    pub fn outb(port: u16, value: u8) void {
        asm volatile ("outb %[val], %[port]"
            :
            : [val] "{al}" (value),
              [port] "{dx}" (port),
        );
    }

    pub fn inb(port: u16) u8 {
        return asm volatile ("inb %[port]"
            : [ret] "={al}" (-> u8),
            : [port] "{dx}" (port),
        );
    }

    pub fn insw(port: u16, buffer: [*]u16, count: u16) void {
        asm volatile ("rep insw"
            :
            : [port] "{dx}" (port),
              [buffer] "{edi}" (buffer),
              [count] "{ecx}" (count),
        );
    }

    pub fn waitReady() void {
        // Wait for drive to be ready
        var timeout: u32 = 10000000;
        while (timeout > 0) : (timeout -= 1) {
            const status = inb(ATAPort.CommandPort);
            if ((status & 0x80) == 0) return; // Not busy
        }
    }

    pub fn readSector(lba: u32, buffer: [*]u8) !void {
        waitReady();

        // Select drive and set LBA
        const drive_select = @as(u8, 0xE0) | @as(u8, @truncate((lba >> 24) & 0x0F));
        outb(ATAPort.DrivePort, drive_select);

        // Set sector count (1 sector)
        outb(ATAPort.SectorCountPort, 1);

        // Set LBA address
        outb(ATAPort.LBALowPort, @as(u8, @truncate(lba & 0xFF)));
        outb(ATAPort.LBAMidPort, @as(u8, @truncate((lba >> 8) & 0xFF)));
        outb(ATAPort.LBAHighPort, @as(u8, @truncate((lba >> 16) & 0xFF)));

        // Issue read command
        outb(ATAPort.CommandPort, @intFromEnum(ATACommand.ReadSectors));

        // Wait for data ready
        var timeout: u32 = 10000000;
        while (timeout > 0) : (timeout -= 1) {
            const status = inb(ATAPort.CommandPort);
            if ((status & 0x08) != 0) break; // Data ready
            if ((status & 0x01) != 0) return error.DiskError; // Error
        }

        if (timeout == 0) return error.DiskTimeout;

        // Read 256 words (512 bytes) into buffer
        insw(ATAPort.DataPort, @as([*]u16, @ptrCast(@alignCast(buffer))), 256);
    }
};

pub fn read_sectors(drive: u8, lba: u32, count: u32, buffer: [*]u8, _: u32) !void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        try readSectorFromDisk(drive, lba + i, buffer + (i * 512));
    }
}

pub fn readSectorFromDisk(_drive: u8, sector: u32, buffer: [*]u8) !void {
    _ = _drive;
    try ATA.readSector(sector, buffer);
}
