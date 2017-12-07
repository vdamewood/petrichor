/* screen.h: Screen driver (text only)
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

#ifndef SCREEN_H
#define SCREEN_H

#include <stdint.h>

// Basics
void scrBreakLine(void);
void scrClear(void);
void scrDelete(void);
void scrPutGlyph(uint8_t);

// Colors
#define scrBlack  0x00
#define scrBlue   0x01
#define scrGreen  0x02
#define scrCyan   0x03
#define scrRed    0x04
#define scrPurple 0x05
#define scrYellow 0x06
#define scrWhite  0x07
#define scrBright 0x08

uint8_t scrGetColor(void);
void scrSetColor(uint8_t);
void scrSetForgroundColor(uint8_t);
void scrSetBackgroundColor(uint8_t);

// Cursor
uint16_t scrGetCursorPosition(void);
void scrSetCursorPostion(uint16_t);
void scrShowCursor(void);
void scrHideCursor(void);

#endif /* SCREEN_H */
