ENTRY(Init32)

SECTIONS
{
	.mboot (0x100080) : { mboot.o(.mboot) }
    .text.init32 (0x10008C) : { init32.o(.text) }
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    .data : { *(.data) }
    .bss  : { *(.bss)  }
}
