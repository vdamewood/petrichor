all: stage2.bin

clean:
	rm -rf stage2.bin

distclean: clean

stage2.bin: stage2.asm a20.asm fat12.asm io.asm keyboard.asm keyscan.asm strings.asm
	nasm stage2.asm -f bin -o stage2.bin

.PHONY: all clean distclean
