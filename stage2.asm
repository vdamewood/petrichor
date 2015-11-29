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

[BITS 16]

; 00000 to 0FFFF:
;   0x0000 to 0x04FF: Reserved for System
;   0x0500 to 0x16FF: File-Allocation Table
;   0x1700 to 0x32FF: Root Directory
;   0x3300 to 0x7BF7: [Empty]
;   0x7BF8 to 0x7BF9: Pointer to Root Directory
;   0x7BFA to 0x7BFB: Pointer to Fat
;   0x7BFC to 0x7BFD: Sector offset for FAT clusters
;   0x7BFE to 0x7BFF: Sector where FAT starts
;   0x7C00 to 0x7DFF: Boot sector
;   0x7E00 to 0xFFFF: [Empty]
; 10000 to 1FFFF: Stage 2 (This file)
; 20000 to 2FFFF: Free
; 30000 to 3FFFF: Free
; 40000 to 4FFFF: Free
; 50000 to 5FFFF: Free
; 60000 to 6FFFF: Free
; 70000 to 7FFFF: Free
; 80000 to 8FFFF: Free
; 90000 to 9FFFF: Free, but Last few 128 KiB (possibly less) unusable
; After  A0000 is unusable.

stage2:
	; Initial Setup. This was probably done differently in the boot sector.
	mov ax, 0x1000
	mov ds, ax
	mov es, ax

	mov ax, 0x2000
	mov ss, ax
	xor sp, sp
	mov bp, sp

	; Display start-up message
	push msg_start
	call print
	add esp, 2

.cmdloop:
	push msg_prompt
	call print
	add sp, 2

	call get
	push str_hi
	push ax
	call match
	add sp, 4
	cmp ax, 0x0000
	je .nomatch
	push msg_hello
	jmp .endmatch
.nomatch:
	push msg_sayhi
.endmatch:
	call print
	add sp, 2
	jmp .cmdloop

; === FUNCTIONS ===

; Match a filename
match_file:
.fpreamb:
	push bp
	mov bp, sp
	push si
	push di
	push cx
	push dx
	push bx
.fbody:
	mov si, [bp+4]
	mov di, [bp+6]
	mov cx, 11
.loop:
	mov al, [di]
	mov dl, [si]
	cmp al, dl
	jne .nomatch
	dec cx
	jcxz .match
	inc di
	inc si
	jmp .loop
.match:
	mov ax, 0xFFFF
	jmp .freturn
.nomatch:
	mov ax, 0x0000
.freturn:
	pop cx
	pop dx
	pop bx
	pop di
	pop si
	mov sp, bp
	pop bp
	ret


; Compare Zero-Terminated Strings
match:
.fpreamb:
	push bp
	mov bp, sp
	push si
	push di
	push dx
.fbody:
	mov si, [bp+4]
	mov di, [bp+6]
.loop:
	mov al, [di]
	mov dl, [si]

	cmp al, dl
	jne .nomatch

	cmp al, 0
	jz .match
	inc di
	inc si
	jmp .loop
.match:
	mov ax, 0xFFFF
	jmp .freturn
.nomatch:
	mov ax, 0x0000
.freturn:
	pop dx
	pop di
	pop si
	mov sp, bp
	pop bp
	ret

; Print a string
print:
.fpreamb:
	push bp
	mov bp, sp
	push si
.fbody:
	mov si, [bp+4]
	mov ah, 0x0E ; Causes the BIOS interrupt to print a character
.loop:
	lodsb        ; Fetch next byte in string, ...
	or al, al    ; ... test if it's 0x00, ...
	jz .freturn  ; ... and, if so, were'd done
	int 0x10     ; Due to ah = 0x0E, prints character
	jmp .loop
.freturn:
	pop si
	mov sp, bp
	pop bp
	ret

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

; === Debuging Functions ===
print_byte:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
	mov ah, 0x0E

	mov al, [bp+4]
	shr al, 4
	add al, 0x30
	cmp al, 0x39
	jle .skip1
	add al, 7
.skip1:
	int 0x10

	mov al, [bp+4]
	and al, 0x0F
	add al, 0x30
	cmp al, 0x39
	jle .skip2
	add al, 7
.skip2:
	int 0x10
.freturn:
	mov sp, bp
	pop bp
	ret

; === Non-executable Data ===
msg_start:   db 'Second stage loaded. '
msg_sayhi:   db 'Say Hi.'
newline:     db 0x0D, 0x0A, 0
msg_prompt:  db '?> ', 0
str_hi:      db 'Hi', 0
msg_hello:   db 'Hello.', 0x0D, 0x0A, 0
; FIXME: This will probably go into a different segment.
cmdbuf_size equ  32
cmdbuf      times cmdbuf_size db 0
