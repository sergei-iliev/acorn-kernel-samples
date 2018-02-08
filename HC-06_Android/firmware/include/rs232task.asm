/*
Running at 11.0592 external quarz
*/

.def    argument=r17  
.def    return = r18
.def    axl=r19
.def    axh=r20

.def	bxl=r21
.def    bxh=r22
	

#define UBRR_VAL	71/*11.0592*/ //51/*8Mhz*/	
;38400
#define UBRR_VAL	17


.SET STATUS_OK=1
.SET STATUS_ERROR=2


.dseg

RxByte: .byte 1 
RxTail:  .byte 1

TxByte: .byte 1
TxTail:  .byte 1
TxCurrentRef: .byte 1

;input buffer to hold answer from HC-06
rs232_input: .byte RS232_BUFF_SIZE
rs232_output: .byte RS232_BUFF_SIZE



TxRxStatus: .byte 1
.cseg


.include "include/rs232op.asm"

RS232_Tx_Task:

 ;reset status


 rcall usart_init_polling

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 



txmain: 

    _EVENT_WAIT RS232_READY_EVENT
    
	
	;check if there is char to send
	lds temp,TxTail 
	tst temp
	breq txmain

	;text out the output buffer
    clr counter
txline_next:	 
    ldi	ZH,high(rs232_output)
    ldi	ZL,low(rs232_output)
	clr temp
	ADD16 ZL,ZH,counter,temp	
    ld argument,Z
	rcall rs232_send_byte 
	
	inc counter
	lds temp,TxTail
	cp counter,temp
    brsh tx_nlcr
    
	rjmp txline_next	

tx_nlcr:
   
    ;Send line feed char to Android
    ldi argument,0x0D
	rcall rs232_send_byte 

    ldi argument,0x0A
	rcall rs232_send_byte 

rjmp txmain




/*****************************Recieve RS232 task****************************
*/

RS232_Rx_Task:

.SET RX=5
_INTERRUPT_DISPATCHER_INIT temp,RX

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

rxmain:


_INTERRUPT_WAIT	RX
	
	lds argument,RxByte
	//add to buffer up to BUFFER_SIZE length
	rcall add_byte_input_buffer
	

	;debug
	;lds counter,RxTail
    ;inc counter
    ;sts RxTail,counter
	
	//update LCD
	_EVENT_SET LCD_UPDATE_EVENT,TASK_CONTEXT

rsint_rx_exit:
_INTERRUPT_END RX

rjmp rxmain

/*****USART Init Interrupt polling mode********************
*Enable Interrupt at recieve byte only
*@USAGE:temp
*/
usart_init_polling:
	ldi temp,high(UBRR_VAL)
	out UBRRH,temp 

	ldi temp,low(UBRR_VAL)
	out UBRRL,temp

	; Enable receiver interrupt
	ldi temp,(1 << RXCIE)|(1<<RXEN)|(1<<TXEN)
	out UCSRB,temp

	; Set frame format: 8data,EVEN parity check,1stop bit by default  PC communication
	;When BT is reprogram to parity EVEN use this setting
	;ldi temp, (1<<URSEL)|(1<<UPM1)|(1 << UCSZ1) | (1 << UCSZ0)

	;default blue thooth setting 9600N81  BLUETOOTH communication
	;start with this to change parity to EVEN
	ldi temp, (1<<URSEL)|(1 << UCSZ1) | (1 << UCSZ0)
	
	out UCSRC,temp

ret


RxComplete:
_PRE_INTERRUPT
    
	//error check
    in temp,UCSRA
	sbrs temp,FE
	rjmp rxi_dor
	rjmp rxi_error 
rxi_dor:
	sbrs temp,DOR 
	rjmp rxi_pe
	;dor error
	rjmp rxi_error        
rxi_pe:
	sbrs temp,PE 
	rjmp rxi_char
	;pe error
	rjmp rxi_error

rxi_char: 
 	in temp, UDR
	sts RxByte,temp	

_keDISPATCH_DPC RX

rxi_error:

 rcall usart_flush 
_POST_INTERRUPT
reti
