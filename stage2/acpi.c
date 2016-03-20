/* acpi.c: ACPI interface code
 *
 * Copyright 2016 Vincent Damewood
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES * LOSS OF USE,
 * DATA, OR PROFITS * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

int Compare(const void*, const void*, unsigned int);
void ScreenPrintHexDWord(int);
void ScreenPrintHexWord(short);
void ScreenPrintHexByte(char);
void ScreenPrintChar(char);
void ScreenPrintSpace(void);
void ScreenBreakLine(void);
void ScreenPrintLine(char*);
void ScreenPrintHexPointer(void*);

struct SdtHeader
{
	char          signature[4];
	unsigned int  length;
	unsigned char revision;
	unsigned char checksum;
	char          oem[6];
	char          oemTable[8];
	unsigned int  oemRevision;
	char          creator[4];
	unsigned int  creatorRevision;
} __attribute__ ((__packed__));
typedef struct SdtHeader SdtHeader;

struct RootSdt
{
	SdtHeader  header;
	SdtHeader *tables[];
} __attribute__ ((__packed__));
typedef struct RootSdt RootSdt;

struct Rsdp
{
	char           signature[8];
	unsigned char  checksum;
	char           vendor[6];
	unsigned char  revision;
	RootSdt       *rootSdt;
} __attribute__ ((__packed__));
typedef struct Rsdp Rsdp;

static char PointerSignature[] = "RSD PTR ";
static char PointerHeader[] =    "Addr     Sig      Ch Vendor Rv RSDTAddr";
static char TableHeader[] =      "Addr     Sig  Length   Rv Ch OEM    OEM Tbl  OEMRev   Crtr CrtrRev";
static char PointerError[] =     "Error: RSDP not found";
static char ShutdownFailed[] =   "Error: Shutdown failed.";
static char FacpSignature[] =    "FACP";
static Rsdp* PointerLocation = (void*)0;


Rsdp *GetPointer(void)
{
	if (!PointerLocation)
		for (unsigned int ecx = 0x000E0000; ecx < 0x00100000; ecx+=0x10)
			if (Compare((void*)ecx, PointerSignature, 8) == 0)
				PointerLocation = (Rsdp*)ecx;
	return PointerLocation;
}


void AcpiShowRsdp(void)
{
	Rsdp *p;
	if(!(p = GetPointer()))
	{
		ScreenPrintLine(PointerError);
		return;
	}

	ScreenPrintLine(PointerHeader);
	ScreenPrintHexPointer(p);
	ScreenPrintChar(' ');

	for (int i = 0; i < 8; i++)
		ScreenPrintChar(p->signature[i]);
	ScreenPrintChar(' ');

	ScreenPrintHexByte(p->checksum);
	ScreenPrintChar(' ');

	for (int i = 0; i < 6; i++)
		ScreenPrintChar(p->vendor[i]);
	ScreenPrintChar(' ');

	ScreenPrintHexByte(p->revision);
	ScreenPrintChar(' ');

	ScreenPrintHexPointer(p->rootSdt);
	ScreenPrintChar(' ');
	ScreenBreakLine();
}


void ShowSdtHeader(SdtHeader *header)
{
	ScreenPrintHexPointer(header);
	ScreenPrintChar(' ');

	for (int i = 0; i < 4; i++)
		ScreenPrintChar(header->signature[i]);
	ScreenPrintChar(' ');

	ScreenPrintHexDWord(header->length);
	ScreenPrintChar(' ');

	ScreenPrintHexByte(header->revision);
	ScreenPrintChar(' ');

	ScreenPrintHexByte(header->checksum);
	ScreenPrintChar(' ');

	for (int i = 0; i < 6; i++)
		ScreenPrintChar(header->oem[i]);
	ScreenPrintChar(' ');

	for (int i = 0; i < 8; i++)
		ScreenPrintChar(header->oemTable[i]);
	ScreenPrintChar(' ');

	ScreenPrintHexDWord(header->oemRevision);
	ScreenPrintChar(' ');

	for (int i = 0; i < 4; i++)
		ScreenPrintChar(header->creator[i]);
	ScreenPrintChar(' ');

	ScreenPrintHexDWord(header->creatorRevision);
	ScreenBreakLine();
}

/*
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

	push ebx
	call showSdtHeader
	pop ebx

	mov ecx, [ebx+4]
	sub ecx, 36
	shr ecx, 2
	mov esi, ebx
	add esi, 36

.loop:
	lodsd
	push eax
	call showSdtHeader
	add esp, 4
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
*/
