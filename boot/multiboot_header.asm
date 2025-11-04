; Minimal Multiboot v1 header (NASM) for GRUB to detect and load the kernel.
; Assembled with: nasm -f elf64 boot/multiboot_header.asm -o build/multiboot_header.o

BITS 64
section .multiboot_header
    align 4
    dd 0x1BADB002         ; magic
    dd 0x00000003         ; flags (page_align | aout_kparams not set)
    dd -(0x1BADB002 + 0x00000003) ; checksum
