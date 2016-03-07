; stage2.asm: Second-stage startup program
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

extern vidtxt_clear
extern vidtxt_show_cursor
extern vidtxt_breakline
extern vidtxt_print
extern vidtxt_println
extern vidtxt_putch
extern vidtxt_space
extern vidtxt_backspace
extern vidtxt_hprint_word
extern vidtxt_hprint_dword
extern vidtxt_hprint_qword
extern IntrSetupInterrupts
extern IntrTest
extern IntrSetupInterrupts
extern CommandLoop

SECTION .data

Hello:    db 'Hello.', 0
Vendor:
VendorW1:    dw 0
VendorW2:    dw 0
VendorW3:    dw 0
term_vendor: db 0

str_memory_table: db 'Base             Size             Status   Ext     ', 0

SECTION .text

%include "functions.inc"

global MiscBreakpoint
MiscBreakpoint:
	fprolog 0
	xchg bx, bx
	freturn

global MiscClearScreen
MiscClearScreen:
	fprolog 0
	call vidtxt_clear
	freturn

global MiscSayHi
MiscSayHi:
	fprolog 0
	push Hello
	call vidtxt_println
	add esp, 4
	freturn

global MiscShowVendor
MiscShowVendor:
	fprolog 0, eax
	call LoadVendor
	push eax
	call vidtxt_println
	add esp, 4
	freturn eax

LoadVendor:
	fprolog 0, ecx, edx, ebx
.fbody:
	mov eax, dword[Vendor]
	or eax, eax
	jnz .done

	xor eax, eax
	cpuid
	mov [VendorW1], ebx
	mov [VendorW2], edx
	mov [VendorW3], ecx
.done:
	mov eax, Vendor
	freturn ecx, edx, ebx

global MiscShowMemory
MiscShowMemory:
%define count 0x3300
%define first 0x3308
	fprolog 0, eax, ecx, ebx

	mov ecx, [count]
	push ecx
	call vidtxt_hprint_word
	add esp, 4

	call vidtxt_breakline

	push str_memory_table
	call vidtxt_println
	add esp, 4

	mov ebx, first
.loop:
	push dword[ebx+4]
	push dword[ebx]
	call vidtxt_hprint_qword
	add esp, 8

	push dword ' '
	call vidtxt_putch
	add esp, 4

	push dword[ebx+12]
	push dword[ebx+8]
	call vidtxt_hprint_qword
	add esp, 8

	push dword ' '
	call vidtxt_putch
	add esp, 4

	push dword[ebx+16]
	call vidtxt_hprint_dword
	add esp, 4

	push dword ' '
	call vidtxt_putch
	add esp, 4

	push dword[ebx+20]
	call vidtxt_hprint_dword
	add esp, 4

	call vidtxt_breakline
	add ebx, 24
	loop .loop

	freturn eax, ecx, ebx
%undef count
%undef first
