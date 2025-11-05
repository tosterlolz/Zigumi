# Zigumi FAT32 Filesystem Quick Reference

## Drive Letter Mapping

| Drive Letter | Physical Drive | Typical Usage |
|---|---|---|
| **A:** | hda (IDE Master on Primary) | Main filesystem |
| **B:** | hdb (IDE Slave on Primary) | Boot/Recovery partition |
| **C:** | hdc (IDE Master on Secondary) | Additional storage |
| **D:** | hdd (IDE Slave on Secondary) | Additional storage |

## File Path Examples

### System Paths (In-Memory)
```
/dev/tty         Terminal device
/dev/null        Null device
/dev/zero        Zero device
/home/           Home directory
/tmp/            Temporary files
/welcome.txt     Welcome message
```

### Drive Paths (FAT32 Filesystems)
```
A:/              Main drive root
A:/file.txt      File on main drive
A:/folder/       Directory on main drive

B:/              Boot drive root
B:/kernel.elf    Kernel image on boot drive

C:/              Third drive (if present)
D:/              Fourth drive (if present)
```

## API Usage

### List Files on a Drive
```zig
const vfs = @import("fs/vfs.zig");
const vga = @import("term/vga.zig");

var writer = vga.Writer.init();
vfs.listFiles(&writer, "A:/");  // Lists main drive
vfs.listFiles(&writer, "B:/");  // Lists boot drive
```

### Check if Drive is Mounted
```zig
const fat32 = @import("fs/fat32.zig");

if (fat32.isMounted('A')) {
    // Main drive is ready
}
```

### Get Filesystem Instance
```zig
if (fat32.getFilesystem('A')) |fs| {
    if (fs.mounted) {
        // Can use the filesystem
        const entries = try fs.listRootDirectory();
    }
}
```

### Read Directory Entries
```zig
const fs = fat32.getFilesystem('A').?;
const entries = try fs.listRootDirectory();

for (entries) |entry| {
    if (entry.name[0] == 0) break;  // End of entries
    if (entry.name[0] == 0xE5) continue;  // Deleted entry
    
    const is_dir = (entry.attributes & 0x10) != 0;
    const file_size = entry.file_size;
    // entry.name is 8.3 format (11 bytes)
}
```

### Read a File
```zig
const file_data = try fat32.readFile("A:/", "README  TXT");
// file_data is [8192]u8 buffer with file contents
```

## Directory Entry Structure

```zig
pub const DirectoryEntry = struct {
    name: [11]u8,              // 8.3 DOS filename format
    attributes: u8,            // File attributes
    reserved: u8,              
    creation_time_tenth: u8,   // Creation time (1/10 second)
    creation_time: u16,        // Creation time
    creation_date: u16,        // Creation date
    access_date: u16,          // Last access date
    cluster_high: u16,         // High word of first cluster
    write_time: u16,           // Last write time
    write_date: u16,           // Last write date
    cluster_low: u16,          // Low word of first cluster
    file_size: u32,            // File size in bytes
};
```

### File Attributes
- Bit 0: Read-only
- Bit 1: Hidden
- Bit 2: System
- Bit 3: Volume label
- Bit 4: Directory
- Bit 5: Archive
- Bit 6-7: Reserved

### 8.3 Filename Format
- First 8 bytes: Base name (padded with spaces)
- Next 3 bytes: Extension (padded with spaces)
- Example: "README  TXT" = "README.TXT"

## Disk Manager API

### Get Manager Instance
```zig
const diskman = @import("drivers/diskman.zig");
const dm = diskman.getManager();
```

### Register Drives
```zig
dm.registerDrive(0, .IDE);  // Register drive 0 (A:)
dm.registerDrive(1, .IDE);  // Register drive 1 (B:)
```

### Get Drive by Letter
```zig
if (dm.getDrive('A')) |drive| {
    try drive.readSector(0, &buffer);
}
```

### Mount/Unmount Drives
```zig
try dm.mountDrive('A');    // Mount drive A:
try dm.unmountDrive('A');  // Unmount drive A:
```

## Error Codes

| Error | Meaning |
|---|---|
| `DriveNotFound` | Specified drive letter doesn't exist |
| `NotMounted` | Filesystem is not mounted |
| `FileNotFound` | Requested file doesn't exist |
| `DiskError` | Hardware read error |
| `DiskTimeout` | I/O operation timed out |
| `FileSystemFull` | No more space in file table |

## Initialization Flow

1. **Boot**: Kernel starts at `_start()`
2. **Disk Manager Init**: Registers drives A: and B:
3. **FAT32 Init**: Creates FAT32FS instances for A: and B:
4. **Mounting**: Attempts to read boot sectors and mount drives
5. **Ready**: VFS routes paths to appropriate filesystem

## Internal Architecture

```
User Code
    ↓
VFS (vfs.zig) - Path routing
    ├─→ Drive paths (A:, B:) → FAT32 Driver
    └─→ System paths (/) → In-memory RAM FS
        ↓
    FAT32 Driver (fat32.zig) - Filesystem logic
        ↓
    Disk Manager (diskman.zig) - Drive management
        ↓
    ATA Driver (ata.zig) - Hardware I/O
```

## Building and Testing

The filesystem modules compile with the main kernel:
```bash
make build
```

To test filesystem operations, create a userland program that calls VFS functions:
```zig
const vfs = @import("fs/vfs.zig");
const vga = @import("term/vga.zig");

pub fn main() void {
    var writer = vga.Writer.init();
    vfs.listFiles(&writer, "A:/");
}
```

## Known Limitations

1. ✗ Only supports root directory listing (subdirectories not navigable)
2. ✗ 8.3 filename format only (no long filenames)
3. ✗ Read-only support (no write capability yet)
4. ✗ No caching (each access reads from disk)
5. ✗ Limited to 4 drives maximum
6. ✗ FAT32 parameters are hardcoded (not parsed from boot sector)

## Future Enhancements

- [ ] Full directory traversal and subdirectory support
- [ ] Write support for FAT32
- [ ] Long Filename (LFN) support
- [ ] Boot sector parsing and validation
- [ ] Disk caching for performance
- [ ] Additional filesystem types
- [ ] Hot-swap drive detection
