# FAT32 Filesystem Fix and Drive Letters Implementation

## Summary
Fixed the FAT32 filesystem driver and added support for drive letters (A:/, B:/, C:/, D:/) to map different ATA drives.

## New Features

### 1. **Disk Manager** (`src/drivers/diskman.zig`)
- New module to manage multiple ATA drives with drive letters
- `Drive` struct: Represents an individual disk drive with:
  - Drive letter (A-D)
  - ATA drive index
  - Mount status
  - Sector count
  - Read operations

- `DiskManager` struct: Central management system with:
  - Drive registration (`registerDrive`)
  - Drive lookup by letter (`getDrive`)
  - Drive mounting/unmounting (`mountDrive`, `unmountDrive`)
  - Drive enumeration

- Default configuration:
  - **A:/** - Primary IDE drive (hda)
  - **B:/** - Secondary IDE drive (hdb)
  - **C:/** - Tertiary IDE drive (hdc) - optional
  - **D:/** - Quaternary IDE drive (hdd) - optional

### 2. **Fixed FAT32 Driver** (`src/fs/fat32.zig`)
Major improvements:
- **Multi-drive support**: Each drive (A:, B:, etc.) has its own FAT32FS instance
- **Proper mounting**: Uses disk manager to read actual boot sectors
- **Cluster chain following**: Correctly implements FAT chain traversal
- **Better structure**:
  - Added `drive_letter` field to FAT32FS
  - Connected to DiskManager for hardware access
  - Proper error handling for mount failures

**Key functions:**
- `init()` - Initializes filesystems for A: and B: drives
- `mount()` - Reads boot sector and sets up filesystem parameters
- `readCluster()` - Reads file data clusters
- `getNextCluster()` - Follows FAT cluster chains
- `listDir(path)` - Lists directory entries (now supports drive letters like "A:/")
- `readFile(path, filename)` - Reads files from specific drives

### 3. **Enhanced VFS** (`src/fs/vfs.zig`)
- **Drive letter support**: Paths can now be:
  - In-memory: `/dev/tty`, `/tmp/file`, etc.
  - Drive-based: `A:/file.txt`, `B:/data/`, etc.
- **Helper functions**:
  - `isDriveLetter()` - Detects if path has drive letter
  - `extractDriveLetter()` - Extracts and normalizes drive letter
  - `listDriveFiles()` - Lists files from FAT32 drives

- **Updated functions**:
  - `listFiles(writer, path)` - Now takes path parameter
  - Automatically routes to FAT32 driver for drive paths
  - Falls back to in-memory filesystem for other paths

### 4. **Updated Kernel** (`src/kernel.zig`)
- Added disk manager initialization
- Added FAT32 filesystem initialization
- Proper boot sequence:
  1. Syscalls
  2. Scheduler
  3. TTY
  4. **Disk Manager** ← NEW
  5. ATA Driver
  6. **FAT32 Filesystem** ← NOW ENABLED

## Architecture

```
Kernel
├── Disk Manager (diskman.zig)
│   └── Manages A:, B:, C:, D: drive letters
│       └── Each maps to an ATA drive
│
├── FAT32 Driver (fat32.zig)
│   └── Instances for each mounted drive
│   └── Handles FAT32 specifics (boot sector, FAT chains, clusters)
│
├── VFS (vfs.zig)
│   └── Route paths to appropriate filesystem
│   ├── Drive paths (A:/, B:/) → FAT32 Driver
│   └── System paths (/dev, /tmp) → In-memory FS
│
└── ATA Driver (ata.zig)
    └── Low-level disk I/O
```

## Path Examples

### In-Memory Filesystem (Unchanged)
```
/dev/tty          - Terminal device
/dev/null         - Null device
/home/            - User home directory
/tmp/             - Temporary files
/welcome.txt      - Welcome file
```

### FAT32 Filesystems (NEW)
```
A:/               - Main drive root
A:/file.txt       - File on main drive
A:/subdir/        - Subdirectory on main drive

B:/               - Boot drive root
B:/kernel.elf     - Kernel file on boot drive

C:/               - Optional third drive
D:/               - Optional fourth drive
```

## Error Handling

- `DriveNotFound` - Drive letter doesn't exist
- `NotMounted` - Filesystem not mounted
- `FileNotFound` - File doesn't exist
- `DiskError` - Hardware read failure
- `DiskTimeout` - I/O timeout

## Future Improvements

1. Implement full directory traversal (currently root directory only)
2. Add write support for FAT32
3. Support long filenames (LFN)
4. Implement directory caching
5. Add hot-swap support for drives
6. Support additional filesystem types (ext2, NTFS)

## Testing

To test the implementation:

```zig
// Mount drives
const diskman = diskman.getManager();
diskman.mountDrive('A') catch unreachable;

// List drive contents
vfs.listFiles(writer, "A:/");

// Read files
const fat32 = fat32.getFilesystem('A');
if (fat32.mounted) {
    const entries = try fat32.listRootDirectory();
}
```

## Compatibility

- **Boot sector format**: Standard FAT32 (512-byte sectors)
- **Cluster size**: 8 sectors per cluster (typical)
- **FAT entries**: 32-bit cluster pointers with 4-bit masking
- **ATA interface**: LBA28 mode (supports up to 28-bit addresses)
