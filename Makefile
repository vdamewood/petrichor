all: stage1/stage1.bin stage2/stage2.bin stage3/stage3.bin bootdisk.img

clean:
	make -C stage1 clean
	make -C stage2 clean
	rm -f bochsout.txt

distclean: clean
	make -C stage1 distclean
	make -C stage2 distclean
	rm -rf bootdisk.img

bootdisk.img: stage1/stage1.bin stage2/stage2.bin stage3/stage3.bin License.txt Readme.md
	mformat -i bootdisk.img -v BOOTDISK -f 1440  -C -B stage1/stage1.bin ::
	mcopy -i bootdisk.img stage2/stage2.bin ::/STAGE2.BIN
	mattrib -i bootdisk.img +s ::/STAGE2.BIN
	mcopy -i bootdisk.img stage3/stage3.bin ::/STAGE3.BIN
	mattrib -i bootdisk.img +s ::/STAGE3.BIN
	mcopy -i bootdisk.img License.txt ::/LICENSE.TXT
	mattrib -i bootdisk.img +r ::/LICENSE.TXT
	mcopy -i bootdisk.img Readme.md ::/README.MD
	mattrib -i bootdisk.img +r ::/README.MD
	mmd -i bootdisk.img ::/STUFF
	mmd -i bootdisk.img ::/STUFF/DOCS
	mcopy -i bootdisk.img License.txt ::/STUFF/DOCS/LICENSE.TXT
	mattrib -i bootdisk.img +r ::/STUFF/DOCS/LICENSE.TXT
	mcopy -i bootdisk.img Readme.md ::/STUFF/DOCS/README.MD
	mattrib -i bootdisk.img +r ::/STUFF/DOCS/README.MD
	mmd -i bootdisk.img ::/STUFF/THINGS
	mmd -i bootdisk.img ::/STUFF/THINGS/FOO
	mmd -i bootdisk.img ::/STUFF/THINGS/BAR
	mmd -i bootdisk.img ::/STUFF/THINGS/BAR/QUUX
	mmd -i bootdisk.img ::/STUFF/THINGS/BAZ


stage1/stage1.bin:
	make -C stage1 stage1.bin

stage2/stage2.bin:
	make -C stage2 stage2.bin

.PHONY: all clean distclean stage1/stage1.bin stage2/stage2.bin
