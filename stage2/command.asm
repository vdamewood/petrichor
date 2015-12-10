; command.asm: Command Interpreter
;
; Copyright 2015, Vincent Damewood
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

cmdbuf_size  equ  32
cmdbuf       times cmdbuf_size db 0

get:
.fpreamb:
	push bp
	mov bp, sp
	push di
.fbody:
	mov cx, cmdbuf
	mov di, cx

.loop:
	call keyboard_get_stroke

.chk_special:
	cmp ah, 0x00
	jne .special

.printable:
	mov dx, di
	sub dx, cx
	cmp dx, (cmdbuf_size-1) ; if buffer is full
	je .loop ; ignore keypress

	push ax
	call vidtxt_putch
	pop ax
	call vidtxt_show_cursor
	stosb
	jmp .loop

.special:
	cmp ah, 0x01 ; Ignore ctrl-, alt- and errors.
	jne .loop

.chk_esc:
	cmp al, 0x00 ; Escape
	jne .chk_bksp
.do_esc:
	cmp di, cx
	je .loop

	call vidtxt_delch
	call vidtxt_show_cursor
	dec di
	jmp .do_esc

	;jmp .loop

.chk_bksp:
	cmp al, 0x10 ; Backspace
	jne .chk_enter
.do_bksp:
	cmp di, cx ; if at the beginning of the buffer
	je .loop   ; ignore

	call vidtxt_delch
	call vidtxt_show_cursor
	dec di
	jmp .loop

.chk_enter:
	cmp al, 0x12 ; Enter
	jne .else
.do_enter:
	mov al, 0
	stosb
	call vidtxt_breakline
	jmp .return

.else:
	jmp .loop ; Ignore all other keystrokes

.return:
	mov ax, cmdbuf
	pop di
	mov sp, bp
	pop bp
	ret
