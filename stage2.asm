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

	call a20_enable
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

%include "stage2-a20.asm"
%include "stage2-fat12.asm"
%include "stage2-io.asm"
%include "stage2-string.asm"

;ftemplate:
;.fpreamb:
;	push bp
;	mov bp, sp
;.fbody:
;.freturn:
;	mov sp, bp
;	pop bp
;	ret

%define CRLF 0x0A, 0x0D
%define CRLFZ CRLF, 0x00

; === Non-executable Data ===
msg_start:      db 'Second stage loaded. '
msg_sayhi:      db 'Say Hi.'
newline:        db CRLFZ
msg_prompt:     db '?> ', 0
str_hi:         db 'Hi', 0
msg_hello:      db 'Hello.', CRLFZ

msg_a20on:      db 'A20 Enabled.', CRLFZ
msg_a20off:     db 'A20 disabled.', CRLFZ
msg_ncarry:     db '[No Carry]',  CRLFZ
msg_carry:      db '[Carry]',  CRLFZ
