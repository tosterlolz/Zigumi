// Bash-like shell for Zigumi OS

const libc = @import("libc.zig");
const fat32 = @import("../fs/fat32.zig");

var current_drive: u8 = 'A';
var current_path: [256]u8 = undefined;
var path_len: usize = 0;

fn setPath(path: []const u8) void {
    path_len = if (path.len > current_path.len) current_path.len else path.len;
    for (path[0..path_len], 0..) |char, i| {
        current_path[i] = char;
    }
}

fn getFullPath() []const u8 {
    return current_path[0..path_len];
}

pub fn start() noreturn {
    main();
    libc.exit(0);
}

fn main() void {
    // Initialize path to root of current drive
    setPath("/");

    // Print banner
    libc.println("=========================================");
    libc.println("             Zigumi Shell ");
    libc.println("=========================================");
    libc.println("");
    libc.println("Welcome to Zigumi OS!");
    libc.println("Type 'help' to see available commands");
    libc.println("");

    var buffer: [256]u8 = undefined;

    while (true) {
        // Print prompt with drive letter and current path
        libc.print("zigumi@");
        libc.putchar(current_drive);
        libc.print(":");
        libc.print(getFullPath());
        libc.print("$ ");

        const line = libc.readLine(&buffer);

        if (line.len == 0) continue;

        // Remove newline if present
        const cmd = if (line[line.len - 1] == '\n')
            line[0 .. line.len - 1]
        else
            line;

        if (cmd.len == 0) continue;

        // Parse command and arguments
        if (startsWith(cmd, "help")) {
            printHelp();
        } else if (startsWith(cmd, "clear") or startsWith(cmd, "cls")) {
            clearScreen();
        } else if (startsWith(cmd, "ls")) {
            listFiles(getFullPath());
        } else if (startsWith(cmd, "pwd")) {
            // Print drive letter and current path
            libc.putchar(current_drive);
            libc.print(":");
            libc.println(getFullPath());
        } else if (startsWith(cmd, "cd")) {
            cdCommand(cmd);
        } else if (startsWith(cmd, "whoami")) {
            libc.println("root");
        } else if (startsWith(cmd, "uname")) {
            if (contains(cmd, "-a")) {
                libc.println("Zigumi 0.5.0 x86 i686");
            } else {
                libc.println("Zigumi");
            }
        } else if (startsWith(cmd, "date")) {
            libc.println("2025-11-05 12:00:00 UTC");
        } else if (startsWith(cmd, "uptime")) {
            libc.println("System uptime: 0 days, 0 hours, 1 minute");
        } else if (startsWith(cmd, "free")) {
            printMemInfo();
        } else if (startsWith(cmd, "ps")) {
            printProcesses();
        } else if (startsWith(cmd, "tasks")) {
            showTasks();
        } else if (startsWith(cmd, "tty")) {
            showTTYInfo();
        } else if (startsWith(cmd, "files")) {
            showVFSFiles();
        } else if (startsWith(cmd, "cat")) {
            catFile(cmd);
        } else if (startsWith(cmd, "echo ")) {
            echoCommand(cmd);
        } else if (startsWith(cmd, "mkdir")) {
            libc.println("mkdir: filesystem is read-only");
        } else if (startsWith(cmd, "touch")) {
            libc.println("touch: filesystem is read-only");
        } else if (startsWith(cmd, "rm")) {
            libc.println("rm: filesystem is read-only");
        } else if (startsWith(cmd, "cd ")) {
            cdCommand(cmd[3..]);
        } else if (cmd.len == 2 and cmd[1] == ':') {
            // Handle drive letter change (e.g., "A:" or "B:")
            const drive = cmd[0];
            if (drive >= 'A' and drive <= 'Z') {
                if (fat32.changeDrive(drive)) {
                    current_drive = drive;
                    setPath("/");
                } else {
                    libc.println("Invalid drive");
                }
            } else {
                libc.println("Invalid drive letter");
            }
        } else if (startsWith(cmd, "df")) {
            printDiskUsage();
        } else if (startsWith(cmd, "kill")) {
            libc.println("kill: no other processes to kill");
        } else if (startsWith(cmd, "reboot")) {
            libc.println("Rebooting system...");
            libc.sleep(1000);
            libc.exit(0);
        } else if (startsWith(cmd, "shutdown")) {
            libc.println("Shutting down...");
            libc.sleep(500);
            libc.exit(0);
        } else if (startsWith(cmd, "history")) {
            libc.println("Command history not yet implemented");
        } else if (startsWith(cmd, "man")) {
            showManual(cmd);
        } else if (startsWith(cmd, "top")) {
            showTop();
        } else if (startsWith(cmd, "dmesg")) {
            showDmesg();
        } else if (startsWith(cmd, "lscpu")) {
            showCpuInfo();
        } else if (startsWith(cmd, "env")) {
            showEnvironment();
        } else if (startsWith(cmd, "alias")) {
            libc.println("alias: not yet implemented");
        } else if (startsWith(cmd, "export")) {
            libc.println("export: not yet implemented");
        } else if (startsWith(cmd, "grep")) {
            libc.println("grep: not yet implemented");
        } else if (startsWith(cmd, "find")) {
            libc.println("find: not yet implemented");
        } else if (startsWith(cmd, "exit") or startsWith(cmd, "logout")) {
            libc.println("Goodbye!");
            libc.exit(0);
        } else {
            libc.print("zigumi: command not found: ");
            libc.println(cmd);
            libc.println("Type 'help' for available commands");
        }
    }
}

