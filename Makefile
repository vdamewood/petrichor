all: bootdisk.img

clean:
	rm -rf stage1.bin stage2.bin fat.bin rootdir.bin

distclean: clean
	rm -rf bootdisk.img

bootdisk.img: stage1.bin stage2.bin fat.bin rootdir.bin
	cat stage1.bin fat.bin fat.bin rootdir.bin > bootdisk.img
	dd of=bootdisk.img if=/dev/zero    bs=512 seek=34  count=2846
	mcopy -i bootdisk.img stage2.bin ::/STAGE2.BIN

%.bin: %.asm
	nasm $< -f bin -o $@

.PHONY: all clean distclean
