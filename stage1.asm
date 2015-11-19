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

mem_start   equ  0x0500
load_start  equ  0x0600
st1_start   equ  0x7C00
st2_start   equ  0x8000
;past_end    equ  0x080000
true        equ  0xFFFF
false       equ  0x0000

stack       equ  st1_start
;load_at     equ  mem_start
fat_at      equ  mem_start + 2

; === FAT DATA ===

	jmp start
	nop
fat_bios_parameter_block:
	db 'MSWIN4.1' ; OEM ID
	dw 512        ; bytes per sector
	db 1          ; sectors per cluster
reserved:
	dw 2          ; Number of reserved clusters
fatcount:
	db 2          ; Number of file-allocation tables
	dw 224        ; Number of root entires
	dw 2880       ; Number of sectors
	db 0xF0       ; Media descriptor
fatsize:
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
	; Setup segments and stack
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, stack
	mov bp, stack

	; Load debugging/development code
	push 0x7E00
	push 1
	call loadsector
	add sp, 4

	; Display start-up message
	push msg_start
	call print
	add sp, 2

.load_dir:
	; Calculate Where root Directory is. (Sector # = fatcount * fatsize + reserved)
	mov ah, 0
	mov al, [fatcount]
	imul ax, [fatsize]
	add ax, [reserved]
	push ax
	push 14
	call load_chunk
	add sp, 4

	mov ax, [load_at]
	mov [fat_at], ax

.load_fat:
	mov ax, [reserved]
	push ax
	mov ax, [fatsize]
	push ax
	call load_chunk
	add sp, 4

	mov bx, 0x500
.readdir:
	push st2_file
	push bx
	call match_file
	add sp, 4

	cmp ax, 0xFFFF
	je .found
	add bx, 32

	cmp bx, [fat_at]
	je .notfound
	jmp .readdir
.found:
	; bx now has directory entry of matching file
	; If I ever decide to keep track of file size,
	; this would be the place to save it. It's at
	; dword[bx+28].

	mov cx, word[bx+26]
	mov bx, st2_start
.loadnext:
	; CX has cluster to load
	; BX has memory address to load to
	push cx
	call fat_sector
	add sp, 2

	push bx
	push ax
	call loadsector
	add sp, 4
	or ax, ax
	jz .loaderr

	; TODO: Check for additional clusters, and load them.



.loadsuccess:
	jmp st2_start
.notfound:
	push msg_notfound
	call print
	add sp, 2
	jmp .freeze
.loaderr:
	push msg_error
	call print
	add sp, 2
.freeze:
	hlt
	jmp .freeze

; === FUNCTIONS ===

; For loading File info
; File entries are 32 bytes.
; #00, to #07:     File name
; #08, to #10:     File Extention
; #26, to #27:     First Cluster
; #28, to #31:     File Size

load_chunk:
.fpreamb:
	push bp
	mov bp, sp
	push cx
	push dx
.fbody:
	mov cx, [bp+4] ; Count
	mov dx, [bp+6] ; Sector #
	mov ax, [load_at]
.loop:
	push ax
	push dx
	call loadsector
	add sp, 4

	mov ax, [load_at]
	add ax, 512
	mov [load_at], ax

	inc dx
	loop .loop
.freturn:
	pop dx
	pop cx
	mov sp, bp
	pop bp
	ret

; Match a filename
match_file:
.fpreamb:
	push bp
	mov bp, sp
	push si
	push di
	push cx
.fbody:
	mov si, [bp+4]
	mov di, [bp+6]

	mov ax, [si+0x0B] ; Ignore directories and the volume label
	and ax, 0x18
	jnz .nomatch

	mov cx, 11
.loop:
	lodsb
	scasb
	jne .nomatch
	loop .loop
.match:
	mov ax, 0xFFFF
	jmp .freturn
.nomatch:
	mov ax, 0x0000
.freturn:
	pop cx
	pop di
	pop si
	mov sp, bp
	pop bp
	ret

fat_sector:
; bp+4: FAT Cluster
.fpreamb:
	push bp
	mov bp, sp
.fbody:
	; The real location of cluster n is sector (reserved + fat_size * fat_count + 14)
	mov ax, [bp+4]
	add ax, 32
.freturn:
	mov sp, bp
	pop bp
	ret

loadsector:
; bp+4: Sector to load
; bp+6: Destination Address
.fpreamb:
	push bp
	mov bp, sp
	push cx
	push dx
	push bx
.fbody:
	mov ax, [bp+4]

; Step 1: Convert sector number to CHS
	mov bl, 36 ; AL has cyl, AH has remainder
	idiv bl ; AL has cyl, AH has remainder

	mov ch, al ; Set CH = Cylinder
	mov al, ah
	mov ah, 0

	mov bl, 18 ; AL has head, AH has sector
	idiv bl

	mov dh, al

	inc ah ; Sectors are 1-based
	mov cl, ah

; Step 2: Profit!
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

; === Non-executable Data ===
load_at:      dw mem_start
;fat_at:       dw 0x0000

st2_file:  db 'STAGE2  BIN'

pad:        times 446-($-$$) db 0
ptable:     times 64 db 0
bootsig:    dw 0xAA55

; Print a string
print:
.fpreamb:
	push bp
	mov bp, sp
	push ax
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
	pop ax
	mov sp, bp
	pop bp
	ret

print_byte:
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
	call print_byte

	mov ax, [bp+4]
	push ax
	call print_byte

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
	call print_byte

	push msg_debug_end
	call print
	add sp, 6
.freturn:
	pop ax
	mov sp, bp
	pop bp
	ret

msg_debug_byte: db 'BYTE(', 0
msg_debug_word: db 'WORD(', 0
msg_debug_end: db ')'
msg_linebreak: db 0x0D, 0x0A, 0
msg_start: db "Welcome to the bootloader.", 0x0D, 0x0A, 0
msg_error: db "Error", 0x0D, 0x0A, 0
msg_notfound: db "Not found", 0x0D, 0x0A, 0
pad2:        times 1024-($-$$) db 0
