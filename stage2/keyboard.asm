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

%define ibuf_full 0x01 ; Output to the keyboard
%define obuf_full 0x02 ; Input from the keyboard
%define get_status 0x20
%define set_status 0x60

keyboard_enable:
	fprolog 0

.fbody:
.wait_buff1:
	in al, 0x64
	and al, obuf_full
	jnz .wait_buff1

.get_status:
	mov al, get_status
	out 0x64, al
	in al, 0x60

.cache_disabled:
	mov ah, 0xFE
	and ah, al

.wait_buff2:
	in al, 0x64
	and al, obuf_full
	jnz .wait_buff2

.set_status:
	mov al, set_status
	out 0x64, al
	mov al, ah
	out 0x60, al
	in al, 0x60 ; Get (and ignore) response to command

.wait_buff3:
	in al, 0x64
	and al, obuf_full
	jnz .wait_buff3

.check_status:
	mov al, get_status
	out 0x64, al
	in al, 0x60
	and al, 1
	jz .zero
	xor ax, ax
	jmp .done
.zero:
	mov ax, 0xFFFF
.done:
	freturn

;keyboard_meta_state: db 0
	; 0: Left Shift
	; 1: Righ Shift
	; 2: Left Ctrl
	; 3: Right Ctrl
	; 4: Left Alt
	; 5: Right Alt

keyboard_get_stroke:
	fprolog 0, ebx
.start:
	in al, 0x64
	and al, ibuf_full
	jz .start

.get_scancode:
	xor eax, eax
	in al, 0x60
	cmp al, 0x80
	jle .start

	; lea, maybe?
	shl eax, 1 ; keyscan_table is a table of words, not bytes
	mov ebx, keyscan_table
	add ebx, eax
	mov ax, word[ebx]
	freturn ebx

str_scancode: db "Scan:", 0
str_keycode:  db "KeyC:", 0

%include "keyscan.asm"

%undef obuf
%undef ibuf

