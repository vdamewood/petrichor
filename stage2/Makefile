all: stage2.bin

clean:
	rm -rf stage2.bin

distclean: clean

stage2.bin: stage2.asm functions.inc gdt.asm fat12.asm vidtxt.asm keyboard.asm keyscan.asm command.asm strings.asm
	nasm stage2.asm -f bin -o stage2.bin

.PHONY: all clean distclean
