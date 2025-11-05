// EXT2 Filesystem implementation for Zigumi OS

const vga = @import("../term/vga.zig");

// EXT2 Superblock structure
pub const Superblock = packed struct {
    s_inodes_count: u32, // Total number of inodes
    s_blocks_count: u32, // Total number of blocks
    s_r_blocks_count: u32, // Number of reserved blocks
    s_free_blocks_count: u32, // Number of free blocks
    s_free_inodes_count: u32, // Number of free inodes
    s_first_data_block: u32, // First data block
    s_log_block_size: u32, // Block size = 1024 << s_log_block_size
    s_log_frag_size: i32, // Fragment size
    s_blocks_per_group: u32, // Blocks per group
    s_frags_per_group: u32, // Fragments per group
    s_inodes_per_group: u32, // Inodes per group
    s_mtime: u32, // Mount time
    s_wtime: u32, // Write time
    s_mnt_count: u16, // Mount count
    s_max_mnt_count: u16, // Maximum mount count
    s_magic: u16, // Magic signature (0xEF53)
    s_state: u16, // File system state
    s_errors: u16, // Behavior when detecting errors
    s_minor_rev_level: u16, // Minor revision level
    s_lastcheck: u32, // Time of last check
    s_checkinterval: u32, // Maximum time between checks
    s_creator_os: u32, // OS that created the filesystem
    s_rev_level: u32, // Revision level
    s_def_resuid: u16, // Default uid for reserved blocks
    s_def_resgid: u16, // Default gid for reserved blocks
};

// EXT2 Inode structure (simplified)
pub const Inode = struct {
    i_mode: u16, // File mode
    i_uid: u16, // Owner UID
    i_size: u32, // Size in bytes
    i_atime: u32, // Access time
    i_ctime: u32, // Creation time
    i_mtime: u32, // Modification time
    i_dtime: u32, // Deletion time
    i_gid: u16, // Group ID
    i_links_count: u16, // Links count
    i_blocks: u32, // Blocks count
    i_flags: u32, // File flags
    i_osd1: u32, // OS dependent 1
    i_block: [15]u32, // Pointers to blocks
    i_generation: u32, // File version
    i_file_acl: u32, // File ACL
    i_dir_acl: u32, // Directory ACL
    i_faddr: u32, // Fragment address
    i_osd2: [12]u8, // OS dependent 2
};

// Directory entry
pub const DirEntry = packed struct {
    inode: u32, // Inode number
    rec_len: u16, // Directory entry length
    name_len: u8, // Name length
    file_type: u8, // File type
    // name follows (variable length)
};

// File types
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

const EXT2_MAGIC = 0xEF53;

