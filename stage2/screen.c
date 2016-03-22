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


#define vmem    ((volatile unsigned short*)0x000B8000)


// When placing, LSB is character in CP437, MSB is Forground/Backgorund color

unsigned char color = 0x07;
unsigned int cursor = 0;

#define width 80
#define height 25

void scrClear(void)
{
	short fill = (color << 8);
	for (int i = 0; i < (width*height); i++)
		vmem[i] = fill;
	cursor = 0;
}

void scrSetCursor(unsigned int newPos)
{
	cursor = newPos;
}

int GetRealCursor(void)
{
	return cursor * 2 + 0x000B8000;
}

void SetRealCursor(unsigned int newPos)
{
	newPos -= 0x000B8000;
	newPos >>= 1;
	cursor = newPos;
}

void scrShowCursor(void)
{
    // out 0x3D4, 0x0F
	asm volatile ("outb %0, %1" : : "a" ((unsigned char)0x0F), "d" ((unsigned short)0x3D4) );
    // out 0x3D5, bl
	asm volatile ("outb %0, %1" : : "a" ((unsigned char)(cursor&0xFF)), "d" ((unsigned short)0x3D5) );
    // out 0x3D4, 0x0E
	asm volatile ("outb %0, %1" : : "a" ((unsigned char)0x0E), "d" ((unsigned short)0x3D4) );
    // out 0x3D5, bh
	asm volatile ("outb %0, %1" : : "a" ((unsigned char)(cursor>>8)), "d" ((unsigned short)0x3D5) );
}

void scrShift(void)
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
		scrShift();
		cursor = (height-1) * width;
	}
	scrShowCursor();
}

void scrPrint(char *string)
{
	for (char *p = string; *p; p++)
	{
		vmem[cursor++] = ((unsigned short)color << 8) | *p;

		// vmem[cursor++] = (color << 8) & *p;
		if (cursor > height*width)
		{
			scrShift();
			cursor = (height-1) * width;
		}
	}
}

void scrPrintLine(char *string)
{
	scrPrint(string);
	scrBreakLine();

}

void scrPrintChar(char c)
{
	vmem[cursor++] = ((unsigned short)color << 8) | c;

	if (cursor > height*width)
	{
		scrShift();
		cursor = (height-1) * width;
	}
}

void scrPrintSpace(void)
{
	scrPrintChar(' ');
}

void scrDelete(void)
{
	vmem[--cursor] &= 0xFF00;
}

void scrPrintHex(const int count, const int value)
{
	const unsigned char *v = (const unsigned char *)(&value);
	for (int i = count-1; i >= 0; i--)
	{
		scrPrintChar((v[i] >> 4)  + (((v[i] >> 4)  > 9) ? 0x37 : 0x30));
		scrPrintChar((v[i] & 0xF) + (((v[i] & 0xF) > 9) ? 0x37 : 0x30));
	}
}

void scrPrintHexByte(char value)
{
	scrPrintHex(1, (int)value);
}

void scrPrintHexWord(short value)
{
	scrPrintHex(2, (int)value);
}

void scrPrintHexDWord(int value)
{
	scrPrintHex(4, value);
}

void scrPrintHexPointer(void *value)
{
	scrPrintHex(4, (int)value);
}