fn startsWith(str: []const u8, prefix: []const u8) bool {
    if (str.len < prefix.len) return false;
    return libc.strcmp(str[0..prefix.len], prefix);
}

fn contains(str: []const u8, substr: []const u8) bool {
    if (str.len < substr.len) return false;
    var i: usize = 0;
    while (i <= str.len - substr.len) : (i += 1) {
        if (libc.strcmp(str[i .. i + substr.len], substr)) {
            return true;
        }
    }
    return false;
}

fn printHelp() void {
    libc.println("=========================================");
    libc.println("        ZIGUMI SHELL COMMANDS");
    libc.println("=========================================");
    libc.println("");
    libc.println("System Information:");
    libc.println("  uname [-a]  - Show system information");
    libc.println("  whoami      - Display current user");
    libc.println("  date        - Show current date/time");
    libc.println("  uptime      - Show system uptime");
    libc.println("  lscpu       - Display CPU information");
    libc.println("  dmesg       - Show kernel messages");
    libc.println("");
    libc.println("File Operations:");
    libc.println("  ls          - List directory contents");
    libc.println("  pwd         - Print working directory");
    libc.println("  cat <file>  - Display file contents");
    libc.println("  cd <dir>    - Change directory");
    libc.println("  mkdir       - Create directory");
    libc.println("  rm          - Remove file");
    libc.println("  touch       - Create file");
    libc.println("");
    libc.println("Process Management:");
    libc.println("  ps          - List running processes");
    libc.println("  tasks       - Show task scheduler status");
    libc.println("  top         - Task manager");
    libc.println("  kill        - Terminate process");
    libc.println("");
    libc.println("Filesystem:");
    libc.println("  files       - Show VFS files");
    libc.println("  tty         - Display TTY information");
    libc.println("");
    libc.println("System Resources:");
    libc.println("  free        - Display memory usage");
    libc.println("  df          - Show disk usage");
    libc.println("");
    libc.println("Utilities:");
    libc.println("  echo <text> - Print text to console");
    libc.println("  clear/cls   - Clear the screen");
    libc.println("  man <cmd>   - Show command manual");
    libc.println("  env         - Show environment");
    libc.println("  history     - Command history");
    libc.println("");
    libc.println("System Control:");
    libc.println("  reboot      - Reboot the system");
    libc.println("  shutdown    - Shutdown the system");
    libc.println("  exit/logout - Exit the shell");
    libc.println("");
}

fn listFiles(path: []const u8) void {
    const entries = fat32.listDir(path) catch {
        libc.println("Error: Could not read directory");
        return;
    };

    // Print directory listing
    libc.println("Directory of ");
    libc.putchar(current_drive);
    libc.print(":");
    libc.println(path);
    libc.println("");

    var total_files: usize = 0;
    var total_dirs: usize = 0;
    var total_size: u32 = 0;

    for (entries) |entry| {
        // Print attributes
        if ((entry.attributes & 0x10) != 0) {
            libc.print("<DIR>     ");
            total_dirs += 1;
        } else {
            var size_buf: [10]u8 = undefined;
            printSizeAligned(entry.file_size, &size_buf);
            total_size += entry.file_size;
            total_files += 1;
        }

        // Print filename (strip trailing spaces)
        var name_end: usize = 11;
        while (name_end > 0 and entry.name[name_end - 1] == ' ') {
            name_end -= 1;
        }

        for (entry.name[0..name_end]) |char| {
            libc.putchar(char);
        }
        libc.println("");
    }

    // Print summary
    libc.println("");
    libc.print("    ");
    printNumber(total_files);
    libc.print(" File(s)    ");
    printNumber(total_size);
    libc.println(" bytes");

    libc.print("    ");
    printNumber(total_dirs);
    libc.println(" Dir(s)");
}

