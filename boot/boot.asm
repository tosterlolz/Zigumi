; MBR (512 bytes)
; Loads the kernel from LBA 1 into physical 0x0000:0x8000 using Int13h Extensions (AH=0x42)
; Then jumps to 0x0000:0x8000

%define KERNEL_SECTORS 4

org 0x7c00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    mov [drive], dl        ; store drive number

    ; Prepare Disk Address Packet at dap
    mov byte [dap], 0x10   ; size
    mov byte [dap+1], 0x0  ; reserved
    mov word [dap+2], KERNEL_SECTORS ; sectors to read (word)
    mov word [dap+4], 0x8000 ; buffer offset (offset low)
    mov word [dap+6], 0x0000 ; buffer segment (segment)
    mov word [dap+8], 1    ; starting LBA low word
    mov word [dap+10], 0   ; starting LBA high word

    ; call int13h ext read
    lea si, [dap]
    mov ah, 0x42
    int 0x13
    jc disk_error

    ; Jump to loaded kernel at 0x0000:0x8000
    jmp 0x0000:0x8000

disk_error:
    hlt
    jmp disk_error

drive: db 0

dap: ; Disk Address Packet (16 bytes)
    db 0x10, 0x0
    dw 0x0
    dw 0x0
    dw 0x0
    dq 0x0

; pad to 510 bytes
times 510-($-$$) db 0
dw 0xAA55
