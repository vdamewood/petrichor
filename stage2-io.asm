; stage2.asm: Second-stage startup program
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

; Print a string
print:
%define string [bp+4]
.fpreamb:
	push bp
	mov bp, sp
	push ds
	push si
	push ax
.fbody:
	mov ax, 0x1000
	mov ds, ax
	mov si, string
	mov ah, 0x0E ; Causes the BIOS interrupt to print a character
.loop:
	lodsb        ; Fetch next byte in string, ...
	or al, al    ; ... test if it's 0x00, ...
	jz .freturn  ; ... and, if so, were'd done
	int 0x10     ; Due to ah = 0x0E, prints character
	jmp .loop
.freturn:
	pop ax
	pop si
	pop ds
	mov sp, bp
	pop bp
	ret
%undef string

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
	mov ah, 0
	int 0x16
.ifbksp:
	cmp al, 0x08 ; Backspace
	jne .ifentr
.bksp:
	cmp di, cx ; if at the beginning of the buffer
	je .loop   ; ignore

	mov ah, 0x0E
	int 0x10
	mov al, ' '
	int 0x10
	mov al, 0x08
	int 0x10
	dec di
	jmp .loop
.ifentr:
	cmp al, 0x0D ; Enter
	jne .else
.entr:
	mov al, 0
	stosb
	push newline
	call print
	add sp, 2
	jmp .return
.else:
	mov dx, di
	sub dx, cx
	cmp dx, (cmdbuf_size-1) ; if buffer is full
	je .loop ; ignore keypress

	mov ah, 0x0E
	int 0x10
	stosb
	jmp .loop
.return:
	mov ax, cmdbuf
	pop di
	mov sp, bp
	pop bp
	ret

putbyte:
%define byte_at [bp+4]
.fpreamb:
	push bp
	mov bp, sp
	push ax
.fbody:
	mov ah, 0x0E
	mov al, byte_at
	shr al, 4
	add al, 0x30
	cmp al, 0x39
	jle .skip1
	add al, 7
.skip1:
	int 0x10

	mov al, byte_at
	and al, 0x0F
	add al, 0x30
	cmp al, 0x39
	jle .skip2
	add al, 7
.skip2:
	int 0x10
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret
%undef byte_at

putword:
%define word_at [bp+4]
.fpreamb:
	push bp
	mov bp, sp
	push ax
.fbody:
	mov ax, word_at
	shr ax, 8
	push ax
	call putbyte

	mov ax, word_at
	push ax
	call putbyte

	add sp, 4
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret
%undef word_at
