/* floppy.c: Floppy disk interface
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

#include "x86asm.h"

void scrPrint(char *);
void scrPrintLine(char *);

void scrPrintHexByte();
void scrPrintChar(char);
void scrBreakLine();

static void InitDma(void);
static void ReadDma(void);
static void WriteDma(void);

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

void *fdGetBuffer(void)
{
	return (void*)0x1000;
}

// IRQ

static volatile char interrupt = 0x00;
void fdHandleInterrupt(void)
{
	scrPrintLine("Floppy: IRQ6 emitted");
	interrupt = 0xFF;
}

static void ResetInterrupt(void)
{
	scrPrintLine("Floppy: IRQ6 resetting");
	interrupt = 0x00;
}

static int WaitForInterrupt(int timeout)
{
	scrPrintLine("Floppy: IRQ6 waiting");
	int i = 0;

	while (!interrupt)
		if (timeout)
			if (++i == timeout)
			{
				scrPrintLine("Floppy: IRQ6 timeout");
				return 0;
			}
	scrPrintLine("Floppy: IRQ6 detected");
	return 1;
}

static void ResetController(void)
{
	scrPrintLine("Floppy: Resetting Controller");
	unsigned char byte = inb(DOR);
	outb(DOR, byte & (~RESET));
	outb(DOR, byte);
}

// Send/Receive

static int SendByte(unsigned char signal)
{
	int timeout = 0x8000; // FIXME: use a time-based method to timeout
	while ((inb(MSR) & 0xC0) != 0x80)
		if (--timeout == 0)
			return 0;

	outb(FIFO, signal);
	return -1;
}

// Reccomended by datasheet
static int ReadByte(unsigned char *signal)
{

	int timeout = 0x8000; // FIXME: use a time-based method to timeout
	while ((inb(MSR) & 0xC0) != 0xC0)
		if (--timeout == 0)
			return 0;

	char c = inb(FIFO);
	if (signal) *signal = c;
	return -1;
}

// Suggested routines

static void Initialize(void)
{
	InitDma();
	ResetInterrupt();
	ResetController();
	outb(CCR, 0x00);
	WaitForInterrupt(0);
	for (int i = 0; i < 4; i++)
	{
		SendByte(SENSE_INTERRUPT_STATUS);
		ReadByte(0);
		ReadByte(0);
	}

	// FIXME: The datasheet says:
	// if (Parameters are different from default)
	// {
	//    issue configure command
	// }

	SendByte(SPECIFY);
	SendByte(0x80);
	SendByte(0x8A);
}

static int Seek(unsigned char cylinder)
{
	outb(DOR, ENABLE_0);
	ResetInterrupt();

	SendByte(SEEK);
	SendByte(0x00);
	SendByte(0x00);
	WaitForInterrupt(0);

	unsigned char ST0, PCN;
	SendByte(SENSE_INTERRUPT_STATUS);
	ReadByte(&ST0);
	ReadByte(&PCN);

	return (ST0 != 0x80);
}

static int Recalibrate(void)
{
	outb(DOR, ENABLE_0);
	ResetInterrupt();

	SendByte(RECALIBRATE);
	SendByte(0x00);
	WaitForInterrupt(0);

	unsigned char ST0, PCN;
	SendByte(SENSE_INTERRUPT_STATUS);
	ReadByte(&ST0);
	ReadByte(&PCN);

	return (ST0 != 0x80);
}

static int Read(void)
{
	outb(DOR, ENABLE_0);
	outb(CCR, 0x00);

	for (int seeks = 3; seeks > 0; seeks--)
	{
		scrPrintLine("Seeking...");
		Seek(0);

		// FIXME: Datasheet says ensure motor has been running for 500 ms

		for (int tries = 3; tries > 0; tries--)
		{
			ReadDma();

			scrPrintLine("Trying to read...");
			ResetInterrupt();
			SendByte(READ_DATA);
			SendByte(0x00);
			SendByte(0x00);
			SendByte(0x00);
			SendByte(0x01);
			SendByte(0x02);
			SendByte(0x01);
			SendByte(0x1B);
			SendByte(0xFF);
			if (!WaitForInterrupt(20000))
			{
				outb(DOR, RESET|DMA_GATE);
				return 0;
			}

			unsigned char result[7];
			for (int i = 0; i < 7; i++)
			{
				ReadByte(&result[i]);
				scrPrintHexByte(result[i]);
				scrPrintChar(' ');
			}
			scrBreakLine();
			// At this point result has these bytes:
			//ST0 ST1 ST2 Cyl Head Sector sector-size

			if((result[0] & 0xC0) == 0)
			{
				outb(DOR, RESET|DMA_GATE);
				return -1;
			}
		}
		Recalibrate();
	}

	outb(DOR, RESET|DMA_GATE);
	return 0;
}


void fdInit(void)
{
	Initialize();
}


void fdRead(void)
{
	Read();
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
