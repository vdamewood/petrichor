all: stage2.bin

clean:
	rm -rf stage2.bin

distclean: clean

pmode.bin: pmode.asm
	nasm pmode.asm -f bin -o pmode.bin

stage2.bin: stage2.asm pmode.bin a20.asm fat12.asm vidtxt.asm keyboard.asm keyscan.asm command.asm strings.asm
	nasm stage2.asm -f bin -o stage2.bin
	cat pmode.bin >> stage2.bin

.PHONY: all clean distclean
