# Petrichor

Petrichor is the code name for my hobby OS-development project. At the moment
the project includes a bootable floppy with a boot sector written in 16-bit
x86 assembly, and a stage-2 image called STAGE2.BIN, written in 32-bit x86
assembly. The program in the boot sector loads and runs STAGE2.BIN from the
floppy disk. The stage-2 image is a simple, toy program with demonstration
commands.

## Future Development

There are a few goals for the stage-2 image:

* Fit in 64 kibibytes, so that it can be loaded into a single
  segment by the stage-1 image.
* Comply with multiboot standard and load a kernel.

The demonstration aspects of the stage-2 image will eventually be moved into
loadable programs, and a stage-3 kernel will be made to load and run them.