// Simple in-memory EXT2 representation
pub const Ext2FS = struct {
    superblock: Superblock,
    inodes: []?Inode,
    directory_entries: []DirEntryInfo,
    mounted: bool,
    block_size: u32,
    max_inodes: u32,
    allocator: ?*anyopaque,

    pub fn init(max_inodes: u32, block_size: u32) Ext2FS {
        return Ext2FS{
            .superblock = Superblock{
                .s_inodes_count = max_inodes,
                .s_blocks_count = 100,
                .s_r_blocks_count = 5,
                .s_free_blocks_count = 90,
                .s_free_inodes_count = max_inodes - 2, // root + lost+found
                .s_first_data_block = 1,
                .s_log_block_size = 0, // 1024 bytes
                .s_log_frag_size = 0,
                .s_blocks_per_group = 8192,
                .s_frags_per_group = 8192,
                .s_inodes_per_group = max_inodes,
                .s_mtime = 0,
                .s_wtime = 0,
                .s_mnt_count = 0,
                .s_max_mnt_count = 20,
                .s_magic = EXT2_MAGIC,
                .s_state = 1, // Clean
                .s_errors = 1, // Continue on errors
                .s_minor_rev_level = 0,
                .s_lastcheck = 0,
                .s_checkinterval = 0,
                .s_creator_os = 0, // Linux
                .s_rev_level = 0,
                .s_def_resuid = 0,
                .s_def_resgid = 0,
            },
            .inodes = &[_]?Inode{}, // Will be initialized properly in mount()
            .directory_entries = &[_]DirEntryInfo{},
            .mounted = false,
            .block_size = block_size,
            .max_inodes = max_inodes,
            .allocator = null,
        };
    }

    pub fn mount(self: *Ext2FS) !void {
        if (self.superblock.s_magic != EXT2_MAGIC) {
            return error.InvalidMagic;
        }

        self.mounted = true;
        self.block_size = @as(u32, 1024) << @as(u5, @intCast(self.superblock.s_log_block_size));

        // Create root directory inode
        self.inodes[2] = Inode{
            .i_mode = 0x41ED, // Directory with 755 permissions
            .i_uid = 0,
            .i_size = 0,
            .i_atime = 0,
            .i_ctime = 0,
            .i_mtime = 0,
            .i_dtime = 0,
            .i_gid = 0,
            .i_links_count = 2,
            .i_blocks = 0,
            .i_flags = 0,
            .i_osd1 = 0,
            .i_block = [_]u32{0} ** 15,
            .i_generation = 0,
            .i_file_acl = 0,
            .i_dir_acl = 0,
            .i_faddr = 0,
            .i_osd2 = [_]u8{0} ** 12,
        };

        // Initialize directory entries
        var di: usize = 0;
        while (di < self.directory_entries.len) : (di += 1) {
            self.directory_entries[di] = DirEntryInfo{
                .inode = 0,
                .name = [_]u8{0} ** 256,
                .name_len = 0,
                .file_type = .Unknown,
            };
        }
    }

    pub fn createFile(self: *Ext2FS, name: []const u8, file_type: FileType) !u32 {
        if (!self.mounted) return error.NotMounted;
        if (self.superblock.s_free_inodes_count == 0) return error.NoFreeInodes;

        // Find free inode
        var inode_num: u32 = 11; // Start from 11 (first 10 reserved)
        while (inode_num < self.max_inodes) : (inode_num += 1) {
            if (self.inodes[inode_num] == null) {
                break;
            }
        }

        if (inode_num >= self.max_inodes) return error.NoFreeInodes;

        // Create inode
        const mode: u16 = if (file_type == .Directory) 0x41ED else 0x81A4;
        self.inodes[inode_num] = Inode{
            .i_mode = mode,
            .i_uid = 0,
            .i_size = 0,
            .i_atime = 0,
            .i_ctime = 0,
            .i_mtime = 0,
            .i_dtime = 0,
            .i_gid = 0,
            .i_links_count = 1,
            .i_blocks = 0,
            .i_flags = 0,
            .i_osd1 = 0,
            .i_block = [_]u32{0} ** 15,
            .i_generation = 0,
            .i_file_acl = 0,
            .i_dir_acl = 0,
            .i_faddr = 0,
            .i_osd2 = [_]u8{0} ** 12,
        };

        // Add directory entry
        var i: usize = 0;
        while (i < self.directory_entries.len) : (i += 1) {
            if (self.directory_entries[i].inode == 0) {
                self.directory_entries[i].inode = inode_num;
                var j: usize = 0;
                while (j < name.len and j < 255) : (j += 1) {
                    self.directory_entries[i].name[j] = name[j];
                }
                self.directory_entries[i].name_len = @as(u8, @intCast(j));
                self.directory_entries[i].file_type = file_type;
                break;
            }
        }

        self.superblock.s_free_inodes_count -= 1;
        return inode_num;
    }

    pub fn listFiles(self: *Ext2FS, writer: *vga.Writer) void {
        if (!self.mounted) {
            writer.write("Filesystem not mounted\n");
            return;
        }

        writer.write("INODE TYPE      NAME\n");
        writer.write("----- --------  ----------------\n");

        for (self.directory_entries) |entry| {
            if (entry.inode != 0) {
                // Print inode number
                printNum(writer, entry.inode);
                writer.write("     ");

                // Print type
                const type_str = switch (entry.file_type) {
                    .Regular => "FILE    ",
                    .Directory => "DIR     ",
                    .CharDevice => "CHAR    ",
                    .BlockDevice => "BLOCK   ",
                    .Symlink => "LINK    ",
                    else => "UNKNOWN ",
                };
                writer.write(type_str);
                writer.write("  ");

                // Print name
                var i: usize = 0;
                while (i < entry.name_len) : (i += 1) {
                    writer.putChar(entry.name[i]);
                }
                writer.write("\n");
            }
        }

        writer.write("\nFilesystem Info:\n");
        writer.write("  Total inodes: ");
        printNum(writer, self.superblock.s_inodes_count);
        writer.write("\n  Free inodes:  ");
        printNum(writer, self.superblock.s_free_inodes_count);
        writer.write("\n  Block size:   ");
        printNum(writer, self.block_size);
        writer.write(" bytes\n");
    }

    pub fn getInfo(self: *Ext2FS) SuperblockInfo {
        return SuperblockInfo{
            .magic = self.superblock.s_magic,
            .total_inodes = self.superblock.s_inodes_count,
            .free_inodes = self.superblock.s_free_inodes_count,
            .total_blocks = self.superblock.s_blocks_count,
            .free_blocks = self.superblock.s_free_blocks_count,
            .block_size = self.block_size,
            .mounted = self.mounted,
        };
    }
};

