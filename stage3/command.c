/* command.c: Command lookup
 *
 * Copyright 2015, 2016 Vincent Damewood
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <stddef.h>

#include "acpi.h"
#include "command.h"
#include "cpuid.h"
//#include "fat12.h"
//#include "floppy.h"
#include "memory.h"
#include "screen.h"
#include "timer.h"
#include "uio.h"
#include "util.h"

static int ClearScreen(int, char *[]);
static int GreetUser(int, char *[]);
static int ShowHelp(int, char *[]);
static int Stub(int, char *[]);
static int Vendor(int, char *[]);
static int MemoryMap(int, char *[]);
static int AcpiHeaders(int, char *[]);
static int Shutdown(int, char *[]);
static int TestArgs(int, char *[]);
static int Color(int, char *[]);
//static int TestFloppy(int, char*[]);
//static int Dir(int, char*[]);
//static int Load(int, char*[]);
static int BootInfo(int, char*[]);

struct entry
{
	char *command;
	char *help;
	int (*routine)(int,char*[]);
};
typedef struct entry entry;

entry CommandTable[] =
{
	{"hi",       "Display a greeting",        GreetUser},
	{"clear",    "Clear the screen",          ClearScreen},
	{"vendor",   "Display vendor from CPUID", Vendor},
	//{"memory",   "Show a map of memory",      MemoryMap},
	{"acpi",     "Show acpi headers",         AcpiHeaders},
	{"help",     "Show this help",            ShowHelp},
	{"shutdown", "Turn the system off",       Shutdown},
	{"test",     "test arguments",            TestArgs},
	{"color",    "change color",              Color},
	//{"floppy",   "test floppy drive",         TestFloppy},
	//{"dir",      "Show a directory",          Dir},
	//{"load",     "Load a file",               Load},
	{"bootinfo", "BootInfo",                  BootInfo},
	{0,          0,                           Stub}
};


// FIXME: Implement memory allocation
#define argMax 8
#define argSize 24
static char argumentBuffer[argMax][argSize];
char *argumentPointers[argMax];


int (*cmdGet(const char *in))(int,char*[])
{
	for (entry *candidate = CommandTable; candidate->command != NULL; candidate++)
			if (blStrCmp(in, candidate->command) == 0)
				return candidate->routine;
	return NULL;
}

static int GreetUser(int argc, char *argv[])
{
	uioPrint("Hello.\n");
	return 0;
}

static int TestArgs(int argc, char *argv[])
{
	for (int i=0; i<argc; i++)
		uioPrintf("%s\n", argv[i]);

	return 0;
}

static int ClearScreen(int argc, char *argv[])
{
	scrClear();
	return 0;
}

static int Vendor(int argc, char *argv[])
{
	cpuidShowVendor();
	return 0;
}

/*static int MemoryMap(int argc, char *argv[])
{
	memShowMap();
	return 0;
}*/

static int AcpiHeaders(int argc, char *argv[])
{
	AcpiShowHeaders();
	return 0;
}

static int Shutdown(int argc, char *argv[])
{
	AcpiShutdown();
	return 0;
}

struct colorTableEntry
{
	char *name;
	unsigned char value;
};


struct colorTableEntry colors[] =
{
	{"black",   scrBlack},
	{"blue",    scrBlue},
	{"green",   scrGreen},
	{"cyan",    scrCyan},
	{"red",     scrRed},
	{"purple",  scrPurple},
	{"yellow",  scrYellow},
	{"white",   scrWhite},
	{"black+",  scrBright | scrBlack},
	{"blue+",   scrBright | scrBlue},
	{"green+",  scrBright | scrGreen},
	{"cyan+",   scrBright | scrCyan},
	{"red+",    scrBright | scrRed},
	{"purple+", scrBright | scrPurple},
	{"yellow+", scrBright | scrYellow},
	{"white+",  scrBright | scrWhite},
	{0,         0xFF}
};

static int Color(int argc, char *argv[])
{
	if (argc == 3)
	{
		unsigned char setColor = 0xFF;

		for (struct colorTableEntry *candidate = colors; candidate->name != 0; candidate++)
			if (blStrCmp(candidate->name, argv[2]) == 0)
				setColor = candidate->value;

		if (setColor != 0xFF)
			if (blStrCmp(argv[1], "text") == 0)
				scrSetForgroundColor(setColor);

			else if (blStrCmp(argv[1], "highlight") == 0)
				scrSetBackgroundColor(setColor);
			else
				uioPrint("Bad color target\n");
		else
			uioPrint("Bad color\n");
	}
	else
	{
		uioPrint("bad arguments\n");
	}
	return 0;
}


