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

void ScreenPrint(char*);
char *uioGetLine(void);
int StringMatch(char*, char*);
void ScreenPrintLine(char*);
void MiscSayHi(void);
void ScreenClear(void);
void MiscShowVendor(void);
void memShowMap(void);
void RunTest(void);
void CommandShowHelp(void);
void CommandStub(void);

#define Prompt "?>"

struct entry
{
	char *command;
	void (*routine)(void);
};
typedef struct entry entry;


entry CommandTable[] =
{
	{"hi", MiscSayHi},
	{"clear", ScreenClear},
	{"vendor", MiscShowVendor},
	{"memory", memShowMap},
	{"test", RunTest},
	{"help", CommandShowHelp},
	{0, CommandStub}
};

char HelpLine00[] = "Command   Description";
char HelpLine01[] = "hi        Display a greeting";
char HelpLine02[] = "clear     Clear the screen";
char HelpLine03[] = "vendor    Display the vendor string from your CPU";
char HelpLine04[] = "memory    Show a map of memory";
char HelpLine05[] = "test      Test the current project";
char HelpLine06[] = "help      Show this help";

char *HelpTable[] =
{
	HelpLine00,
	HelpLine01,
	HelpLine02,
	HelpLine03,
	HelpLine04,
	HelpLine05,
	HelpLine06,
	0
};

void CommandLoop(void)
{
	while(1)
	{
		ScreenPrint(Prompt);
		char *command = uioGetLine();
		for (entry *candidate = CommandTable; candidate->command != 0; candidate++)
			if (StringMatch(command, candidate->command))
			{
				candidate->routine();
				break;
			}
	}
}

void CommandShowHelp(void)
{
	for(char **line = HelpTable; *line != (char*)0; line++)
		ScreenPrintLine(*line);
}

void RunTest(void)
{
	ScreenPrintLine("No test enabled.");
}

void CommandStub(void)
{

}
