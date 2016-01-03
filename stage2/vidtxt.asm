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

vidtxt_color:  db  0x07
vidtxt_cursor: dd  0x000B8000

%define vmem    0x000B8000
%define pcolor  vidtxt_color
%define pcursor vidtxt_cursor
%define color   byte[vidtxt_color]
%define cursor  dword[vidtxt_cursor]
%define width   80
%define height  25
%define fullscr (width*height)

; When placing, LSB is character in CP437, MSB is Forground/Backgorund color

vidtxt_clear:
.fpramb:
	push ebp
	mov ebp, esp
	push eax
	push ecx
	push edi
.fbody:
	mov edi, vmem
	mov ax, 0
	mov ecx, fullscr
.loop:
	mov word[edi], ax
	add edi, 2
	loop .loop
	mov eax, vmem
	mov cursor, eax
.freturn:
	pop edi
	pop ecx
	pop eax
	mov esp, ebp
	pop ebp
	ret

vidtxt_set_cursor:
%define newpos [bp+8]
.fpramb:
	push ebp
	mov ebp, esp
	push eax
.fbody:
	mov eax, newpos
	mov cursor, eax
.freturn:
	pop eax
	mov esp, ebp
	pop ebp
	ret
%undef newpos

vidtxt_show_cursor:
.fpramb:
	push ebp
	mov ebp, esp
	push eax
	push edx
	push ebx
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
	pop ebx
	pop edx
	pop eax
	mov esp, ebp
	pop ebp
	ret


vidtxt_shift:
.fpramb:
	push ebp
	mov ebp, esp
	push eax
	push ecx
	push esi
	push edi
.fbody:
	mov edi, vmem
	mov esi, vmem+160
	mov ecx, 80 * 24
	rep movsw

	xor eax, eax
	mov ah, color
	mov ecx, 80
.lastline:
	mov word[edi], ax
	add edi, 2
	loop .lastline
.freturn:
	pop edi
	pop esi
	pop ecx
	pop eax
	mov esp, ebp
	pop ebp
	ret

vidtxt_breakline:
.fpreamb:
	push ebp
	mov ebp, esp
	push eax
	push edx
	push ebx
.fbody:
	mov eax, cursor
	sub eax, vmem
	cmp eax, 2*80*24
	jge .last_line
.not_last_line:
	mov ebx, 2*80
	xor edx, edx
	div ebx ; eax = quot ; edx = mod
	mov eax, cursor
	sub eax, edx ; cursor - mod = first char of row
	add eax, 2*80 ; next row
	mov cursor, eax
	jmp .show_cursor
.last_line:
	call vidtxt_shift
	mov eax, 2*80*24
	mov cursor, eax
.show_cursor:
	call vidtxt_show_cursor
.freturn:
	pop ebx
	pop edx
	pop eax
	mov esp, ebp
	pop ebp
	ret

; Print a string
vidtxt_print:
%define string [ebp+8]
.fpreamb:
	push ebp
	mov ebp, esp
	push esi
	push edi
	push eax
.fbody:
	mov esi, string
	mov edi, cursor
	mov ah, color
.loop:
	lodsb        ; Fetch next byte in string, ...
	or al, al    ; ... test if it's 0x00, ...
	jz .done     ; ... and, if so, were'd done
	stosw
	jmp .loop
.done:
	mov cursor, edi
	;call vidtxt_show_cursor
.freturn:
	pop eax
	pop edi
	pop esi
	mov esp, ebp
	pop ebp
	ret
%undef string

vidtxt_println:
%define string dword[ebp+8]
.fpreamb:
	push ebp
	mov ebp, esp
.fbody:
	push string
	call vidtxt_print
	add esp, 4
	call vidtxt_breakline
.freturn:
	mov esp, ebp
	pop ebp
	ret
%undef string

vidtxt_putch:
.fpreamb:
	push ebp
	mov ebp, esp
	push eax
	push edi
.fbody:
	mov ax, [bp+4]
	mov ah, [vidtxt_color]
	mov edi, [vidtxt_cursor]
	stosw
	cmp edi, 80*25*2
	jle .save_cursor

	call vidtxt_shift
	mov edi, 80*24*2
.save_cursor:
	mov [vidtxt_cursor], edi
.freturn:
	pop edi
	pop eax
	mov esp, ebp
	pop ebp
	ret


vidtxt_delch:
vidtxt_backspace:
.fpreamb:
	push ebp
	mov ebp, esp
	push eax
	push edi
.fbody:
	mov ah, [vidtxt_color]
	mov edi, vmem
	add edi, [vidtxt_cursor]
	sub edi, 2
	mov al, ' '

	mov [edi], ax
	mov [vidtxt_cursor], edi
.freturn:
	pop edi
	pop eax
	mov esp, ebp
	pop ebp
	ret

%ifdef blockcomment

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
	push ax
	call vidtxt_putch
	pop ax

	mov al, byte_at
	and al, 0x0F
	add al, 0x30
	cmp al, 0x39
	jle .skip2
	add al, 7
.skip2:
	push ax
	call vidtxt_putch
	pop ax
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

%endif

%undef vmem
%undef pcolor
%undef pcursor
%undef color
%undef cursor
%undef width
%undef height
%undef fullscr
