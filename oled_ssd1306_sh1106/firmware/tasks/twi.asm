/*
I2C MASTER driver implementation to control OLED
@WARNING mind the external oscilator frequency - calculate I2C to 100kHz
* POLLING Mode at CPU 16MHz
*/

//General Master staus codes											
//***************************************************************************
#define TWI_START		            0x08		//START has been transmitted	
#define	TWI_REP_START	            0x10		//Repeated START has been 
											//transmitted		
//Master Transmitter staus codes											
//***************************************************************************
#define	MTX_ADR_ACK		        0x18		//SLA+W has been tramsmitted
											//and ACK received	
#define	MTX_ADR_NACK	        0x20		//SLA+W has been tramsmitted
											//and NACK received		
#define	MTX_DATA_ACK	        0x28		//Data byte has been tramsmitted
											//and ACK received			
#define	MTX_DATA_NACK	        0x30		//Data byte has been tramsmitted
											//and NACK received			
#define	MTX_ARB_LOST	        0x38		//Arbitration lost in SLA+W or 
											//data bytes	
//Master Receiver staus codes	
//***************************************************************************
#define	MRX_ARB_LOST	        0x38		//Arbitration lost in SLA+R or 
											//NACK bit
#define	MRX_ADR_ACK		        0x40		//SLA+R has been tramsmitted
											//and ACK received	
#define	MRX_ADR_NACK	        0x48		//SLA+R has been tramsmitted
											//and NACK received		
#define	MRX_DATA_ACK	        0x50		//Data byte has been received
											//and ACK returned
#define	MRX_DATA_NACK	        0x58		//Data byte has been received											        
											//and NACK tramsmitted


//Slave Transmitter staus codes											
//***************************************************************************
#define	STX_ADR_ACK		        0xA8		//Own SLA+R has been received
											//and ACK returned
#define	ARB_LOST_STX_ADR_ACK    0xB0		//Arbitration lost in SLA+R/W as
                                            //a Master. Own SLA+W has been 
                                            //received and ACK returned
#define	STX_DATA_ACK	        0xB8		//Data byte has been tramsmitted
											//and ACK received			
#define	STX_DATA_NACK	        0xC0		//Data byte has been tramsmitted
											//and NACK received			
#define	STX_LAST_DATA 	        0xC8		//Last byte un I2DR has been 
                                            //transmitted(TWEA = '0') ACK has
                                            //been received											
//Slave Receiver staus codes	
//***************************************************************************
#define	SRX_ADR_ACK		        0x60		//SLA+R has been received
											//and ACK returned
#define	ARB_LOST_SRX_ADR_ACK	0x68		//Arbitration lost in SLA+R/W as
                                            //a Master. Own SLA+R has been 
                                            //received and ACK returned
#define	SRX_GCALL_ACK	        0x70		//Generall call has been received
											//and ACK returned
#define	ARB_LOST_SRX_GCALL_ACK	0x78		//Arbitration lost in SLA+R/W as
                                            //a Master. General Call has been 
                                            //received and ACK returned
#define	SRX_DATA_ACK	        0x80		//Previously addressed with own 
                                            //SLA+W.Data byte has been received
											//and ACK returned
#define	SRX_DATA_NACK	        0x88		//Previously addressed with own 
                                            //SLA+WData byte has been received
                                            //and NACK returned
#define	SRX_GCALL_ACK	        0x90		//Previously addressed with General 
                                            //Call.Data byte has been received
											//and ACK returned
#define	SRX_GCALL_NACK	        0x98		//Previously addressed with General 
                                            //Call. Data byte has been received
                                            //and NACK returned
#define	SRX_STOP	            0xA0		//A STOP condition or repeated START
                                            //condition has been received while 
                                            //still addressed as a slave
									        
//Miscellanous States
//***************************************************************************
#define	TWI_IN_PROGRESS_STATUS	            0x01		

#define	TWI_BUS_ERROR_STATUS	            0x02		

#define	TWI_FREE_STATUS					0x00		






#define F_CPU 16000000 // CPU clock speed 16 MHz
#define F_SCL 400000 // I2C clock speed 200 kHz
#define RATE ((F_CPU/F_SCL)-16)/2; //at 200kH
/**************INIT TWI******************
*@USAGE:temp
*/
twi_init:			
	
	clr temp
	sts TWSR,temp	;set to prescaler to 0  /dev by 1

	ldi temp,RATE
	sts TWBR,temp;                    			//Set baud-rate to 100 KHz at 

	ldi temp,0xFF											
    sts TWDR,temp	;release bus
	 
	lds temp,TWCR
	sbr temp,(1<<TWEN)
	sts TWCR,temp						//Enable TWI-interface

ret

/**************************TWI WAITING*************************
;Pollimg mode requires waiting on interrupt flag
;@USAGE: temp
;
******************************************************************/
twi_wait:
    lds temp,TWCR
	sbrs temp,TWINT
	rjmp twi_wait	    
ret

/**************************SEND START TWI*************************
;@USAGE: temp
;@OUTPUT:  T flag 0 - FAILURE
;				  1 - SUCCESS 	
******************************************************************/
twi_start:
	clt
	//send start
	ldi temp,(1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
	sts TWCR, temp				;//Send START
	
	//wait
	rcall twi_wait							//Wait for TWI interrupt flag set

	lds temp,TWSR
	andi temp, 0xF8
	cpi temp, TWI_REP_START		;repeated start
	brne twistr_00
	set 
ret
twistr_00:
	cpi temp, TWI_START			;start
	brne twiexit
	set
twiexit:
ret
/**************************SEND STOP TWI*************************
;@USAGE: temp
*****************************************************************/
twi_send_stop:
	ldi   temp,(1<<TWINT)|(1<<TWEN)|(1<<TWSTO) 
    sts   TWCR,temp

twi_wait_stp:
    lds temp,TWCR
	sbrc temp,TWSTO
	rjmp twi_wait_stp
		
ret
/**************************SEND BYTE TWI*************************
;@INPUT:  argument - byte data to send	
;@USAGE: temp
;@OUTPUT:  T flag 0 - FAILURE
;				  1 - SUCCESS
****************************************************************/
twi_send_byte:
          sts   TWDR,argument
          ldi   temp,(1<<TWINT)|(1<<TWEN)
          sts   TWCR,temp

		  rcall twi_wait
ret