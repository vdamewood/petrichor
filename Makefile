all: bootdisk.img

clean:
	rm -rf stage1.bin stage2.bin rootdir.bin

distclean: clean
	rm -rf bootdisk.img

bootdisk.img: stage1.bin stage2.bin rootdir.bin
	dd of=bootdisk.img if=stage1.bin   bs=512         count=1
	dd of=bootdisk.img if=stage2.bin   bs=512 seek=1  count=1
	dd of=bootdisk.img if=/dev/zero    bs=512 seek=2  count=18
	dd of=bootdisk.img if=rootdir.bin  bs=512 seek=20 count=1
	dd of=bootdisk.img if=/dev/zero    bs=512 seek=21 count=2859

stage1.bin: stage1.asm
	nasm stage1.asm -f bin -o stage1.bin

stage2.bin: stage2.asm
	nasm stage2.asm -f bin -o stage2.bin

rootdir.bin: rootdir.asm
	nasm rootdir.asm -f bin -o rootdir.bin

.PHONY: all clean distclean
