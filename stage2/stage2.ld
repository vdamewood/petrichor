ENTRY(Init16)

SECTIONS
{
    .text.init16 (0x10080) : { init16.o(.text) }
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss)  }
}
