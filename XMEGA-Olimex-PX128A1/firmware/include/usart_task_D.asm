

.def    argument=r17
.def    return=r18
.def    counter=r19  

.def	axl=r20
.def	axh=r21

.def	bxl=r22
.def	bxh=r23

.def	dxl=r24
.def	dxh=r25

.def	cxl=r14
.def	cxh=r15

.dseg
#define USARTE0_QUEUE_MAX_SIZE  1024 

#define USARTD0_QUEUE_MAX_SIZE  1024 
usartD0_16: .byte 4+USARTD0_QUEUE_MAX_SIZE*2
.cseg

/*USARTD0 task
Test consumer producer circular buffer
*/
.set RX1_INT_ID =7

usart_task_D:
    ldi temp,1<<0
	sts PORTA_DIR,temp

	ldi ZL,low(usartD0_16)
	ldi ZH,high(usartD0_16)
	rcall spc_queue16_init

	/* USARTD0, 8 Data bits, No Parity, 1 Stop bit. */
	rcall usart_init_d_int

_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER

_INTERRUPT_DISPATCHER_INIT temp,RX1_INT_ID

main_usart_d:

    _INTERRUPT_WAIT RX1_INT_ID
		ldi ZL,low(usartD0_16)
		ldi ZH,high(usartD0_16)	  	
		ldi axl,low(USARTD0_QUEUE_MAX_SIZE)
		ldi axh,high(USARTD0_QUEUE_MAX_SIZE)		
		rcall spc_queue16_pop
	_INTERRUPT_END RX1_INT_ID

	;queue output is in `dxh:dxl`
    brts wait_rx_int_d		;is empty queue?
    rjmp main_usart_d		

wait_rx_int_d:
	rcall usart_send_byte_e

rjmp main_usart_d	


;***send byte D channel
usart_send_byte_d:
wait_send_int_d:    
	lds temp,USARTD0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp wait_send_int_d	

	LDI temp,1<<0		
    STS PORTA_OUTTGL,temp	

	;ldi dxl,'Q'
	sts USARTD0_DATA,dxl
ret






;******configure USARTD0 in interrupt mode
usart_init_d_int:
		/* PIN3 (TXD0) as output. */
	ldi temp,1<<3
	sts PORTD_DIR,temp
	
	/* PIN2 (RXD0) as input. */
	ldi temp,1<<2
	sts PORTD_DIRCLR,temp

    /* USARTD0, 8 Data bits, No Parity, 1 Stop bit. */
	ldi temp,USART_CHSIZE_8BIT_gc|USART_PMODE_DISABLED_gc|(0<<USART_SBMODE_bp)
	sts USARTD0_CTRLC,temp

	/* Set Baudrate to 9600 bps:
	 * Use the default I/O clock fequency that is 12 MHz.	 
	 */
    ldi temp, (3317 & 0xff) << USART_BSEL_gp
    sts USARTD0_BAUDCTRLA, temp
    ldi temp, ((-4) << USART_BSCALE_gp) | ((3317 >> 8) << USART_BSEL_gp)
    sts USARTD0_BAUDCTRLB, temp

	;enable receive interrupt
	lds temp,USARTD0_CTRLA
	cbr temp,USART_RXCINTLVL_gm
	ori temp,USART_RXCINTLVL_LO_gc
	sts USARTD0_CTRLA,temp

	
	lds temp,USARTD0_CTRLB
	ori temp,USART_RXEN_bm|USART_TXEN_bm	
	sts USARTD0_CTRLB,temp
    
ret


 ;usart D0 receive int handler
 USARTD0_Rx:
_PRE_INTERRUPT
    push ZH
	push ZL
	push cxh
	push cxl
	push dxh
	push dxl
	push axh
	push axl
    push argument
	push bxl
	push bxh
	push r0
	push r1
    push r2
	push r3

	;read USART data in 8 bit buffer
    ;lds argument,USARTD0_DATA
	;ldi ZL,low(uart8)
	;ldi ZH,high(uart8)	  	
	;ldi axl,UART_QUEUE_MAX_SIZE		
    ;rcall spc_queue8_push  

	;read USART data in 16bit buffer
    lds dxl,USARTD0_DATA

	ldi ZL,low(usartD0_16)
	ldi ZH,high(usartD0_16)	  	
	ldi axl,low(USARTD0_QUEUE_MAX_SIZE)
	ldi axh,high(USARTD0_QUEUE_MAX_SIZE)
	
	rcall spc_queue16_push_from_isr	

	pop r3
	pop r2
	pop r1
	pop r0
	pop bxh
	pop bxl
	pop argument
	pop axl
	pop axh
	pop dxl
	pop dxh
	pop cxl
	pop cxh
	pop ZL
	pop ZH

;_POST_INTERRUPT
;_RETI
_keDISPATCH_DPC RX1_INT_ID
.EXIT