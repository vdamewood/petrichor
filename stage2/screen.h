/* screen.h: Screen driver (text only)
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

#ifndef SCREEN_H
#define SCREEN_H

#include <stdint.h>

#define scrBlack  0x00
#define scrBlue   0x01
#define scrGreen  0x02
#define scrCyan   0x03
#define scrRed    0x04
#define scrPurple 0x05
#define scrYellow 0x06
#define scrWhite  0x07
#define scrBright 0x08

void scrSetForgroundColor(uint8_t);
void scrSetBackgroundColor(uint8_t);
void scrSetColor(uint8_t);

void scrClear(void);
void scrSetCursor(uint16_t);
void scrShowCursor(void);
void scrBreakLine(void);
void scrDelete(void);

void scrPrint(const char *);
void scrPrintLine(const char *);
void scrPrintChar(char);
void scrPrintHexByte(uint8_t);
void scrPrintHexWord(uint16_t);
void scrPrintHexDWord(uint32_t);
void scrPrintHexPointer(const void *);

#endif /* SCREEN_H */
