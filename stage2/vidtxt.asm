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

%define vidtxt_segment 0xB800

vidtxt_color:      db 0x07
vidtxt_cursor:     dw 0x0000
; When placing, LSB is character in CP437, MSB is Forground/Backgorund color


vidtxt_shift:
.fpramb:
	push bp
	mov bp, sp
	push ds
	push es
	push ax
	push cx
	push si
	push di
.fbody:
	mov ax, vidtxt_segment
	mov ds, ax
	mov es, ax
	mov di, 0
	mov si, 160
	mov cx, 80 * 24
	rep movsw

	mov al, 0
	mov ah, [cs:vidtxt_color]
	mov cx, 80
.lastline:
	mov [di], ax
	add di, 2
	loop .lastline
.freturn:
	pop di
	pop si
	pop cx
	pop ax
	pop es
	pop ds
	mov sp, bp
	pop bp
	ret

vidtxt_set_bios_cursor:
.fpreamb:
	push bp
	mov bp, sp
	push ax
	push dx
	push bx
.fbody:
	mov ax, [cs:vidtxt_cursor]
	mov bx, 2*80
	xor dx, dx
	div bx ; ax = quot ; dx = mod
	shr dx, 1
	mov dh, al
	mov bh, 0
	mov ah, 2
	int 0x10
.freturn:
	pop bx
	pop dx
	pop ax
	mov sp, bp
	pop bp
	ret

vidtxt_breakline:
.fpreamb:
	push bp
	mov bp, sp
	push ax
	push dx
	push bx
.fbody:
	mov ax, [cs:vidtxt_cursor]
	cmp ax, 2*80*24
	jge .last_line
.not_last_line:
	mov bx, 2*80
	xor dx, dx
	div bx ; ax = quot ; dx = mod
	mov ax, [cs:vidtxt_cursor]
	sub ax, dx
	add ax, 2*80
	mov [cs:vidtxt_cursor], ax
	jmp .bios_cursor
.last_line:
	call vidtxt_shift
	mov ax, 2*80*24
	mov [cs:vidtxt_cursor], ax
.bios_cursor:
	call vidtxt_set_bios_cursor
.freturn:
	pop bx
	pop dx
	pop ax
	mov sp, bp
	pop bp
	ret

; Print a string
print:
vidtxt_print:
%define string [bp+4]
.fpreamb:
	push bp
	mov bp, sp
	push ds
	push es
	push si
	push di
	push ax
.fbody:
	mov ax, 0x1000
	mov ds, ax
	mov ax, vidtxt_segment
	mov es, ax
	mov si, string
	mov di, [cs:vidtxt_cursor]
	mov ah, [cs:vidtxt_color]
.loop:
	lodsb        ; Fetch next byte in string, ...
	or al, al    ; ... test if it's 0x00, ...
	jz .done     ; ... and, if so, were'd done
	stosw
	jmp .loop
.done:
	mov [cs:vidtxt_cursor], di
	call vidtxt_set_bios_cursor
.freturn:
	pop ax
	pop di
	pop si
	pop es
	pop ds
	mov sp, bp
	pop bp
	ret
%undef string

vidtxt_println:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
	push word[bp+4]
	call print
	add sp, 2
	call vidtxt_breakline
.freturn:
	mov sp, bp
	pop bp
	ret

vidtxt_putch:
.fpreamb:
	push bp
	mov bp, sp
	push ax
.fbody:
	mov ax, [bp+4]
	mov ah, 0x0E
	int 0x10
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret

vidtxt_delch:
vidtxt_backspace:
.fpreamb:
	push bp
	mov bp, sp
	push ax
.fbody:
	mov ax, 0x0E08
	int 0x10
	mov al, ' '
	int 0x10
	mov al, 0x08
	int 0x10
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret

vidtxt_putbyte:
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

vidtxt_putword:
%define word_at [bp+4]
.fpreamb:
	push bp
	mov bp, sp
	push ax
.fbody:
	mov ax, word_at
	shr ax, 8
	push ax
	call vidtxt_putbyte

	mov ax, word_at
	push ax
	call vidtxt_putbyte

	add sp, 4
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret
%undef word_at

%undef vidtxt_segment
