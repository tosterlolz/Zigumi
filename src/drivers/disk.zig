// ATA/IDE Disk Driver for Zigumi OS

// ATA I/O Ports
const ATA_PRIMARY_DATA: u16 = 0x1F0;
const ATA_PRIMARY_ERROR: u16 = 0x1F1;
const ATA_PRIMARY_SECTOR_COUNT: u16 = 0x1F2;
const ATA_PRIMARY_LBA_LOW: u16 = 0x1F3;
const ATA_PRIMARY_LBA_MID: u16 = 0x1F4;
const ATA_PRIMARY_LBA_HIGH: u16 = 0x1F5;
const ATA_PRIMARY_DRIVE_HEAD: u16 = 0x1F6;
const ATA_PRIMARY_STATUS: u16 = 0x1F7;
const ATA_PRIMARY_COMMAND: u16 = 0x1F7;

// ATA Commands
const ATA_CMD_READ_SECTORS: u8 = 0x20;
const ATA_CMD_IDENTIFY: u8 = 0xEC;

// ATA Status bits
const ATA_STATUS_BSY: u8 = 0x80; // Busy
const ATA_STATUS_DRQ: u8 = 0x08; // Data Request Ready
const ATA_STATUS_ERR: u8 = 0x01; // Error

pub const Disk = struct {
    pub fn init() Disk {
        return Disk{};
    }

    // Read a sector from disk
    pub fn readSector(self: *const Disk, lba: u32, buffer: [*]u8) bool {
        _ = self;

        // Wait for drive to be ready
        while ((inb(ATA_PRIMARY_STATUS) & ATA_STATUS_BSY) != 0) {}

        // Select drive and LBA mode
        outb(ATA_PRIMARY_DRIVE_HEAD, 0xE0 | @as(u8, @truncate((lba >> 24) & 0x0F)));

        // Send sector count (1 sector)
        outb(ATA_PRIMARY_SECTOR_COUNT, 1);

        // Send LBA address
        outb(ATA_PRIMARY_LBA_LOW, @truncate(lba & 0xFF));
        outb(ATA_PRIMARY_LBA_MID, @truncate((lba >> 8) & 0xFF));
        outb(ATA_PRIMARY_LBA_HIGH, @truncate((lba >> 16) & 0xFF));

        // Send read command
        outb(ATA_PRIMARY_COMMAND, ATA_CMD_READ_SECTORS);

        // Wait for drive to be ready
        while ((inb(ATA_PRIMARY_STATUS) & ATA_STATUS_BSY) != 0) {}

        // Check for errors
        if ((inb(ATA_PRIMARY_STATUS) & ATA_STATUS_ERR) != 0) {
            return false;
        }

        // Wait for data to be ready
        while ((inb(ATA_PRIMARY_STATUS) & ATA_STATUS_DRQ) == 0) {}

        // Read 256 words (512 bytes)
        var i: u32 = 0;
        while (i < 256) : (i += 1) {
            const word = inw(ATA_PRIMARY_DATA);
            buffer[i * 2] = @truncate(word & 0xFF);
            buffer[i * 2 + 1] = @truncate((word >> 8) & 0xFF);
        }

        return true;
    }

    pub fn readSectors(self: *const Disk, lba: u32, count: u32, buffer: [*]u8) bool {
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            if (!self.readSector(lba + i, buffer + (i * 512))) {
                return false;
            }
        }
        return true;
    }
};

// Port I/O functions
fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

fn inw(port: u16) u16 {
    return asm volatile ("inw %[port], %[result]"
        : [result] "={ax}" (-> u16),
        : [port] "N{dx}" (port),
    );
}

fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "N{dx}" (port),
    );
}
