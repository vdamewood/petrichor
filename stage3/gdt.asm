; gdt.asm: Copy of Global Descriptor Table
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

section .data

global GdtPointer
GdtPointer:
limit: dw 23
base:  dd GdtTable

GdtTable:
.null:
	times 8 db 0

GdtSysCode:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0x9A   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

GdtSysData:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0x92   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

GdtUserCode:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0xFA   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base

GdtUserData:
.limit_low:   dw 0xFFFF ; lower 16 bits of limit
.base_low:    dw 0x0000 ; Low 16 bits of the base
.base_middle: db 0x00   ; Next 8 bytes of the base.
.access       db 0xF2   ; Access flags, ring, etc
.granularity  db 0xCF   ; Example code set all to 0xCF
.base_high    db 0x00   ; highest 0 bits of base
