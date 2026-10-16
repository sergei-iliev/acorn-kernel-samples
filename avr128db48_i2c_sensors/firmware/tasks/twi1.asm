/*AVR128DB48
I2C MASTER driver implementation - TWI1
@WARNING mind the external oscilator frequency - calculate I2C to 100kHz
DOES NOT INVESTIGATE I2C send/write line status
* POLLING Mode at CPU 20MHz
Default pins: PF2 = SDA, PF3 = SCL
*/


#ifndef I2C_INIT
.equ I2C_INIT  = 0x00
.equ I2C_ACK= 0x01
.equ I2C_NACK= 0x02
.equ I2C_READY = 0x03
.equ I2C_ERROR = 0x04

.equ I2C_BUS_IDLE=0xF1
.equ I2C_BUS_BUSY=0xF2
#endif

#ifndef I2C_SCL_FREQ
#define I2C_SCL_FREQ                                    100000
#endif
#define TWI1_BAUD  (((((SYSTEM_CLOCK /I2C_SCL_FREQ))-10-(SYSTEM_CLOCK * 0.3)/1000000))/2) ;100kH clocking

/**************INIT TWI1 ******************
*@USAGE:temp
*/
twi1_init:			
    ; Setup TWI1 Pins (PF2/PF3) & internal pullups
    
	ldi temp, PORT_PULLUPEN_bm   ; 0x08
    sts PORTF_PIN2CTRL, temp     ; PF2 = SDA
    sts PORTF_PIN3CTRL, temp     ; PF3 = SCL

	ldi temp,TWI1_BAUD
	sts TWI1_MBAUD,temp

    ldi temp,TWI_BUSSTATE_IDLE_gc
	sts TWI1_MSTATUS,temp

	ldi temp,TWI_ENABLE_bm
	sts TWI1_MCTRLA,temp
ret

/**************************WAIT TWI BUS IDLE*************************
;@USAGE: temp
*****************************************************************/
twi1_wait_idle:
    lds temp,TWI1_MSTATUS
    andi temp,TWI_BUSSTATE_gm
    cpi temp,TWI_BUSSTATE_IDLE_gc
    brne twi1_wait_idle
ret
/**************************SEND STOP TWI*************************
;@USAGE: temp
*****************************************************************/
twi1_send_stop:
   ldi temp,TWI_MCMD_STOP_gc
   sts TWI1_MCTRLB,temp
   rcall twi1_wait_idle
ret
/**************************SEND ACK AND RECEIVE NEXT BYTE*************************
;After twi1_read_byte, ACK the current byte and clock in the next one.
;@USAGE: temp
*****************************************************************/
twi1_send_ack:
   ldi temp,TWI_ACKACT_ACK_gc | TWI_MCMD_RECVTRANS_gc
   sts TWI1_MCTRLB,temp
ret
/**************************SEND NACK AND STOP*************************
;@USAGE: temp
*****************************************************************/
twi1_send_nack_stop:   
   ldi temp,TWI_ACKACT_NACK_gc | TWI_MCMD_STOP_gc
   sts TWI1_MCTRLB,temp
   rcall twi1_wait_idle
ret
/**************************SEND BYTE TWI*************************
;@INPUT:  argument - byte data to send	
;@OUTPUT: argument - status
****************************************************************/
twi1_send_byte:
   sts TWI1_MDATA,argument
   rcall twi1_wait_write
ret
/**************************CHECK IF TWI BUS BUSY*************************
;@OUTPUT: argument I2C status
****************************************************************/
twi1_is_busy:   
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_BUSSTATE_gm)	
   cpi temp,TWI_BUSSTATE_IDLE_gc
   breq twi1idle

   ldi argument,I2C_BUS_BUSY
ret
twi1idle:
	ldi argument,I2C_BUS_IDLE
ret
/**************************SEND BYTE TWI*************************
;@INPUT:  argument - byte data to send	
;@USAGE: temp
;@OUTPUT: argument - status
****************************************************************/
twi1_send_addr:
     sts   TWI1_MADDR,argument 	          
	 rcall twi1_wait_write
ret
/**************************WAIT WRITE TWI*************************
;@USAGE: argument,temp
;@OUTPUT:  argument - status				  
****************************************************************/

twi1_wait_write:
   ldi argument,I2C_INIT

twi1ww_00:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_WIF_bm | TWI_RIF_bm)
   tst temp
   breq twi1ww_01

   ;good
   lds temp,TWI1_MSTATUS
   andi temp,TWI_RXACK_bm
   tst temp 
   breq twi1ww_02
   ldi argument,I2C_NACK               //NACK
   rjmp twi1ww_loop  

twi1ww_02:                        //ACK
   ldi argument,I2C_ACK
   rjmp twi1ww_loop

twi1ww_01:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_BUSERR_bm | TWI_ARBLOST_bm)
   tst temp
   breq twi1ww_loop
   
   ;bad
   ldi argument,I2C_ERROR		  //ERROR
twi1ww_loop:
   cpi argument,I2C_INIT
   breq twi1ww_00   ;keep looping until something happens
   
ret

/**************************READ BYTE TWI*************************
	
;@USAGE: 
;@OUTPUT:  axl - byte read
           argument - status
****************************************************************/
twi1_read_byte:
   rcall twi1_wait_read
   lds axl,TWI1_MDATA
ret

/**************************WAIT READ TWI*************************
;@USAGE: argument,temp
;@OUTPUT:  argument - status				  
****************************************************************/

twi1_wait_read:
   ldi argument,I2C_INIT ;0x00

twi1wr_00:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_WIF_bm | TWI_RIF_bm)
   tst temp
   breq twi1wr_01
   ;good
   ldi argument,I2C_READY               
   rjmp twi1wr_loop  

twi1wr_01:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_BUSERR_bm | TWI_ARBLOST_bm)
   tst temp
   breq twi1wr_loop

   ;bad
   ldi argument,I2C_ERROR		  //ERROR
twi1wr_loop:
   cpi argument,I2C_INIT
   breq twi1wr_00   ;keep looping until something happens

ret
