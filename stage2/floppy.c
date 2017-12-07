/* floppy.c: Floppy disk interface
 *
 * Copyright 2016 Vincent Damewood
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

#include <stddef.h>
#include <stdint.h>

#include "floppy.h"
#include "timer.h"
#include "x86asm.h"

static void InitDma(void);
static void ReadDma(void);
static void WriteDma(void);

enum Drives
{
	Drive_0 = 0x00,
	Drive_1 = 0x01,
	Drive_2 = 0x10,
	Drive_3 = 0x11
};

enum Ports
{
	SRA  = 0x3F0, // R  Status Register A
	SRB  = 0x3F1, // R  Statis Register B
	DOR  = 0x3F2, // RW Digital Output Register
	TDR  = 0x3F3, // RW Tape Drive Register
	MSR  = 0x3F4, // R  Main Status Register
	DSR  = 0x3F4, //  W Data Rate Select Register
	FIFO = 0x3F5, // RW Data FIFO
	DIR  = 0x3F7, // R  Digital Input Register
	CCR  = 0x3F7  //  W Configuration Control Register
};

enum DOR_Bits
{
	MOT_EN3     = 0x80, // Motor Enable 3
	MOT_EN2     = 0x40, // Motor Enable 2
	MOT_EN1     = 0x20, // Motor Enable 1
	MOT_EN0     = 0x10, // Motor Enable 0
	DMA_GATE    = 0x08, //
	RESET       = 0x04, //
	DRIVE_SEL_3 = 0x03, //
	DRIVE_SEL_2 = 0x02, //
	DRIVE_SEL_1 = 0x01, //
	DRIVE_SEL_0 = 0x00, //
	ENABLE_0    = 0x1C, // DRIVE_SEL_0 | RESET | DMA_GATE | MOT_EN 0
	ENABLE_1    = 0x2D, // DRIVE_SEL_1 | RESET | DMA_GATE | MOT_EN 1
	ENABLE_2    = 0x4E, // DRIVE_SEL_2 | RESET | DMA_GATE | MOT_EN 2
	ENABLE_3    = 0x8F  // DRIVE_SEL_3 | RESET | DMA_GATE | MOT_EN 3
};

enum MSR_Bits
{
	RQM        = 0x80, // Indicates can transfer: 1: Yes 0: No
	DIO        = 0x40, // Direction of transfer: 1: Read; 2: Write
	NON_DMA    = 0x20,
	CMD_BSY    = 0x10,
	DRV_3_BUSY = 0x08,
	DRV_2_BUSY = 0x04,
	DRV_1_BUSY = 0x02,
	DRV_0_BUSY = 0x01
};

enum Commands
{
	READ_DATA              = 0x06,
	READ_DELETED_DATA      = 0x0C,
	WRITE_DATA             = 0x05,
	WRITE_DELETED_DATA     = 0x09,
	READ_TRACK             = 0x02,
	VERIFY                 = 0x16,
	VERSION                = 0x10,
	FORMAT_TRACK           = 0x0D,
	SCAN_EQUAL             = 0x11,
	SCAN_LOW_OR_EQUAL      = 0x19,
	SCAN_HIGH_OR_EQUAL     = 0x1D,
	RECALIBRATE            = 0x07,
	SENSE_INTERRUPT_STATUS = 0x08,
	SPECIFY                = 0x03,
	SENSE_DRIVE_STATUS     = 0x04,
	SEEK                   = 0x0F,
	CONFIGURE              = 0x13,
	RELATIVE_SEEK          = 0x8F,
	DUMPREG                = 0x0E,
	READ_ID                = 0x0A,
	PERPENDICULAR_MODE     = 0x12,
	LOCK                   = 0x14
};

enum CommandParameters
{
	MT                     = 0x80, // Multi Track; OR into Read/Write
	MFT                    = 0x40, // Double Density; OR into Read/Write
	SK                     = 0x20  // Skip; OR into Read
};

static char Initialized = 0x00;

void *fdGetBuffer(void)
{
	return (void*)0x1000;
}

static volatile char interrupt = 0x00;
void fdHandleInterrupt(void)
{
	interrupt = 0xFF;
}

static void ResetInterrupt(void)
{
	interrupt = 0x00;
}

static int WaitForInterrupt(int timeout)
{
	int i = 0;
	while (!interrupt)
	{
		tmrWait(1);
		if (timeout && (++i == timeout))
			return 0;
	}
	return -1;
}

static void ResetController(void)
{
	unsigned char byte = inb(DOR);
	outb(DOR, byte & (~RESET));
	outb(DOR, byte);
}

static int SendByte(unsigned char signal)
{
	int timeout = 0x500;
	while ((inb(MSR) & 0xC0) != 0x80)
	{
		if (--timeout == 0)
			return 0;
		tmrWait(1);
	}

	outb(FIFO, signal);
	return -1;
}

static int ReadByte(unsigned char *signal)
{

	int timeout = 0x500;
	while ((inb(MSR) & 0xC0) != 0xC0)
	{
		if (--timeout == 0)
			return 0;
		tmrWait(1);
	}

	char c = inb(FIFO);
	if (signal) *signal = c;
	return -1;
}

static void EnableDrive(unsigned char drive)
{
	outb(DOR, drive | RESET | DMA_GATE | (0x10 << drive));
}

static void DisableDrive(unsigned char drive)
{
	outb(DOR, RESET | DMA_GATE);
}

static int Specify(uint8_t srt, uint8_t hut, uint8_t hlt, uint8_t nd);
static int SenseInterruptStatus(uint8_t *result);
static int Seek(uint8_t drive, uint8_t head, uint8_t cyl);
static int Recalibrate(uint8_t drive);

static int Specify(uint8_t srt, uint8_t hut, uint8_t hlt, uint8_t nd)
{
	return SendByte(SPECIFY)
		&& SendByte(srt<<4 | (hut & 0x0F))
		&& SendByte(hlt<<1 | (nd & 0x01));
}

static int SenseInterruptStatus(uint8_t *result)
{
	return SendByte(SENSE_INTERRUPT_STATUS)
		&& ReadByte(result ? result + 0 : NULL)
		&& ReadByte(result ? result + 1 : NULL);
}

static int Seek(uint8_t drive, uint8_t head, uint8_t cyl)
{
	EnableDrive(drive);
	ResetInterrupt();

	if (!(SendByte(SEEK)
		&& SendByte((head & 0x01) << 2 | (drive & 0x03))
		&& SendByte(cyl)))
	{
		return 0;
	}
	WaitForInterrupt(500);

	unsigned char result[2];
	if (!SenseInterruptStatus(result))
		return 0;

	return result[0] != 0x80;
}

static int Recalibrate(uint8_t drive)
{
	EnableDrive(drive);
	ResetInterrupt();

	if (!(SendByte(RECALIBRATE)
		&& SendByte(drive & 0x03)))
	{
		return 0;
	}
	WaitForInterrupt(500);

	unsigned char result[2];
	if (!SenseInterruptStatus(result))
		return 0;

	return result[0] != 0x80;
}

static int ReadData(uint8_t drive, uint8_t cyl, uint8_t head, uint8_t sector, uint8_t length)
{
	EnableDrive(drive);
	outb(CCR, 0x00); // Set Data Rate to 1M

	for (int seeks = 3; seeks > 0; seeks--)
	{
		Seek(drive, head, cyl);

		tmrWait(500);

		for (int tries = 3; tries > 0; tries--)
		{
			ReadDma();

			ResetInterrupt();
			if (!(SendByte(READ_DATA | MFT)
				&& SendByte((head&1) << 2 | (drive&3))
				&& SendByte(cyl)
				&& SendByte(head)
				&& SendByte(sector)
				&& SendByte(0x02) // sector size
				&& SendByte(length)
				&& SendByte(0x1B) // Gap Length
				&& SendByte(0xFF))) // data length; Always 0xFF when Sector Size != 128 bytes
			{
				continue;
			}
			WaitForInterrupt(1000);

			unsigned char result[7];
			for (int i = 0; i < 7; i++)
				ReadByte(&result[i]);

			// At this point result has these bytes:
			//ST0 ST1 ST2 Cyl Head Sector sector-size
			if((result[0] & 0xC0) == 0)
			{
				DisableDrive(drive);
				return -1;
			}
		}
		Recalibrate(drive);
	}

	DisableDrive(drive);
	return 0;
}

static int Initialize(void)
{
	InitDma();
	ResetInterrupt();
	ResetController();

	outb(CCR, 0x00); // Set Data Rate to 1M

	if (!WaitForInterrupt(1000))
		return 0;

	for (int i = 0; i < 4; i++)
		if (!SenseInterruptStatus(NULL))
			return 0;

	if (!Specify(0x08, 0x00, 0x45, 0x00))
		return 0;

	Initialized = 0xFF;
	return -1;
}

struct fdState
{
	uint16_t controller;
	enum Drives drive;
};

static struct fdState singleton =
{
	0x3F0,
	Drive_0
};

static char driverName[] = "FLOPPY DISK::82077AA";

static int fdGetName(void *VoidMe, char *Buffer, int BufferSize)
{
	int i = 0;
	for (; driverName[i] != 0 && i < BufferSize-1; i++)
		Buffer[i] = driverName[i];
	if (BufferSize != 0)
		Buffer[i++] = '\0';
	return sizeof(driverName) - (int)BufferSize;
}

static uint32_t fdGetVersion(void *VoidMe)
{
	return 0x00000000;
}

static uint8_t fdSectorSize(void *VoidMe)
{
	return 9; // 2^9 = 512 bytes
}

static void chs(uint16_t LinearSector, unsigned char *values)
{
	values[2] = LinearSector / (2*18);
	LinearSector %= (2*18);
	values[1] = LinearSector / (18);
	LinearSector %= (18);
	values[0] = LinearSector + 1;
}

static int fdReadSectors(void *VoidMe, unsigned int Start, unsigned int Length, void *Memory)
{
	if (Start + Length > 2880)
		return 0;
	//ReadData(uint8_t drive, uint8_t cyl, uint8_t head, uint8_t sector, uint8_t length)
	struct fdState *Me = (struct fdState*)VoidMe;

	unsigned char secinfo[3];
	chs(Start, secinfo);

	// FIXME: Read across cylinder boundaries
	ReadData(Me->drive, secinfo[2], secinfo[1], secinfo[0], Length);
	rep_movsb(fdGetBuffer(), Memory, Length<<9);
	return -1;

}

drvStorageDevice fdGetDriver(void)
{
	if (!Initialized)
		Initialize();

	// FIXME: Make this function take an input indicating which drive
	// Save that value in the status structure
	struct drvStorageDevice rVal = {{0, &singleton, fdGetName,fdGetVersion}, fdSectorSize, fdReadSectors};
	return rVal;
}

static void InitDma(void)
{
	outb(0x0a, 0x06);
    outb(0x0c, 0xFF);
    outb(0x04, 0x00);
    outb(0x04, 0x10);
    outb(0x0c, 0xFF);
    outb(0x05, 0xFF);
    outb(0x05, 0x23);
    outb(0x81, 0x00);
    outb(0x0a, 0x02);
}

static void WriteDma(void)
{
    outb(0x0a, 0x06);
    outb(0x0b, 0x5A);
    outb(0x0a, 0x02);
}

static void ReadDma(void)
{
    outb(0x0a, 0x06);
    outb(0x0b, 0x56);
    outb(0x0a, 0x02);
}
