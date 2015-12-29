[ORG 0x10800]
[BITS 32]
PMode:
	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x90000
	mov ebp, esp
.jmpy:
	hlt
	jmp .jmpy
