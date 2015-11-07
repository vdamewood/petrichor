# Petrichor

Petrichor is the code name for my hobby OS-development project. At the moment
the project includes a boot sector written in 16-bit x86 assembly. The program
in the boot sector waits for the user to type something, then echos the text
back at the user.

# Future Goals

In the near future it's hoped that Petricor loads a second-stage image, and
include some demonstration tasks. After the second-stage image is complete,
development will focus on a third-stage image that will eventually become
the kernel of the Petrichor operating system.

## The Second-Stage Image

At first, the second-stage image will run a simple command-line interface
and perform demonstation tasks. After these tasks are complete, a demonstration
task to load the third-stage image (future kernel) will be made. With a workable
third-stage image, the other demonstration tasks will be moved into the
third-stage image and the second-stage loader will focus on setting up the machine state to run a proper kernel.

## The Kernel

The Kernel will start out as just a simple third-stage image with commands
taken from the early second-stage image. These commands will be moved into
separate executables and the third-stage image will be modified to load these
demonstration tools from separate executables.

## Eventual Goals

If time allows and my interest doesn't wane, I will try to make the kernel
compatible with GNU GRUB, and make the second-stage loader a simple stub that
loads the kernel and handles what GNU GRUB would do. Focus will then be taken
away from the second-stage loader, and boot sector.