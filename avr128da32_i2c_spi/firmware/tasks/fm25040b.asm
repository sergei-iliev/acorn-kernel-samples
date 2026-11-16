
/*
FM25040B 4Kbit SPI FRAM, 512 x 8, on SPI0 (tasks/spi0.asm).
PA4 MOSI -> SI, PA5 MISO <- SO, PA6 SCK.
Chip 0 /S = PA7. Chip 1 /S = PA3.
Mode 0, MSB first. /WP and /HOLD stay tied high on the device.
*/
.include "tasks/spi0.asm"

#define FM25040_WREN	0x06
#define FM25040_WRSR	0x01
#define FM25040_WRITE	0x02
#define FM25040_READ	0x03

/***************************init FM25040B************************
Init SPI0 channel. /CS is left high.
**************************************************************/
fm25040_init:
	rcall spi0_init
	;CS on PORTC.0
	sbi VPORTC_DIR,PIN0

	;/CS idle high. SO is Hi-Z while /S is high.
	sbi VPORTC_OUT,PIN0
	rcall fm25040_unprotect

	;CS on PORTA.3
	;lds temp,PORTA_DIR
	;sbr temp,(1<<PIN3)
	;sts PORTA_DIR,temp
	;lds temp,PORTA_OUT
	;sbr temp,(1<<PIN3)	;chip 1 /S idle high
	;sts PORTA_OUT,temp
ret

/**************************SELECT FM25040B /CS*************************
;r2 is the chip number. One /S goes low.
;  0 = PA7
;  1 = PA3
;@INPUT: r2 - chip number
;@USAGE: temp
*****************************************************************/
fm25040_select:
;	mov temp,r2
;	cpi temp,0
;	breq fm25040_sel_0
;	cpi temp,1
;	breq fm25040_sel_1
;ret
;fm25040_sel_0:
	cbi VPORTC_OUT,PIN0
;ret
;fm25040_sel_1:
;	cbi VPORTA_OUT,PIN3
ret

/**************************RELEASE FM25040B /CS*************************
;PC0 and PA3 high. Rising /S commits a FM25040B write.
*****************************************************************/
fm25040_deselect:
	sbi VPORTC_OUT,PIN0
;	sbi VPORTA_OUT,PIN3
ret

/**************************CLEAR BLOCK PROTECT*************************
;BP1,BP0 are nonvolatile. BP1 = 1 protects 0x100-0x1FF, so addresses
;above 255 ignore writes and a later read returns the old byte.
;WRSR 0x00 clears BP1 and BP0. /WP must be high.
;@USAGE: argument
*****************************************************************/
fm25040_unprotect:
	rcall fm25040_select
	ldi argument,FM25040_WREN
	rcall spi0_transfer
	rcall fm25040_deselect

	rcall fm25040_select
	ldi argument,FM25040_WRSR
	rcall spi0_transfer
	ldi argument,0x00
	rcall spi0_transfer
	rcall fm25040_deselect
ret

/***************************write FM25040B byte************************
WREN, then WRITE. A8 is bit 3 of the opcode. A7-A0 follow.
The byte is stored on rising /S. There is no write-cycle wait.
@INPUT: r2 - chip number. 0 = PA7 , 1 = PA3
        r8 - address A7-A0
        r9 - address A8 in bit 0
        argument - data
@USAGE: argument, temp, axl
@OUTPUT: T flag set
*************************************************************/
fm25040_write_byte:
	mov axl,argument

	rcall fm25040_select
	ldi argument,FM25040_WREN
	rcall spi0_transfer
	rcall fm25040_deselect

	rcall fm25040_select
	mov temp,r9
	andi temp,0x01
	lsl temp
	lsl temp
	lsl temp
	ori temp,FM25040_WRITE
	mov argument,temp
	rcall spi0_transfer

	mov argument,r8
	rcall spi0_transfer

	mov argument,axl
	rcall spi0_transfer
	rcall fm25040_deselect
	set
ret

/***************************read FM25040B byte************************
READ opcode, then A7-A0. One dummy clock returns the stored byte.
@INPUT: r2 - chip number. 0 = PA7 , 1 = PA3
        r8 - address A7-A0
        r9 - address A8 in bit 0
@USAGE: argument, temp
@OUTPUT: axl - data
         T flag set
*************************************************************/
fm25040_read_byte:
	rcall fm25040_select
	mov temp,r9
	andi temp,0x01
	lsl temp
	lsl temp
	lsl temp
	ori temp,FM25040_READ
	mov argument,temp
	rcall spi0_transfer

	mov argument,r8
	rcall spi0_transfer

	ldi argument,0x00
	rcall spi0_transfer
	mov axl,argument
	rcall fm25040_deselect
	set
ret

/***************************write FM25040B buffer************************
One /S-low burst. The chip increments the address and wraps 0x1FF to 0.
@INPUT: r2 - chip number
        X  - FRAM address (XL = A7-A0, XH bit 0 = A8)
        Z  - RAM buffer
        axl, axh - byte count
@USAGE: argument, temp, axl, axh, X, Z
@OUTPUT: T flag set
*************************************************************/
fm25040_write_buffer:
	CPI16 axl,axh,temp,0
	breq fm25040_wbuf_ok

	rcall fm25040_select
	ldi argument,FM25040_WREN
	rcall spi0_transfer
	rcall fm25040_deselect

	rcall fm25040_select
	mov temp,XH
	andi temp,0x01
	lsl temp
	lsl temp
	lsl temp
	ori temp,FM25040_WRITE
	mov argument,temp
	rcall spi0_transfer
	mov argument,XL
	rcall spi0_transfer

fm25040_wbuf_byte:
	ld argument,Z+
	rcall spi0_transfer
	DEC16 axl,axh
	brne fm25040_wbuf_byte

	rcall fm25040_deselect
fm25040_wbuf_ok:
	set
ret

/***************************read FM25040B buffer************************
One /S-low burst. Each stored byte is clocked in with a dummy 0x00.
@INPUT: r2 - chip number
        X  - FRAM address (XL = A7-A0, XH bit 0 = A8)
        Z  - RAM buffer
        axl, axh - byte count
@USAGE: argument, temp, axl, axh, X, Z
@OUTPUT: T flag set
*************************************************************/
fm25040_read_buffer:
	CPI16 axl,axh,temp,0
	breq fm25040_rbuf_ok

	rcall fm25040_select
	mov temp,XH
	andi temp,0x01
	lsl temp
	lsl temp
	lsl temp
	ori temp,FM25040_READ
	mov argument,temp
	rcall spi0_transfer
	mov argument,XL
	rcall spi0_transfer

fm25040_rbuf_byte:
	ldi argument,0x00
	rcall spi0_transfer
	st Z+,argument
	DEC16 axl,axh
	brne fm25040_rbuf_byte

	rcall fm25040_deselect
fm25040_rbuf_ok:
	set
ret