pub const DirEntryInfo = struct {
    inode: u32,
    name: [256]u8,
    name_len: u8,
    file_type: FileType,
};

pub const SuperblockInfo = struct {
    magic: u16,
    total_inodes: u32,
    free_inodes: u32,
    total_blocks: u32,
    free_blocks: u32,
    block_size: u32,
    mounted: bool,
};

fn printNum(writer: *vga.Writer, num: u32) void {
    if (num == 0) {
        writer.putChar('0');
        return;
    }

    if (num < 10) {
        writer.putChar(@as(u8, @intCast(num + '0')));
    } else {
        printNum(writer, num / 10);
        writer.putChar(@as(u8, @intCast((num % 10) + '0')));
    }
}

// Global EXT2 filesystem instances with fixed-size storage
const DEFAULT_MAX_INODES = 128;
const DEFAULT_BLOCK_SIZE = 1024;

var ext2fs_inodes: [DEFAULT_MAX_INODES]?Inode = [_]?Inode{null} ** DEFAULT_MAX_INODES;
var ext2fs_dir_entries: [DEFAULT_MAX_INODES]DirEntryInfo = undefined;
var ext2fs: Ext2FS = undefined;
var initialized: bool = false;

pub fn init() void {
    // Initialize ext2fs structure with fixed-size storage
    ext2fs = Ext2FS.init(DEFAULT_MAX_INODES, DEFAULT_BLOCK_SIZE);
    ext2fs.inodes = ext2fs_inodes[0..];
    ext2fs.directory_entries = ext2fs_dir_entries[0..];

    // Try to mount the filesystem from the virtual superblock
    ext2fs.mount() catch {
        // If mount fails, just initialize as virtual
        ext2fs.mounted = true;
        ext2fs.block_size = DEFAULT_BLOCK_SIZE;

        // Initialize root directory inode (inode 2)
        if (ext2fs.inodes[2] == null) {
            ext2fs.inodes[2] = Inode{
                .i_mode = 0x41ED, // Directory with 755 permissions
                .i_uid = 0,
                .i_size = 0,
                .i_atime = 0,
                .i_ctime = 0,
                .i_mtime = 0,
                .i_dtime = 0,
                .i_gid = 0,
                .i_links_count = 2,
                .i_blocks = 0,
                .i_flags = 0,
                .i_osd1 = 0,
                .i_block = [_]u32{0} ** 15,
                .i_generation = 0,
                .i_file_acl = 0,
                .i_dir_acl = 0,
                .i_faddr = 0,
                .i_osd2 = [_]u8{0} ** 12,
            };
        }
    };

    initialized = true;
}

pub fn getFilesystem() *Ext2FS {
    return &ext2fs;
}

pub fn isInitialized() bool {
    return initialized;
}
