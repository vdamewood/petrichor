#!/bin/sh

make &&
qemu-system-i386 -fda bootdisk.img -boot order=a
