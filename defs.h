/* defs.h - MemTest-86 assembler/compiler definitions
 *
 * Released under version 2 of the Gnu Public License.
 * By Chris Brady, cbrady@sgi.com
 */


//#define	__2HD_144__	1


#ifdef __2HD_144__
#define SETUPSECS	4		/* Number of setup sectors */
#else
#define SETUPSECS	2		/* Number of setup sectors */
#endif

/*
 * Caution!! There is magic in the build process.  Read
 * README.build-process before you change anything.
 * Unlike earlier versions all of the settings are in defs.h
 * so the build process should be more robust.
 */
#define LOW_TEST_ADR	0x00002000		/* Final adrs for test code */

#ifdef __2HD_144__
#define BOOTSEG		0x1FE0			/* Segment adrs PC-98 1.44 */
#else
#define BOOTSEG		0x1FC0			/* Segment adrs PC-98 1.25 */
#endif
#define INITSEG		0x9000			/* Segment adrs for relocated boot */
#define SETUPSEG	(INITSEG+0x20)		/* Segment adrs for relocated setup */
#define TSTLOAD		0x1000			/* Segment adrs for load of test */

#define KERNEL_CS	0x10			/* 32 bit segment adrs for code */
#define KERNEL_DS	0x18			/* 32 bit segment adrs for data */
#define REAL_CS		0x20			/* 16 bit segment adrs for code */
#define REAL_DS		0x28			/* 16 bit segment adrs for data */
