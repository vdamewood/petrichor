all: bootdisk.img

clean:
	rm -rf stage1.bin stage2.bin

distclean: clean
	rm -rf ptrcboot.img

bootdisk.img: stage1.bin stage2.bin
	dd of=bootdisk.img if=stage1.bin bs=512        count=1
	dd of=bootdisk.img if=stage2.bin bs=512 seek=1 count=1
	dd of=bootdisk.img if=/dev/zero  bs=512 seek=2 count=2878

stage1.bin: stage1.asm
	nasm stage1.asm -f bin -o stage1.bin

stage2.bin: stage2.asm
	nasm stage2.asm -f bin -o stage2.bin

.PHONY: all clean distclean
