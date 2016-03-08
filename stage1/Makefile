all: stage1.bin

clean:
	rm -rf stage1.bin

distclean: clean

stage1.bin: stage1.asm
	nasm -f bin -o stage1.bin stage1.asm

.PHONY: all clean distclean
