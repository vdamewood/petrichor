/* command.c: Command interpreter
 *
 * Copyright 2015, 2016 Vincent Damewood
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

#include "screen.h"

void  AcpiShutdown(void);
void  AcpiShowHeaders(void);
int   blStrCmp(const void*, const void*);
int   blStrLen(const char*);
void  memShowMap(void);
void  cpuidShowVendor(void);
char *uioGetLine(void);
void tmrSetInterval(unsigned short);

static void  ClearScreen(int argc, char *argv[]);
static void  GreetUser(int argc, char *argv[]);
static void  ShowHelp(int argc, char *argv[]);
static void  Stub(int argc, char *argv[]);
static void  Vendor(int argc, char *argv[]);
static void  MemoryMap(int argc, char *argv[]);
static void  AcpiHeaders(int argc, char *argv[]);
static void  Shutdown(int argc, char *argv[]);
static void  TestArgs(int argc, char *argv[]);
static void  Color(int argc, char *argv[]);
static void TestFloppy(int, char*[]);

struct entry
{
	char *command;
	char *help;
	void (*routine)(int,char*[]);
};
typedef struct entry entry;

entry CommandTable[] =
{
	{"hi",       "Display a greeting",        GreetUser},
	{"clear",    "Clear the screen",          ClearScreen},
	{"vendor",   "Display vendor from CPUID", Vendor},
	{"memory",   "Show a map of memory",      MemoryMap},
	{"acpi",     "Show acpi headers",         AcpiHeaders},
	{"help",     "Show this help",            ShowHelp},
	{"shutdown", "Turn the system off",       Shutdown},
	{"test",     "test arguments",            TestArgs},
	{"color",    "change color",              Color},
	{"floppy",   "test floppy drive",         TestFloppy},
	{0,          0,                           Stub}
};


// FIXME: Implement memory allocation
#define argMax 8
#define argSize 24
static char argumentBuffer[argMax][argSize];
char *argumentPointers[argMax];


void CommandLoop(void)
{
	// This approximates 1000 ticks = 1 second.
	tmrSetInterval(1193);
	for (int i = 0; i < argMax; i++)
		argumentPointers[i] = argumentBuffer[i];

	while(1)
	{
		scrPrint("?> ");
		char *command = uioGetLine();

		int inChar = 0;
		int outChar = 0;
		int count = 0;

		do
		{
			if (command[inChar] != ' ' && command[inChar] != '\0')
			{
				if (outChar < argSize-1)
					argumentPointers[count][outChar++] = command[inChar];
			}
			else
			{
				argumentPointers[count++][outChar] = '\0';
				outChar = 0;
			}

			if (count == argMax)
				break;
		} while(command[inChar++] != '\0');

		for (entry *candidate = CommandTable; candidate->command != 0; candidate++)
			if (blStrCmp(argumentPointers[0], candidate->command) == 0)
			{
				candidate->routine(count, argumentPointers);
				break;
			}
	}
}

static void GreetUser(int argc, char *argv[])
{
	scrPrintLine("Hello.");
}

static void TestArgs(int argc, char *argv[])
{
	for (int i=0; i<argc; i++)
		scrPrintLine(argv[i]);
}

static void ClearScreen(int argc, char *argv[])
{
	scrClear();
}

static void Vendor(int argc, char *argv[])
{
	cpuidShowVendor();
}

static void MemoryMap(int argc, char *argv[])
{
	memShowMap();
}

static void AcpiHeaders(int argc, char *argv[])
{
	AcpiShowHeaders();
}

static void Shutdown(int argc, char *argv[])
{
	AcpiShutdown();
}

void scrSetColor(unsigned char newColor);
void scrSetForgroundColor(unsigned char newColor);
void scrSetBackgroundColor(unsigned char newColor);

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

static void Color(int argc, char *argv[])
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
				scrPrintLine("Bad color target");
		else
			scrPrintLine("Bad color");
	}
	else
	{
		scrPrintLine("bad arguments");
	}
}

void fdInit(void);
void fdRead(void);
void *fdGetBuffer(void);

static void TestFloppy(int argc, char *argv[])
{
	if (argc == 2)
	{
		if (blStrCmp("init", argv[1]) == 0)
		{
			scrPrintLine("Testing floppy drive initialization.");
			fdInit();
		}
		else if (blStrCmp("read", argv[1]) == 0)
		{
			scrPrintLine("Testing floppy drive read.");
			fdRead();
		}
		else if (blStrCmp("verify", argv[1]) == 0)
		{
			char *byte = fdGetBuffer();
			do
			{
				scrPrintHexByte(*byte++);
				scrPrintChar(' ');
			}
			while(byte < (char*)fdGetBuffer() + 0x18);
			scrBreakLine();

			byte = (char*)0x7C00;
			do
			{
				scrPrintHexByte(*byte++);
				scrPrintChar(' ');
			}
			while(byte < (char*)0x7C18);
			scrBreakLine();
		}
		else
		{
			scrPrint("-floppy: Error: Invalid sub-command: ");
			scrPrintLine(argv[1]);
		}
	}
	else
	{
		scrPrintLine("-floppy: Error: Sub-command required");
	}

}

static void ShowHelp(int argc, char *argv[])
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
		scrPrint(candidate->command);
		for (int i = maxLen + 2 - blStrLen(candidate->command); i != 0; i--)
			scrPrintChar(' ');

		//scrPrint(" -- ");
		scrPrint(candidate->help);
		scrBreakLine();
		//asm("int 0x21");
		//scrBreakLine();
	}
}

static void Stub(int argc, char *argv[])
{

}
