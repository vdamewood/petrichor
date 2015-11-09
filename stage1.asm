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

mem_start   equ  0x000500
st1_start   equ  0x007C00
st2_start   equ  0x007E00
past_end    equ  0x080000

stack       equ  (st1_start - 2)

; === FAT DATA ===

	jmp start
	nop
fat_bios_parameter_block:
	db 'MSWIN4.1' ; OEM ID
	dw 512        ; bytes per sector
	db 1          ; sectors per cluster
	dw 1          ; Number of reserved clusters
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

; === BOOT LOADER ===
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

	; TODO: Find file and get cluster number
	mov ax, 2

	push st2_start
	push ax
	call loadsector
	add sp, 4
	or ax, ax
	jz .loaderr

.loadsuccess:
	jmp st2_start
.loaderr:
	push msg_error
	call print
	add sp, 2
.freeze:
	hlt
	jmp .freeze

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

loadsector:
; bp+4: FAT Cluster to load
; bp+6: Destination Address
.fpreamb:
	push bp
	mov bp, sp
	push cx
	push dx
	push bx
.fbody:
	mov ax, [bp+4]

; Step 1: Convert Cluster number to sector number
	add ax, 31 ; 33 is the first data sector. 2 is the first FAT Cluster

; Step 2: Convert sector number to CHS
	mov bl, 36 ; AL has cyl, AH has remainder
	idiv bl ; AL has cyl, AH has remainder

	mov ch, al ; Set CH = Cylinder
	mov al, ah
	xor ah, ah

	mov bl, 18 ; AL has head, AH has sector
	idiv bl

	mov dh, al

	inc ah ; Sectors are 1-based
	mov cl, ah

; Step 3: Profit!
	mov al, 1 ; Number of sectors
	mov dl, 0 ; drive

	mov bx, [bp+6] ; buffer
	mov ah, 2 ; Read sectors
	int 0x13 ; due to ah = 0x02, Read sectors into memory

	jc .fail
	mov ax, 0xFFFF
	jmp .freturn
.fail:
	mov ax, 0x0000
.freturn:
	pop bx
	pop dx
	pop cx
	mov sp, bp
	pop bp
	ret

; === Debuging Functions; Remove from Final Sector ===
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
msg_start:   db "Boot Sector", 0x0D, 0x0A, 0
msg_error:   db "Error", 0x0D, 0x0A, 0
st2_file:   db 'STAGE2  BIN'

pad:        times 446-($-$$) db 0
ptable:     times 64 db 0
bootsig:    dw 0xAA55
