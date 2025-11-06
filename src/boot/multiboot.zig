// Multiboot helper (Zig)
// This module documents and provides a tiny symbol to ensure the
// multiboot header/section (implemented in src/multiboot.S) is part of
// the final kernel image. The actual multiboot header bytes are
// emitted by the assembly file (src/multiboot.S). Keep this file so
// the kernel sources can import a named boot helper if desired.

pub fn ensureMultiboot() void {
    // Intentionally empty; calling this from `_start` or another
    // init path will create a reference to this module which helps
    // ensure the multiboot assembly object is linked into the final
    // binary when the build system compiles both the assembly and
    // the Zig sources together.
}
