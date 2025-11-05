; Bootloader for Zigumi OS
; Built with NASM
; Loaded at 0x7C00

[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    cld

    ; Save boot drive number
    mov [boot_drive], dl

    ; Print loading message
    mov si, msg_loading
    call print_string

    ; Read kernel from disk using INT 0x13 AH=02 (read sectors)
    ; We need to read sectors 1-2 into memory 0x1000
    ; CHS: Cylinder 0, Head 0, Sectors 1-2
    ; ES:BX = physical address. 0x1000 = (0x0000 * 16) + 0x1000
    
    mov ax, 0x0000
    mov es, ax                  ; ES = 0x0000
    mov bx, 0x1000              ; BX = 0x1000 (offset)
    
    mov ah, 0x02                ; INT 0x13 function: read sectors
    mov al, 2                   ; Read 2 sectors
    mov ch, 0                   ; Cylinder 0
    mov dh, 0                   ; Head 0
    mov cl, 1                   ; Start at sector 1
    mov dl, [boot_drive]        ; Drive number
    
    int 0x13
    jc .read_error
    
    ; Print dots
    mov si, msg_dot
    call print_string
    mov si, msg_dot
    call print_string
    
.read_done:
    mov si, msg_loaded
    call print_string

    ; Switch to protected mode
    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Long jump to 32-bit code
    jmp 0x08:protected_mode

.read_error:
    mov si, msg_disk_error
    call print_string
    jmp halt_rm

; 16-bit protected mode entry point (still in real mode addressing)
[BITS 32]
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    mov esp, 0x90000
    mov eax, 0x1000
    call eax

halt_pm:
    cli
    hlt
    jmp halt_pm


[BITS 16]

halt_rm:
    cli
    hlt
    jmp halt_rm

print_string:
    pusha
    mov ah, 0x0E
.print_loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .print_loop
.done:
    popa
    ret

; ============================================================================
; GDT and descriptor tables
; ============================================================================

gdt_start:
    dq 0x0000000000000000      ; Null descriptor
    dq 0x00CF9A000000FFFF      ; Code segment (32-bit)
    dq 0x00CF92000000FFFF      ; Data segment (32-bit)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; ============================================================================
; Data section
; ============================================================================

msg_loading:
    db "Loading Zigumi...", 0x0D, 0x0A, 0

msg_loaded:
    db "Loaded! Switching to PM...", 0x0D, 0x0A, 0

msg_disk_error:
    db "Disk error!", 0x0D, 0x0A, 0

msg_dot:
    db ".", 0

boot_drive:
    db 0

; ============================================================================
; Boot sector padding and signature
; ============================================================================

times 510 - ($ - $$) db 0
dw 0xAA55
