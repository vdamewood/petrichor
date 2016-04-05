; intr.asm: Interrupt handler
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

extern KeyboardHandleInterrupt
extern scrBreakLine
extern scrPrintHexDWord
extern scrPrintSpace
extern scrPrintChar
extern fdHandleInterrupt
extern tmrHandleInterrupt

%include "functions.inc"

%define IdtCount 48
%define IdtSize  (IdtCount<<3)
%define IdtLimit (IdtSize-1)
%define HexTable '0123456789ABCDEF'

section .data

IntrTableReference:
	.Limit: dw IdtLimit
	.Base:  dd IntrTable

; This makes a table of references to the ISRs so
; that it can be looped through to create the real IDT.
IntrSimpleTable:
%assign i 0
%rep IdtCount
	%substr IsrDigit1 HexTable ((i / 16 + 1))
	%substr IsrDigit2 HexTable ((i % 16 + 1))
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

section .bss
IntrTable: resb IdtSize

section .text

IntrIsrCommon:
%define Interrupt dword[ebp+4]
%define Code     dword[ebp+8]
	push ebp
	mov ebp, esp
	pusha

	mov eax, Interrupt
	;cmp eax, 0x20
	;je .cleanup

.try_timer:
	cmp eax, 0x20
	jne .not_timer
.yes_timer:
	call tmrHandleInterrupt
	jmp .cleanup
.not_timer:

.try_keyboard:
	cmp eax, 0x21
	jne .not_keyboard
.yes_keyboard:
	call KeyboardHandleInterrupt
	jmp .cleanup
.not_keyboard:

.try_floppy:
	cmp eax, 0x26
	jne .not_floppy
.yes_floppy:
	call fdHandleInterrupt
	jmp .cleanup
.not_floppy:

.default:
	push Interrupt
	call scrPrintHexDWord
	push 0x20
	push scrPrintChar
	;call scrPrintSpace
	push Code
	call scrPrintHexDWord
	call scrBreakLine
	add esp, 12

.cleanup:
	mov ecx, Interrupt
	cmp ecx, 0x20
	jl .done
	cmp ecx, 0x2F
	jg .done
	mov al, 0x20
	out 0x20, al
	cmp ecx, 0x28
	jl .done
	out 0xA0, al
.done:
	popa
	mov esp, ebp
	pop ebp
	add esp, 8
	sti
	iret
%undef Interrupt
%undef Code


; The following code creates ISRs for each interrupt.
%assign i 0
%rep IdtCount
	%substr IsrDigit1 HexTable ((i / 16 + 1))
	%substr IsrDigit2 HexTable ((i % 16 + 1))
	%strcat IsrHexString '0x' IsrDigit1 IsrDigit2
	%deftok IsrHexToken IsrHexString
IntrIsr%[IsrHexToken]:
		cli
		%if (0)
		%else
			push 0
		%endif
		push i
		jmp IntrIsrCommon
	%assign i i+1
%endrep


global IntrSetupInterrupts
IntrSetupInterrupts:
	fprolog 0, eax, edx, ebx
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

	;read 0x21
	;read 0xA1
	in al, 0x21
	shl ax, 8
	in al, 0xA1
	mov bx, ax

	;0x20 <-- 0x11
	;0xA0 <-- 0x11
	mov al, 0x11
	out 0x20, al
	out 0xA0, al

	;0x21 <-- 0x20
	;0xA1 <-- 0x28
	mov al, 0x20
	out 0x21, al
	mov al, 0x28
	out 0xA1, al

	;0x21 <-- 0x04
	;0xA1 <-- 0x02
	mov al, 0x04
	out 0x21, al
	mov al, 0x02
	out 0xA1, al

	;0x21 <-- 0x01
	;0xA1 <-- 0x01
	mov al, 0x01
	out 0x21, al
	out 0xA1, al

	;replace 0xA1
	;replace 0x21
	mov ax, bx
	out 0xA1, al
	shr ax, 8
	out 0x21, al

	mov al,20h
	out 20h,al

	intrfreturn eax, edx, ebx

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

%undef IdtCount
%undef IdtSize
%undef IdtLimit
