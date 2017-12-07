/* screen.c: Screen driver (text only)
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
