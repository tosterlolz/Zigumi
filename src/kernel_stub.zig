// Minimal freestanding kernel stub used to verify the build pipeline.
// This file intentionally does not reference the larger, unfinished sources
// in the repository. Remove it when you want to build the full OS.

pub export fn _start() noreturn {
    // Halt CPU in an infinite loop. A real kernel would initialize hardware
    // and jump into a scheduler or shell.
    while (true) {}
}
