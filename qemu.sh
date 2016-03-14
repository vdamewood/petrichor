#!/bin/sh

make &&
qemu-system-i386 \
    -drive file=bootdisk.img,format=raw,index=0,if=floppy \
    -boot order=a
