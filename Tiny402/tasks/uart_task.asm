

.EQU PIN6=6
.EQU PIN7=7


#define F_CPU 20000000
#define PRESCALE 1
#define F_PER (F_CPU/PRESCALE)
#define BAUD_RATE 38400
#define USART0_BAUD_RATE  (F_PER * 4 /BAUD_RATE)  ;8333

.def    argument=r17   
.def    global_byte=r14

#define USART_TASK_ID 2   ;in main.asm task position is 2
uart_task:

  rcall usart_init

  ;setup SLEEP mode
   _SLEEP_INIT temp

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main2:
      
	_INTERRUPT_WAIT USART_TASK_ID
	mov argument,global_byte
	rcall usart_send

	_INTERRUPT_END USART_TASK_ID

	mov temp,global_byte
	cpi temp,'S'
	brne main2

   ;sleep CPU if 'S' char received
	_SLEEP_CPU temp

rjmp main2

;@INPUT: argument
usart_send:
    sts USART0_TXDATAL,argument
wait_send:    
	lds temp,USART0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp wait_send	
	
	lds temp,USART0_STATUS
	sbr temp, (1<<USART_TXCIF_bp)
	sts USART0_STATUS,temp
	
ret


;default is 8N1
usart_init:
  cli
  
  ldi temp,CPU_CCP_IOREG_gc		// disable register security for oscillator update	   
  out CPU_CCP,temp
  ;set periferal to 1
  lds temp,CLKCTRL_MCLKCTRLB
  clr temp
  sts CLKCTRL_MCLKCTRLB,temp


  ;input output   
  lds temp,PORTA_DIRSET
  sbr temp,(1<<PIN6)  ;output  Tx  PA6
  cbr temp,(1<<PIN7)  ;input   Rx  PA7 
  sts PORTA_DIRSET,temp

  ;set low level
  lds temp,VPORTA_OUT
  cbr temp,1<<PIN6
  sts VPORTA_OUT,temp

  ldi r20,low(USART0_BAUD_RATE)
  ldi r21,high(USART0_BAUD_RATE)
  
  
  ;set baud rate
  sts USART0_BAUDL,r20
  sts USART0_BAUDH,r21

  ;enable Tx
  lds temp,USART0_CTRLB
  ori temp,  USART_TXEN_bm | USART_RXEN_bm
  sts USART0_CTRLB,temp

  rcall enable_uart
  ;8N1
  //lds temp,USART0_CTRLC
  //ori temp,USART_CMODE_ASYNCHRONOUS_gc 
  /* Asynchronous Mode */
	//		 | USART_CHSIZE_8BIT_gc /* Character size: 8 bit */
	//		 | USART_PMODE_DISABLED_gc /* No Parity */
	//		 | USART_SBMODE_1BIT_gc; /* 1 stop bit */
   
  sei
ret

enable_uart:
//enable Rx interrupt
  lds temp,USART0_CTRLA
  ori temp,USART_RXCIE_bm
  sts USART0_CTRLA,temp
ret

disable_uart:
  lds temp,USART0_CTRLA
  cbr temp,1<<USART_RXCIE_bp
  sts USART0_CTRLA,temp

ret






USART0_RXC_Intr:
_PRE_INTERRUPT

 ;global memory byte r14
 lds temp,USART0_RXDATAL;
 mov global_byte,temp

 ;is sleep requested -> ALWAYS return RETI to avoid elivation to DEVICE level
 _IS_SLEEP_CPU_REQUESTED uart_intr_exit,temp


_keDISPATCH_DPC USART_TASK_ID

uart_intr_exit:
_POST_INTERRUPT
_RETI

.EXIT