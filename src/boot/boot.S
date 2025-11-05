.code16
.global _start

_start:
    cli
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $0x7C00, %sp
    cld

    movb %dl, boot_drive

    mov $msg_loading, %si
    call print_string

    mov $0x1000, %bx
    call disk_load

    mov $msg_loaded, %si
    call print_string

    cli
    lgdt gdt_descriptor

    mov %cr0, %eax
    or $0x1, %eax
    mov %eax, %cr0

    ljmp $0x08, $protected_mode

.code32
protected_mode:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov %ax, %fs
    mov %ax, %gs
    mov $0x90000, %esp
    mov $0x1000, %eax
    call *%eax

halt_pm:
    cli
    hlt
    jmp halt_pm

.code16
disk_load:
    pusha
    mov $0x0000, %ax
    mov %ax, %es
    mov $0x1000, %bx
    mov $0x02, %ah
    mov $25, %al        # Load 25 sectors (12.5KB) to fit the kernel
    mov $0x00, %ch
    mov $2, %cl
    mov $0x00, %dh
    movb boot_drive, %dl
    int $0x13
    jc disk_error
    popa
    ret

disk_error:
    popa
    mov $msg_disk_error, %si
    call print_string

halt_rm:
    cli
    hlt
    jmp halt_rm

print_string:
    pusha
    mov $0x0E, %ah
.print_loop:
    lodsb
    test %al, %al
    jz .done
    int $0x10
    jmp .print_loop
.done:
    popa
    ret

gdt_start:
    .quad 0x0000000000000000
    .quad 0x00CF9A000000FFFF
    .quad 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    .word gdt_end - gdt_start - 1
    .long gdt_start

msg_loading:
    .ascii "Loading Zigumi...\r\n"
    .byte 0

msg_loaded:
    .ascii "Loaded! Switching to PM...\r\n"
    .byte 0

msg_disk_error:
    .ascii "Disk error!\r\n"
    .byte 0

boot_drive:
    .byte 0

.fill 510 - (. - _start), 1, 0
.word 0xAA55
