// Simple userland shell for Zigumi OS

const libc = @import("libc.zig");

pub fn start() noreturn {
    main();
    libc.exit(0);
}

fn main() void {
    libc.println("Zigumi Shell v0.1");
    libc.println("Type 'help' for commands");
    libc.println("");

    var buffer: [256]u8 = undefined;

    while (true) {
        libc.print("> ");

        const line = libc.readLine(&buffer);

        if (line.len == 0) continue;

        // Remove newline if present
        const cmd = if (line[line.len - 1] == '\n')
            line[0 .. line.len - 1]
        else
            line;

        if (libc.strcmp(cmd, "help")) {
            printHelp();
        } else if (libc.strcmp(cmd, "clear")) {
            clearScreen();
        } else if (libc.strcmp(cmd, "echo")) {
            libc.println("Echo: Type something!");
        } else if (libc.strcmp(cmd, "pid")) {
            libc.print("Process ID: ");
            libc.printInt(libc.getPid());
            libc.println("");
        } else if (libc.strcmp(cmd, "exit")) {
            libc.println("Goodbye!");
            libc.exit(0);
        } else if (cmd.len > 0) {
            libc.print("Unknown command: ");
            libc.println(cmd);
            libc.println("Type 'help' for available commands");
        }
    }
}

fn printHelp() void {
    libc.println("Available commands:");
    libc.println("  help   - Show this help message");
    libc.println("  clear  - Clear the screen");
    libc.println("  echo   - Echo test");
    libc.println("  pid    - Show process ID");
    libc.println("  exit   - Exit the shell");
}

fn clearScreen() void {
    // Send escape sequence to clear screen
    var i: u32 = 0;
    while (i < 25) : (i += 1) {
        libc.println("");
    }
}
