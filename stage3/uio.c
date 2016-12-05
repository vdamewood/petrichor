/* uio.c: User interface input/output
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

#include "keyboard.h"
#include "screen.h"
#include "uio.h"

#define BufferSize 76
char Buffer[BufferSize];

const char *uioPrompt(const char *prompt)
{
	while (*prompt)
		scrPutGlyph(*prompt++);

	uint16_t eax;
	char *edi = Buffer;
	scrShowCursor();

	while (-1)
	{
		eax = KeyboardGetStroke();

		switch(eax &0xFF00)
		{
		case 0x0000:
			if (edi - Buffer == BufferSize-1)
				break;
			scrPutGlyph(eax);
			scrShowCursor();
			*edi++ = (char)(eax&0x00FF);
			break;
		case 0x0100:
			switch (eax & 0x00FF)
			{
			case 0x0000: // ESC
				while (edi > Buffer)
				{
					scrDelete();
					scrShowCursor();
					edi--;
				}
				break;
			case 0x0010: // Backspace
				if (edi != Buffer)
				{
					scrDelete();
					scrShowCursor();
					edi--;
				}
				break;
			case 0x0012: // Enter
				*edi = 0;
				scrBreakLine();
				return Buffer;
			}
		}
	}
}

void uioPrintChar(const char c)
{
	switch (c)
	{
	case '\n':
		scrBreakLine();
		break;
	case 0x7F:
		scrDelete();
		break;
	default:
		scrPutGlyph(c);
	}
}

void uioPrint(const char *string)
{
	for (const char *p = string; *p; p++)
		uioPrintChar(*p);
}

void uioPrintN(int length, const char *string)
{
	for (int i = 0; i < length; i++)
		uioPrintChar(string[i]);
}

static void PrintHex(const int count, const int value)
{
	const unsigned char *v = (const unsigned char *)(&value);
	for (int i = count-1; i >= 0; i--)
	{
		uioPrintChar((v[i] >> 4)  + (((v[i] >> 4)  > 9) ? 0x37 : 0x30));
		uioPrintChar((v[i] & 0xF) + (((v[i] & 0xF) > 9) ? 0x37 : 0x30));
	}
}

void uioPrintHexByte(uint8_t value)
{
	PrintHex(1, (int)value);
}

void uioPrintHexWord(uint16_t value)
{
	PrintHex(2, (int)value);
}

void uioPrintHexDWord(uint32_t value)
{
	PrintHex(4, value);
}

void uioPrintHexPointer(const void *value)
{
	PrintHex(4, (uint32_t)value);
}
