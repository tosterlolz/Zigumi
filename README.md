# Zigumi OS

Zigumi OS is a simple operating system project written in Zig. It features a structured layout with modular components, including a bootloader, framebuffer initialization, PS/2 keyboard support, and a minimal interactive shell.

## Project Structure

```
zigumi-os
├── boot
│   ├── limine.cfg          # Configuration for the Limine bootloader
│   ├── stage2.S           # Assembly code for the second stage of the bootloader
│   └── Makefile            # Build instructions for the bootloader
├── src
│   ├── main.zig            # Entry point of the Zigumi OS
│   ├── build.zig           # Build configuration for the Zig project
│   ├── kernel
│   │   ├── kernel.zig      # Main kernel code
│   │   ├── entry.zig       # Entry point for the kernel
│   │   ├── init.zig        # Initialization routines for the kernel
│   │   └── panic.zig       # Panic handler for critical errors
│   ├── drivers
│   │   ├── framebuffer.zig  # Framebuffer driver for drawing operations
│   │   └── ps2.zig         # PS/2 keyboard driver for input handling
│   ├── shell
│   │   └── shell.zig       # Interactive shell implementation
│   ├── memory
│   │   └── mm.zig          # Memory management routines
│   ├── arch
│   │   └── x86_64
│   │       ├── gdt.zig     # Global Descriptor Table setup
│   │       └── paging.zig   # Paging and memory management
│   └── util
│       └── fmt.zig         # Utility functions for formatting output
├── tools
│   └── run_qemu.sh         # Script to run the OS in QEMU
├── scripts
│   └── install-limine.sh    # Script to install the Limine bootloader
├── .gitignore               # Files and directories to ignore by Git
├── LICENSE                  # Licensing information for the project
├── README.md                # Documentation for the project
└── Makefile                 # Build instructions for the entire project
```

## Features

- **Bootloader**: Utilizes Limine for booting the OS.
- **Framebuffer**: Initializes a framebuffer with pastel colors for output.
- **PS/2 Keyboard Support**: Handles keyboard input through a PS/2 driver.
- **Interactive Shell**: Provides a minimal shell for user interaction.
- **Modular Design**: Clear separation of concerns across different components.

## Getting Started

1. **Clone the Repository**: 
   ```
   git clone <repository-url>
   cd zigumi-os
   ```

2. **Build the Project**: 
   ```
   make
   ```

3. **Run in QEMU**: 
   ```
   ./tools/run_qemu.sh
   ```

## License

This project is licensed under the MIT License. See the LICENSE file for more details.