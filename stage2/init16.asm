; init16.asm: 16-bit, real-mode initialization
;
; Copyright 2015, 2016 Vincent Damewood
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

extern Init32

%define PMemTableCount  0x3300
%define MemTableCount   dword[PMemTableCount]
%define MemTableCountHi [PMemTableCount+4]
%define PMemTable       (PMemTableCount+8)

section .data

GdtPointer:
limit: dw 23
base:  dd GdtTable

GdtTable:
null:
	times 8 db 0

sys_code:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0x9A   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

sys_data:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0x92   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

usr_code:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0xFA   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

usr_data:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0xF2   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

section .text
[BITS 16]
global Init16
Init16:
	xor eax, eax
	mov dx, ax
	mov es, ax

LoadMemoryTable:
	; The following blanks a qword for alignment purposes.
	mov MemTableCount, eax
	mov MemTableCountHi, eax

	mov di, PMemTable
	xor ebx, ebx
	mov edx, 0x534D4150
.loop:
	mov eax, 0xE820
	mov ecx, 24
	int 0x15
	jc .invalid
	inc MemTableCount

	or ebx, ebx
	jz .done
	add di, 24
	jmp .loop
.invalid:
	xor eax, eax
	dec eax
	mov ecx, 24
	rep stosb
.done:


EnableA20:
	mov ax, 0x2401
	int 0x15


LoadGdt:
	; GdtPointer will be a 32-bit address, so here
	; we convert it.
	mov ebx, GdtPointer

	; Segment to ds
	mov eax, ebx
	shr eax, 4
	mov ds, ax

	; Offset to eax. This is probably always going
	; to be 0, but just in case we calculate here.
	mov eax, ebx
	and eax, 0x0F

	cli
	lgdt [eax]


EnterProtectedMode:
	mov eax, cr0
	or al, 1
	mov cr0, eax
	jmp dword 0x08:Init32
