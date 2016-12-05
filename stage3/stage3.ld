ENTRY(Init32)

SECTIONS
{
	.mboot (0x100080) : { mboot.o(.mboot) }
    .text.init16 (0x10008C) : { init32.o(.text) }
    .rodata : { *(.rodata) }
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss)  }
}
