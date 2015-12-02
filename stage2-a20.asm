; s2-a20.asm: Routines for manipulating the A20 line
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


; Enable A20 Line
; FIXME: The method used isn't supported on all systems. Add other methods
;   for other kinds of systems.
a20_enable:
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
a20_disable:
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

