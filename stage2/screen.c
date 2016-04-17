/* screen.c: Screen driver (text only)
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
#include "x86asm.h"

static uint8_t  color  = 0x07;
static uint16_t cursor = 0;
static volatile uint16_t *vmem = (uint16_t*) 0x000B8000;

#define width 80
#define height 25

void Scroll(void)
{
	for (int i = 0; i < width * (height-1); i++)
		vmem[i] = vmem[i+width];
	for (int i = width * (height-1); i < width * height; i++)
		vmem[i] = (color<<8);
}

void scrBreakLine(void)
{
	if (cursor < (height-1) * width)
	{
		cursor -= cursor % width;
		cursor += width;
	}
	else
	{
		Scroll();
		cursor = (height-1) * width;
	}
}

void scrClear(void)
{
	short fill = (color << 8);
	for (int i = 0; i < (width*height); i++)
		vmem[i] = fill;
	cursor = 0;
}

void scrDelete(void)
{
	vmem[--cursor] &= 0xFF00;
}

void scrPutGlyph(const uint8_t c)
{
	vmem[cursor++] = ((uint16_t)color << 8) | c;

	if (cursor > height*width)
	{
		Scroll();
		cursor = (height-1) * width;
	}
}





uint8_t scrGetColor(void)
{
	return color;
}

void scrSetColor(const uint8_t newColor)
{
	color = newColor;
}

void scrSetForgroundColor(const uint8_t newColor)
{
	color = (color & 0xF0) | (newColor & 0x0F);
}

void scrSetBackgroundColor(const uint8_t newColor)
{
	color = ((newColor<<4) & 0xF0) | (color & 0x0F);
}




uint16_t scrGetCursorPosition(void)
{
	return cursor;
}

void scrSetCursor(const uint16_t newPos)
{
	cursor = newPos;
}

void scrShowCursor(void)
{
    outb(0x3D4, 0x0F);
    outb(0x3D5, cursor & 0xFF);
    outb(0x3D4, 0x0E);
    outb(0x3D5, cursor>>8);
}

void scrHideCursor(void)
{
    //outb(0x3D4, 0x0F);
    //outb(0x3D5, cursor & 0xFF);
    //outb(0x3D4, 0x0E);
    //outb(0x3D5, cursor>>8);
}
