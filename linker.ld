ENTRY(_start)

/* Simple higher-half linker script.
   Place code in the canonical higher-half and keep rodata in the text
   segment. Align data to page boundaries to avoid overlapping loadable
   segments. We rely on the default PT_LOAD generation performed by the
   linker. */
SECTIONS
{
  . = 0xffffffff80001000;

  .text : ALIGN(0x1000)
  {
    _text_start = .;
    *(.text .text.*)
    *(.eh_frame_hdr)
    *(.eh_frame)
    _text_end = .;
  }

  .rodata : ALIGN(0x1000)
  {
    _rodata_start = .;
    *(.rodata .rodata.*)
    _rodata_end = .;
  }

  . = ALIGN(0x1000);

  .data : ALIGN(0x1000)
  {
    _data_start = .;
    *(.data .data.*)
    _data_end = .;
  }

  .bss : ALIGN(0x1000)
  {
    _bss_start = .;
    *(COMMON)
    *(.bss .bss.*)
    _bss_end = .;
  }

  _kernel_end = .;
}
