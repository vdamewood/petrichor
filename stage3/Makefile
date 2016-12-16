CC=clang
CFLAGS=-g -ffreestanding -fno-builtin -nostdlib \
	--target=i686-pc-none-elf -march=i686 -c
ASM=nasm
ASMFLAGS=-f elf -g -F dwarf
OBJECTS= \
	mboot.o \
	gdt.o \
	init32.o \
	init32c.o \
	screen.o \
	keyboard.o \
	uio.o \
	shell.o \
	memory.o \
	command.o \
	util.o \
	acpi.o \
	cpuid.o


all: stage3.bin

stage3.bin: stage3.ld $(OBJECTS)
	i686-elf-ld -T stage3.ld -o stage3.bin $(OBJECTS)

mboot.o: mboot.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

gdt.o: gdt.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

init32.o: init32.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

init32c.o: init32c.c
	clang $(CFLAGS) -o $@ $<

distclean: clean

clean:
	rm -rf stage2.bin *.o

.PHONY: all clean distclean
