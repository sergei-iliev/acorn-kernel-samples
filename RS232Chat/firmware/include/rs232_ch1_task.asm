
//#define UBRR_VAL	103  /*9600 at 16Mhz*/	works!

//#define UBRR_VAL	51  /*19.2k at 16Mhz*/	works!
#define UBRR_VAL	25  /*38.4k at 16Mhz*/	


#define QUEUE_CLIENT_ONE_MAX_SIZE  250

.dseg
rxByte1: .byte 1
buffer_input_one: .byte 3 + QUEUE_CLIENT_ONE_MAX_SIZE
.cseg

#define RX1_EVENT_ID  0

#define RX1_INT_ID  7
 


/*************IDT task Producer for Channel 1************************************************/
rs232_ch1_task_producer:		 
  rcall rs232_ch1_init
  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

  _INTERRUPT_DISPATCHER_INIT temp,RX1_INT_ID
  ;input
  	ldi ZL,low(buffer_input_one)
	ldi ZH,high(buffer_input_one)
	
	rcall queue8_init

rs232mainInt:
	ldi ZL,low(buffer_input_one)
    ldi ZH,high(buffer_input_one)
	
    ldi axl,QUEUE_CLIENT_ONE_MAX_SIZE    
	
	_INTERRUPT_WAIT RX1_INT_ID
		lds argument,rxByte1
		rcall queue8_enqueue
	_INTERRUPT_END RX1_INT_ID
	
	;sbi PORTF,PF1    
	cpi argument,10
	brne rs232mainInt
    _EVENT_SET   RX1_EVENT_ID, TASK_CONTEXT

rjmp rs232mainInt

/*************IDT task Consumer for Channel 1************************************************/
rs232_ch1_task_consumer:
   _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

rs232main1_consumer:
	_EVENT_WAIT   RX1_EVENT_ID
cons1_loop:	
	_DISABLE_TASK_SWITCH TRUE
	;read current size of input bytes from client 1
  	ldi ZL,low(buffer_input_one)
	ldi ZH,high(buffer_input_one)

	ldi axl,QUEUE_CLIENT_ONE_MAX_SIZE
	
	rcall queue8_dequeue

	_DISABLE_TASK_SWITCH FALSE
	
	mov	argument,return	
	rcall rs232_send_byte2			;send to channel 2

	//test if empty
	ldi ZL,low(buffer_input_one)
	ldi ZH,high(buffer_input_one)
	
	rcall queue8_is_empty		
	brtc cons1_loop				;drain the buffer

rjmp rs232main1_consumer


;send byte as decimal
;@INPUT: argument
;@USAGE: temp
rs232_send_dec_out:
	set   ;used to fascilitate leading ziro removal
	ldi temp, -1 + '0' 

_ask1: 
	inc temp 
	subi argument, 100 
	brcc _ask1
;write out first digit
	push argument
	mov argument,temp
;no need of leading ziro
	cpi argument,'0'
	breq _ask11 
	rcall rs232_send_byte1	
	clt 

_ask11:		 
	pop argument

	ldi temp, 10 + '0' 

_ask2: 
	dec temp 
	subi argument, -10 
	brcs _ask2
	sbci argument, -'0' 
;write out second digit
	push argument
	mov argument,temp           
;test for leading zero - if T is clear stop testing - it is not leading zero
	brtc _ask222
	cpi argument,'0'		 
	breq _ask22         

_ask222:		 
	rcall rs232_send_byte1	

_ask22:		 
	pop argument
;write out third digit
	rcall rs232_send_byte1	
ret  





/***********Send byte in polling mode**********************
*@INPUT: argument
*@USAGE: temp 
*/
rs232_send_byte1:
	; Wait for empty transmit buffer
	lds temp,UCSR1A
	sbrs temp,UDRE1
	rjmp rs232_send_byte1
	; Put data into buffer, sends the data
	sts UDR1,argument
ret
/***************flash buffers********************
*@USAGE:temp
*/
usart_flush:
	lds temp,UCSR1A
	sbrs temp, RXC1
ret
	lds temp, UDR1
	//rjmp usart_flush
ret
/*****USART Init********************
*@USAGE:temp
*/
rs232_ch1_init:
	;disable power reduction mode
	lds temp,PRR1
	cbr temp,(1<<PRUSART1)
	sts PRR1,temp

	ldi temp,high(UBRR_VAL)
	sts UBRR1H,temp 

	ldi temp,low(UBRR_VAL)
	sts UBRR1L,temp
	
	; Enable receiver	
	ldi   temp,(1 << RXCIE1)|(1<<RXEN1)|(1<<TXEN1) 
	sts UCSR1B,temp
	
	; Set frame format: Async, no parity, 8 data bits, 1 stop bit
	ldi temp, (1 << UCSZ01) | (1 << UCSZ00)	
	sts UCSR1C,temp
	
ret	



Rx1Complete:
_PRE_INTERRUPT
	lds temp, UDR1
	sts rxByte1,temp
_keDISPATCH_DPC RX1_INT_ID
