/* shell.c: Command interpreter
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

