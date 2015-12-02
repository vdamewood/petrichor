ifdef DEBUG
	DDEBUG="-DDEBUG"
else
	DDEBUG=""
endif

all: bootdisk.img

clean:
	rm -rf stage1.bin stage2.bin

distclean: clean
	rm -rf bootdisk.img

bootdisk.img: stage1.bin stage2.bin
	mformat -i bootdisk.img -v BOOTDISK -f 1440  -C -B stage1.bin ::
	mcopy -i bootdisk.img stage2.bin ::/STAGE2.BIN

%.bin: %.asm
	nasm $(DDEBUG) $< -f bin -o $@

.PHONY: all clean distclean
