;***********************************************USART 1***********************************************
;Use this task to send ESP-01 output to serial port
;#define F_CPU 20000000
//PLEASE SET PERIFERAL DEVIDER TO 1
;#define PRESCALE 1
;#define F_PER (F_CPU/PRESCALE)
;#define BAUD_RATE 115200
;#define USART_BAUD_RATE  (F_PER * 4 /BAUD_RATE)  ;8333

.dseg
usart_queue: .byte 2+USART_QUEUE_MAX_SIZE			;8 bit input queue
.cseg


;=========================================================
; USART task: drain `usart_queue` to USART1
;@USAGE: Z,axl,argument,return,bxl,bxh,r0,r1
;=========================================================
usart_task:
    rcall usart1_init
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
usart_main:

urt_00:
     _YIELD_TASK
urt_01:
     ;read input usart queue 
	 ldi ZL,low(usart_queue)
     ldi ZH,high(usart_queue)	  	
     ldi axl,USART_QUEUE_MAX_SIZE		

	 rcall spc_queue8_pop
	 brtc urt_00					;it is empty nothing to read

     ;send to terminal program
	 mov argument,return
	 rcall usart1_send 
	 rjmp urt_01
	  
rjmp usart_main

;=========================================================
;USART1 init 
;@USAGE:temp,r20,r21
;=========================================================
usart1_init:
  ;input output   
  lds temp,PORTC_DIRSET
  sbr temp,(1<<PIN0)  ;output  Tx  PC0
  cbr temp,(1<<PIN1)  ;input   Rx  PC1 
  sts PORTC_DIRSET,temp

  ldi r20,low(USART_BAUD_RATE)
  ldi r21,high(USART_BAUD_RATE)
  
  
  ;set baud rate
  sts USART1_BAUDL,r20
  sts USART1_BAUDH,r21

  ;enable Tx and Rx
  lds temp,USART1_CTRLB
  ori temp, USART_TXEN_bm | USART_RXEN_bm
  sts USART1_CTRLB,temp

ret
;===================================================
;@INPUT: argument
;@USAGE: argument,temp
;===================================================
usart1_send:
    sts USART1_TXDATAL,argument
u1_wait_send:    
	lds temp,USART1_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp u1_wait_send	

ret

;===================================================
;@INPUT: argument
;@USAGE: ZH,ZL,axl,argument,bxl,bxh,r0,r1
;===================================================
send_usart_queue:
	push ZH
	push ZL	
	push axl
	push bxl
	push bxh
	push r0
	push r1
    
   ldi ZL,low(usart_queue)
   ldi ZH,high(usart_queue)	  	
   ldi axl,USART_QUEUE_MAX_SIZE	
   rcall spc_queue8_push


	pop r1
	pop r0
	pop bxh
	pop bxl
	pop axl
	pop ZL
	pop ZH
ret