/* driver.h: Driver interface
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

#ifndef DRIVER_H
#define DRIVER_H

#include <stdint.h>

struct drvDriver
{
	unsigned int Type;
	void *State; // Opaque data used by the driver. 
	int (*GetName)(void *Me, char *Buffer, int BufferSize);
		// Buffer is a buffer to store the name into
		// BufferSize is the number of characters it is safe to write
		// to, including the null terminator.
		// The return value is calculated as the number of additional
		//   characters needed to store the full 'Name' of the driver
		//   and a null terminator. If BufferSize is the exact size
		//   needed, then the return value is 0. If BufferSize is
		//   greater than the required space, then the return value
		//   is negative.
		// If BufferSize is not zero, then the string written to Buffer will
		//   be null terminated.
		// Calling this function with BufferSize = 0 will result in Buffer never
		//   being written to. Calling with Buffer=NULL and BufferSize=0 is safe.
	uint32_t (*GetVersion)(void *Me);
		// Integer in form byte[Major] byte[Minor] word[Patch], thus version 2.11.1022
		//   returns 0x020B03FE.
};

// FIXME: Add I/O streams.

struct drvStorageDevice
{
	struct drvDriver Driver;
	uint8_t (*SectorSize)(void *Me);
		// Return value is the base-2 logorithm of the size of a sector on the device
		// Common examples:
		//   512 bytes -> 9;
		//   4096 bytes -> 12
	int (*ReadSectors)(void *Me, unsigned int Start, unsigned int Length, void *Memory);
		// Start: First sector to read
		// Length: Number of sectors to read
		// Memory: Location to which to copy
};
typedef struct drvStorageDevice drvStorageDevice;


struct FileInfo
{
	char *Name;
	uint32_t Size;
};

struct drvStorageVolume
{
	struct drvDriver Driver;
	int (*GetFileList)(void *Me, struct FileInfo *Buffer, int BufferSize);
	int (*LoadFile)(void *Me, char *Filename, void *Memory);
};
typedef struct drvStorageVolume drvStorageVolume;

#endif /* DRIVER_H */