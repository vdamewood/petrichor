/* shell.c: Command interpreter
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

#include "command.h"
#include "memory.h"
#include "screen.h"
#include "shell.h"
#include "uio.h"

// FIXME: Implement memory allocation
#define argMax 7
#define argSize 24
static char argumentBuffer[argMax+1][argSize];
static char *argumentPointers[argMax];

void shLoop(void)
{
	for (int i = 0; i < argMax; i++)
		argumentPointers[i] = argumentBuffer[i];

	while(1)
	{
		const char *command = uioPrompt("?> ");

		int inChar = 0;
		int outChar = 0;
		int count = 0;

		// FIXME: This can be replaced with something that understands escapes and
		//        quotes.
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
		}
		while(command[inChar++] != '\0');
		argumentPointers[count][0] = '\0';

		int (*function)(int,char*[]) = cmdGet(argumentPointers[0]);
		if (function)
			function(count, argumentPointers);

		memReset();
	}
}

