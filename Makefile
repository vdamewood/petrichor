all: petrichr.img

clean:
	rm -rf petrboot.bin stage2.bin

distclean: clean
	rm -rf petrichr.img

petrichr.img: petrboot.bin stage2.bin
	dd of=petrichr.img if=petrboot.bin bs=512        count=1
	dd of=petrichr.img if=stage2.bin   bs=512 seek=1 count=1
	dd of=petrichr.img if=/dev/zero    bs=512 seek=2 count=2878

petrboot.bin: petrboot.asm
	nasm petrboot.asm -f bin -o petrboot.bin

stage2.bin: stage2.asm
	nasm stage2.asm -f bin -o stage2.bin


.PHONY: all clean distclean
