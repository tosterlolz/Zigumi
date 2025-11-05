// Common filesystem interface for Zigumi OS
// This provides a unified way to interact with different filesystem types
// without VFS dependencies or hardcoded values

const vga = @import("../term/vga.zig");

pub const FilesystemType = enum {
    EXT2,
    FAT32,
    Unknown,
};

pub const FileType = enum(u8) {
    Unknown = 0,
    Regular = 1,
    Directory = 2,
    CharDevice = 3,
    BlockDevice = 4,
    FIFO = 5,
    Socket = 6,
    Symlink = 7,
};

pub const FileInfo = struct {
    name: [256]u8,
    name_len: usize,
    file_type: FileType,
    size: u32,
    inode: u32,
};

pub const FilesystemError = error{
    NotMounted,
    NotSupported,
    NotFound,
    FileSystemFull,
    InvalidPath,
    ReadError,
    WriteError,
};

// Generic filesystem interface
pub const Filesystem = struct {
    fs_type: FilesystemType,
    mounted: bool,
    implementation: *anyopaque,

    // Function pointers for operations
    listFilesFn: *const fn (*anyopaque, *vga.Writer, []const u8) FilesystemError!void,
    readFileFn: *const fn (*anyopaque, []const u8, []u8) FilesystemError!usize,
    createFileFn: *const fn (*anyopaque, []const u8, FileType) FilesystemError!u32,

    pub fn listFiles(self: *Filesystem, writer: *vga.Writer, path: []const u8) !void {
        if (!self.mounted) return FilesystemError.NotMounted;
        return self.listFilesFn(self.implementation, writer, path);
    }

    pub fn readFile(self: *Filesystem, path: []const u8, buffer: []u8) !usize {
        if (!self.mounted) return FilesystemError.NotMounted;
        return self.readFileFn(self.implementation, path, buffer);
    }

    pub fn createFile(self: *Filesystem, path: []const u8, file_type: FileType) !u32 {
        if (!self.mounted) return FilesystemError.NotMounted;
        return self.createFileFn(self.implementation, path, file_type);
    }
};

// Filesystem registry
const MAX_FILESYSTEMS = 8;

var registered_filesystems: [MAX_FILESYSTEMS]?Filesystem = [_]?Filesystem{null} ** MAX_FILESYSTEMS;
var fs_registry_count: usize = 0;

pub fn registerFilesystem(fs: Filesystem) !u32 {
    if (fs_registry_count >= MAX_FILESYSTEMS) {
        return FilesystemError.FileSystemFull;
    }

    registered_filesystems[fs_registry_count] = fs;
    const id = @as(u32, @intCast(fs_registry_count));
    fs_registry_count += 1;

    return id;
}

pub fn getFilesystem(id: u32) ?*Filesystem {
    if (id >= fs_registry_count) return null;
    if (registered_filesystems[id]) |*fs| {
        return fs;
    }
    return null;
}

pub fn getFilesystemByType(fs_type: FilesystemType) ?*Filesystem {
    var i: usize = 0;
    while (i < fs_registry_count) : (i += 1) {
        if (registered_filesystems[i]) |*fs| {
            if (fs.fs_type == fs_type) {
                return fs;
            }
        }
    }
    return null;
}

pub fn init() void {
    var i: usize = 0;
    while (i < MAX_FILESYSTEMS) : (i += 1) {
        registered_filesystems[i] = null;
    }
    fs_registry_count = 0;
}
