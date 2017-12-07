/* x86asm.h: Inline assembly language conveniences
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

#ifndef X86ASM_H
#define X86ASM_H

#include <stdint.h>

#define bochsBreak asm("xchg %bx, %bx");

static inline void outb(uint16_t port, uint8_t value)
{
	asm ("outb %0, %1" :: "a"(value), "Nd"(port));
}

static inline unsigned char inb(uint16_t port)
{
	register uint8_t value;
	asm volatile ("inb %1, %0" :"=a"(value): "Nd"(port));
	return value;
}

static inline void rep_movsb(void *src, void *dest, uint32_t size)
{
	asm("rep movsb" :: "S"(src), "D"(dest), "c"(size));
}

#endif /* X86ASM_H */
