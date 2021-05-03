
//#define UBRR_VAL	103  /*9600 at 16Mhz*/	works!

//#define UBRR_VAL	51  /*19.2k at 16Mhz*/	works!
#define UBRR_VAL	25  /*38.4k at 16Mhz*/	


#define QUEUE_CLIENT_TWO_MAX_SIZE  200

.dseg
rxByte2: .byte 1
buffer_input_two: .byte 3 + QUEUE_CLIENT_TWO_MAX_SIZE
.cseg

#define RX2_EVENT_ID  1

#define RX2_INT_ID  6
 

/*************IDT task Producer for Channel 2************************************************/
rs232_ch2_task_producer:		 
  rcall rs232_ch2_init
  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

  _INTERRUPT_DISPATCHER_INIT temp,RX2_INT_ID
  ;input
  	ldi ZL,low(buffer_input_two)
	ldi ZH,high(buffer_input_two)
	
	rcall queue8_init

rs232mainInt2:
	ldi ZL,low(buffer_input_two)
    ldi ZH,high(buffer_input_two)
	
    ldi axl,QUEUE_CLIENT_TWO_MAX_SIZE    
	
	_INTERRUPT_WAIT RX2_INT_ID
		lds argument,rxByte2		
		rcall queue8_enqueue
	_INTERRUPT_END RX2_INT_ID
	
	;sbi PORTF,PF1
	cpi argument,10
	brne rs232mainInt2
    _EVENT_SET   RX2_EVENT_ID, TASK_CONTEXT

rjmp rs232mainInt2

/*************IDT task Consumer for Channel 1************************************************/
rs232_ch2_task_consumer:
   _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

rs232main2_consumer2:
	_EVENT_WAIT   RX2_EVENT_ID

cons2_loop:	
	_DISABLE_TASK_SWITCH TRUE
	
  	ldi ZL,low(buffer_input_two)
	ldi ZH,high(buffer_input_two)
	
	ldi axl,QUEUE_CLIENT_TWO_MAX_SIZE
	
	rcall queue8_dequeue
	
	_DISABLE_TASK_SWITCH FALSE
	
	mov	argument,return
	rcall rs232_send_byte1			;Send to channel 1

	//test if empty
	ldi ZL,low(buffer_input_two)
	ldi ZH,high(buffer_input_two)
	
	rcall queue8_is_empty		
	brtc cons2_loop				;drain the buffer
	
	
	
rjmp rs232main2_consumer2





/***********Send byte in polling mode**********************
*@INPUT: argument
*@USAGE: temp 
*/
rs232_send_byte2:
	; Wait for empty transmit buffer
	lds temp,UCSR2A
	sbrs temp,UDRE2
	rjmp rs232_send_byte2
	; Put data into buffer, sends the data
	sts UDR2,argument
ret

/*****USART Init********************
*@USAGE:temp
*/
rs232_ch2_init:
	;disable power reduction mode
	lds temp,PRR1
	cbr temp,(1<<PRUSART2)
	sts PRR1,temp

	ldi temp,high(UBRR_VAL)
	sts UBRR2H,temp 

	ldi temp,low(UBRR_VAL)
	sts UBRR2L,temp
	
	; Enable receiver	
	ldi   temp,(1 << RXCIE2)|(1<<RXEN2)|(1<<TXEN2) 
	sts UCSR2B,temp
	
	; Set frame format: Async, no parity, 8 data bits, 1 stop bit
	ldi temp, (1 << UCSZ01) | (1 << UCSZ00)	
	sts UCSR2C,temp
	
ret	



Rx2Complete:
_PRE_INTERRUPT
	lds temp, UDR2
	sts rxByte2,temp
_keDISPATCH_DPC RX2_INT_ID