fn printNumber(num: u32) void {
    var buf: [20]u8 = undefined;
    var len: usize = 0;
    var n = num;

    if (n == 0) {
        libc.putchar('0');
        return;
    }

    while (n > 0) {
        buf[len] = @as(u8, @intCast((n % 10) + '0'));
        n /= 10;
        len += 1;
    }

    while (len > 0) {
        len -= 1;
        libc.putchar(buf[len]);
    }
}

fn printSizeAligned(size: u32, buf: []u8) void {
    var pos: usize = 0;
    var n = size;

    // Convert to string, right to left
    while (n > 0) {
        buf[pos] = @as(u8, @intCast((n % 10) + '0'));
        n /= 10;
        pos += 1;
    }

    // Handle zero size
    if (pos == 0) {
        buf[pos] = '0';
        pos += 1;
    }

    // Pad with spaces
    while (pos < 9) {
        libc.putchar(' ');
        pos += 1;
    }

    // Print in correct order
    var i: usize = pos;
    while (i > 0) {
        i -= 1;
        libc.putchar(buf[i]);
    }
}

fn cdCommand(path: []const u8) void {
    // Check for empty path
    if (path.len == 0) {
        // Empty cd command - go to root
        setPath("/");
        return;
    }

    // Handle drive letter change if path starts with drive letter
    if (path.len >= 2 and path[1] == ':') {
        const drive = path[0];
        if (drive >= 'A' and drive <= 'Z') {
            if (!fat32.changeDrive(drive)) {
                libc.println("Invalid drive");
                return;
            }
            current_drive = drive;
            // If only drive letter specified, go to root
            if (path.len == 2) {
                setPath("/");
                return;
            }
            // Continue with the rest of the path
            cdCommand(path[2..]);
            return;
        }
    }

    // Handle special paths
    if (libc.strcmp(path, "/") or libc.strcmp(path, "\\")) {
        setPath("/");
        return;
    }

    if (libc.strcmp(path, "..")) {
        // Go to parent directory
        if (path_len <= 1) {
            // Already at root
            return;
        }

        // Find last separator
        var i = path_len - 1;
        // Skip trailing slashes
        while (i > 0 and current_path[i] == '/') : (i -= 1) {}
        // Find previous slash
        while (i > 0 and current_path[i] != '/') : (i -= 1) {}
        // Update path
        if (i == 0) {
            setPath("/");
        } else {
            setPath(current_path[0..i]);
        }
        return;
    }

    if (libc.strcmp(path, ".")) {
        // Stay in current directory
        return;
    }

    // Handle path with or without leading slash
    var new_path: [256]u8 = undefined;
    var new_path_len: usize = 0;

    if (path[0] == '/' or path[0] == '\\') {
        // Absolute path
        @memcpy(new_path[0..path.len], path);
        new_path_len = path.len;
    } else {
        // Relative path - concatenate with current path
        @memcpy(new_path[0..path_len], current_path[0..path_len]);
        new_path_len = path_len;

        if (new_path_len > 0 and new_path[new_path_len - 1] != '/') {
            new_path[new_path_len] = '/';
            new_path_len += 1;
        }

        @memcpy(new_path[new_path_len..][0..path.len], path);
        new_path_len += path.len;
    }

    // Normalize slashes
    for (new_path[0..new_path_len]) |*c| {
        if (c.* == '\\') c.* = '/';
    }

    // Try to change directory
    if (fat32.changeDir(new_path[0..new_path_len])) {
        setPath(new_path[0..new_path_len]);
    } else {
        libc.print("cd: ");
        for (path) |c| {
            libc.putchar(c);
        }
        libc.println(": No such file or directory");
    }
}

fn printMemInfo() void {
    libc.println("              total        used        free");
    libc.println("Mem:          1024KB       256KB       768KB");
    libc.println("Swap:            0KB         0KB         0KB");
}

fn printProcesses() void {
    libc.println("  PID USER     TIME     COMMAND");
    libc.println("    1 root     0:00     kernel");
    libc.println("    2 root     0:00     shell");
}

fn showTasksOld() void {
    libc.println("Task Scheduler Status:");
    libc.println("");
    libc.println("ID  STATE      NAME");
    libc.println("--  ---------  ----------------");
    libc.println("0   Running    kernel");
    libc.println("1   Ready      background-1");
    libc.println("2   Ready      background-2");
    libc.println("3   Running    shell");
    libc.println("");
    libc.println("Scheduler: ENABLED (Cooperative)");
    libc.println("Algorithm: Round-Robin");
}

