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

extern vidtxt_clear
extern vidtxt_show_cursor
extern vidtxt_breakline
extern vidtxt_print
extern vidtxt_println
extern vidtxt_putch
extern vidtxt_space
extern vidtxt_backspace
extern vidtxt_hprint_word
extern vidtxt_hprint_dword
extern vidtxt_hprint_qword
extern IntrSetupInterrupts
extern IntrTest
extern IntrSetupInterrupts
extern command_get

extern GdtPointer
extern GdtTable

SECTION .data

dummy_table:
	dd 0
	dd stub
command_table:
	dd str_clear
	dd clear_screen
	dd str_hi
	dd say_hi
	dd str_vendor
	dd show_vendor
	dd str_memory
	dd show_memory
	dd cmd_int
	dd IntrTest
	dd cmd_break
	dd Breakpoint
	dd 0
	dd stub

msg_start:      db 'Second stage loaded.', 0
msg_prompt:     db '?> ', 0
msg_hello:      db 'Hello.', 0
msg_fail:		db 'Command failed.', 0
msg_vendor:
sub_vendor_1:   times 4 db 0
sub_vendor_2:   times 4 db 0
sub_vendor_3:   times 4 db 0
term_vendor:    db 0

str_hi:         db 'hi', 0
str_vendor:     db 'vendor', 0
str_memory:     db 'memory', 0
cmd_int:        db 'int', 0
str_clear:      db 'clear', 0
cmd_break:      db 'break', 0

str_memory_table: db 'Base             Size             Status   Ext     ', 0

section .text
[BITS 16]
%define CodeOrg       0x11000
%define CodeSegment   (CodeOrg>>4)
%define CodeOffset(x) (x-CodeOrg)
global Stage2
Stage2:
	; Copy Memory Information
	xor eax, eax
	mov dx, ax
	mov es, ax
	mov [0x3300], eax
	mov [0x3304], eax

	mov di, 0x3308
	xor ebx, ebx
	mov edx, 0x534D4150
.next_mem:
	mov eax, 0xE820
	mov ecx, 24
	int 0x15
	jc .mem_invalid
	mov eax, [0x3300]
	inc eax
	mov [0x3300], eax

	or ebx, ebx
	jz .mem_done
	add di, 24
	jmp .next_mem
.mem_invalid:
	xor eax, eax
	sub eax, 1
	mov ecx, 24
	rep stosb
.mem_done:
	; Enable A20
	; FIXME: This only works on a few systems.
	; Might want to check if other systems need a
	; different method.
	mov ax, 0x2401
	int 0x15

	; Move to protected mode

	; Move an appropriate segment to ds
	mov eax, GdtPointer
	shr eax, 4
	mov ds, ax

	; Move an offset to eax. The offset
	; should probably always be 0, but
	; just in case, we calculate.
	mov eax, GdtPointer
	and eax, 0x0F

	cli
	lgdt [eax]
	mov eax, cr0
	or al, 1
	mov cr0, eax
	jmp dword 0x08:pmode

[BITS 32]

extern string_match
extern command_get

pmode:
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x90000
	mov ebp, esp

	call IntrSetupInterrupts
	call vidtxt_clear
	push msg_start
	call vidtxt_println
	add esp, 4

stage2_cmdloop:
.cmdloop:
	push msg_prompt
	call vidtxt_print
	add esp, 4

	call command_get
	push eax

	mov ebx, dummy_table
.check_next:
	add ebx, 8
	mov eax, [ebx]
	or eax, eax
	jz .default

	push eax
	call string_match
	add esp, 4
	or eax, eax
	jz .check_next
.found_it:
	add ebx, 4
	mov eax, [ebx]
	call eax
.default:
	add esp, 4
	jmp .cmdloop

; === FUNCTIONS ===

%include "functions.inc"

stub:
	ret

Breakpoint:
	fprolog 0
	xchg bx, bx
	freturn

clear_screen:
	fprolog 0
	call vidtxt_clear
	freturn

say_hi:
	fprolog 0
	push msg_hello
	call vidtxt_println
	add esp, 4
	freturn

show_vendor:
	fprolog 0, eax
	call load_vendor_id
	push eax
	call vidtxt_println
	add esp, 4
	freturn eax

show_memory:
%define count 0x3300
%define first 0x3308
	fprolog 0, eax, ecx, ebx

	mov ecx, [count]
	push ecx
	call vidtxt_hprint_word
	add esp, 4

	call vidtxt_breakline

	push str_memory_table
	call vidtxt_println
	add esp, 4

	mov ebx, first
.loop:
	push dword[ebx+4]
	push dword[ebx]
	call vidtxt_hprint_qword
	add esp, 8

	push dword ' '
	call vidtxt_putch
	add esp, 4

	push dword[ebx+12]
	push dword[ebx+8]
	call vidtxt_hprint_qword
	add esp, 8

	push dword ' '
	call vidtxt_putch
	add esp, 4

	push dword[ebx+16]
	call vidtxt_hprint_dword
	add esp, 4

	push dword ' '
	call vidtxt_putch
	add esp, 4

	push dword[ebx+20]
	call vidtxt_hprint_dword
	add esp, 4

	call vidtxt_breakline
	add ebx, 24
	loop .loop

	freturn eax, ecx, ebx
%undef count
%undef first


load_vendor_id:
	fprolog 0, ecx, edx, ebx
.fbody:
	mov eax, dword[msg_vendor]
	or eax, eax
	jnz .set_rval

	xor eax, eax
	cpuid
	mov [sub_vendor_1], ebx
	mov [sub_vendor_2], edx
	mov [sub_vendor_3], ecx
.set_rval:
	mov eax, msg_vendor
	freturn ecx, edx, ebx
