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

code_seg equ 0x1000

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

	call a20_on
	call a20_status
	or ax, ax
	jnz .a20on
.a20off:
	push msg_a20off
	jmp .a20end
.a20on:
	push msg_a20on
.a20end:
	call print
	add sp, 2

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

ftemplate:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
.freturn:
	mov sp, bp
	pop bp
	ret

; Enable A20 Line
; FIXME: The method used isn't supported on all systems. Add other methods
;   for other kinds of systems.
a20_on:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
	call a20_status
	or ax, ax
	jnz .freturn
	mov ax, 0x2401
	int 0x15
.freturn:
	mov sp, bp
	pop bp
	ret

; Disable A20 Line
; FIXME: The method used isn't supported on all systems. Add other methods
;   for other kinds of systems.
a20_off:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
	call a20_status
	or ax, ax
	jz .freturn
	mov ax, 0x2400
	int 0x15
.freturn:
	mov sp, bp
	pop bp
	ret

; Check for A20 Status
a20_status:
%define original   [ds:0x7DFE]
%define wraparound [es:0x7E0E]
.fpreamb:
	push bp
	mov bp, sp
	push dx
	push bx
	push ds
	push es
.fbody:
	xor ax, ax
	mov ds, ax
	mov ax, 0xFFFF
	mov es, ax

	; First Test
	mov dx, original
	mov bx, wraparound
	cmp dx, bx
	jne .enabled

	; Change value probed
	mov ax, dx
	xor ax, 0xFFFF
	mov original, ax

	; Test if change reflects
	mov dx, original
	mov bx, wraparound

	; Put the original Value back
	xor ax, 0xFFFF
	mov ax, original

	; Continue Testing
	cmp dx, bx
	jne .enabled

.notenabled:
	xor ax, ax
	jmp .freturn
.enabled:
	mov ax, 0xFFFF
.freturn:
	pop es
	pop ds
	pop bx
	pop dx
	mov sp, bp
	pop bp
	ret
%undef original
%undef wraparound

; Match a filename
match_file:
%define source      [bp+4]
%define destination [bp+6]
.fpreamb:
	push bp
	mov bp, sp
	push cx
	push si
	push di
.fbody:
	mov si, source
	mov di, destination
	mov cx, 11
	repe cmpsb
	jne .nomatch
.match:
	mov ax, 0xFFFF
	jmp .freturn
.nomatch:
	mov ax, 0x0000
.freturn:
	pop di
	pop si
	pop cx
	mov sp, bp
	pop bp
	ret
%undef source
%undef destination

; Compare Zero-Terminated Strings
match:
%define source      [bp+4]
%define destination [bp+6]
.fpreamb:
	push bp
	mov bp, sp
	push si
	push di
.fbody:
	mov si, source
	mov di, destination
.loop:
	lodsb
	scasb
	jne .nomatch

	or al, al
	jnz .loop
.match:
	mov ax, 0xFFFF
	jmp .freturn
.nomatch:
	mov ax, 0x0000
.freturn:
	pop di
	pop si
	mov sp, bp
	pop bp
	ret
%undef src
%undef dst

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

debug_printq_byte:
.fpreamb:
	push bp
	mov bp, sp
	push ax
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
	pop ax
	mov sp, bp
	pop bp
	ret

debug_word:
.fpreamb:
	push bp
	mov bp, sp
	push ax
.fbody:
	push msg_debug_word
	call print

	mov ax, [bp+4]
	shr ax, 8
	push ax
	call debug_printq_byte

	mov ax, [bp+4]
	push ax
	call debug_printq_byte

	push msg_debug_end
	call print
	add sp, 8
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret

debug_byte:
.fpreamb:
	push bp
	mov bp, sp
	push ax
.fbody:
	push msg_debug_byte
	call print

	mov ax, [bp+4]
	push ax
	call debug_printq_byte

	push msg_debug_end
	call print
	add sp, 6
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret

%define CRLF 0x0A, 0x0D
%define CRLFZ CRLF, 0x00

; === Non-executable Data ===
msg_start:      db 'Second stage loaded. '
msg_sayhi:      db 'Say Hi.'
newline:        db CRLFZ
msg_prompt:     db '?> ', 0
str_hi:         db 'Hi', 0
msg_hello:      db 'Hello.', CRLFZ

msg_debug_byte: db 'BYTE(', 0
msg_debug_word: db 'WORD(', 0
msg_debug_end:  db ')', 0x0A, 0x0D, 0

msg_a20on:      db 'A20 Enabled.', CRLFZ
msg_a20off:     db 'A20 disabled.', CRLFZ
msg_ncarry:     db '[No Carry]',  CRLFZ
msg_carry:      db '[Carry]',  CRLFZ

cmdbuf_size  equ  32
cmdbuf       times cmdbuf_size db 0
