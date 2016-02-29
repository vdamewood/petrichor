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

%define IdtCount 32
%define IdtSize  (IdtCount<<3)
%define IdtLimit (IdtSize-1)

%macro INTR_NOCODE 1
  IntrIsr%1:
    cli
    push byte 0
    push byte %1
    jmp IntrIsrCommonStub
%endmacro

%macro INTR_ERCODE 1
  IntrIsr%1:
    cli
    push byte %1
    jmp IntrIsrCommonStub
%endmacro

INTR_NOCODE 0
INTR_NOCODE 1
INTR_NOCODE 2
INTR_NOCODE 3
INTR_NOCODE 4
INTR_NOCODE 5
INTR_NOCODE 6
INTR_NOCODE 7
INTR_NOCODE 8
INTR_NOCODE 9
INTR_NOCODE 10
INTR_NOCODE 11
INTR_NOCODE 12
INTR_NOCODE 13
INTR_NOCODE 14
INTR_NOCODE 15
INTR_NOCODE 16
INTR_NOCODE 17
INTR_NOCODE 18
INTR_NOCODE 19
INTR_NOCODE 20
INTR_NOCODE 21
INTR_NOCODE 22
INTR_NOCODE 23
INTR_NOCODE 24
INTR_NOCODE 25
INTR_NOCODE 26
INTR_NOCODE 27
INTR_NOCODE 28
INTR_NOCODE 29
INTR_NOCODE 30
INTR_NOCODE 31

IntrIsrCommonStub:
	call vidtxt_hprint_dword
	call vidtxt_breakline
	add esp, 8
	sti
	iret

IntrTable:
	times IdtSize db 0x00

IntrTableReference:
	;.Limit: dw ((32<<3)-1)
	.Limit: dw IdtLimit
	.Base:  dd IntrTable

IntrSimpleTable:
	dd IntrIsr0
	dd IntrIsr1
	dd IntrIsr2
	dd IntrIsr3
	dd IntrIsr4
	dd IntrIsr5
	dd IntrIsr6
	dd IntrIsr7
	dd IntrIsr8
	dd IntrIsr9
	dd IntrIsr10
	dd IntrIsr11
	dd IntrIsr12
	dd IntrIsr13
	dd IntrIsr14
	dd IntrIsr15
	dd IntrIsr16
	dd IntrIsr17
	dd IntrIsr18
	dd IntrIsr19
	dd IntrIsr20
	dd IntrIsr21
	dd IntrIsr22
	dd IntrIsr23
	dd IntrIsr24
	dd IntrIsr25
	dd IntrIsr26
	dd IntrIsr27
	dd IntrIsr28
	dd IntrIsr29
	dd IntrIsr30
	dd IntrIsr31

SetupInturrupts:
	fprolog 0, eax, ebx
	mov eax, 0
	mov ebx, IntrSimpleTable
	push 0x8E ; Flags
	push 0x08 ; Segment

.loop:
	push dword[ebx]
	push eax
	call AddInterrupt
	add esp, 8
	add ebx, 4 ; next entry
	inc eax
	cmp eax, 32
	jne .loop

	mov edx, IntrTableReference
	lidt [edx]
	freturn eax, edx

AddInterrupt:
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
