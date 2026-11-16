/*
23LC512 512Kbit SPI SRAM, 64K x 8, on SPI1 (tasks/spi1.asm).
PC0 MOSI -> SI, PC1 MISO <- SO, PC2 SCK, PC3 /CS.
SPI mode 0, MSB first. /HOLD stays tied high on the device.
*/
.include "tasks/spi1.asm"

#define M23LC512_SPI1_WRMR	0x01
#define M23LC512_SPI1_WRITE	0x02
#define M23LC512_SPI1_READ	0x03
#define M23LC512_SPI1_MODE_SEQUENTIAL	0x40

/***************************init 23LC512 on SPI1************************
Init SPI1 channel. /CS on PC3 is left high.
Mode register bits 7:6 = 01, Sequential.
**************************************************************/
m23lc512_spi1_init:
	;SPI1 /CS = PC3. SSD in spi1_init keeps a low from forcing slave mode.
	sbi VPORTC_DIR,PIN3
	sbi VPORTC_OUT,PIN3

	rcall spi1_init
	rcall m23lc512_spi1_set_sequential
ret

;@USAGE: argument
m23lc512_spi1_set_sequential:
	rcall m23lc512_spi1_select
	ldi argument,M23LC512_SPI1_WRMR
	rcall spi1_transfer
	ldi argument,M23LC512_SPI1_MODE_SEQUENTIAL
	rcall spi1_transfer
	rcall m23lc512_spi1_deselect
ret

/**************************SELECT 23LC512 /CS*************************
;PC3 goes low.
*****************************************************************/
m23lc512_spi1_select:
	cbi VPORTC_OUT,PIN3
ret

/**************************RELEASE 23LC512 /CS*************************
;PC3 high.
*****************************************************************/
m23lc512_spi1_deselect:
	sbi VPORTC_OUT,PIN3
ret

/***************************write 23LC512 byte************************
WRITE opcode, then A15-A8, A7-A0, then the data byte.
SRAM stores the byte on rising /CS. There is no WREN and no write-cycle wait.
@INPUT: r8 - address A7-A0
        r9 - address A15-A8
        argument - data
@USAGE: argument, axl
@OUTPUT: T flag set
*************************************************************/
m23lc512_spi1_write_byte:
	mov axl,argument

	rcall m23lc512_spi1_select
	ldi argument,M23LC512_SPI1_WRITE
	rcall spi1_transfer
	mov argument,r9
	rcall spi1_transfer
	mov argument,r8
	rcall spi1_transfer
	mov argument,axl
	rcall spi1_transfer
	rcall m23lc512_spi1_deselect
	set
ret

/***************************read 23LC512 byte************************
READ opcode, then A15-A8, A7-A0. One dummy clock returns the stored byte.
@INPUT: r8 - address A7-A0
        r9 - address A15-A8
@USAGE: argument
@OUTPUT: axl - data
         T flag set
*************************************************************/
m23lc512_spi1_read_byte:
	rcall m23lc512_spi1_select
	ldi argument,M23LC512_SPI1_READ
	rcall spi1_transfer
	mov argument,r9
	rcall spi1_transfer
	mov argument,r8
	rcall spi1_transfer
	ldi argument,0x00
	rcall spi1_transfer
	mov axl,argument
	rcall m23lc512_spi1_deselect
	set
ret

/***************************write 23LC512 buffer************************
Copies a RAM buffer into the SRAM. One /CS-low burst. The chip
increments the address and wraps 0xFFFF to 0.
@INPUT: X   - SRAM address
        Z   - RAM buffer address
        axl - byte count, low
        axh - byte count, high
@USAGE: argument, temp, axl, axh, X, Z
@OUTPUT: T flag set
*************************************************************/
m23lc512_spi1_write_buffer:
	CPI16 axl,axh,temp,0
	breq m23lc512_spi1_wbuf_ok

	rcall m23lc512_spi1_select
	ldi argument,M23LC512_SPI1_WRITE
	rcall spi1_transfer
	mov argument,XH
	rcall spi1_transfer
	mov argument,XL
	rcall spi1_transfer

m23lc512_spi1_wbuf_byte:
	ld argument,Z+
	rcall spi1_transfer
	DEC16 axl,axh
	brne m23lc512_spi1_wbuf_byte

	rcall m23lc512_spi1_deselect
m23lc512_spi1_wbuf_ok:
	set
ret

/***************************read 23LC512 buffer************************
Reads the SRAM into a RAM buffer. One /CS-low burst. Each stored
byte is clocked in with a dummy 0x00. The chip increments the
address and wraps 0xFFFF to 0.
@INPUT: X   - SRAM address
        Z   - RAM buffer address
        axl - byte count, low
        axh - byte count, high
@USAGE: argument, temp, axl, axh, X, Z
@OUTPUT: T flag set
*************************************************************/
m23lc512_spi1_read_buffer:
	CPI16 axl,axh,temp,0
	breq m23lc512_spi1_rbuf_ok

	rcall m23lc512_spi1_select
	ldi argument,M23LC512_SPI1_READ
	rcall spi1_transfer
	mov argument,XH
	rcall spi1_transfer
	mov argument,XL
	rcall spi1_transfer

m23lc512_spi1_rbuf_byte:
	ldi argument,0x00
	rcall spi1_transfer
	st Z+,argument
	DEC16 axl,axh
	brne m23lc512_spi1_rbuf_byte

	rcall m23lc512_spi1_deselect
m23lc512_spi1_rbuf_ok:
	set
ret
