; init.asm: Protected-mode, secont-stage initialization
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

extern CommandLoop
extern IntrSetupInterrupts
extern ScreenClear
extern ScreenPrintLine
extern Compare

SECTION .data

Loaded: db 'Second stage loaded.', 0
BssSignature: db '.bss', 0
BssNotFound: db 'Warning: Unable to clear .bss.', 0

SECTION .text

global Init
Init:
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x90000
	mov ebp, esp
LoadBss:
	mov esi, [0x10020] ; Section Table Offset
	add esi, 0x10000 ; Convert offset to memory

	; Entry = SectionTable + EntrySize * StringIndex
	xor eax, eax
	xor edx, edx
	mov ax, word[0x1002E] ; Size of Entry in section table
	mov dx, word[0x10032] ; Index of .shstrtab section, in section table
	mul dx
	shl edx, 16
	or eax, edx
	add eax, esi ; We now have the offset within the table, add offset to base

	mov ebx, eax
	add ebx, 0x10      ; Byte 0x10 of a table entry the section's offset
	mov ebx, [ebx]
	add ebx, 0x10000   ; ebx now has the memory address of .shstrtab

	xor ecx, ecx
	xor edx, edx
	mov dx, word[0x1002E] ; Load Entry size... again
	mov cx, word[0x10030] ; Count

	push 4
	push BssSignature
.BssScanLoop:
	mov eax, [esi]
	add eax, ebx
	push eax

	call Compare
	pop eax
	jz .BssFound

	add esi, edx
	loop .BssScanLoop
.BssNotFound:
	push BssNotFound
	call ScreenPrintLine
	add esp, 12
	jmp .BssDone
.BssFound:
	add esp, 8

	mov eax, [esi]
	add eax, ebx

	xor eax, eax
	mov edi, [esi+0x0C] ; Address of .bss
	mov ecx, [esi+0x14] ; Size of .bss
	rep stosb
.BssDone:


	call IntrSetupInterrupts
.loop:
	call ScreenClear
	push Loaded
	call ScreenPrintLine
	add esp, 4
	call CommandLoop
	jmp .loop
