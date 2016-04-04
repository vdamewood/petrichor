all: stage1/stage1.bin stage2/stage2.bin bootdisk.img

clean:
	make -C stage1 clean
	make -C stage2 clean
	rm -f bochsout.txt

distclean: clean
	make -C stage1 distclean
	make -C stage2 distclean
	rm -rf bootdisk.img

bootdisk.img: stage1/stage1.bin stage2/stage2.bin
	mformat -i bootdisk.img -v BOOTDISK -f 1440  -C -B stage1/stage1.bin ::
	mcopy -i bootdisk.img stage2/stage2.bin ::/STAGE2.BIN

stage1/stage1.bin:
	make -C stage1 stage1.bin

stage2/stage2.bin:
	make -C stage2 stage2.bin

.PHONY: all clean distclean
