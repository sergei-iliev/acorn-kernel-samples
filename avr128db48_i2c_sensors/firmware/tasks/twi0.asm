/*AVR1608
I2C MASTER driver implementation to control OLED
@WARNING mind the external oscilator frequency - calculate I2C to 100kHz
DOES NOT INVESTIGATE I2C send/write line status
* POLLING Mode at CPU 20MHz
*/


.equ I2C_INIT  = 0x00
.equ I2C_ACK= 0x01
.equ I2C_NACK= 0x02
.equ I2C_READY = 0x03
.equ I2C_ERROR = 0x04

.equ I2C_BUS_IDLE=0xF1
.equ I2C_BUS_BUSY=0xF2

//#define CLK_PER                                         20000000     // 20MHz default clock no prescaling
#define I2C_SCL_FREQ                                    100000
#define TWI0_BAUD  (((((SYSTEM_CLOCK /I2C_SCL_FREQ))-10-(SYSTEM_CLOCK * 0.3)/1000000))/2) ;100kH clocking

/**************INIT TWI0 ******************
*@USAGE:temp
*/
twi0_init:			
    ; Setup TWI??? Pins (PF2/PF3) & internal pullups
    
	ldi temp, PORT_PULLUPEN_bm   ; 0x08
    sts PORTA_PIN2CTRL, temp     ; PA2 = SDA
    sts PORTA_PIN3CTRL, temp     ; PA3 = SCL

	ldi temp,TWI0_BAUD
	sts TWI0_MBAUD,temp

    ldi temp,TWI_BUSSTATE_IDLE_gc
	sts TWI0_MSTATUS,temp

	ldi temp,TWI_ENABLE_bm
	sts TWI0_MCTRLA,temp
ret

/**************************WAIT TWI BUS IDLE*************************
;@USAGE: temp
*****************************************************************/
twi0_wait_idle:
    lds temp,TWI0_MSTATUS
    andi temp,TWI_BUSSTATE_gm
    cpi temp,TWI_BUSSTATE_IDLE_gc
    brne twi0_wait_idle
ret
/**************************SEND STOP TWI*************************
;@USAGE: temp
*****************************************************************/
twi0_send_stop:
   ldi temp,TWI_MCMD_STOP_gc
   sts TWI0_MCTRLB,temp
   rcall twi0_wait_idle
ret
/**************************SEND ACK AND RECEIVE NEXT BYTE*************************
;After twi0_read_byte, ACK the current byte and clock in the next one.
;@USAGE: temp
*****************************************************************/
twi0_send_ack:
   ldi temp,TWI_ACKACT_ACK_gc | TWI_MCMD_RECVTRANS_gc
   sts TWI0_MCTRLB,temp
ret
/**************************SEND NACK AND STOP*************************
;@USAGE: temp
*****************************************************************/
twi0_send_nack_stop:   
   ldi temp,TWI_ACKACT_NACK_gc | TWI_MCMD_STOP_gc
   sts TWI0_MCTRLB,temp
   rcall twi0_wait_idle
ret
/**************************SEND BYTE TWI*************************
;@INPUT:  argument - byte data to send	
;@OUTPUT: argument - status
****************************************************************/
twi0_send_byte:
   sts TWI0_MDATA,argument
   rcall twi0_wait_write
ret
/**************************CHECK IF TWI BUS BUSY*************************
;@OUTPUT: argument I2C status
****************************************************************/
twi0_is_busy:   
   lds temp,TWI0_MSTATUS
   andi temp,(TWI_BUSSTATE_gm)	
   cpi temp,TWI_BUSSTATE_IDLE_gc
   breq twiidle

   ldi argument,I2C_BUS_BUSY
ret
twiidle:
	ldi argument,I2C_BUS_IDLE
ret
/**************************SEND BYTE TWI*************************
;@INPUT:  argument - byte data to send	
;@USAGE: temp
;@OUTPUT: argument - status
****************************************************************/
twi0_send_addr:
     sts   TWI0_MADDR,argument 	          
	 rcall twi0_wait_write
ret
/**************************WAIT WRITE TWI*************************
;@USAGE: argument,temp
;@OUTPUT:  argument - status				  
****************************************************************/

twi0_wait_write:
   ldi argument,I2C_INIT

twiww_00:
   lds temp,TWI0_MSTATUS
   andi temp,(TWI_WIF_bm | TWI_RIF_bm)
   tst temp
   breq twiww_01

   ;good
   lds temp,TWI0_MSTATUS
   andi temp,TWI_RXACK_bm
   tst temp 
   breq twiww_02
   ldi argument,I2C_NACK               //NACK
   rjmp twiww_loop  

twiww_02:                        //ACK
   ldi argument,I2C_ACK
   rjmp twiww_loop

twiww_01:
   lds temp,TWI0_MSTATUS
   andi temp,(TWI_BUSERR_bm | TWI_ARBLOST_bm)
   tst temp
   breq twiww_loop
   
   ;bad
   ldi argument,I2C_ERROR		  //ERROR
twiww_loop:
   cpi argument,I2C_INIT
   breq twiww_00   ;keep looping until something happens
   
ret

/**************************READ BYTE TWI*************************
	
;@USAGE: 
;@OUTPUT:  axl - byte read
           argument - status
****************************************************************/
twi0_read_byte:
   rcall twi0_wait_read
   lds axl,TWI0_MDATA
ret

/**************************WAIT READ TWI*************************
;@USAGE: argument,temp
;@OUTPUT:  argument - status				  
****************************************************************/

twi0_wait_read:
   ldi argument,I2C_INIT ;0x00

twiwr_00:
   lds temp,TWI0_MSTATUS
   andi temp,(TWI_WIF_bm | TWI_RIF_bm)
   tst temp
   breq twiwr_01
   ;good
   ldi argument,I2C_READY               
   rjmp twiwr_loop  

twiwr_01:
   lds temp,TWI0_MSTATUS
   andi temp,(TWI_BUSERR_bm | TWI_ARBLOST_bm)
   tst temp
   breq twiwr_loop

   ;bad
   ldi argument,I2C_ERROR		  //ERROR
twiwr_loop:
   cpi argument,I2C_INIT
   breq twiwr_00   ;keep looping until something happens

ret
