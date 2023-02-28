/*
 *	 bootsect.s		Copyright (C) 1991, 1992 Linus Torvalds
 *
 * bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
 * itself out of the way to address 0x90000, and jumps there.
 *
 * It then loads 'setup' directly after itself (0x90200), and the system
 * at 0x10000, using BIOS interrupts.
 *
 * The loader has been made as simple as possible, and continuos
 * read errors will result in a unbreakable loop. Reboot by hand. It
 * loads pretty fast by getting whole tracks at a time whenever possible.
 *
 * 1-Jan-96 Modified by Chris Brady for use as a boot loader for MemTest-86.
 */

#include "defs.h"

ROOT_DEV = 0

.code16
.section ".bootsect", "ax", @progbits
_boot:


# ld86 requires an entry symbol. This may as well be the usual one.
.globl	_main
_main:

	movw	$BOOTSEG, %ax
	movw	%ax, %ds
	movw	$INITSEG, %ax
	movw	%ax, %es
	movw	$256, %cx
	subw	%si, %si
	subw	%di, %di



	cld
	rep
	movsw
	ljmp	$INITSEG, $go - _boot

go:
	movw	%cs, %ax
	movw	$(0x4000-12), %dx	# 0x4000 is arbitrary value >= length of
					# bootsect + length of setup + room for stack
					# 12 is disk parm size

# bde - changed 0xff00 to 0x4000 to use debugger at 0x6400 up (bde).  We
# wouldn't have to worry about this if we checked the top of memory.  Also
# my BIOS can be configured to put the wini drive tables in high memory
# instead of in the vector table.  The old stack might have clobbered the
# drive table.

	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %ss		# put stack at INITSEG:0x4000-12.
	movw	%dx, %sp



# load the setup-sectors directly after the bootblock.
# Note that 'es' is already set up.
	
load_setup:


	#PC-98
#ifdef __2HD_144__
	movw	$0x5630, %ax	# READ DATA MultiTrack/MFM/NoRetry/Seek, 640KB FDD/1.44/#0
	movw	$0x0400, %bx	# DATA Length 1024byte=512*2sector
	movw	$0x0200, %cx	# 512B/sector, Cylinder(track):0
	movw	$0x0002, %dx	# head 0, sector 2
#else	/* 2HD 1.25MB */
	movw	$0xD690, %ax	# READ DATA MultiTrack/MFM/NoRetry/Seek, 1MB FDD/1.25/#0
	movw	$0x0400, %bx	# DATA Length 1024byte=1024*1sector
	movw	$0x0300, %cx	# 1024B/sector, Cylinder(track):0
	movw	$0x0002, %dx	# head 0, sector 2
#endif
	movw	$0x0200, %bp	# address = 512, in INITSEG
	int	$0x1B		# DISK BIOS call
	jnc	ok_load_setup			# ok - continue


#	pushw	%ax			# dump error code
#	call	print_nl
#	movw	%sp, %bp
#	call	print_hex
#	popw	%ax

	# disp error code
	shrb	$4, %ah
	orb	$0x40, %ah
	movw	$0xa004, %bx
	movw	$0x0000, %di
	movw	%bx, %es
	movb	%ah, %es:(%di)
loopx:
	jmp loopx	# halt

ok_load_setup:

# Get disk drive parameters, specifically nr of sectors/track


/* It seems that there is no BIOS call to get the number of sectors.  Guess
 * 18 sectors if sector 18 can be read, 15 if sector 15 can be read.
 * Otherwise guess 9
 */

# Print some inane message

# ok, we've written the message, now
# we want to load the system (at 0x10000)

	movw	$TSTLOAD, %ax
	movw	%ax, %es		# segment of 0x010000

	#The memtest body will be less than 192kbyte
	movw	$0x0000, %bp	# address = 0, in TSTLOAD
	movb	$0x00, %cl		# cylinder
	movb	$0x00, %dh		# head 0
#ifdef __2HD_144__
	movb	$0x06, %dl		# sector 6	0x0A00
#else
	movb	$0x03, %dl		# sector 4	0x0C00
#endif
	movw	$0x0000, %ax	# counter

read_loop:
	pushw	%ax
#ifdef __2HD_144__
	movw	$0x5630, %ax	# READ DATA MFM/NoRetry/Seek, 640KB FDD/1.44/#0
	movw	$0x0200, %bx	# DATA Length 512byte
	movb	$0x02, %ch	# 512B/sector
#else
	movw	$0xD690, %ax	# READ DATA MultiTrack/MFM/NoRetry/Seek, 1MB FDD/1.25/#0
	movw	$0x0400, %bx	# DATA Length 512byte
	movb	$0x03, %ch	# 1024B/sector
#endif
	int	$0x1B		# DISK BIOS call	
	jnc	read_ok
	# error code
	shrb	$4, %ah
	orb	$0x40, %ah
	movw	$0xa014, %bx
	movw	$0x0000, %di
	movw	%bx, %es
	movb	%ah, %es:(%di)

	# C
	movw	$0xa015, %bx
	movw	%bx, %es
	add	$0x30, %cl
	movb	%cl, %es:(%di)
	# H
	movw	$0xa016, %bx
	movw	%bx, %es
	add	$0x30, %dh
	movb	%dh, %es:(%di)
	# S
	movw	$0xa017, %bx
	movw	%bx, %es
	add	$0x30, %dl
	movb	%dl, %es:(%di)

	# segment counter
	popw	%ax
	movw	$0xa01a, %bx
	movw	%bx, %es
	add	$0x30, %ah
	movb	%ah, %es:(%di)
	# loop counter
	movw	$0xa01b, %bx
	movw	%bx, %es
	add	$0x30, %al
	movb	%al, %es:(%di)

error_hlt:
	jmp error_hlt

read_ok:
	popw	%ax
	inc	%al
	add	$1, %dl
#ifdef __2HD_144__
	cmpb	$19, %dl
#else
	cmpb	$9, %dl
#endif
	jl	check_next_seg
#ifdef __2HD_144__
	sub	$18, %dl
#else
	sub	$8, %dl
#endif
	# head 0->1 1->0	
	not	%dh
	and	$0x01, %dh	
	# if head 1->0 then next cylinder
	cmpb	$0, %dh
	jne	check_next_seg
	inc	%cl

check_next_seg:
	add	%bx, %bp
	cmpw	$0, %bp
	jne	check_read_end
	movw	%es, %bx
	add	$0x1000, %bx	# next segment
	movw	%bx, %es
	movw	$0x0000, %bp
	inc	%ah		# segment number 

check_read_end:
	cmpb	$3, %ah	/* 65536*3 */
	jle	read_loop
	

readok:

# after that (everyting loaded), we jump to
# the setup-routine loaded directly after
# the bootblock:

loop:

	ljmp	$SETUPSEG,$0


/*
 *	print_all is for debugging purposes.
 *	It will print out all of the registers.  The assumption is that this is
 *	called from a routine, with a stack frame like
 *	dx
 *	cx
 *	bx
 *	ax
 *	error
 *	ret <- sp
 *
*/
	
sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading"

.org 497
setup_sects:
	.byte SETUPSECS
.org 500
syssize:
	.word _syssize
.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55
#ifndef __2HD_144__
.org 1022	/* sector 1:bootsector 2:setup 3-:body	*/
	.word 0xFFFF
#endif
_eboot:
