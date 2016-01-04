; stage2.asm: Second-stage startup program
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

[ORG 0x10000]

%define popoff(num) add sp, (num*4)

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
; After A0000 is unusable.

stage2:
	; Initial Setup. This may not be needed, anymore.
	mov ax, 0x1000
	mov ds, ax
	mov es, ax

	mov ax, 0x2000
	mov ss, ax
	xor sp, sp
	mov bp, sp

	; Enable A20
	; FIXME: This only works on a few systems.
	; Might want to check if other systems need a
	; different method.
	mov ax, 0x2401
	int 0x15

	; Move to protected mode
	cli
	; The following code loads a GDT that's hard-coded
	; into the boot sector. Move it to a more sane
	; location.
	xor ax, ax
	mov ds, ax
	mov eax, 0x7DBC
	lgdt [eax]

	mov eax, cr0
	or al, 1
	mov cr0, eax
 	jmp dword 0x08:pmode

[BITS 32]
pmode:
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x90000
	mov ebp, esp

	call vidtxt_clear

	push msg_start
	call vidtxt_print
	add esp, 4

.infloop:
	jmp .infloop

; === FUNCTIONS ===

%include "functions.inc"

load_vendor_id:
.fpreamb:
	push ebp
	mov ebp, esp
	push ecx
	push edx
	push ebx
.fbody:
	mov al, [msg_vendor]
	or al, al
	jnz .set_rval
	xor eax, eax
	cpuid
	mov [sub_vendor_1], ebx
	mov [sub_vendor_2], edx
	mov [sub_vendor_3], ecx
.set_rval:
	mov eax, msg_vendor
.freturn:
	pop ebx
	pop edx
	pop ecx
	mov esp, ebp
	pop ebp
	ret

%include "vidtxt.asm"

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
;msg_pmode_enabled: db 'Protected Mode Enabled', 0
;msg_a20on:      db 'A20 Enabled.', 0
;msg_a20off:     db 'A20 disabled.', 0
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

;pad:        times 0x800-($-$$) db 0
