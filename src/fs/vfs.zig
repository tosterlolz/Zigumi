// Filesystem Router for Zigumi OS
// Routes filesystem operations to the appropriate filesystem driver

const diskman = @import("../drivers/diskman.zig");
const fat32 = @import("fat32.zig");
const ext2 = @import("ext2.zig");
const vga = @import("../term/vga.zig");

pub const FileType = enum(u8) {
    Regular,
    Directory,
    Device,
};

// Path parsing helpers
fn isDriveLetter(path: []const u8) bool {
    return path.len >= 2 and path[1] == ':' and
        ((path[0] >= 'A' and path[0] <= 'Z') or (path[0] >= 'a' and path[0] <= 'z'));
}

fn extractDriveLetter(path: []const u8) u8 {
    if (path[0] >= 'a' and path[0] <= 'z') {
        return path[0] - 32; // Convert to uppercase
    }
    return path[0];
}

fn getPathAfterDrive(path: []const u8) []const u8 {
    if (isDriveLetter(path) and path.len > 2) {
        return path[2..];
    }
    return path;
}

// Route to appropriate filesystem
pub fn listFiles(writer: *vga.Writer, path: []const u8) void {
    if (isDriveLetter(path)) {
        const letter = extractDriveLetter(path);
        const actual_path = getPathAfterDrive(path);

        if (fat32.getFilesystem(letter)) |fs| {
            const entries = fs.listRootDirectory() catch {
                writer.write("Error: Failed to list directory\n");
                return;
            };

            // Print directory listing
            writer.write("Directory of ");
            writer.putChar(letter);
            writer.write(":");
            writer.write(actual_path);
            writer.write("\n\n");

            for (entries) |entry| {
                // Skip empty entries
                if (entry.name[0] == 0) break;

                // Print attributes
                if ((entry.attributes & 0x10) != 0) {
                    writer.write("<DIR>  ");
                } else {
                    writer.write("       ");
                }

                // Print name (8.3 format)
                var i: usize = 0;
                while (i < 11 and entry.name[i] != 0) : (i += 1) {
                    if (i == 8) writer.write(".");
                    writer.putChar(entry.name[i]);
                }
                writer.write("\n");
            }
        } else {
            writer.write("Error: Drive not mounted\n");
        }
    } else {
        // In-memory/virtual filesystem not implemented
        writer.write("Error: Virtual filesystem not supported\n");
        writer.write("Use drive letters (A:/, B:/, etc.)\n");
    }
}

pub fn changeDrive(letter: u8) bool {
    const dm = diskman.getManager();
    const drive = dm.getDrive(letter) catch return false;
    return drive.mounted;
}

pub fn changeDir(path: []const u8) bool {
    if (isDriveLetter(path)) {
        const letter = extractDriveLetter(path);
        const actual_path = getPathAfterDrive(path);

        if (fat32.getFilesystem(letter)) |_| {
            // For now, just verify the path format is valid
            _ = actual_path;
            return true;
        }
    }
    return false;
}

pub fn readFile(path: []const u8, buffer: []u8) !usize {
    if (isDriveLetter(path)) {
        const letter = extractDriveLetter(path);
        const actual_path = getPathAfterDrive(path);

        if (fat32.getFilesystem(letter)) |_| {
            // Extract filename from path
            // For now, treat the entire actual_path as filename
            _ = fat32.readFile(path, actual_path) catch return error.FileNotFound;
            _ = buffer; // TODO: copy data to buffer
            return 0;
        }
    }
    return error.FileNotFound;
}

pub fn init() void {
    // Initialize filesystem routing - nothing needed here
    // Individual filesystems initialize themselves
}
