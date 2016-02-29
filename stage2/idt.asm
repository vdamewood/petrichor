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

%define IdtCount 48
%define IdtSize  (IdtCount<<3)
%define IdtLimit (IdtSize-1)

IntrIsrCommon:
	call vidtxt_hprint_dword
	call vidtxt_breakline
	add esp, 8
	sti
	iret

%define IntrHexTable '0123456789ABCDEF'

; The following code creates ISRs for each interrupt.
%assign i 0
%rep IdtCount
	%substr IsrDigit1 IntrHexTable ((i / 16 + 1))
	%substr IsrDigit2 IntrHexTable ((i % 16 + 1))
	%strcat IsrHexString '0x' IsrDigit1 IsrDigit2
	%deftok IsrHexToken IsrHexString
IntrIsr%[IsrHexToken]:
		cli
		%if (0)
		%else
			push byte 0
		%endif
		push byte i
		jmp IntrIsrCommon
	%assign i i+1
%endrep

; This makes a table of ISRs so that it can be looped
; through to create the real IDT.
IntrSimpleTable:
%assign i 0
%rep IdtCount
	%substr IsrDigit1 IntrHexTable ((i / 16 + 1))
	%substr IsrDigit2 IntrHexTable ((i % 16 + 1))
	%strcat IsrHexString '0x' IsrDigit1 IsrDigit2
	%deftok IsrHexToken IsrHexString
	dd IntrIsr%[IsrHexToken]
	%assign i i+1
%endrep

%undef IsrHexToken
%undef IsrHexString
%undef IsrDigit2
%undef IsrDigit1
%undef IntrHexTable

; Space allocated for the IDT
IntrTable:
	times IdtSize db 0x00

IntrTableReference:
	.Limit: dw IdtLimit
	.Base:  dd IntrTable

IntrSetupInturrupts:
	fprolog 0, eax, ebx
	mov eax, 0
	mov ebx, IntrSimpleTable
	push 0x8E ; Flags
	push 0x08 ; Segment
.loop:
	push dword[ebx]
	push eax
	call IntrAddInterrupt
	add esp, 8
	add ebx, 4 ; next entry
	inc eax
	cmp eax, IdtCount
	jne .loop

	mov edx, IntrTableReference
	lidt [edx]
	freturn eax, edx

IntrAddInterrupt:
	fprolog 0, eax, ebx
%define SrcNumber  byte  [ebp+ 8]
%define SrcAddr    dword [ebp+12]
%define SrcSegment word  [ebp+16]
%define SrcFlags   byte  [ebp+20]
%define DstAddrLo  word  [ebx+0]
%define DstSegment word  [ebx+2]
%define DstZero    byte  [ebx+4]
%define DstFlags   byte  [ebx+5]
%define DstAddrHi  word  [ebx+6]
.EndDebug:
	xor eax, eax
	xor ebx, ebx

	; Establish Entry Address
	mov bl, SrcNumber
	shl ebx, 3
	add ebx, IntrTable

	; Set the Always-Zero Field to Zero
	mov DstZero, al

	; Mangle and save the ISR address
	mov eax, SrcAddr
	mov DstAddrLo, ax
	shr eax, 16
	mov DstAddrHi, ax

	; Simple copies
	mov ax, SrcSegment
	mov DstSegment, ax
	mov al, SrcFlags
	mov DstFlags, al
%undef SrcNumber
%undef SrcAddr
%undef SrcSegment
%undef SrcFlags
%undef DstAddrHi
%undef DstSegment
%undef DstZero
%undef DstFlags
%undef DstAddrLo
	freturn eax, ebx

IntrTest:
	fprolog 0
	int 0x03
	int 0x04
	freturn

%undef IdtCount
%undef IdtSize
%undef IdtLimit
