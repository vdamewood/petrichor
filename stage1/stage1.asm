; stage1.asm: Boot sector startup program
;
; Copyright 2015 Vincent Damewood
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.


[BITS 16]
[ORG 0x7C00]

data_start    equ  0x0500  ; Begining of memory where we'll load data: The
                           ; directory and file allocation tables.
stg2_segment  equ  0x1000  ; Where to load the stage-2 image.
stack_base    equ  0x7C00  ; This is where the stack starts.
rootsize      equ  14      ; Number of sectors in root directory.

; === FAT DATA ===

	jmp start
	nop
fat_bios_parameter_block:
	db 'MSWIN4.1' ; OEM ID
	dw 512        ; bytes per sector
cluster:
	db 1          ; sectors per cluster
reserved:
	dw 1          ; Number of reserved clusters
fatcount:
	db 2          ; Number of file-allocation tables
entries:
	dw 224        ; Number of root entires
	dw 2880       ; Number of sectors
	db 0xF0       ; Media descriptor
fatsize:
	dw 9          ; Sectors per file-allocation table
sectors:
	dw 18         ; Sectors per track (cylinder)
heads:
	dw 2          ; Number of heads/sides
	dd 0          ; Hidden sectors
	dd 0          ; Number of sectors (if > 2^16-1)
fat_extended_boot_record:
	db 0x00          ; Drive number
	db 0x00          ; Current Head (Unused)
	db 0x29          ; Signature (0x28 or 0x29)
	dd 0x00000000    ; Volume ID, will be replaced by formatter
	db 'BOOTDISK   ' ; Volume label
	db 'FAT12   '    ; System ID; Unreliable.

; === BOOT LOADER ===
start:
	; Setup segments and stack
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, stack_base
	mov bp, stack_base
	mov [bootdrive], dl

%define fat_sector  word[bp-2]
%define data_sector word[bp-4]
%define fat_memory  word[bp-6]
%define root_memory word[bp-8]

find_disk_values:
	; Calculate Where root Directory is.
	; (Sector # = fatcount * fatsize + reserved)
	mov al, [fatcount]
	mul word[fatsize]
	add ax, [reserved]
	push ax ; fat_sector, sector on disk that has FAT

	; The data sectors start at (rootdir + rootsize), we subtract 2 because FAT
	; enties 0 and 1 are reserved, so actual data starts at 2.
	add ax, rootsize-2
	push ax ; data_sector

load_fat:
	push data_start     ; fat_memory, beginning of FAT
	push word[reserved] ; Source
	push word[fatsize]  ; Count
	call load
	add sp, 4 ; We pushed 3 values to stack, but only pop 2.
	          ; The remaining value (the beginning of the FAT in
	          ; memory) will be used later.
	or bx, bx
	jz error.loadfat
	push bx  ; root_memory, beginning of root dir

load_root_dir:      ; Use previous push as destination
	push fat_sector ; Soure
	push rootsize   ; Count
	call load
	add sp, 4 ; We're going to keep the last value again.
	or bx, bx
	jz error.loaddir

find_stage_2:
	mov bx, root_memory
	mov cx, [entries]
.nextfile:
	mov ax, [bx+0x0B] ; Ignore directories and the volume label
	and ax, 0x18
	jnz .file_nomatch

	mov al, [bx]      ; If the first byte is 0x00, this is the end of the root
	or al, al         ; directory and we've failed to find the file.
	jz error.notfound ; So, panic and cry about it.

	push cx ; Inner Loop
	mov si, st2_file
	mov di, bx
	mov cx, 11
	repe cmpsb
	pop cx
	je load_file
.file_nomatch:
	add bx, 32 ; Directory entries are 32 bytes
	loop .nextfile
	jmp error.notfound ; We've exhausted all entries. Quit.

load_file:
	; bx now has directory entry of matching file
	; If I ever decide to keep track of file size,
	; this would be the place to save it. It's at
	; dword[bx+28].

	mov ax, stg2_segment
	mov es, ax

	mov cx, word[bx+26]
	xor bx, bx
.loadnext:
	; CX has cluster to load
	; BX has memory address to load to

	mov ax, data_sector
	add ax, cx

	push bx
	push ax
	mov al, [cluster]
	push ax
	call load
	add sp, 6

	or bx, bx
	jz error.loads2sec

.find_next_sector:
	; The following bit of magic takes the value of cx, multiplies it by
	; 1.5 and notes if it was odd or even before the process. This gives
	; us the memory offset from the beginning of the FAT for the FAT
	; entry of cluster cx.
	mov si, cx
	shr si, 1       ; si = floor(cx/2)
	sbb dx, dx      ; dx = (cx mod 2) == 0 ? 0 : -1
	add si, cx      ; si = 1.5*cx
	add si, fat_memory  ; si = location in fat for cx

	mov cx, [si]    ; load cx from new location

	or dx, dx           ; At this point cx contains a value with four garbage
	jz .fat_align_even  ; bits. So we check if the cluster number was odd/even.
	shr cx, 4           ; If odd, garbage bits are the low-order bits. Shift.
	jmp .fat_align_end
.fat_align_even:
	and cx, 0x0FFF      ; If even, garbage bits are the high-order bits. Zero.
.fat_align_end:
	; At this point cx has the next cluster
	cmp cx, 0xFF8      ; If the next cluster is not an EOF marker...
	jl .loadnext       ; load the next cluster.

jump_to_stage_2:
	jmp stg2_segment:0x80 ; Else, We're done loading, jmp to the next stage.

%undef fat_sector
%undef data_sector
%undef fat_memory
%undef root_memory

error:
.loaddir:
.loadfat:
.notfound:
.loads2sec:
	mov ax, 0x0E21
.print:
	int 0x10
.freeze:
	hlt
	jmp .freeze

; === FUNCTIONS ===

load:
;[bp+4]: Number of sectors to load
;[bp+6]: First sector to load
;[bp+8]: Destination starting memory address
; returns bx: Memory address that's one past
;        the end of the loaded section
.fpreamb:
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
.fbody:

; Step 1: Convert sector number to CHS
	mov bl, [sectors]
	mov al, [heads]
	mul bl
	mov bl, al

	mov ax, [bp+6]
	div bl ; AL has cyl, AH has remainder

	mov ch, al ; Set CH = Cylinder
	mov al, ah
	mov ah, 0

	mov bl, byte[sectors] ; AL has head, AH has sector
	div bl

	mov dh, al

	inc ah ; Sectors are 1-based
	mov cl, ah

; Step 2: Make the actual copy to memory
	mov al, [bp+4] ; Number of sectors
	mov dl, [bootdrive] ; drive

	mov bx, [bp+8] ; destination
	mov ah, 2
	int 0x13 ; due to ah = 0x02, Read sectors into memory
	jnc .success
	xor bx, bx
	jmp .freturn
; Step 3: Find and return the end of the load
.success:
	mov bx, [bp+4]
	shl bx, 9 ; bx := bx * 512
	add bx, [bp+8]
.freturn:
	pop dx
	pop cx
	pop ax
	mov sp, bp
	pop bp
	ret

; === Non-executable Data ===
st2_file:  db 'STAGE2  BIN'
bootdrive:  db 0
pad:        times 446-($-$$) db 0
ptable:     times 64 db 0
bootsig:    dw 0xAA55
