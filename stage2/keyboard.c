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

volatile static unsigned short KeyscanTable[0x60];
volatile static unsigned short KeyscanShiftTable[0x60];

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

#define dw

static volatile uint16_t KeyscanTable[] =
{
// 0x00
	0xFFFF, // Not assigned
	0x0100, // Escape
	dw '1',
	dw '2',
	dw '3',
	dw '4',
	dw '5',
	dw '6',
	dw '7',
	dw '8',
	dw '9',
	dw '0',
	dw '-',
	dw '=',
	dw 0x0110, // backspace
	dw 0x0111, // tab
// 0x10
	dw 'q',
	dw 'w',
	dw 'e',
	dw 'r',
	dw 't',
	dw 'y',
	dw 'u',
	dw 'i',
	dw 'o',
	dw 'p',
	dw '[',
	dw ']',
	dw 0x0112, // Enter
	dw 0xFFFE, // Left Ctrl
	dw 'a',
	dw 's',
// 0x20
	dw 'd',
	dw 'f',
	dw 'g',
	dw 'h',
	dw 'j',
	dw 'k',
	dw 'l',
	dw ';',
	dw 0x0027, // Single Quote
	dw '`',
	dw 0xFFFE, // Left Shift
	dw '\\',
	dw 'z',
	dw 'x',
	dw 'c',
	dw 'v',
// 0x30
	dw 'b',
	dw 'n',
	dw 'm',
	dw ',',
	dw '.',
	dw '/',
	dw 0xFFFE, // Right Shift
	dw '*',    // Numeric Keypad
	dw 0xFFFE, // Left Alt
	dw ' ',
	dw 0xFFFE, //　Caps Lock
	dw 0xFFFF, // F1
	dw 0xFFFF, // F2
	dw 0xFFFF, // F3
	dw 0xFFFF, // F4
	dw 0xFFFF, // F5
// 0x40
	dw 0xFFFF, // F6
	dw 0xFFFF, // F7
	dw 0xFFFF, // F8
	dw 0xFFFF, // F9
	dw 0xFFFF, // F10
	dw 0xFFFE, // Num lock
	dw 0xFFFE, // Scroll lock
	dw '7', // Numeric Keypad
	dw '8', // Numeric Keypad
	dw '9', // Numeric Keypad
	dw '-', // Numeric Keypad
	dw '4', // Numeric Keypad
	dw '5', // Numeric Keypad
	dw '6', // Numeric Keypad
	dw '+', // Numeric Keypad
	dw '1', // Numeric Keypad
// 0x50
	dw '2', // Numeric Keypad
	dw '3', // Numeric Keypad
	dw '0', // Numeric Keypad
	dw '.', // Numeric Keypad
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF, // F11
	dw 0xFFFF, // F12
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF
};

static volatile uint16_t KeyscanShiftTable[] =
{
	dw 0xFFFF, //  Not assigned
	dw 0xFFFF, // Escape
	dw '!',
	dw '@',
	dw '#',
	dw '$',
	dw '%',
	dw '^',
	dw '&',
	dw '*',
	dw '(',
	dw ')',
	dw '_',
	dw '+',
	dw 0xFFFF, // ; backspace
	dw 0xFFFF, // ; tab
// 0x10
	dw 'Q',
	dw 'W',
	dw 'E',
	dw 'R',
	dw 'T',
	dw 'Y',
	dw 'U',
	dw 'I',
	dw 'O',
	dw 'P',
	dw '{',
	dw '}',
	dw 0xFFFF, // Enter
	dw 0xFFFE, // Left Ctrl
	dw 'A',
	dw 'S',
// 0x20
	dw 'D',
	dw 'F',
	dw 'G',
	dw 'H',
	dw 'J',
	dw 'K',
	dw 'L',
	dw ':',
	dw '"',
	dw '~',
	dw 0xFFFE, // Left Shift
	dw '|',
	dw 'Z',
	dw 'X',
	dw 'C',
	dw 'V',
// 0x30
	dw 'B',
	dw 'N',
	dw 'M',
	dw '<',
	dw '>',
	dw '?',
	dw 0xFFFE, // Right Shift
	dw '*',  // Numeric Keypad
	dw 0xFFFE, // Left Alt
	dw ' ',
	dw 0xFFFF, // Caps Lock
	dw 0xFFFF , // F1
	dw 0xFFFF , // F2
	dw 0xFFFF , // F3
	dw 0xFFFF , // F4
	dw 0xFFFF , // F5
// 0x40
	dw 0xFFFF , // F6
	dw 0xFFFF , // F7
	dw 0xFFFF , // F8
	dw 0xFFFF , // F9
	dw 0xFFFF , // F10
	dw 0xFFFF , // Num lock
	dw 0xFFFF , // Scroll lock
	dw 0xFFFF , // Numeric Keypad 7
	dw 0xFFFF , // Numeric Keypad 8
	dw 0xFFFF , // Numeric Keypad 9
	dw '-'  , // Numeric Keypad
	dw 0xFFFF , // Numeric Keypad 4
	dw 0xFFFF , // Numeric Keypad 5
	dw 0xFFFF , // Numeric Keypad 6
	dw '+'  , // Numeric Keypad
	dw 0xFFFF , // Numeric Keypad 1
// 0x50
	dw 0xFFFF , // Numeric Keypad 2
	dw 0xFFFF , // Numeric Keypad 3
	dw 0xFFFF , // Numeric Keypad 0
	dw '.'  , // Numeric Keypad
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF, // F11
	dw 0xFFFF, // F12
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF,
	dw 0xFFFF
};
