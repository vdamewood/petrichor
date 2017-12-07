/* acpi.c: ACPI interface code
 *
 * Copyright 2016 Vincent Damewood
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "acpi.h"
#include "uio.h"
#include "util.h"

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

static char PointerError[] =     "Error: RSDP not found\n";
static Rsdp* PointerLocation = (void*)0;


static Rsdp *GetPointer(void)
{
	if (!PointerLocation)
		for (unsigned int ecx = 0x000E0000; ecx < 0x00100000; ecx+=0x10)
			if (blMemCmp((void*)ecx, "RSD PTR \n", 8) == 0)
				PointerLocation = (Rsdp*)ecx;
	return PointerLocation;
}


void AcpiShowRsdp(void)
{
	Rsdp *p;
	if(!(p = GetPointer()))
	{
		uioPrint(PointerError);
		return;
	}

	uioPrint("Addr     Sig      Ch Vendor Rv RSDTAddr\n");

	uioPrintf("%p %.8s %0.2hhX %.6s %0.2hhX %p\n",
		p, p->signature, p->checksum, p->vendor, p->revision, p->rootSdt);
}

static void ShowSdtHeader(SdtHeader *header)
{
	uioPrintf("%.8p %.4s %08X %02hhX %02hhX %.6s %.8s %-8.2X %.4s %08X\n",
		header, header->signature, header->length, header->revision,
		header->checksum, header->oem, header->oemTable, header->oemRevision,
		header->creator, header->creatorRevision);
}

void AcpiShowTables(void)
{
	Rsdp *p = GetPointer();
	if(p)
	{
		uioPrint("Addr     Sig  Length   Rv Ch OEM    OEM Tbl  OEMRev   Crtr CrtrRev\n");
		ShowSdtHeader((SdtHeader *)p->rootSdt);

		unsigned int size = (p->rootSdt->header.length - sizeof(SdtHeader)) / sizeof(SdtHeader*);
		for (int i = 0; i < size; i++)
			ShowSdtHeader(p->rootSdt->tables[i]);
	}
	else
	{
		uioPrint(PointerError);
	}
}

static FacpSdt *FindFacp(void)
{
	Rsdp *p = GetPointer();
	if (p)
	{
		unsigned int size = (p->rootSdt->header.length - sizeof(SdtHeader)) / sizeof(SdtHeader*);
		for (int i = 0; i < size; i++)
			if (blMemCmp(p->rootSdt->tables[i]->signature, "FACP", 4) == 0)
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
	uioPrintChar('\n');
	AcpiShowTables();
}

void AcpiShutdown(void)
{
	unsigned int port = GetShutdownPort();
	if (port)
		asm volatile ( "outw %0, %1" : : "a"((unsigned short)0x2000), "d"((unsigned short)port) );
	else
		uioPrint("Error: Shutdown failed.\n");
}
