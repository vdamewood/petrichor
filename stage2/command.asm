; command.asm: Command interpreter
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

extern IntrTest
extern KeyboardGetStroke
extern MiscBreakpoint
extern MiscSayHi
extern MiscShowMemory
extern MiscShowVendor
extern ScreenBreakLine
extern ScreenClear
extern ScreenDelete
extern StringMatch
extern ScreenPrint
extern ScreenPrintChar
extern ScreenShowCursor

%include "functions.inc"

%define BufferSize 32
%define end    (Buffer+BufferSize-1)

section .data

Prompt       db '?> ', 0
CmdHi:       db 'hi', 0       ; Display the word 'Hello' to the screen
CmdClear:    db 'clear', 0    ; Clear the screen
CmdVendor:   db 'vendor', 0   ; Show vendor from CPUID
CmdMemory:   db 'memory', 0   ; Show memory map generated in real16.asm
CmdInt:      db 'int', 0      ; Test interrupt handler
CmdBreak:    db 'break', 0    ; Trigger a breakpoint in Bochs

CommandTable:
	dd CmdHi
	dd MiscSayHi
	dd CmdClear
	dd ScreenClear
	dd CmdVendor
	dd MiscShowVendor
	dd CmdMemory
	dd MiscShowMemory
	dd CmdInt
	dd IntrTest
	dd CmdBreak
	dd MiscBreakpoint
	dd 0
	dd CommandStub

section .bss

Buffer: resb BufferSize

section .text

global CommandLoop
CommandLoop:
	fprolog 0, eax
.start:
	push Prompt
	call ScreenPrint
	add esp, 4

	call Get
	push eax

	mov ebx, CommandTable
.check_next:
	mov eax, [ebx]
	or eax, eax
	jz .default

	push eax
	call StringMatch
	add esp, 4
	or eax, eax
	jnz .found_it
	add ebx, 8
	jmp .check_next
.found_it:
	add ebx, 4
	mov eax, [ebx]
	call eax
.default:
	add esp, 4
	jmp .start
.done:
	freturn eax

Get:
	fprolog 0, edi
.start:
	call ScreenShowCursor
	mov edi, Buffer

.loop:
	call KeyboardGetStroke

.check_special:
	cmp ah, 0x00
	jne .special

.printable:
	cmp edi, end ; if buffer is full
	je .loop ; ignore keypress

	push eax
	call ScreenPrintChar
	pop eax ; smaller than add esp, 4
	call ScreenShowCursor
	stosb
	jmp .loop

.special:
	cmp ah, 0x01 ; Ignore ctrl-, alt- and errors.
	jne .loop

.check_esc:
	cmp al, 0x00 ; Escape
	jne .not_esc
.do_esc:
	cmp edi, Buffer
	je .loop

	call ScreenDelete
	call ScreenShowCursor
	dec edi
	jmp .do_esc
.not_esc:

.check_bksp:
	cmp al, 0x10 ; Backspace
	jne .not_bksp
.do_bksp:
	cmp edi, Buffer ; if at the beginning of the buffer
	je .loop   ; ignore

	call ScreenDelete
	call ScreenShowCursor
	dec edi
	jmp .loop
.not_bksp:

.check_enter:
	cmp al, 0x12 ; Enter
	jne .not_enter
.do_enter:
	mov al, 0
	stosb
	call ScreenBreakLine
	jmp .done
.not_enter:

.else:
	jmp .loop ; Ignore all other keystrokes

.done:
	mov eax, Buffer
	freturn edi


CommandStub:
	ret

