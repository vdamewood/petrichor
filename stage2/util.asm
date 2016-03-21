; util.asm: Utility routines
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

%include "functions.inc"

section .text

section .text

global blStrCmp
blStrCmp:
	fprolog 0, esi, edi
%define mem1 dword[ebp+8]
%define mem2 dword[ebp+12]

	xor eax, eax
	mov esi, mem1
	mov edi, mem2
.loop:
	lodsb
	scasb
	jne .nomatch
	or al, al
	jnz .loop
.match:
	xor eax, eax
	jmp .done
.nomatch:
	lahf
	movsx eax, ah
	sar eax, 6
	xor eax, 1
.done:
	freturn esi, edi

global blStrLen
blStrLen:
	fprolog 0
	xor ecx, ecx
	mov esi, dword[ebp+8]
.loop:
	lodsb
	or al, al
	jz .done
	inc ecx
	jmp .loop
.done:
	mov eax, ecx
	freturn

global blMemCmp
blMemCmp:
	fprolog 0, ecx, esi, edi
%define mem1 dword[ebp+8]
%define mem2 dword[ebp+12]
%define count dword[ebp+16]

	xor eax, eax
	mov esi, mem1
	mov edi, mem2
	mov ecx, count
	repe cmpsb

	lahf
	movsx eax, ah
	sar eax, 6
	xor eax, 1

	freturn ecx, esi, edi
