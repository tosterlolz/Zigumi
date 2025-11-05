// Virtual File System for Zigumi OS

const vga = @import("../term/vga.zig");

pub const FileType = enum(u8) {
    Regular,
    Directory,
    Device,
};

pub const File = struct {
    name: [64]u8,
    name_len: usize,
    file_type: FileType,
    size: u32,
    data: ?[*]u8,

    pub fn init(name: []const u8, ftype: FileType) File {
        var file = File{
            .name = [_]u8{0} ** 64,
            .name_len = 0,
            .file_type = ftype,
            .size = 0,
            .data = null,
        };

        var i: usize = 0;
        while (i < name.len and i < 64) : (i += 1) {
            file.name[i] = name[i];
        }
        file.name_len = i;

        return file;
    }
};

const MAX_FILES = 64;

var root_files: [MAX_FILES]?File = [_]?File{null} ** MAX_FILES;
var file_count: usize = 0;

pub fn init() void {
    // Initialize with some default files/devices
    _ = createFile("/", "dev", .Directory) catch {};
    _ = createFile("/", "home", .Directory) catch {};
    _ = createFile("/", "tmp", .Directory) catch {};
    _ = createFile("/dev", "null", .Device) catch {};
    _ = createFile("/dev", "zero", .Device) catch {};
    _ = createFile("/dev", "tty", .Device) catch {};

    // Create a welcome file
    const welcome_text = "Welcome to Zigumi OS!\nA simple x86 OS written in Zig.\n";
    _ = createFileWithContent("/", "welcome.txt", welcome_text) catch {};
}
pub fn createFile(path: []const u8, name: []const u8, ftype: FileType) !u32 {
    if (file_count >= MAX_FILES) {
        return error.FileSystemFull;
    }

    _ = path; // TODO: Use path for directory structure

    const file = File.init(name, ftype);
    root_files[file_count] = file;
    const id = @as(u32, @intCast(file_count));
    file_count += 1;

    return id;
}

pub fn createFileWithContent(path: []const u8, name: []const u8, content: []const u8) !u32 {
    const id = try createFile(path, name, .Regular);

    if (root_files[id]) |*file| {
        file.size = @as(u32, @intCast(content.len));
        // In real FS, we'd allocate memory here
        // For now, just store the pointer (const data)
        file.data = @constCast(content.ptr);
    }

    return id;
}

pub fn listFiles(writer: *vga.Writer) void {
    writer.write("Files in root:\n");
    writer.write("TYPE  SIZE     NAME\n");
    writer.write("----  -------  ----------------\n");

    var i: usize = 0;
    while (i < file_count) : (i += 1) {
        if (root_files[i]) |file| {
            const type_str = switch (file.file_type) {
                .Regular => "FILE",
                .Directory => "DIR ",
                .Device => "DEV ",
            };
            writer.write(type_str);
            writer.write("  ");

            // Print size
            printNum(writer, file.size);

            // Pad to 8 chars
            const size_digits = countDigits(file.size);
            var pad: usize = 0;
            while (pad < 8 - size_digits) : (pad += 1) {
                writer.write(" ");
            }

            // Print name
            var j: usize = 0;
            while (j < file.name_len) : (j += 1) {
                writer.putChar(file.name[j]);
            }
            writer.write("\n");
        }
    }
}

pub fn readFile(name: []const u8, buffer: []u8) !usize {
    var i: usize = 0;
    while (i < file_count) : (i += 1) {
        if (root_files[i]) |file| {
            if (nameMatches(file.name[0..file.name_len], name)) {
                if (file.data) |data| {
                    const copy_len = if (file.size < buffer.len) file.size else @as(u32, @intCast(buffer.len));
                    var j: usize = 0;
                    while (j < copy_len) : (j += 1) {
                        buffer[j] = data[j];
                    }
                    return copy_len;
                }
                return 0;
            }
        }
    }
    return error.FileNotFound;
}

pub fn writeFile(name: []const u8, data: []const u8) !void {
    var i: usize = 0;
    while (i < file_count) : (i += 1) {
        if (root_files[i]) |*file| {
            if (nameMatches(file.name[0..file.name_len], name)) {
                file.size = @as(u32, @intCast(data.len));
                file.data = @constCast(data.ptr);
                return;
            }
        }
    }

    // File doesn't exist, create it
    const id = try createFile("/", name, .Regular);
    if (root_files[id]) |*file| {
        file.size = @as(u32, @intCast(data.len));
        file.data = @constCast(data.ptr);
    }
}

pub fn fileExists(name: []const u8) bool {
    var i: usize = 0;
    while (i < file_count) : (i += 1) {
        if (root_files[i]) |file| {
            if (nameMatches(file.name[0..file.name_len], name)) {
                return true;
            }
        }
    }
    return false;
}

fn nameMatches(name1: []const u8, name2: []const u8) bool {
    if (name1.len != name2.len) return false;

    var i: usize = 0;
    while (i < name1.len) : (i += 1) {
        if (name1[i] != name2[i]) return false;
    }
    return true;
}

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

fn countDigits(num: u32) usize {
    if (num == 0) return 1;

    var count: usize = 0;
    var n = num;
    while (n > 0) {
        n /= 10;
        count += 1;
    }
    return count;
}

pub fn getFileCount() usize {
    return file_count;
}
