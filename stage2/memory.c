/* memory.c: Memory management
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

#include "uio.h"
#include "memory.h"

char *StatusTable[] =
{
	"",
	"1:Free",
	"2:Reserved",
	"3:ACPI Reclaimable",
	"4:ACPI Non-volatile",
	"5:Bad"
};

struct entry
{
	int base;
	int baseHi;
	int length;
	int lengthHi;
	int status;
	int extra;
};
typedef struct entry entry;

void memShowMap(void)
{
	uioPrint("Base     Size     Status\n");
	for (
			entry *i = (entry*)0x3308;
			i < (entry*)(0x3308 + sizeof(entry) * (*((int *)0x3300)));
			i++)
		uioPrintf("%.8X %.8x %s\n", i->base, i->length, StatusTable[i->status]);
}

#define PoolBase 0x30000
#define PoolSize 0x10000

void *freeSpace = (void*)PoolBase;

void *memAlloc(size_t size)
{
	char *tmp = freeSpace;
	if (tmp + size >= (char*)PoolBase + PoolSize)
		return NULL;

	freeSpace = tmp + size;
	return tmp;
}

void memFree(void *location)
{
}

void memReset(void)
{
	freeSpace = (void*)PoolBase;
}
