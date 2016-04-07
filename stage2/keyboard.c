/* keyboard.c: Keyboard interface
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

#include "stdint.h"
#include "x86asm.h"

volatile uint16_t KeyboardBuffer = 0;
volatile uint8_t  MetaState = 0;

enum MetaStates
{
	LSHIFT =0x01,
	RSHIFT =0x02,
	SHIFT  = (LSHIFT|RSHIFT),

	LCTRL  =0x04,
	RCTRL  =0x08,
	CTRL   = (LCTRL|RCTRL),

	LALT   =0x10,
	RALT   =0x20,
	ALT    = (LALT|RALT)
};

volatile extern unsigned short KeyscanTable[];
volatile extern unsigned short KeyscanShiftTable[];

enum ScanStates
{
	START = 0,
	MULTIBYTE,
	PRINTSCR_PRESS_2,
	PRINTSCR_PRESS_3,
	PRINTSCR_RELEASE_2,
	PRINTSCR_RELEASE_3,
	PAUSE_1,
	PAUSE_2,
	PAUSE_3,
	PAUSE_4,
	PAUSE_5,
};

static volatile enum ScanStates ScanState = START;

void KeyboardHandleInterrupt(void)
{
	unsigned char code = inb(0x60);
	switch(ScanState)
	{
	case START:
		switch(code)
		{
		case 0x2A:
			MetaState |= LSHIFT;
			break;
		case 0x36:
			MetaState |= RSHIFT;
			break;
		case 0xAA:
			MetaState &= ~LSHIFT;
			break;
		case 0xB6:
			MetaState &= ~RSHIFT;
			break;
		case 0xE0:
			ScanState = MULTIBYTE;
			break;
		case 0xE1:
			ScanState = PAUSE_1;
		default:
			if (code < 0x80)
			{
				if (MetaState & SHIFT)
					KeyboardBuffer = KeyscanShiftTable[code];
				else
					KeyboardBuffer = KeyscanTable[code];
			}
		}
		break;
	case MULTIBYTE:
		switch (code)
		{
		case 0x1D:
			MetaState |= RCTRL;
			break;
		case 0x2A:
			ScanState = PRINTSCR_PRESS_2;
			break;
		case 0x38:
			MetaState |= RALT;
			break;
		case 0x9D:
			MetaState &= ~RCTRL;
			break;
		case 0xB7:
			ScanState = PRINTSCR_RELEASE_2;
			break;
		case 0xB8:
			break;
		}
		if (ScanState == MULTIBYTE)
			ScanState = START;
		break;
	case PRINTSCR_PRESS_2:
		if (code == 0xE0)
			ScanState = PRINTSCR_PRESS_3;
		else
			ScanState = START;
		break;
	case PRINTSCR_PRESS_3:
		if (code == 0x37)
		{
			// Print Screen Pressed
			ScanState = START;
		}
		else
		{
			ScanState = START;
		}
		break;
	case PRINTSCR_RELEASE_2:
		if (code == 0xE0)
			ScanState = PRINTSCR_RELEASE_3;
		else
			ScanState = START;
		break;
	case PRINTSCR_RELEASE_3:
		if (code == 0xAA)
		{
			// Print Screen Released
			ScanState = START;
		}
		else
			ScanState = START;
		break;
	case PAUSE_1:
		if (code == 0x1D)
			ScanState = PAUSE_2;
		else
			ScanState = START;
		break;
	case PAUSE_2:
		if (code == 0x45)
			ScanState = PAUSE_3;
		else
			ScanState = START;
		break;
	case PAUSE_3:
		if (code == 0xE1)
			ScanState = PAUSE_4;
		else
			ScanState = START;
		break;
	case PAUSE_4:
		if (code == 0x9D)
			ScanState = PAUSE_5;
		else
			ScanState = START;
		break;
	case PAUSE_5:
		if (code == 0xC5)
		{
			// Pause Pressed
			ScanState = START;
		}
		else
		{
			ScanState = START;
		}
		break;
		;
	}

}

unsigned short KeyboardGetStroke()
{
	while (!KeyboardBuffer)
		asm("hlt");

	unsigned short rVal = KeyboardBuffer;
	KeyboardBuffer = 0;
	return rVal;
}
