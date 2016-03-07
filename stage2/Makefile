all: stage2.bin

clean:
	rm -rf stage2.bin *.o

distclean: clean

OBJECTS=real16.o init.o command.o gdt.o intr.o keyboard.o keyscan.o misc.o screen.o strings.o

%.o: %.asm functions.inc
	nasm $< -f elf -o $@

real16.o: real16.asm
	nasm real16.asm -f elf -o real16.o

init.o: init.asm
	nasm init.asm -f elf -o init.o

stage2.bin: stage2.ld $(OBJECTS)
	i686-elf-ld -T stage2.ld -o stage2.bin $(OBJECTS)
	i686-elf-strip stage2.bin

.PHONY: all clean distclean
