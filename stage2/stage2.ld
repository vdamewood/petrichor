ENTRY(Stage2)

SECTIONS
{
    . = 0x11000;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss : { *(.bss) }
}
