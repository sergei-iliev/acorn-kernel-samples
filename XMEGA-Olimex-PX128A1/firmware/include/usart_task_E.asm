

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
usartE0_16: .byte 4+USARTE0_QUEUE_MAX_SIZE*2
.cseg
/*USARTE0 task
Test consumer producer circular buffer
*/
.SET RX2_INT_ID=6
usart_task_E:
    ldi temp,1<<0|1<<1
	sts PORTA_DIR,temp

	ldi ZL,low(usartE0_16)
	ldi ZH,high(usartE0_16)
	rcall spc_queue16_init

	/* USARTE0, 8 Data bits, No Parity, 1 Stop bit. */
	rcall usart_init_e_int
	
_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER

_INTERRUPT_DISPATCHER_INIT temp,RX2_INT_ID

main_usart_e:
    ;pop from other channel
	_INTERRUPT_WAIT RX2_INT_ID
		ldi ZL,low(usartE0_16)
		ldi ZH,high(usartE0_16)	  	
		ldi axl,low(USARTE0_QUEUE_MAX_SIZE)
		ldi axh,high(USARTE0_QUEUE_MAX_SIZE)		
		rcall spc_queue16_pop
	_INTERRUPT_END RX2_INT_ID

	;queue output is in `dxh:dxl`
    brts wait_rx_int_e		;is empty queue?
    rjmp main_usart_e

wait_rx_int_e:    
	rcall usart_send_byte_d			;cross channel

rjmp main_usart_e




;***send byte E channel
usart_send_byte_e:
wait_send_int_e:    
	lds temp,USARTE0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp wait_send_int_e
	
	LDI temp,1<<1		
    STS PORTA_OUTTGL,temp	

	;ldi dxl,'A'
	sts USARTE0_DATA,dxl
ret  



;******configure USARTE0 in interrupt mode
usart_init_e_int:
		/* PIN3 (TXE0) as output. */
	clr temp
	sbr temp,1<<3
	sts PORTE_DIRSET,temp
	
	/* PIN2 (RXE0) as input. */
	clr temp
	sbr temp,1<<2
	sts PORTE_DIRCLR,temp

    /* USARTE0, 8 Data bits, No Parity, 1 Stop bit. */
	ldi temp,USART_CHSIZE_8BIT_gc|USART_PMODE_DISABLED_gc|(0<<USART_SBMODE_bp)
	sts USARTE0_CTRLC,temp

	/* Set Baudrate to 9600 bps:
	 * Use the default I/O clock fequency that is 12 MHz.	 
	 */
    ldi temp, (3317 & 0xff) << USART_BSEL_gp
    sts USARTE0_BAUDCTRLA, temp
    ldi temp, ((-4) << USART_BSCALE_gp) | ((3317 >> 8) << USART_BSEL_gp)
    sts USARTE0_BAUDCTRLB, temp

	;enable receive interrupt
	lds temp,USARTE0_CTRLA
	cbr temp,USART_RXCINTLVL_gm
	ori temp,USART_RXCINTLVL_LO_gc
	sts USARTE0_CTRLA,temp

	
	lds temp,USARTE0_CTRLB
	ori temp,USART_RXEN_bm|USART_TXEN_bm	
	sts USARTE0_CTRLB,temp
    
ret
 ;usart E0 receive int handler
 USARTE0_Rx:
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
    lds dxl,USARTE0_DATA

	ldi ZL,low(usartE0_16)
	ldi ZH,high(usartE0_16)	  	
	ldi axl,low(USARTE0_QUEUE_MAX_SIZE)
	ldi axh,high(USARTE0_QUEUE_MAX_SIZE)
	
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

_keDISPATCH_DPC RX2_INT_ID

.EXIT
