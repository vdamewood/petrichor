/* timer.c: Programmable interval timer interface
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

	uioPrintHexByte(BiosHigh);
	uioPrintHexByte(BiosLow);
	uioPrintChar('\n');
}

void tmpResetInterval(void)
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
