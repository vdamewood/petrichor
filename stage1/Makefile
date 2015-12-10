all: stage1.bin

clean:
	rm -rf stage1.bin

distclean: clean

stage1.bin: stage1.asm
	nasm stage1.asm -f bin -o stage1.bin

.PHONY: all clean distclean
