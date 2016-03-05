all: stage2.bin

clean:
	rm -rf stage2.bin

distclean: clean

vidtxt.o: vidtxt.asm
	nasm vidtxt.asm -f elf -o vidtxt.o

stage2.o: stage2.asm functions.inc gdt.asm idt.asm fat12.asm keyboard.asm keyscan.asm command.asm strings.asm
	nasm stage2.asm -f elf -o stage2.o

stage2.bin: stage2.ld stage2.o vidtxt.o
	i686-elf-ld -T stage2.ld -o stage2.bin stage2.o vidtxt.o
	i686-elf-strip stage2.bin

.PHONY: all clean distclean
