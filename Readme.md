# Petrichor

Petrichor is the code name for my hobby OS-development project. At the moment
the project includes a bootable floppy with a boot sector written in 16-bit
x86 assembly. The program in the boot sector loads and runs a file named
STAGE2.BIN from the floppy disk. A version of STAGE2.BIN is included, written
in 32-bit x86 assembly. It is a simple, toy program that demonstrates
that the first stage has completed.

## Future Development

I hope to make STAGE2.BIN 64 kibibytes or less, that way it can be loaded in
a single segment by the stage1 image, and compliant to the multiboot standard.

## The Kernel

The Kernel will start out as just a simple third-stage image with some simple
commands. These commands will be moved into separate executables and the
third-stage image will be modified to load these demonstration tools from
separate executables.
