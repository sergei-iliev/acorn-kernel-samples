/*
DS1307 serial I2C real time clock
WORKS
*/
.include "tasks/twi0.asm"

#define DS1307_ADDRESS 0x68

.equ DS1307_SEC_REG = 0x00
.equ DS1307_MIN_REG = 0x01
.equ DS1307_HOUR_REG = 0x02
.equ DS1307_DOW_REG = 0x03
.equ DS1307_DATE_REG = 0x04
.equ DS1307_MONTH_REG = 0x05
.equ DS1307_YEAR_REG = 0x06

/***************************init DS1307************************
Init TWI0 channel
**************************************************************/
ds1307_init:
  rcall twi0_init
ret

/***************************read DS1307 time************************
Reads seconds, minutes, hours (BCD) starting at register 0x00.
Last received byte is NACKed, as required by the DS1307.
@INPUT: none
@USAGE: argument, temp, axl
@OUTPUT: r8  - seconds (BCD, bit 7 = CH)
         r9  - minutes (BCD)
         r10 - hours (BCD)
         T flag 1 - success, 0 - failure
*************************************************************/
ds1307_read_time:
	ldi argument,(DS1307_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne ds1307_rdt00

	;set register pointer to seconds
	ldi argument,DS1307_SEC_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_rdt00

	;repeated start, read
	ldi argument,(DS1307_ADDRESS<<1)|1
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne ds1307_rdt00

	;seconds
	rcall twi0_read_byte
	cpi argument,I2C_READY
	brne ds1307_rdt00
	mov r8,axl
	rcall twi0_send_ack

	;minutes
	rcall twi0_read_byte
	cpi argument,I2C_READY
	brne ds1307_rdt00
	mov r9,axl
	rcall twi0_send_ack

	;hours — last byte must be NACK+STOP
	rcall twi0_read_byte
	cpi argument,I2C_READY
	brne ds1307_rdt00
	mov r10,axl

	rcall twi0_send_nack_stop
	set
ret
ds1307_rdt00:
	rcall twi0_send_stop
	clt
ret

/***************************write DS1307 time************************
Writes seconds, minutes, hours starting at register 0x00.
CH (seconds bit 7) is cleared so the oscillator stays running.
@INPUT: r8  - seconds (BCD)
        r9  - minutes (BCD)
        r10 - hours (BCD)
@USAGE: argument, temp
@OUTPUT: T flag 1 - success, 0 - failure
*************************************************************/
ds1307_write_time:
	ldi argument,(DS1307_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne ds1307_wrt00

	ldi argument,DS1307_SEC_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrt00

	mov argument,r8
	andi argument,0x7F			;CH=0, oscillator on
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrt00

	mov argument,r9
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrt00

	mov argument,r10
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrt00

	rcall twi0_send_stop
	set
ret
ds1307_wrt00:
	rcall twi0_send_stop
	clt
ret

/***************************read DS1307 date************************
Reads date, month, year (BCD) starting at register 0x04.
Last received byte is NACKed, as required by the DS1307.
@INPUT: none
@USAGE: argument, temp, axl
@OUTPUT: r8  - date (BCD, 01-31)
         r9  - month (BCD, 01-12)
         r10 - year (BCD, 00-99)
         T flag 1 - success, 0 - failure
*************************************************************/
ds1307_read_date:
	ldi argument,(DS1307_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne ds1307_rdd00

	;set register pointer to date
	ldi argument,DS1307_DATE_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_rdd00

	;repeated start, read
	ldi argument,(DS1307_ADDRESS<<1)|1
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne ds1307_rdd00

	;date
	rcall twi0_read_byte
	cpi argument,I2C_READY
	brne ds1307_rdd00
	mov r8,axl
	rcall twi0_send_ack

	;month
	rcall twi0_read_byte
	cpi argument,I2C_READY
	brne ds1307_rdd00
	mov r9,axl
	rcall twi0_send_ack

	;year — last byte must be NACK+STOP
	rcall twi0_read_byte
	cpi argument,I2C_READY
	brne ds1307_rdd00
	mov r10,axl

	rcall twi0_send_nack_stop
	set
ret
ds1307_rdd00:
	rcall twi0_send_stop
	clt
ret

/***************************write DS1307 date************************
Writes date, month, year starting at register 0x04.
@INPUT: r8  - date (BCD, 01-31)
        r9  - month (BCD, 01-12)
        r10 - year (BCD, 00-99)
@USAGE: argument, temp
@OUTPUT: T flag 1 - success, 0 - failure
*************************************************************/
ds1307_write_date:
	ldi argument,(DS1307_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne ds1307_wrd00

	ldi argument,DS1307_DATE_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrd00

	mov argument,r8
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrd00

	mov argument,r9
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrd00

	mov argument,r10
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne ds1307_wrd00

	rcall twi0_send_stop
	set
ret
ds1307_wrd00:
	rcall twi0_send_stop
	clt
ret
