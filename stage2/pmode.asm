[ORG 0x10800]

PMode:
	mov eax, 0xFEEDFACE
	mov ecx, 0xF00DD00D
	mov edx, 0xBAADBEEF
.jmpy:
	hlt
	jmp .jmpy