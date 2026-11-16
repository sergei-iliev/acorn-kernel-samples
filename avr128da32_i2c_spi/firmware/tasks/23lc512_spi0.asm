/*
23LC512 512Kbit SPI SRAM, 64K x 8, on SPI0 (tasks/spi0.asm).
PA4 MOSI -> SI, PA5 MISO <- SO, PA6 SCK.
Chip 0 /CS = PA7. Chip 1 /CS = PC0.
SPI mode 0 (CPOL = 0, CPHA = 0), MSB first. /HOLD stays tied high on the device.
*/
.include "tasks/spi0.asm"

#define M23LC512_SPI0_WRMR	0x01
#define M23LC512_SPI0_WRITE	0x02
#define M23LC512_SPI0_READ	0x03
#define M23LC512_SPI0_MODE_SEQUENTIAL	0x40

/***************************init 23LC512************************
Init SPI0 channel. Both /CS pins are left high.
Mode register bits 7:6 = 01, Sequential, on each chip.
**************************************************************/
m23lc512_spi0_init:
	;Chip 0 /CS = PA7. SSD in spi0_init keeps a low from forcing slave mode.
	sbi VPORTA_DIR,PIN7
	sbi VPORTA_OUT,PIN7
	
	;Chip 1 /CS = PC0
	;sbi VPORTC_DIR,PIN0
	;sbi VPORTC_OUT,PIN0

	rcall spi0_init

	;ldi temp,0
	;mov r2,temp
	rcall m23lc512_spi0_set_sequential
	;ldi temp,1
	;mov r2,temp
	;rcall m23lc512_spi0_set_sequential
ret

;@INPUT: r2 - chip number
;@USAGE: argument
m23lc512_spi0_set_sequential:
	rcall m23lc512_spi0_select
	ldi argument,M23LC512_SPI0_WRMR
	rcall spi0_transfer
	ldi argument,M23LC512_SPI0_MODE_SEQUENTIAL
	rcall spi0_transfer
	rcall m23lc512_spi0_deselect
ret

/**************************SELECT 23LC512 /CS*************************
;r2 is the chip number. One /CS goes low.
;  0 = PA7
;  1 = PC0
;@INPUT: r2 - chip number
;@USAGE: temp
*****************************************************************/
m23lc512_spi0_select:
	;mov temp,r2
	;cpi temp,0
	;breq m23lc512_spi0_sel_0
	;cpi temp,1
	;breq m23lc512_spi0_sel_1
;ret
;m23lc512_spi0_sel_0:
	cbi VPORTA_OUT,PIN7
;ret
;m23lc512_spi0_sel_1:
;	cbi VPORTC_OUT,PIN0
ret

/**************************RELEASE 23LC512 /CS*************************
;PA7 and PC0 high.
*****************************************************************/
m23lc512_spi0_deselect:
	sbi VPORTA_OUT,PIN7
	;sbi VPORTC_OUT,PIN0
ret

/***************************write 23LC512 byte************************
WRITE opcode, then A15-A8, A7-A0, then the data byte.
SRAM stores the byte on rising /CS. There is no WREN and no write-cycle wait.
@INPUT: r2 - chip number. 0 = PA7, 1 = PC0
        r8 - address A7-A0
        r9 - address A15-A8
        argument - data
@USAGE: argument, axl
@OUTPUT: T flag set
*************************************************************/
m23lc512_spi0_write_byte:
	mov axl,argument

	rcall m23lc512_spi0_select
	ldi argument,M23LC512_SPI0_WRITE
	rcall spi0_transfer
	mov argument,r9
	rcall spi0_transfer
	mov argument,r8
	rcall spi0_transfer
	mov argument,axl
	rcall spi0_transfer
	rcall m23lc512_spi0_deselect
	set
ret

/***************************read 23LC512 byte************************
READ opcode, then A15-A8, A7-A0. One dummy clock returns the stored byte.
@INPUT: r2 - chip number. 0 = PA7, 1 = PC0
        r8 - address A7-A0
        r9 - address A15-A8
@USAGE: argument
@OUTPUT: axl - data
         T flag set
*************************************************************/
m23lc512_spi0_read_byte:
	rcall m23lc512_spi0_select
	ldi argument,M23LC512_SPI0_READ
	rcall spi0_transfer
	mov argument,r9
	rcall spi0_transfer
	mov argument,r8
	rcall spi0_transfer
	ldi argument,0x00
	rcall spi0_transfer
	mov axl,argument
	rcall m23lc512_spi0_deselect
	set
ret

/***************************write 23LC512 buffer************************
Copies a RAM buffer into the SRAM. One /CS-low burst. The chip
increments the address and wraps 0xFFFF to 0.
@INPUT: r2  - chip number. 0 = PA7, 1 = PC0
        X   - SRAM address
        Z   - RAM buffer address
        axl - byte count, low
        axh - byte count, high
@USAGE: argument, temp, axl, axh, X, Z
*************************************************************/
m23lc512_spi0_write_buffer:
	CPI16 axl,axh,temp,0
	breq m23lc512_spi0_wbuf_ok

	rcall m23lc512_spi0_select
	ldi argument,M23LC512_SPI0_WRITE
	rcall spi0_transfer
	mov argument,XH
	rcall spi0_transfer
	mov argument,XL
	rcall spi0_transfer

m23lc512_spi0_wbuf_byte:
	ld argument,Z+
	rcall spi0_transfer
	DEC16 axl,axh
	brne m23lc512_spi0_wbuf_byte

	rcall m23lc512_spi0_deselect

m23lc512_spi0_wbuf_ok:
	set
ret

/***************************read 23LC512 buffer************************
Reads the SRAM into a RAM buffer. One /CS-low burst. Each stored
byte is clocked in with a dummy 0x00. The chip increments the
address and wraps 0xFFFF to 0.
@INPUT: r2  - chip number. 0 = PA7, 1 = PC0
        X   - SRAM address
        Z   - RAM buffer address
        axl - byte count, low
        axh - byte count, high
@USAGE: argument, temp, axl, axh, X, Z

*************************************************************/
m23lc512_spi0_read_buffer:
	CPI16 axl,axh,temp,0
	breq m23lc512_spi0_rbuf_ok

	rcall m23lc512_spi0_select
	ldi argument,M23LC512_SPI0_READ
	rcall spi0_transfer
	mov argument,XH
	rcall spi0_transfer
	mov argument,XL
	rcall spi0_transfer

m23lc512_spi0_rbuf_byte:
	ldi argument,0x00
	rcall spi0_transfer
	st Z+,argument
	DEC16 axl,axh
	brne m23lc512_spi0_rbuf_byte

	rcall m23lc512_spi0_deselect
m23lc512_spi0_rbuf_ok:
	set
ret
