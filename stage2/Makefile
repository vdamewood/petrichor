all: stage2.bin

clean:
	rm -rf stage2.bin *.o

distclean: clean

OBJECTS=stage2.o idt.o vidtxt.o keyboard.o keyscan.o command.o strings.o

%.o: %.asm functions.inc
	nasm $< -f elf -o $@

stage2.o: stage2.asm gdt.asm functions.inc
	nasm $< -f elf -o $@


stage2.bin: stage2.ld $(OBJECTS)
	i686-elf-ld -T stage2.ld -o stage2.bin $(OBJECTS)
	#i686-elf-strip stage2.bin

.PHONY: all clean distclean
