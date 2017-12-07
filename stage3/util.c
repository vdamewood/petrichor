/* util.c: Utility routines
 *
 * Copyright 2016 Vincent Damewood
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

#include "util.h"

int blStrCmp(const char *mem1, const char *mem2)
{
	int rVal;
	asm(
		"0:\n"
		"\tlodsb\n"
		"\tscasb\n"
		"\tjne 1f\n"
		"\tor %%al, %%al\n"
		"\tjnz 0b\n"
		"\txor %%eax, %%eax\n"
		"\tjmp 2f\n"
		"1:\n"
		"\tlahf\n"
		"\tmovsx %%ah, %%eax\n"
		"\tsar $6, %%eax\n"
		"\txor $1, %%eax\n"
		"2:\n"
		"\tnop"
		: "=a"(rVal)
		: "S"(mem1), "D"(mem2)
		: "esi", "edi"
	);
	return rVal;
}

int blStrLen(const char *string)
{
	int i = 0;
	for (; *string++; i++);
	return i;
}

int blMemCmp(void *src, void *dst, int count)
{
	int rVal;
	asm(
	"repe cmpsb\n"
	"\tlahf\n"
	"\tmovsx %%ah, %%eax\n"
	"\tsar $6, %%eax\n"
	"\txor $1, %%eax"
	: "=a"(rVal)
	: "c"(count), "S"(src), "D"(dst)
	);
	return rVal;
}
