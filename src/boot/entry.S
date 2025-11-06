.section .text
.global _start
.extern _kernel_end
.type _start, @function
/*
 * Higher-half entry for the kernel. Called by Limine with paging enabled
 * when linked at a higher-half address (linker.ld uses 0xffffffff80001000).
 * This sets up a basic stack (just above _kernel_end), clears RBP, and
 * calls the Zig `kernel_main` entrypoint.
 */
_start:
    cli
    /* Load address of _kernel_end (absolute symbol from linker) into RAX */
    movabs $_kernel_end, %rax
    /* Move the stack to just below _kernel_end (one page lower) so it's
     * inside the mapped BSS region and won't fault. Using a negative offset
     * keeps the stack within the kernel image's mapped pages. */
    sub $0x1000, %rax
    mov %rax, %rsp
    xor %rbp, %rbp
    /* Call into the Zig kernel entry */
    call kernel_main
1:
    hlt
    jmp 1b

.size _start, .-_start
