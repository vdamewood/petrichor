all: stage2.bin

clean:
	rm -rf stage2.bin *.o

distclean: clean

OBJECTS=init16.o init32.o \
	cpuid.o gdt.o intr.o keyboard.o \
	keyscan.o memory.o screen.o \
	uio.o util.o \
	acpi.o command.o misc.o \


init%.o: init%.asm
	nasm -f elf -o $@ $<

%.o: %.asm functions.inc
	nasm -f elf -o $@ $<

%.o: %.c
	clang -ffreestanding -fno-builtin -nostdlib -nostdinc -c --target=i686-pc-none-elf -march=i686 -o $@ $<

%_s.o: %.asm functions.inc
	nasm -f elf -o $@ $<

%_c.o: %.c
	clang -ffreestanding -fno-builtin -nostdlib -nostdinc -c --target=i686-pc-none-elf -march=i686 -o $@ $<


stage2.bin: Makefile stage2.ld $(OBJECTS)
	i686-elf-ld -s -T stage2.ld -o stage2.bin $(OBJECTS)

.PHONY: all clean distclean