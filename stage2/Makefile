all: stage2.bin

clean:
	rm -rf stage2.bin *.o

distclean: clean

OBJECTS=real16.o init.o \
	command.o gdt.o intr.o keyboard.o \
	keyscan.o memory.o misc_c.o misc_s.o screen.o \
	strings.o uio.o util.o

%.o: %.asm functions.inc
	nasm -f elf -o $@ $<

%.o: %.c
	clang -ffreestanding -fno-builtin -nostdlib -nostdinc -c --target=i686-pc-none-elf -march=i686 -o $@ $<

%_s.o: %.asm functions.inc
	nasm -f elf -o $@ $<

%_c.o: %.c
	clang -ffreestanding -fno-builtin -nostdlib -nostdinc -c --target=i686-pc-none-elf -march=i686 -o $@ $<


real16.o: real16.asm
	nasm -f elf -o real16.o real16.asm

init.o: init.asm
	nasm -f elf -o init.o init.asm

stage2.bin: stage2.ld $(OBJECTS)
	i686-elf-ld -s -T stage2.ld -o stage2.bin $(OBJECTS)

.PHONY: all clean distclean