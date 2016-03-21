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
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

int blMemCmp(const void*, const void*, unsigned int);
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

struct FacpSdt
{
	SdtHeader header;
	char padding[64-36]; // I'm lazy
	int port;

} __attribute__ ((__packed__));
typedef struct FacpSdt FacpSdt;

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


static Rsdp *GetPointer(void)
{
	if (!PointerLocation)
		for (unsigned int ecx = 0x000E0000; ecx < 0x00100000; ecx+=0x10)
			if (blMemCmp((void*)ecx, PointerSignature, 8) == 0)
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

static void ShowSdtHeader(SdtHeader *header)
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

void AcpiShowTables(void)
{
	Rsdp *p = GetPointer();
	if(p)
	{
		ScreenPrintLine(TableHeader);
		ShowSdtHeader((SdtHeader *)p->rootSdt);

		unsigned int size = (p->rootSdt->header.length - sizeof(SdtHeader)) / sizeof(SdtHeader*);
		for (int i = 0; i < size; i++)
			ShowSdtHeader(p->rootSdt->tables[i]);
	}
	else
	{
		ScreenPrintLine(PointerError);
	}
}

static FacpSdt *FindFacp(void)
{
	Rsdp *p = GetPointer();
	if (p)
	{
		unsigned int size = (p->rootSdt->header.length - sizeof(SdtHeader)) / sizeof(SdtHeader*);
		for (int i = 0; i < size; i++)
			if (blMemCmp(p->rootSdt->tables[i]->signature, FacpSignature, 4) == 0)
				return (FacpSdt*)p->rootSdt->tables[i];
	}
	return (FacpSdt*)0;
}

static unsigned int GetShutdownPort(void)
{
	FacpSdt *p = FindFacp();
	if (p)
		return p->port;
	else
		return 0;
}

void AcpiShowHeaders(void)
{
	AcpiShowRsdp();
	ScreenBreakLine();
	AcpiShowTables();
}

void AcpiShutdown(void)
{
	unsigned int port = GetShutdownPort();
	if (port)
		asm volatile ( "outw %0, %1" : : "a"((unsigned short)0x2000), "d"((unsigned short)port) );
	else
		ScreenPrintLine(ShutdownFailed);
}