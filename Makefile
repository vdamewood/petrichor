all: bootdisk.img

clean:
	rm -rf stage1.bin stage2.bin

distclean: clean
	rm -rf bootdisk.img

bootdisk.img: stage1.bin stage2.bin
	mformat -i bootdisk.img -v BOOTDISK -f 1440  -C -B stage1.bin ::
	mcopy -i bootdisk.img stage2.bin ::/STAGE2.BIN

stage1.bin: stage1.asm
	nasm stage1.asm -f bin -o stage1.bin

stage2.bin: stage2.asm stage2-a20.asm stage2-fat12.asm stage2-io.asm stage2-kbd.asm stage2-scantbl.asm stage2-string.asm
	nasm stage2.asm -f bin -o stage2.bin

.PHONY: all clean distclean
