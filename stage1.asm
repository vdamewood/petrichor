; stage1.asm: Boot sector startup program
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
[ORG 0x7C00]

exe_end     equ 446 ; End of space for executable code and data
ptbl_size   equ  64 ; size of a partition table
cmdbuf      equ  0x500
cmdbuf_size equ  72 ; size of the input buffer
stack       equ  0x7BFF
stage2      equ  0x7E00


; === FAT DATA ===

	jmp start
	nop
fat_bios_parameter_block:
	db 'MSWIN4.1' ; OEM ID
	dw 512        ; bytes per sector
	db 1          ; sectors per cluster
	dw 2          ; Number of reserved clusters
	db 2          ; Number of file-allocation tables
	dw 224        ; Number of root entires
	dw 2880       ; Number of sectors
	db 0xF0       ; Media descriptor
	dw 9          ; Sectors per file-allocation table
	dw 18         ; Sectors per track (cylinder)
	dw 2          ; Number of heads/sides
	dd 0          ; Hidden sectors
	dd 0          ; Number of sectors (if > 2^16-1)
fat_extended_boot_record:
	db 0x00          ; Drive number
	db 0x00          ; Current Head (Unused)
	db 0x28          ; Signature (0x28 or 0x29)
	dd 0xBAADBEEF    ; Volume ID
	db 'BOOTDISK   ' ; Volume label
	db 'FAT12   '    ; System ID; Unreliable.

start:
	; Setup segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; Setup stack
	mov ax, stack
	mov sp, ax
	mov bp, ax

	; Display start-up message
	push msg_start
	call print
	add esp, 2

	mov ah, 2 ; Read sectors
	mov al, 1 ; Number of sectors
	mov ch, 0 ; low 'half' of cylinder
	mov cl, 2 ; sector number (high 2 bits for cylinder)
	mov dh, 0 ; head
	mov dl, 0 ; drive
	mov bx, stage2 ; buffer
	int 0x13 ; due to ah = 0x02, Read sectors into memory
	jnc stage2 ; If it worked (carry cleared), jump to code.

	push msg_error ; else show an error message.
	call print
	add sp, 2

.cmdloop:
	push msg_prompt
	call print
	add sp, 2

	call get
	mov bx, ax
	push msg_resp
	call print
	add sp, 2

	push bx
	call print
	add sp, 2

	push newline
	call print
	add sp, 2
	jmp .cmdloop

; === FUNCTIONS ===

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

; === Non-executable Data ===
msg_start:  db 'Starting System...', 0x0D, 0x0A, 0
msg_error:  db 'Load failed!', 0x0D, 0x0A, 0
msg_prompt: db '?> ', 0
msg_resp:   db '!: ', 0
newline:    db 0x0D, 0x0A, 0
pad:        times exe_end-($-$$) db 0
ptable:     times ptbl_size db 0
bootsig:    dw 0xAA55
