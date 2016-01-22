; idt.asm: Inturupt Descriptor Table
;
; Copyright 2016 Vincent Damewood
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

IdtReference:
.Limit:		dw 0x07FF
.Base:		dd IDT

DefaultInturrupt:
	push eax
	push str_int
	call vidtxt_println
	add esp, 4
	pop eax
	iret

str_int db "Int!", 0

SetupInturrupts:
	fprolog 0, ecx
	mov ecx, 256
	push DefaultInturrupt
.loop:
	call AddInterrupt
	loop .loop
	add esp, 4
	mov ecx, IdtReference
	lidt [ecx]
	freturn ecx

AddInterrupt:
	fprolog 0, eax, ebx
%define Isr     dword[ebp+8]
%define AddrHi  word[ebx]
%define Segment word[ebx+2]
%define Zero    byte[ebx+4]
%define Flags   byte[ebx+5]
%define AddrLo  word[ebx+6]
	mov ebx, [IdtWhere]
	cmp ebx, IdtEnd
	je .end

	mov eax, Isr
	mov AddrLo, ax
	shr eax, 16
	mov AddrHi, ax

	mov ax, 0x0008
	mov Segment, ax
	mov al, 0x8E
	mov Flags, al
	xor eax, eax
	mov Zero, al
	add ebx, 8
	mov [IdtWhere], ebx
%undef address
%undef AddrHi
%undef Segment
%undef Zero
%undef Flags
%undef AddrLo
.end:
	freturn eax, ebx

; w AddrHi
; w Seg
; b 0
; b 0x8E
; w AddrLo

IdtWhere: dd IDT
IDT:
	times 0x800 db 0x00
IdtEnd:
