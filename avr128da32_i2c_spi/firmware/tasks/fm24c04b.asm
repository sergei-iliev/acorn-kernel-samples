/*
FM24C04B 4Kbit FRAM, 512 x 8, on TWI1 (tasks/twi1.asm).
r2 is the 7-bit slave address with A8 clear.
  A2=A1=0 -> r2=0x50   0x000-0x0FF = 0xA0/0xA1, 0x100-0x1FF = 0xA2/0xA3
  A2=A1=1 -> r2=0x56   0x000-0x0FF = 0xAC/0xAD, 0x100-0x1FF = 0xAE/0xAF
The driver shifts r2 left one bit and inserts A8. The word address is A7-A0.
FRAM commits on STOP. There is no write-cycle wait.
*/
.include "tasks/twi1.asm"

;if A2 and A1 are connected to GND
#define FM24C04_ADDRESS_00 0x50
;if A2 and A1 are connected to VCC
#define FM24C04_ADDRESS_11 0x56

/***************************init FM24C04B************************
Init TWI1 channel
**************************************************************/
fm24c04_init:
	rcall twi1_init
ret

/***************************write FM24C04B byte************************
@INPUT: r2  - 7-bit I2C address, A8 clear
        r8  - address A7-A0
        r9  - address A8 in bit 0
        argument - data
@USAGE: argument, temp, axl
@OUTPUT: T flag 1 - success, 0 - failure
*************************************************************/
fm24c04_write_byte:
	mov axl,argument
	mov temp,r9
	mov argument,r2
	lsl argument
	andi temp,0x01
	lsl temp
	or argument,temp
	rcall twi1_send_addr
	cpi argument,I2C_ACK
	brne fm24c04_wr00

	mov argument,r8
	rcall twi1_send_byte
	cpi argument,I2C_ACK
	brne fm24c04_wr00

	mov argument,axl
	rcall twi1_send_byte
	cpi argument,I2C_ACK
	brne fm24c04_wr00

	rcall twi1_send_stop
	set
ret
fm24c04_wr00:
	rcall twi1_send_stop
	clt
ret

/***************************read FM24C04B byte************************
Random read. The data byte is NACKed.
@INPUT: r2  - 7-bit I2C address, A8 clear
        r8  - address A7-A0
        r9  - address A8 in bit 0
@USAGE: argument, temp, axl
@OUTPUT: axl - data
         T flag 1 - success, 0 - failure
*************************************************************/
fm24c04_read_byte:
	mov temp,r9
	mov argument,r2
	lsl argument
	andi temp,0x01
	lsl temp
	or argument,temp
	rcall twi1_send_addr
	cpi argument,I2C_ACK
	brne fm24c04_rd00

	mov argument,r8
	rcall twi1_send_byte
	cpi argument,I2C_ACK
	brne fm24c04_rd00

	mov temp,r9
	mov argument,r2
	lsl argument
	andi temp,0x01
	lsl temp
	or argument,temp
	ori argument,0x01
	rcall twi1_send_addr
	cpi argument,I2C_ACK
	brne fm24c04_rd00

	rcall twi1_read_byte
	cpi argument,I2C_READY
	brne fm24c04_rd00

	rcall twi1_send_nack_stop
	set
ret
fm24c04_rd00:
	rcall twi1_send_stop
	clt
ret

/***************************write FM24C04B buffer************************
Copies a RAM buffer into the FRAM. Each byte is loaded into argument
and sent with twi1_send_byte. A sequential write stays inside one
256-byte half. Crossing 0x100 or 0x1FF starts a new transaction so A8
tracks the address. Past 511 the address rolls over to 0.
16-bit address and size use kernel/math.inc.
@INPUT: r2  - 7-bit I2C address, A8 clear
        X   - target address (XL = A7-A0, XH bit 0 = A8)
        Z   - RAM buffer address
        axl - byte count, low
        axh - byte count, high
@USAGE: argument, temp, axl, axh, X, Z
@OUTPUT: T flag 1 - success, 0 - failure
*************************************************************/
fm24c04_write_buffer:
	CPI16 axl,axh,temp,0
	breq fm24c04_wbuf_ok

