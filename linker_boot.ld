ENTRY(_start)
OUTPUT_FORMAT(binary)

SECTIONS {
    . = 0x7C00;
    
    .text : {
        *(.text*)
    }
    
    .rodata : {
        *(.rodata*)
    }
    
    .data : {
        *(.data*)
    }
    
    .bss : {
        *(.bss*)
    }
    
    /* Pad to 510 bytes */
    . = 0x7C00 + 510;
    .boot_sig : {
        SHORT(0xAA55)
    }
    
    /DISCARD/ : {
        *(.note*)
        *(.comment*)
    }
}
