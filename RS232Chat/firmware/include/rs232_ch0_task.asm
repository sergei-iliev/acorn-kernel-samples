;16MHz

/****************************************DELETE no interrupt at Rx0 **********************************/
.def    argument=r17   

;#define UBRR_VAL	103  /*9600 at 16Mhz*/	
#define UBRR_VAL	25  /*38.4k at 16Mhz*/	

#define QUEUE_CLIENT_ZERO_MAX_SIZE  250

.dseg
rxByte0: .byte 1
buffer_input_zero: .byte 3 + QUEUE_CLIENT_ZERO_MAX_SIZE
.cseg

#define RX0_EVENT_ID  1

#define RX0_INT_ID  6


rs232_ch0_task_DELETE:		 
  rcall rs232_ch0_init
  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
rs232main:
nop
nop                    
	_SLEEP_TASK 255
	_SLEEP_TASK 255

	ldi	argument,'A'
	rcall rs232_send_byte		

	ldi	argument, 'B'
	rcall rs232_send_byte

rjmp rs232main  


/*************IDT task Producer for Channel 1************************************************/
rs232_ch0_task_int:		 
  rcall rs232_ch0_init
  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

  _INTERRUPT_DISPATCHER_INIT temp,RX0_INT_ID
  ;input
  	ldi ZL,low(buffer_input_zero)
	ldi ZH,high(buffer_input_zero)
	
	rcall queue8_init

rs232mainInt0:
	ldi ZL,low(buffer_input_zero)
    ldi ZH,high(buffer_input_zero)
	
    ldi axl,QUEUE_CLIENT_ZERO_MAX_SIZE    
	
	_INTERRUPT_WAIT RX0_INT_ID
		lds argument,rxByte0
		rcall queue8_enqueue
	_INTERRUPT_END RX0_INT_ID
	
	;sbi PORTF,PF1
    _EVENT_SET   RX0_EVENT_ID, TASK_CONTEXT

rjmp rs232mainInt0


/*************Consumer for Channel 0************************************************/
rs232_ch0_task_consumer:
   _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

rs232main0_consumer:
	_EVENT_WAIT   RX0_EVENT_ID
	_DISABLE_TASK_SWITCH TRUE
	;read current size of input bytes from client 1
  	ldi ZL,low(buffer_input_zero)
	ldi ZH,high(buffer_input_zero)
	rcall queue8_size

	mov	argument,return
	rcall rs232_send_dec_out		

	ldi	argument, ','
	rcall rs232_send_byte

	_DISABLE_TASK_SWITCH FALSE
	
rjmp rs232main0_consumer

;******send byte as decimal
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
	rcall rs232_send_byte	
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
	rcall rs232_send_byte	

_ask22:		 
	pop argument
;write out third digit
	rcall rs232_send_byte	
ret 

/***********Send byte in polling mode**********************
*@INPUT: argument
*@USAGE: temp 
*/
rs232_send_byte:
	; Wait for empty transmit buffer
	lds temp,UCSR0A
	sbrs temp,UDRE0
	rjmp rs232_send_byte
	; Put data into buffer, sends the data
	sts UDR0,argument
ret

/*****USART Init********************
*@USAGE:temp
*/
rs232_ch0_init:
	;disable power reduction mode
	lds temp,PRR0
	cbr temp,(1<<PRUSART0)
	sts PRR0,temp

	ldi temp,high(UBRR_VAL)
	sts UBRR0H,temp 

	ldi temp,low(UBRR_VAL)
	sts UBRR0L,temp
	
	; Enable receiver	
	ldi   temp,(1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0)
	sts UCSR0B,temp
	
	; Set frame format: Async, no parity, 8 data bits, 1 stop bit
	ldi temp, (1 << UCSZ01) | (1 << UCSZ00)	
	sts UCSR0C,temp
	
ret	




Rx0Complete:
_PRE_INTERRUPT
sbi PORTF,PF1
	lds temp, UDR0
	sts rxByte0,temp
_keDISPATCH_DPC RX0_INT_ID

.EXIT
