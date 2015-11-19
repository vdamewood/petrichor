# Petrichor

Petrichor is the code name for my hobby OS-development project. At the moment
the project includes a bootable floppy with a boot sector written in 16-bit
x86 assembly. The program in the boot sector loads and runs a file named
STAGE2.BIN from the floppy disk. A version of STAGE2.BIN is included, also
written in 16-bit x86 assembly. It is a simple, toy program that demonstrates
that the first stage has completed.

## Future Development

Hopefully I can get the second-stage image to configure the system into a
modern working state. Once that's complete, the second stage image will
load a proper kernel.

## The Kernel

The Kernel will start out as just a simple third-stage image with some simple
commands. These commands will be moved into separate executables and the
third-stage image will be modified to load these demonstration tools from
separate executables.

## Eventual Goals

If time allows and my interest doesn't wane, I will try to make the kernel
compatible with GNU GRUB, and make the second-stage loader a simple stub that
loads the kernel and handles what GNU GRUB would do. Focus will then be taken
away from the second-stage loader, and boot sector.
