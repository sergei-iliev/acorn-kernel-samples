/*
Scan i2c and send result to serial terminal
*/

;***********************************************USART 0***********************************************
.include "kernel/single-producer-consumer.asm"

#define BAUD_RATE 57600
#define USART0_BAUD_RATE ((SYSTEM_CLOCK * 64 / (16 * BAUD_RATE)) + 0.5)



#define OUTPUT_QUEUE_MAX_SIZE  100
.dseg

;head,tail + byte buffer
output_queue: .byte 2+OUTPUT_QUEUE_MAX_SIZE			;8 bit output/result queue


.cseg



usart0_task:	

	ldi ZL,low(output_queue)
	ldi ZH,high(output_queue)	
	rcall spc_queue8_init

cli
	rcall usart_init
sei

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	

uart0_main:
	ldi ZL,low(output_queue)
	ldi ZH,high(output_queue)
	ldi axl,OUTPUT_QUEUE_MAX_SIZE
	rcall spc_queue8_pop
	brtc uart0_idle

	mov argument,return
	rcall usart0_send
	rjmp uart0_main

uart0_idle:
	_SLEEP_TASK_EXT 20000
rjmp uart0_main


;@INPUT: argument - byte to queue for USART TX
;@USAGE: Z, axl, bxl, bxh, r0, r1
;@OUTPUT: T flag 1 - queued, 0 - queue full
usart0_queue:
	ldi ZL,low(output_queue)
	ldi ZH,high(output_queue)
	ldi axl,OUTPUT_QUEUE_MAX_SIZE
	rcall spc_queue8_push
ret

;@INPUT: argument
usart0_send:
    sts USART0_TXDATAL,argument
u0_wait_send:    
	lds temp,USART0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp u0_wait_send	
	
	lds temp,USART0_STATUS
	sbr temp, (1<<USART_TXCIF_bp)
	sts USART0_STATUS,temp
	
ret

;default is 8N1
usart_init:  

  ; USART0 ALT1: PA4 = TxD, PA5 = RxD
  lds temp,PORTMUX_USARTROUTEA
  andi temp,~PORTMUX_USART0_gm
  ori temp,PORTMUX_USART0_ALT1_gc
  sts PORTMUX_USARTROUTEA,temp

  lds temp,PORTA_DIR
  sbr temp,(1<<PIN4)  ;output  Tx  PA4
  cbr temp,(1<<PIN5)  ;input   Rx  PA5
  sts PORTA_DIR,temp

  ;input output   
  ;lds temp,PORTA_DIR
  ;sbr temp,(1<<PIN0)  ;output  Tx  PA0
  ;sts PORTA_DIR,temp
  ;output
  ;lds temp,PORTA_DIR
  ;cbr temp,(1<<PIN1)  ;input   Rx  PA1 
  ;sts PORTA_DIR,temp


  ;8 bit
  ;ERROR FOR SOME REASON I DON:T KNOW
  ;ldi temp,USART_CMODE_ASYNCHRONOUS_gc | USART_NORMAL_CHSIZE_8BIT_gc | USART_NORMAL_PMODE_DISABLED_gc | USART_NORMAL_SBMODE_1BIT_gc
  ;sts USART0_CTRLC,temp
     
  ldi r20,low(USART0_BAUD_RATE)
  ldi r21,high(USART0_BAUD_RATE)
  
  
  ;set baud rate
  sts USART0_BAUDL,r20
  sts USART0_BAUDH,r21

  ;enable Tx and Rx
  ;lds temp,USART0_CTRLB
  ori temp, USART_TXEN_bm | USART_RXEN_bm | USART_RXMODE_NORMAL_gc
  sts USART0_CTRLB,temp

  rcall enable_uart
  
  
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


.EXIT