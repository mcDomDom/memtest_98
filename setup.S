/*
 * setup.s is responsible for getting the system data from the BIOS,
 * and putting them into the appropriate places in system memory.
 * both setup.s and system has been loaded by the bootblock.
 *
 * 1-Jan-96 Modified by Chris Brady for use as a boot/loader for memtest-86.
 */

#define __ASSEMBLY__
#include "defs.h"

.code16
.section ".setup", "ax", @progbits
.globl start
start:
# ok, the read went well
# now we want to move to protected mode ...


	cli			# no interrupts allowed #

	movb	$0xff, %al	# disable NMI for the bootup sequence
	outb	%al, $0x50


# The system will move itself to its rightful place.

	push	%cs
	pop	%ds
	lidt	idt_48 - start	# load idt with 0,0
	lgdt	gdt_48 - start	# load gdt with whatever appropriate


	movb	$0x00, %al	# A20 Line Enable
	outb	%al, $0xf2	# any value
	movb	$0x02, %al	# A20 Line Enable
	outb	%al, $0xf6

/*
 * Note that the short jump isn't strictly needed, althought there are
 * reasons why it might be a good idea. It won't hurt in any case.
 */
	movw	$0x0001, %ax	# protected mode (PE) bit
	lmsw	%ax		# This is it#
	jmp	flush_instr
flush_instr:
	movw	$KERNEL_DS, %ax
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %ss
	movw	%ax, %fs
	movw	%ax, %gs

data32	ljmp	$KERNEL_CS, $(TSTLOAD <<4)	# jmp offset 2000 of segment 0x10 (cs)


#
# Delay is needed after doing i/o
#
delay:
	.word	0x00eb			# jmp $+2
	ret

gdt:
	.word	0,0,0,0		# dummy

	.word	0,0,0,0		# unused

	.word	0x7FFF		# limit 128mb
	.word	0x0000		# base address=0
	.word	0x9A00		# code read/exec
	.word	0x00C0		# granularity=4096, 386

	.word	0x7FFF		# limit 128mb
	.word	0x0000		# base address=0
	.word	0x9200		# data read/write
	.word	0x00C0		# granularity=4096, 386

idt_48:
	.word	0			# idt limit=0
	.long	0			# idt base=0L

gdt_48:
	.word	0x800		# gdt limit=2048, 256 GDT entries
	.word	512+gdt - start,0x9	# gdt base = 0X9xxxx

msg1:
	.asciz "Setup.S\r\n"

	/* Pad setup to the proper size */
#ifdef __2HD_144__
	.org	(SETUPSECS*512)
#else
	.org	(SETUPSECS*1024)
#endif

