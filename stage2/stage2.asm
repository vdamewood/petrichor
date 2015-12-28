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
	call vidtxt_println
	add esp, 2

stage2_enable_a20:
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
	call vidtxt_print
	call vidtxt_breakline
	add sp, 2

stage2_cmdloop:
.cmdloop:
	push msg_prompt
	call print
	add sp, 2

	call get
	
	push ax
	push str_hi
	call match
	add sp, 2
	or ax, ax
	jz .not_hi
	push msg_hello
	call vidtxt_println
	add sp, 4
	jmp .cmdloop
.not_hi:
	push str_enable
	call match
	add sp, 2
	or ax, ax
	jz .not_enable
	add sp, 2
	call keyboard_enable
	or ax, ax
	jz .enable_fail
	push msg_kbd_on
	call vidtxt_println
	add sp, 2
	jmp .cmdloop
.enable_fail:
	push msg_fail
	call vidtxt_println
	add sp, 2
	jmp .cmdloop
.not_enable:
	push str_disable
	call match
	add sp, 2
	or ax, ax
	jz .check_vendor
	add sp, 2
	call keyboard_disable
	or ax, ax
	jz .disable_fail
	push msg_kbd_off
	call vidtxt_println
	add sp, 2
	jmp .cmdloop
.disable_fail:
	push msg_fail
	call vidtxt_println
	add sp, 2
	jmp .cmdloop
.check_vendor:
	push str_vendor
	call match
	add sp, 2
	or ax, ax
	jz .check_pmode
	call load_vendor_id
	push msg_vendor
	call vidtxt_println
	add sp, 2
	jmp .cmdloop
.check_pmode:
	push str_pmode
	call match
	or ax, ax
	jz .default
	push ax
	call vidtxt_putword
	pop ax
	call enter_pmode
.default:
	jmp .cmdloop

; === FUNCTIONS ===

enter_pmode:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
	push msg_pmode_enabled
	call vidtxt_println
	add sp, 2
.freturn:
	mov sp, bp
	pop bp
	ret


load_vendor_id:
ftemplate:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
	mov al, [msg_vendor]
	or al, al
	jnz .freturn
	xor eax, eax
	push cx
	push dx
	push bx
	cpuid
	mov [sub_vendor_1], ebx
	mov [sub_vendor_2], edx
	mov [sub_vendor_3], ecx
	pop bx
	pop dx
	pop cx
.freturn:
	mov sp, bp
	pop bp
	ret


GDT_Pointer:
limit: dw 0xFFFF
base:  dq GlobalDescTable + 0x10000

GlobalDescTable:
GDT_null:
	times 8 db 0

GDT_sys_code:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0x9A   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

GDT_sys_data:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0x92   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

GDT_usr_code:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0xFA   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

GDT_usr_data:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0xF2   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base



%include "a20.asm"
%include "vidtxt.asm"
%include "keyboard.asm"
%include "command.asm"
;%include "fat12.asm"
%include "strings.asm"

%ifdef blockcomment
ftemplate:
.fpreamb:
	push bp
	mov bp, sp
.fbody:
.freturn:
	mov sp, bp
	pop bp
	ret
%endif

; === Non-executable Data ===
msg_start:      db 'Second stage loaded.', 0
msg_sayhi:      db 'Say hi.', 0
msg_prompt:     db '?> ', 0
msg_hello:      db 'Hello.', 0
msg_pmode_enabled: db 'Protected Mode Enabled', 0
msg_a20on:      db 'A20 Enabled.', 0
msg_a20off:     db 'A20 disabled.', 0
msg_kbd_on:     db 'Keyboard driver enabled.', 0
msg_kbd_off:    db 'Keyboard driver disabled.', 0
msg_fail:		db 'Command failed.', 0
msg_vendor:
sub_vendor_1:   times 4 db 0
sub_vendor_2:   times 4 db 0
sub_vendor_3:   times 4 db 0
term_vendor:    db 0

str_hi:         db 'hi', 0
str_enable:     db 'enable', 0
str_disable:    db 'disable', 0
str_vendor:     db 'vendor', 0
str_pmode:      db 'pmode', 0