fm24c04_wbuf_blk:
	mov temp,XH
	mov argument,r2
	lsl argument
	andi temp,0x01
	lsl temp
	or argument,temp
	rcall twi1_send_addr
	cpi argument,I2C_ACK
	brne fm24c04_wbuf_err

	mov argument,XL
	rcall twi1_send_byte
	cpi argument,I2C_ACK
	brne fm24c04_wbuf_err

fm24c04_wbuf_byte:
	ld argument,Z+
	rcall twi1_send_byte
	cpi argument,I2C_ACK
	brne fm24c04_wbuf_err

	DEC16 axl,axh
	breq fm24c04_wbuf_stop

	ADDI16 XL,XH,1
	CPI16 XL,XH,temp,512	;max FRAM size
	brne fm24c04_wbuf_wrap
	LDI16 XL,XH,0

fm24c04_wbuf_wrap:
	cpi XL,0
	brne fm24c04_wbuf_byte

	rcall twi1_send_stop
	rjmp fm24c04_wbuf_blk

fm24c04_wbuf_stop:
	rcall twi1_send_stop
fm24c04_wbuf_ok:
	set
ret
fm24c04_wbuf_err:
	rcall twi1_send_stop
	clt
ret

/***************************read FM24C04B buffer************************
Reads the FRAM into a RAM buffer. twi1_read_byte returns each
data byte in axl. A sequential read stays
inside one 256-byte half. Crossing 0x100 or 0x1FF starts a new
transaction so A8 tracks the address. Past 511 the address rolls over
to 0. The last byte of each transaction is NACKed.
16-bit address and size use kernel/math.inc.
@INPUT: r2  - 7-bit I2C address, A8 clear
        X   - target address (XL = A7-A0, XH bit 0 = A8)
        Z   - RAM buffer address
        axl - byte count, low
        axh - byte count, high
@USAGE: argument, temp, axl, axh, bxl, bxh, X, Z
@OUTPUT: T flag 1 - success, 0 - failure
*************************************************************/
fm24c04_read_buffer:
	CPI16 axl,axh,temp,0
	breq fm24c04_rbuf_ok
	mov bxl,axl
	mov bxh,axh

fm24c04_rbuf_blk:
	mov temp,XH
	mov argument,r2
	lsl argument
	andi temp,0x01
	lsl temp
	or argument,temp
	rcall twi1_send_addr
	cpi argument,I2C_ACK
	brne fm24c04_rbuf_err

	mov argument,XL
	rcall twi1_send_byte
	cpi argument,I2C_ACK
	brne fm24c04_rbuf_err

	mov temp,XH
	mov argument,r2
	lsl argument
	andi temp,0x01
	lsl temp
	or argument,temp
	ori argument,0x01
	rcall twi1_send_addr
	cpi argument,I2C_ACK
	brne fm24c04_rbuf_err

fm24c04_rbuf_byte:
	rcall twi1_read_byte
	cpi argument,I2C_READY
	brne fm24c04_rbuf_err
	st Z+,axl

	DEC16 bxl,bxh
	breq fm24c04_rbuf_nack

	cpi XL,0xFF
	breq fm24c04_rbuf_split

	rcall twi1_send_ack
	ADDI16 XL,XH,1
	rjmp fm24c04_rbuf_byte

fm24c04_rbuf_split:
	rcall twi1_send_nack_stop
	ADDI16 XL,XH,1
	CPI16 XL,XH,temp,512
	brne fm24c04_rbuf_blk
	LDI16 XL,XH,0
	rjmp fm24c04_rbuf_blk

fm24c04_rbuf_nack:
	rcall twi1_send_nack_stop
fm24c04_rbuf_ok:
	set
ret
fm24c04_rbuf_err:
	rcall twi1_send_stop
	clt
ret
