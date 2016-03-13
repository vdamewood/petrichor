; misc.asm: Unsorted routines
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

extern ScreenBreakLine
extern ScreenPrintHexWord
extern ScreenPrintHexDWord
extern ScreenPrintHexQWord
extern ScreenPrintLine
extern ScreenPrintSpace

%include "functions.inc"

SECTION .data

Hello:    db 'Hello.', 0
Vendor:
VendorW1:    dd 0
VendorW2:    dd 0
VendorW3:    dd 0
term_vendor: db 0

SECTION .text

global MiscSayHi
MiscSayHi:
	fprolog 0
	push Hello
	call ScreenPrintLine
	add esp, 4
	freturn

global MiscShowVendor
MiscShowVendor:
	fprolog 0, eax
	call LoadVendor
	push eax
	call ScreenPrintLine
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
