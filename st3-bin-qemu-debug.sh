#!/bin/sh

qemu-system-i386 \
    -s -S \
    --kernel stage3.bin
