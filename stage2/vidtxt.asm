; vidtxt.asm: Video text driver
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

vidtxt_color:  db  0x07
vidtxt_cursor: dd  0x000B8000
vidtxt_width:  db  80
vidtxt_height: db  25

%define vmem    0x000B8000
%define pcolor  vidtxt_color
%define pcursor vidtxt_cursor
%define color   byte[vidtxt_color]
%define cursor  dword[vidtxt_cursor]
%define width   byte[vidtxt_width]
%define height  byte[vidtxt_height]

; When placing, LSB is character in CP437, MSB is Forground/Backgorund color

; Clears the screen
vidtxt_clear:
	fprolog 0, eax, ecx, edi
.fbody:
	mov edi, vmem
	mov cursor, edi
	mov al, width
	mov ah, height
	mul ah
	mov cx, ax
	xor ax, ax
	mov ah, color
.loop:
	mov word[edi], ax
	add edi, 2
	loop .loop
.freturn:
	freturn eax, ecx, edi

vidtxt_set_cursor:
	fprolog 0, eax
.fbody:
%define newpos [ebp+8]
	mov eax, newpos
	mov cursor, eax
%undef newpos
.freturn:
	freturn eax

vidtxt_show_cursor:
	fprolog 0, eax, edx, ebx
.fbody:
	mov ebx, cursor
	sub ebx, vmem
	shr ebx, 1

    ; out 0x3D4, 0x0F
	mov dx, 0x03D4
	mov al, 0x0F
	out dx, al

    ; out 0x3D5, bl
	mov dx, 0x03D5
	mov al, bl
	out dx, al

    ; out 0x3D4, 0x0E
	mov dx, 0x03D4
	mov al, 0x0E
	out dx, al

    ; out 0x3D5, 0
	mov dx, 0x03D5
	mov al, bh
	out dx, al
.freturn:
	freturn eax, edx, ebx


vidtxt_shift:
	fprolog 0, eax, ecx, esi, edi
.fbody:
	; Clear register so that high bytes don't contain garbage
	xor eax, eax

	; edi: Start of shift
	mov edi, vmem

	; esi: Line below edi; should be edi+width*2
	mov al, width
	mov ah, 2
	mul ah
	mov esi, eax
	add esi, edi

	; ecx: Number of characters to move; width*(height-1)
	mov ah, width
	mov al, height
	sub al, 1
	mul ah
	mov ecx, eax

	rep movsw

.lastline:
	xor eax, eax
	mov ah, color
	mov cl, width
.loop:
	mov word[edi], ax
	add edi, 2
	loop .loop
.freturn:
	freturn eax, ecx, esi, edi

; Shift the flow of text to the next line.
vidtxt_breakline:
.fpreamb:
	fprolog 0, eax, edx, ebx
.fbody:
	; edx = (height-1)*width*2, that is height-1 lines
	xor eax, eax
	mov ah, width
	mov al, height
	dec al
	mul ah
	shl ax, 1
	mov edx, eax

	; eax = cursor's offset from vmem
	mov eax, cursor
	sub eax, vmem

	cmp eax, edx ; If The offset is past the first n-1 lines
	jge .last_line ; then handle the last line specially
.not_last_line:
	; ebx = width*2
	xor ebx, ebx
	mov bl, width
	shl bx, 1

	xor edx, edx
	div ebx ; cursor position/line size: eax = quotient ; edx = modulus
	mov eax, cursor
	sub eax, edx ; cursor - mod = first char of row
	add eax, ebx ; next row
	mov cursor, eax
	jmp .show_cursor
.last_line:
	call vidtxt_shift

	xor eax, eax
	mov al, height
	mov ah, width
	sub al, 1
	mul ah
	shl ax, 1
	add eax, vmem

	mov cursor, eax
.show_cursor:
	call vidtxt_show_cursor
.freturn:
	freturn eax, edx, ebx

; Print a string
vidtxt_print:
%define string [ebp+8]
.fpreamb:
	fprolog 0, esi, edi, eax
.fbody:
	mov esi, string
	mov edi, cursor
	mov ah, color
.loop:
	lodsb        ; Fetch next byte in string, ...
	or al, al    ; ... test if it's 0x00, ...
	jz .done     ; ... and, if so, were'd done
	stosw

	; FIXME: Check for line wrapping
	;  and adjust behavior when wrapping past the end of
	;  the last line.

	jmp .loop
.done:
	mov cursor, edi
.freturn:
	freturn esi, edi, eax
%undef string

vidtxt_println:
%define string dword[ebp+8]
	fprolog 0
.fbody:
	push string
	call vidtxt_print

	add esp, 4
	; FIXME: Check that the cursor isn't in the
	;   first column and skip the call if it is.
	call vidtxt_breakline
.freturn:
	freturn
%undef string

vidtxt_putch:
	fprolog 0, eax, edi
.fbody:
%define char byte[ebp+8] ; Only the LSB is considered
	mov al, char
	mov ah, color

	mov edi, cursor
	stosw

	xor eax, eax
	mov ah, width
	mov al, height
	mul ah
	shl eax, 1

	cmp eax, edi
	jle .save_cursor

	mov edi, eax
	xor eax, eax
	mov al, width
	shl eax, 1
	sub edi, eax

	call vidtxt_shift
	sub edi, eax
.save_cursor:
	mov cursor, edi
%undef char
.freturn:
	freturn eax, edi

vidtxt_delch:
vidtxt_backspace:
.fpreamb:
	fprolog 0, eax, edi
.fbody:
	mov ah, color
	mov al, ' '

	mov edi, cursor
	sub edi, 2

	mov [edi], ax
	mov cursor, edi
.freturn:
	freturn eax, edi

vidtxt_print_hex:
	fprolog 0, eax, ecx, edx
.fbody:
%define value [ebp+12] ; The Value to print. If fewer than 4 bytes are printed, the low-order bytes are printed
%define count [ebp+8] ; The number of bytes to print
	mov ecx, count
	shl ecx, 3
.loop:
	sub ecx, 4

	mov eax, value
	shr eax, cl
	and eax, 0x0F

	add al, 0x30
	cmp al, 0x39
	jle .skip1
	add al, 7
.skip1:
	push eax
	call vidtxt_putch
	pop eax

	or ecx, ecx
	jnz .loop
%undef value
%undef count
.freturn:
	freturn eax, ecx, edx

vidtxt_hprint_byte:
	fprolog 0
%define arg dword[ebp+8]
	push arg
	push 1
	call vidtxt_print_hex
%undef arg
	freturn

vidtxt_hprint_word:
	fprolog 0
%define arg dword[ebp+8]
	push arg
	push 2
	call vidtxt_print_hex
%undef arg
	freturn

vidtxt_hprint_dword:
	fprolog 0
%define arg dword[ebp+8]
	push arg
	push 4
	call vidtxt_print_hex
%undef arg
	freturn

vidtxt_hprint_qword:
	fprolog 0
%define argl dword[ebp+8]
%define argh dword[ebp+12]
	push argh
	push 4
	call vidtxt_print_hex
	push argl
	push 4
	call vidtxt_print_hex
	freturn



%undef vmem
%undef pcolor
%undef pcursor
%undef color
%undef cursor
%undef width
%undef height
%undef fullscr

%macro print 1
	push %1
	call vidtxt_print
	add esp, 4
%endmacro

%macro println 1
	push %1
	call vidtxt_println
	add esp, 4
%endmacro