fn catFile(cmd: []const u8) void {
    if (cmd.len <= 4) {
        libc.println("cat: missing file operand");
        libc.println("Try 'cat README.TXT'");
        return;
    }

    const filename = cmd[4..];
    if (contains(filename, "README")) {
        libc.println("=========================================");
        libc.println("          ZIGUMI OS README");
        libc.println("=========================================");
        libc.println("");
        libc.println("Welcome to Zigumi OS!");
        libc.println("");
        libc.println("A simple operating system written in Zig");
        libc.println("for x86 architecture.");
        libc.println("");
        libc.println("Features:");
        libc.println("  * VGA text mode display");
        libc.println("  * PS/2 keyboard driver");
        libc.println("  * System call interface");
        libc.println("  * Basic shell with commands");
        libc.println("  * FAT filesystem support");
        libc.println("");
        libc.println("Author: tosterlolz");
    } else {
        libc.print("cat: ");
        libc.print(filename);
        libc.println(": No such file or directory");
    }
}

fn echoCommand(cmd: []const u8) void {
    if (cmd.len <= 5) {
        libc.println("");
        return;
    }
    libc.println(cmd[5..]);
}

fn printDiskUsage() void {
    libc.println("Filesystem     Size  Used Avail Use% Mounted on");
    libc.println("/dev/hda1      100M   10M   90M  10% /");
}

fn showManual(cmd: []const u8) void {
    _ = cmd;
    libc.println("MAN(1)                 Zigumi Manual                 MAN(1)");
    libc.println("");
    libc.println("NAME");
    libc.println("     Zigumi Shell - command interpreter");
    libc.println("");
    libc.println("SYNOPSIS");
    libc.println("     Use 'help' to see all available commands");
    libc.println("");
    libc.println("DESCRIPTION");
    libc.println("     The Zigumi shell is a bash-like command");
    libc.println("     line interpreter for Zigumi OS.");
}

fn showTop() void {
    libc.println("top - 12:00:00 up 1 min, 1 user");
    libc.println("Tasks: 2 total, 1 running");
    libc.println("");
    libc.println("  PID USER      %CPU %MEM    TIME COMMAND");
    libc.println("    1 root      25.0  5.0   0:00 kernel");
    libc.println("    2 root       5.0 10.0   0:00 shell");
    libc.println("");
    libc.println("Press any key to return...");
    var buf: [1]u8 = undefined;
    _ = libc.read(0, &buf);
}

fn showDmesg() void {
    libc.println("[    0.000000] Zigumi OS v0.5 booting...");
    libc.println("[    0.001000] VGA text mode initialized");
    libc.println("[    0.001500] PS/2 keyboard initialized");
    libc.println("[    0.002000] GDT loaded");
    libc.println("[    0.002500] IDT initialized");
    libc.println("[    0.003000] Syscall interface ready");
    libc.println("[    0.003500] Task scheduler initialized");
    libc.println("[    0.004000] TTY driver loaded (4 terminals)");
    libc.println("[    0.004500] VFS initialized");
    libc.println("[    0.005000] Starting shell...");
}

fn showCpuInfo() void {
    libc.println("Architecture:        x86");
    libc.println("CPU op-mode(s):      32-bit");
    libc.println("CPU(s):              1");
    libc.println("Vendor ID:           GenuineIntel");
    libc.println("Model name:          i686");
    libc.println("CPU MHz:             2400.000");
}

fn showEnvironment() void {
    libc.println("PATH=/bin:/usr/bin");
    libc.println("HOME=/home/root");
    libc.println("USER=root");
    libc.println("SHELL=/bin/zsh");
    libc.println("TERM=vga");
}

fn clearScreen() void {
    // Send escape sequence to clear screen
    var i: u32 = 0;
    while (i < 25) : (i += 1) {
        libc.println("");
    }
}

fn showTasks() void {
    libc.println("Task Scheduler Status:");
    libc.println("PID  STATE    NAME");
    libc.println("---  -------  ----------------");
    libc.println("  1  Running  kernel");
    libc.println("  2  Running  shell");
    libc.println("");
    libc.println("Total tasks: 2");
}

fn showTTYInfo() void {
    libc.println("TTY Information:");
    libc.println("Current TTY: tty0");
    libc.println("Available TTYs: 4 (tty0-tty3)");
    libc.println("Use Alt+F1-F4 to switch (not yet implemented)");
}

fn showVFSFiles() void {
    libc.println("Virtual Filesystem:");
    libc.println("TYPE  SIZE     NAME");
    libc.println("----  -------  ----------------");
    libc.println("DIR   0        dev");
    libc.println("DIR   0        home");
    libc.println("DIR   0        tmp");
    libc.println("DEV   0        null");
    libc.println("DEV   0        zero");
    libc.println("DEV   0        tty");
    libc.println("FILE  56       welcome.txt");
    libc.println("");
    libc.println("Total files: 7");
}
