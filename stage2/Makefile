CC=clang
CFLAGS=-ffreestanding -fno-builtin -nostdlib \
	--target=i686-pc-none-elf -march=i686 -c
ASM=nasm
ASMFLAGS=-f elf
OBJECTS= \
	init16.o \
	init32.o \
	init32c.o \
	acpi.o \
	command.o \
	cpuid.o \
	floppy.o \
	keyboard.o \
	keyscan.o \
	memory.o \
	screen.o \
	shell.o \
	timer.o \
	uio.o \
	util.o \


all: stage2.bin

stage2.bin: stage2.ld $(OBJECTS)
	i686-elf-ld -s -T stage2.ld -o stage2.bin $(OBJECTS)

init16.o: init16.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

init32.o: init32.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

init32c.o: init32c.c screen.h shell.h
	clang $(CFLAGS) -o $@ $<

acpi.o: acpi.c screen.h
	$(CC) $(CFLAGS) -o acpi.o acpi.c

command.o: command.c screen.h
	$(CC) $(CFLAGS) -o command.o command.c

cpuid.o: cpuid.c screen.h
	$(CC) $(CFLAGS) -o cpuid.o cpuid.c

floppy.o: floppy.c screen.h x86asm.h
	$(CC) $(CFLAGS) -o floppy.o floppy.c

memory.o: screen.c screen.h
	$(CC) $(CFLAGS) -o memory.o memory.c

screen.o: screen.c screen.h x86asm.h
	$(CC) $(CFLAGS) -o screen.o screen.c

shell.o: shell.c command.h screen.h shell.h uio.h
	$(CC) $(CFLAGS) -o shell.o shell.c

%.o: %.asm functions.inc
	$(ASM) $(ASMFLAGS) -o $@ $<

%.o: %.c
	clang $(CFLAGS) -o $@ $<

distclean: clean

clean:
	rm -rf stage2.bin *.o

.PHONY: all clean distclean
