; keyboard.asm: Keyboard driver
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

extern keyscan_table
extern keyscan_shift_table

%define ibuf_full 0x01 ; Output to the keyboard
%define obuf_full 0x02 ; Input from the keyboard
%define get_status 0x20
%define set_status 0x60

section .data

keyboard_meta_state: db 0
	; 0: Left Shift
	; 1: Righ Shift
	; 2: Left Ctrl
	; 3: Right Ctrl
	; 4: Left Alt
	; 5: Right Alt

;%include "keyscan.asm"

section .text

global keyboard_irq
keyboard_irq:
	fprolog 0, eax, ebx
.start:
	xor eax, eax
	in al, 0x60
	cmp ax, 0x80 ; If the code scanned is a 'release' code
	jge .done    ; ignore it

	lea ebx, [eax*2+keyscan_table]
	mov ax, word[ebx]
	mov word[keyboard_buffer], ax
	push eax
.done:
	freturn eax, ebx

keyboard_buffer: dw 0

global keyboard_get_stroke
keyboard_get_stroke:
	fprolog 0, ebx
.try_again:
	hlt
	xor eax, eax
	mov ax, word[keyboard_buffer]
	or ax, ax
	jz .try_again

	xor ebx, ebx
	mov word[keyboard_buffer], bx
	freturn ebx