/*char buffer[80] = "";
static int TestFloppy(int argc, char *argv[])
{
	uioPrint("Testing floppy drive initialization.\n");
	drvStorageDevice floppy = fdGetDriver();
	uioPrint("Testing floppy drive read.");
	floppy.ReadSectors(floppy.Driver.State, 0, 1, (void*)0x500);

	uioPrint("Checking values:\n");

	char *buffers[3] = {(char*)0x7C00, fdGetBuffer(), (char*)0x500};

	for (int i = 0; i < 3; i++)
	{
		char *byte = buffers[i];
		char *limit = byte+0x18;
		do
			uioPrintf("%hhx ", *byte++);
		while(byte < limit);
		uioPrintChar('\n');
	}
	return 0;
}*/

static int ShowHelp(int argc, char *argv[])
{
	static int maxLen = 0;

	if (!maxLen)
		for (entry *candidate = CommandTable; candidate->command != 0; candidate++)
		{
			int current = blStrLen(candidate->command);
			if (current > maxLen)
				maxLen = current;
		}

	for (entry *candidate = CommandTable; candidate->command != 0; candidate++)
	{
		uioPrint(candidate->command);
		for (int i = maxLen + 2 - blStrLen(candidate->command); i != 0; i--)
			uioPrintChar(' ');

		uioPrint(" -- ");
		uioPrint(candidate->help);
		uioPrintChar('\n');
	}
	return 0;
}

/*static int Dir(int argc, char *argv[])
{
	const char *directory = "/";
	drvStorageDevice floppy = fdGetDriver();

	if (argc == 2)
		directory = argv[1];

	fat12ShowDirectory(&floppy, directory);
	return 0;
}

static int Load(int argc, char *argv[])
{
	if (argc != 2)
	{
		uioPrint("Specify file\n");
		return 1;
	}
	drvStorageDevice floppy = fdGetDriver();
	fat12LoadFile(&floppy, argv[1], (void*)0x500);
	return 0;
}*/

#include "mboot.h"
static int BootInfo(int argc, char *argv[])
{
	uioPrintf("Saved registers: EAX(%#.8X) EBX(%#.8X)\n", SavedEax, SavedEbx);
	uioPrintf("Flags: %#.8X\n", MbInfo.flags);

	if (MbInfo.flags & MB_FLAG_MEMORY)
		uioPrintf("Memory: Lower: %ik; Upper: %ik\n", MbInfo.mem_lower, MbInfo.mem_upper);

	if (MbInfo.flags & MB_FLAG_BOOTDEV)
		uioPrintf("Boot: %hhX(%hhx:%hhX:%hhX)\n",
			MbInfo.boot_device, MbInfo.boot_parts[2],
			MbInfo.boot_parts[1], MbInfo.boot_parts[0]);

	if (MbInfo.flags & MB_FLAG_COMMAND)
		uioPrintf("Command: %s\n", MbInfo.cmdline);

	if (MbInfo.flags & MB_FLAG_BOOTMODS)
	{
		uioPrintf("Booted Modules: %i\n", MbInfo.mods_count);
		for (int i = 0; i < MbInfo.mods_count; i++)
			uioPrintf("%d: %s\n", i, MbInfo.mods[i].string);
	}

	if (MbInfo.flags & MB_FLAG_AOUTIMG)
		uioPrint("Bootloader passed a.out data, but this kernel doesn't support a.out.\n");

	if (MbInfo.flags & MB_FLAG_ELFIMG)
		uioPrintf("ELF: %i, %i, %X, %i\n",
			MbInfo.Elf.num, MbInfo.Elf.size, MbInfo.Elf.addr, MbInfo.Elf.shndx);

	if (MbInfo.flags & MB_FLAG_MMAP)
		uioPrintf("MMAP: Length: %d; Address: %p\n", MbInfo.mmap_length, MbInfo.mmap_addr);

	if (MbInfo.flags & MB_FLAG_DRIVES)
		uioPrintf("Drive: Length: %i Addr: %p\n", MbInfo.drives_length, MbInfo.drives_addr);

	if (MbInfo.flags & MB_FLAG_BIOSCONF)
		uioPrintf("config_table: %#.8X", MbInfo.config_table, "\n");

	if (MbInfo.flags & MB_FLAG_BOOTLDR)
		uioPrintf("Bootloader: %s\n", MbInfo.boot_loader_name);

	if (MbInfo.flags & MB_FLAG_APMTBL)
		uioPrintf("apm_table: %.8X\n", MbInfo.apm_table);

	if (MbInfo.flags & MB_FLAG_GRAPHICS)
	{
		uioPrintf("vbe_control_info:  %.8X\n", MbInfo.vbe_control_info);
		uioPrintf("vbe_mode_info:     %.8X\n", MbInfo.vbe_mode_info);
		uioPrintf("vbe_mode:          %.8X\n", MbInfo.vbe_mode);
		uioPrintf("vbe_interface_seg: %.8X\n", MbInfo.vbe_interface_seg);
		uioPrintf("vbe_interface_off: %.8X\n", MbInfo.vbe_interface_off);
		uioPrintf("vbe_interface_len: %.8X\n", MbInfo.vbe_interface_len);
	}
	return 0;
}

static int Stub(int argc, char *argv[])
{
	return 0;
}
