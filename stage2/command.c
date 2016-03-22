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

void  AcpiShutdown(void);
void  AcpiShowHeaders(void);
int   blStrCmp(const void*, const void*);
int   blStrLen(const char*);
void  memShowMap(void);
void  cpuidShowVendor(void);
void  scrClear(void);
void  scrPrintLine(const char*);
void  scrBreakLine(void);
void  scrPrint(const char*);
void  scrPrintChar(char);
char *uioGetLine(void);

static void  GreetUser(void);
static void  ShowHelp(void);
static void  Stub(void);

struct entry
{
	char *command;
	char *help;
	void (*routine)(void);
};
typedef struct entry entry;

entry CommandTable[] =
{
	{"hi",       "Display a greeting",        GreetUser},
	{"clear",    "Clear the screen",          scrClear},
	{"vendor",   "Display vendor from CPUID", cpuidShowVendor},
	{"memory",   "Show a map of memory",      memShowMap},
	{"acpi",     "Show acpi headers",         AcpiShowHeaders},
	{"help",     "Show this help",            ShowHelp},
	{"shutdown", "Turn the system off",       AcpiShutdown},
	{0,        0,                             Stub}
};

void CommandLoop(void)
{
	while(1)
	{
		scrPrint("?> ");
		char *command = uioGetLine();
		for (entry *candidate = CommandTable; candidate->command != 0; candidate++)
			if (blStrCmp(command, candidate->command) == 0)
			{
				candidate->routine();
				break;
			}
	}
}

static void GreetUser(void)
{
	scrPrintLine("Hello.");
}

static void ShowHelp(void)
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
	}
}

static void Stub(void)
{

}
