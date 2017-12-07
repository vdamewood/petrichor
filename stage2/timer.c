/* timer.c: Programmable interval timer interface
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

#include "timer.h"
#include "x86asm.h"

volatile static unsigned int clock = 0;
volatile static uint8_t BiosLow = 0;
volatile static uint8_t BiosHigh = 0;
volatile static uint8_t BiosCached = 0;

void tmrHandleInterrupt(void)
{
	if (clock)
		clock--;
}

void tmrSetInterval(unsigned short count)
{
	asm("cli");

	if (!BiosCached)
	{
		outb(0x43, 0x00);
		BiosLow = inb(0x40);
		BiosHigh = inb(0x40);
		BiosCached = 0xFF;
	}

	outb(0x40, count&0xFF);
	outb(0x40, count >> 8);

	asm("sti");
}

void tmrResetInterval(void)
{
	asm("cli");

	if (BiosCached)
	{
		outb(0x40, BiosLow);
		outb(0x40, BiosHigh);
	}

	asm("sti");
}

int tmrTimeout(unsigned int ticks, int (*done)(void))
{
	int rVal = 0;
	clock = ticks;
	while (!(rVal = done()) && clock)
		asm("hlt");

	return rVal;
}

void tmrWait(unsigned int ticks)
{
	clock = ticks;
	while (clock)
		asm("hlt");
}
