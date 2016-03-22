; memory.asm: Memory management
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

%include "functions.inc"

extern scrBreakLine
extern scrPrint
extern scrPrintHexWord
extern scrPrintHexDWord
extern scrPrintHexQWord
extern scrPrintLine
extern scrPrintSpace

SECTION .data

TableHeader: db 'Base     Size     Status', 0

StatusTable: dd 0,Status1,Status2,Status3,Status4,Status5

Status1: db '1:Free', 0
Status2: db '2:Reserved', 0
Status3: db '3:ACPI Reclaimable', 0
Status4: db '4:ACPI Non-volatile', 0
Status5: db '5:Bad', 0

SECTION .text

global memShowMap
memShowMap:
%define count 0x3300
%define first 0x3308
	fprolog 0, eax, ecx, ebx
	push TableHeader
	call scrPrintLine
	add esp, 4

	mov ecx, [count]
	mov ebx, first
.loop:
	push ecx

	push ebx
	push dword[ebx]
	call scrPrintHexDWord
	call scrPrintSpace
	pop ebx
	pop ebx


	push ebx
	push dword[ebx+8]
	call scrPrintHexDWord
	call scrPrintSpace
	pop ebx
	pop ebx


	mov eax, dword[ebx+16]
	shl eax, 2
	add eax, StatusTable
	mov eax, [eax]

	push eax
	call scrPrint
	pop eax

	push ebx
	call scrBreakLine
	pop ebx
	add ebx, 24
	pop ecx
	loop .loop

	freturn eax, ecx, ebx
%undef count
%undef first
