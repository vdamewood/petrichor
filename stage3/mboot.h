/* mboot.h: Multiboot support
 *
 * Copyright 2016 Vincent Damewood
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !defined MBOOT_H
#define MBOOT_H

extern unsigned int SavedEax;
extern unsigned int SavedEbx;

#define MB_FLAG_MEMORY   0x001
#define MB_FLAG_BOOTDEV  0x002
#define MB_FLAG_COMMAND  0x004
#define MB_FLAG_BOOTMODS 0x008
#define MB_FLAG_AOUTIMG  0x010
#define MB_FLAG_ELFIMG   0x020
#define MB_FLAG_MMAP     0x040
#define MB_FLAG_DRIVES   0x080
#define MB_FLAG_BIOSCONF 0x100
#define MB_FLAG_BOOTLDR  0x200
#define MB_FLAG_APMTBL   0x400
#define MB_FLAG_GRAPHICS 0x800

struct BootMod
{
	void *start;
	void *end;
	char *string;
	unsigned int reserved;
};

struct AoutInfo
{
	unsigned int tabsize;
	unsigned int str;
	unsigned int addr;
	unsigned int reserved;
};

struct ElfInfo
{
	unsigned int num;
	unsigned int size;
	unsigned int addr;
	unsigned int shndx;
};

struct MultiBootInfo
{
	unsigned int flags;
	unsigned int mem_lower;
	unsigned int mem_upper;
	unsigned char boot_parts[3];
	unsigned char boot_device;
	char *cmdline;
	unsigned int mods_count;
	struct BootMod *mods;
	union
	{
		struct AoutInfo Aout;
		struct ElfInfo Elf;

	};
	unsigned int mmap_length;
	unsigned int mmap_addr;
	unsigned int drives_length;
	unsigned int drives_addr;
	unsigned int config_table;
	char *boot_loader_name;
	unsigned int apm_table;
	unsigned int vbe_control_info;
	unsigned int vbe_mode_info;
	unsigned short vbe_mode;
	unsigned short vbe_interface_seg;
	unsigned short vbe_interface_off;
	unsigned short vbe_interface_len;
};

extern struct MultiBootInfo MbInfo;

#endif /* MBOOT_H */
