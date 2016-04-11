/* fat12.c: FAT12 interface
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

#include "fat12.h"
#include "screen.h"

#define AttrReadOnly  0x01
#define AttrHidden    0x02
#define AttrSystem    0x04
#define AttrVolume    0x08
#define AttrDirectory 0x10
#define AttrArchive   0x20

struct BootBlock
{
	char skip[3];
	char OemId[8];
	uint16_t BytesPerSector;
	uint8_t SectorsPerCluster;
	uint16_t ReservedSectorCount;
	uint8_t FatCount;
	uint16_t RootEntryCount;
	uint16_t SectorCount16;
	uint8_t MediaDescriptor;
	uint16_t FatSize16;
	uint16_t SectorsPerTrack;
	uint16_t HeadCount;
	uint32_t HiddenSectors;
	uint32_t SectorCount32;
	uint8_t DriveNumber;
	uint8_t Reserved;
	uint8_t BootSignature;
	uint32_t VolumeId;
	char VolumeLabel[11];
	char FsType[8];
} __attribute__((__packed__));

struct DirectoryEntry
{
	char     Name[11];
	uint8_t  Attr;
	uint8_t  NtRes;
	uint8_t  CrtTimeTenth;
	uint16_t CrtTime;
	uint16_t CrtDate;
	uint16_t AccessDate;
	uint16_t ClusterHi;
	uint16_t ModTime;
	uint16_t ModDate;
	uint16_t ClusterLo;
	uint32_t FileSize;

} __attribute__((__packed__));

#define BlockBuffer     0x30000
#define DirectoryBuffer 0x30200

void ShowDirectory(drvStorageDevice *device, const char*directory)
{
	device->ReadSectors(device->Driver.State, 0, 1, (void*)BlockBuffer);
	struct BootBlock *block = (void*)BlockBuffer;

	int root_sector = block->ReservedSectorCount + block->FatSize16 * block->FatCount;
	device->ReadSectors(device->Driver.State, root_sector, 1, (void*)DirectoryBuffer);

	for(struct DirectoryEntry *dir = (void*)DirectoryBuffer;
		dir->Name[0] != 0;
		dir++)
	{
		if (dir->Name[0] == -27 || (dir->Attr&0x08))
			continue;

		uint8_t oldColor = scrCacheColor();

		if (dir->Attr & AttrDirectory)
			scrSetColor(scrBlue);
		else if (dir->Attr & (AttrSystem|AttrHidden))
			scrSetColor(scrRed);

		scrPrintN(11,dir->Name);
		scrPrintChar(' ');
		scrPrintHexByte(dir->Attr);
		scrPrintChar(' ');
		scrPrintHexDWord(dir->FileSize);
		scrSetColor(oldColor);
		scrBreakLine();
	}
}

void LoadFile()
{

}