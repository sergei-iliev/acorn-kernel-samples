/*
TC74A1 temperature sensor driver
WORKS
*/
//.include "tasks/twi0.asm"

#define TC74A1_ADDRESS 0x49

.equ TC74A1_TEMP_REG = 0x00
.equ TC74A1_CONFIG_REG = 0x01

.equ TC74A1_STANDBY_VALUE = 0x80
.equ TC74A1_NORMAL_VALUE = 0x00
.equ TC74A1_DATA_RDY_bp = 6

/***************************init TC74A1************************
Init TWI0 channel
**************************************************************/
tc74a1_init:
  rcall twi0_init
ret

/***************************read TC74A1 temperature************************
@INPUT: none
@USAGE: argument, temp, axl
@OUTPUT: axl - temperature (signed byte, degrees C)
         T flag 1 - success, 0 - failure
*************************************************************/
tc74a1_read_temp:
	ldi argument,(TC74A1_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne tc74a1_rdtmp00	;report error

	;set register at 0x00
	ldi argument,TC74A1_TEMP_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK	
	brne tc74a1_rdtmp00	;report error 

	ldi argument,(TC74A1_ADDRESS<<1)|1	
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne tc74a1_rdtmp00	;report error

	rcall twi0_read_byte
	cpi argument,I2C_READY			
	brne tc74a1_rdtmp00	;report error

    rcall twi0_send_nack_stop
	set
ret
tc74a1_rdtmp00:
	rcall twi0_send_stop
	clt
ret

/***************************put TC74A1 in standby************************
@INPUT: none
@USAGE: argument, temp
@OUTPUT: T flag 1 - success, 0 - failure
*************************************************************/
tc74a1_sleep:
	ldi argument,(TC74A1_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne tc74a1_slp00

	ldi argument,TC74A1_CONFIG_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne tc74a1_slp00

	ldi argument,TC74A1_STANDBY_VALUE
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne tc74a1_slp00

	rcall twi0_send_stop
	set
ret
tc74a1_slp00:
	rcall twi0_send_stop
	clt
ret

/***************************wake TC74A1 from standby************************
Writes CONFIG=0 then waits until DATA_RDY (max ~250ms).
@INPUT: none
@USAGE: argument, temp, axl, bxl
@OUTPUT: T flag 1 - success, 0 - failure
*************************************************************/
tc74a1_wakeup:
	ldi argument,(TC74A1_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne tc74a1_wkp00

	ldi argument,TC74A1_CONFIG_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne tc74a1_wkp00

	ldi argument,TC74A1_NORMAL_VALUE
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne tc74a1_wkp00

	rcall twi0_send_stop

/* ADD _TASK_SLEEP between wake call and temp measure call
Setting the CONFIG write of 0x00 was not enough.
After standby, the TC74 clears DATA_RDY and needs a new conversion (up to 250 ms) before TEMP is valid. 
The old code read immediately, so you kept getting the frozen last value — which looks like it never woke up. 

1. Writes CONFIG 0x00 (clear SHDN)
2. Waits until STOP has finished (bus idle)
3. Polls CONFIG until DATA_RDY (bit 6) is set, then returns
/*
	ldi bxl,10			; ~10 x 40ms timeout
tc74a1_wkp_rdy:
	rcall tc74a1_read_config
	brtc tc74a1_wkp_wait
	sbrc axl,TC74A1_DATA_RDY_bp
	rjmp tc74a1_wkp_ok
tc74a1_wkp_wait:
	dec bxl
	breq tc74a1_wkp_fail
	_SLEEP_TASK_EXT 1000
	rjmp tc74a1_wkp_rdy

tc74a1_wkp_ok:
*/
	set
ret
tc74a1_wkp00:
	rcall twi0_send_stop
;tc74a1_wkp_fail:
	clt
ret

/***************************read TC74A1 CONFIG register************************
@INPUT: none
@USAGE: argument, temp, axl
@OUTPUT: axl - CONFIG byte
         T flag 1 - success, 0 - failure
*************************************************************/
tc74a1_read_config:
	ldi argument,(TC74A1_ADDRESS<<1)
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne tc74a1_rdcfg00

	ldi argument,TC74A1_CONFIG_REG
	rcall twi0_send_byte
	cpi argument,I2C_ACK
	brne tc74a1_rdcfg00

	ldi argument,(TC74A1_ADDRESS<<1)|1
	rcall twi0_send_addr
	cpi argument,I2C_ACK
	brne tc74a1_rdcfg00

	rcall twi0_read_byte
	cpi argument,I2C_READY
	brne tc74a1_rdcfg00

	rcall twi0_send_nack_stop
	set
ret
tc74a1_rdcfg00:
	rcall twi0_send_stop
	clt
ret
