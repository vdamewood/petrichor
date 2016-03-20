; acpi.asm: ACPI interface code
;
; Copyright 2016 Vincent Damewood
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

extern Compare
extern ScreenPrintLine

; Should be local, but isn't
extern GetPointer
extern ShowSdtHeader

section .data

TableHeader:       db "Addr     Sig  Length   Rv Ch OEM    OEM Tbl  OEMRev   Crtr CrtrRev", 0
PointerError:      db "Error: RSDP not found", 0
ShutdownFailed:    db 'Error: Shutdown failed.', 0
FacpSignature      db "FACP"

section .text

global AcpiShowTables
AcpiShowTables:
	fprolog 0, eax, ecx, ebx
	call GetPointer
	or eax, eax
	jnz .exists
	push PointerError
	call ScreenPrintLine
	add esp, 4
	jmp .done

.exists:
	push TableHeader
	call ScreenPrintLine
	add esp, 4

	mov ebx, [eax+16]

	push ecx
	push ebx
	call ShowSdtHeader
	pop ebx
	pop ecx

	mov ecx, [ebx+4]
	sub ecx, 36
	shr ecx, 2
	mov esi, ebx
	add esi, 36

.loop:
	lodsd
	push ecx
	push eax
	call ShowSdtHeader
	pop eax
	pop ecx
	loop .loop

.done:
	freturn eax, ecx, ebx

FindFacp:
	fprolog 0
	call GetPointer
	or eax, eax
	jz .done ; Can't find pointer. Quit.
.exists:
	mov ebx, [eax+16]
	mov ecx, [ebx+4]
	sub ecx, 36
	shr ecx, 2
	mov esi, ebx
	add esi, 36

.loop:
	lodsd
	mov ebx, eax
	push dword 4
	push FacpSignature
	push eax
	call Compare
	add esp, 12

	or eax, eax
	jz .found
	loop .loop
.notfound:
	xor eax, eax
	jmp .done
.found:
	mov eax, ebx
.done:
	freturn

GetShutdownPort:
	fprolog 0
	call FindFacp
	or eax, eax
	jnz .exists ; FIXME
	jmp .done
.exists:
	add eax, 64
	mov eax, dword[eax]
.done:
	freturn

global AcpiShutdown
AcpiShutdown:
	fprolog 0
	call GetShutdownPort
	or eax, eax
	jz .failed
	mov dx, ax

	; FIXME: 0x2000 is hard-coded, it shouldn't be.
	mov ax, 0x2000
	out dx, ax
	jmp .done
.failed:
	push ShutdownFailed
	call ScreenPrintLine
	add esp, 4
.done:
	freturn eax, edx
