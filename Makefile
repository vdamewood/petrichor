ifdef DEBUG
	DDEBUG="-DDEBUG"
else
	DDEBUG=""
endif

all: bootdisk.img

clean:
	rm -rf stage1.bin stage2.bin fat.bin rootdir.bin

distclean: clean
	rm -rf bootdisk.img

bootdisk.img: stage1.bin stage2.bin fat.bin rootdir.bin
	cat stage1.bin fat.bin fat.bin rootdir.bin > bootdisk.img
	dd of=bootdisk.img if=/dev/null bs=512 seek=2880
	mcopy -i bootdisk.img stage2.bin ::/STAGE2.BIN

%.bin: %.asm
	nasm $(DDEBUG) $< -f bin -o $@

.PHONY: all clean distclean
