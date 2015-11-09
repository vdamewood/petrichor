all: bootdisk.img

clean:
	rm -rf stage1.bin stage2.bin fat.bin rootdir.bin

distclean: clean
	rm -rf bootdisk.img

bootdisk.img: stage1.bin stage2.bin fat.bin rootdir.bin
	rm -f bootdisk.img
	dd of=bootdisk.img if=stage1.bin   bs=512 seek=0   count=1
	dd of=bootdisk.img if=fat.bin      bs=512 seek=1   count=9
	dd of=bootdisk.img if=fat.bin      bs=512 seek=10  count=9
	dd of=bootdisk.img if=rootdir.bin  bs=512 seek=19  count=14
	dd of=bootdisk.img if=stage2.bin   bs=512 seek=33  count=1
	dd of=bootdisk.img if=/dev/zero    bs=512 seek=34  count=2846
	chmod 444 bootdisk.img

%.bin: %.asm
	nasm $< -f bin -o $@

.PHONY: all clean distclean
