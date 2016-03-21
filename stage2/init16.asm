; real16.asm: Real-mode, second-stage initialization
;
; Copyright 2015, 2016 Vincent Damewood
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
;
; 1. Redistributions of source code must retain the above copyright
; notice, this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright
; notice, this list of conditions and the following disclaimer in the
; documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
; HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

extern GdtPointer
extern Init32

%define PMemTableCount  0x3300
%define MemTableCount   dword[PMemTableCount]
%define MemTableCountHi [PMemTableCount+4]
%define PMemTable       (PMemTableCount+8)

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
