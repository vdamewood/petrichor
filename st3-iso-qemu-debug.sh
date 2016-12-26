#!/bin/sh

qemu-system-i386 \
    -s -S \
    -boot d -cdrom stage3.iso
