ENTRY(Real16)

SECTIONS
{
    .text.real16 (0x10080) : { real16.o(.text) }
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss)  }
}
