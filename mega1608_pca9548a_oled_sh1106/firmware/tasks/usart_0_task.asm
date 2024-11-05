;***********************************************USART 0***********************************************
;#define F_CPU 20000000
//PLEASE SET PERIFERAL DEVIDER TO 1
#define PRESCALE 1
#define F_PER (SYSTEM_CLOCK/PRESCALE)
#define BAUD_RATE 57600
#define USART_BAUD_RATE  (F_PER * 4 /BAUD_RATE)  ;8333

//WHY -   because PERIFERAL clock has a devision ; set it to 1 first to use above formula

/*
Recieve bytes from Web Browser serial port
Use single producer single consumer pattern 
*/

.include "tasks/single-producer-consumer.asm"
#define CLEAR_SCREEN_COMMAND    0x10
#define DRAW_PIXEL_COMMAND    0x20
#define RENDER_SCREEN_COMMAND    0x30
#define DRAW_BUFFER_COMMAND    0x40

#define ROTATE_SCREEN_COMMAND    0x50
#define HORIZONTAL_SCROLL_SCREEN_COMMAND    0x60
#define INVERT_COLOR_SCREEN_COMMAND    0x70

#define CHANEL_NUMBER_MASK_0 0b00000001
#define CHANEL_NUMBER_MASK_1 0b00000010
#define CHANEL_NUMBER_MASK_2 0b00000100
#define CHANEL_NUMBER_MASK_3 0b00001000
#define CHANEL_NUMBER_MASK_4 0b00010000
#define CHANEL_NUMBER_MASK_5 0b00100000
#define CHANEL_NUMBER_MASK_6 0b01000000
#define CHANEL_NUMBER_MASK_7 0b10000000
#define CHANEL_NUMBER_MASK_ALL 0xFF

.dseg
#define USART_QUEUE_MAX_SIZE  255 
usart_queue: .byte 2+USART_QUEUE_MAX_SIZE			;8 bit input queue

chanel_number: .byte 1   ;keep current lcd chanel

.cseg

.SET RX_EVENT_ID=7

.def    cxl=r14
.def    cxh=r15

.def    argument=r17
.def    axl=r18
.def    axh=r19
.def    bxl = r20
.def    bxh = r21
.def    dxl=r22
.def    dxh=r23
.def    return=r24

usart_0_task:
	;init usart queue
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)
	call spc_queue8_init
   
    ;setup SLEEP on UART interrupt
    _SLEEP_INIT temp
	
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

	;init usart
	rcall usart0_init


usart0_main:

rs_read_wait_00:

	_EVENT_WAIT  RX_EVENT_ID

rs_read_loop_00:
    ;read from queue target lcd chanel
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE		
	rcall spc_queue8_pop

	brtc rs_read_wait_00					;it is empty nothing to read

	;target LCD # in return reg -> keep in axh
	sts chanel_number,return
	

;wait for command
rs_read_loop_01:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc rs_read_loop_01					;it is empty nothing to send	

	cpi return,CLEAR_SCREEN_COMMAND
	brne rs_read_cmd_00
	rcall clear_screen_command
	rjmp rs_read_loop_00

rs_read_cmd_00:
	cpi return,DRAW_BUFFER_COMMAND
	brne rs_read_cmd_01
	rcall draw_buffer_command
	rjmp rs_read_loop_00

rs_read_cmd_01:
	cpi return,RENDER_SCREEN_COMMAND
	brne rs_read_cmd_02
	rcall render_screen_command
	    
	;put the CPU to sleep
    _SLEEP_CPU temp	

	rjmp rs_read_loop_00	

rs_read_cmd_02:		
    rjmp rs_read_loop_00            ;repeat untill queue is empty
rjmp usart0_main

/******************DRAW BUFFER COMMAND****************************
Execute draw pixel command
Size structure 3 bytes long + Length bytes stream up to 2^16
   1. Command type
   2. Buffer Length byte MSB
   3. Buffer Length byte LSB
   ... Size bytes stream
   
***********************************************************/

draw_buffer_command:
;read size length
;1. MSB
drw_buff_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE
		
	rcall spc_queue8_pop
	brtc drw_buff_loop_00					;it is empty nothing to read, keep looping
	;size MSB 
	mov dxh,return
;2. LSB
drw_buff_loop_02:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	rcall spc_queue8_pop
	brtc drw_buff_loop_02					;it is empty nothing to read, keep looping
	;size LSB  
	mov dxl,return


;3. read size number of bytes
		
	;position buffer
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

drw_buff_loop_11:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc drw_buff_loop_11					;it is empty nothing to read, keep looping

	mov axl,return
	st Y+,axl								;store in buffer


	;counter decrement	
	SUBI16 dxl,dxh,1
	CPI16 dxl,dxh,temp,0
	brne drw_buff_loop_11                  ;keep looping untill size gets to 0

ret
/******************RENDER SCREEN****************************
Execute render buffer to  screen command
***********************************************************/
render_screen_command:
    ldi temp,2
	mov cxl,temp
;read next 2 bytes from structure
rnd_scr_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc rnd_scr_loop_00					;it is empty nothing to send, keep looping

	dec cxl
	tst cxl
	brne rnd_scr_loop_00                    ;not finished keep looping until 2 bytes are read

	
	;execute command #7
	lds argument,chanel_number
	cpi argument,7
	brne rnd_scr_loop_01
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_7
	call psa9548a_select_channel
	call sh1106_send_buffer
	ret

rnd_scr_loop_01:
	;execute command #6
	lds argument,chanel_number
	cpi argument,6
	brne rnd_scr_loop_02
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_6
	call psa9548a_select_channel
	call sh1106_send_buffer
	ret
rnd_scr_loop_02:
	;execute command #5
	lds argument,chanel_number
	cpi argument,5
	brne rnd_scr_loop_03
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_5
	call psa9548a_select_channel
	call sh1106_send_buffer
	ret

rnd_scr_loop_03:
	;execute command All
	lds argument,chanel_number
	cpi argument,255
	brne rnd_scr_loop_04
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_ALL
	call psa9548a_select_channel
	call sh1106_send_buffer
	ret
rnd_scr_loop_04:
ret

/******************CLEAR SCREEN****************************
Execute clear screen command and local buffer

***********************************************************/
clear_screen_command:
    ldi temp,2
	mov cxl,temp
;read next 2 bytes from structure
clr_scr_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc clr_scr_loop_00					;it is empty nothing to send, keep looping

	dec cxl
	tst cxl
	brne clr_scr_loop_00                    ;not finished keep looping until 2 bytes are read

	;execute command #7
	lds argument,chanel_number
	cpi argument,7
	brne clr_scr_01
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_7
	call psa9548a_select_channel

	call sh1106_clear_screen
	;clear local buffer
	call sh1106_clear_buffer

	ret
clr_scr_01:
	;execute command #6
	lds argument,chanel_number
	cpi argument,6
	brne clr_scr_02
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_6
	call psa9548a_select_channel

	call sh1106_clear_screen
	;clear local buffer
	call sh1106_clear_buffer

	ret
clr_scr_02:
	;execute command #5
	lds argument,chanel_number
	cpi argument,5
	brne clr_scr_03
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_5
	call psa9548a_select_channel

	call sh1106_clear_screen
	;clear local buffer
	call sh1106_clear_buffer

	ret

clr_scr_03:
	;execute command All
	lds argument,chanel_number
	cpi argument,255
	brne clr_scr_04
	;select chanel
	ldi axl,CHANEL_NUMBER_MASK_ALL
	call psa9548a_select_channel

	call sh1106_clear_screen
	;clear local buffer
	call sh1106_clear_buffer

	ret
clr_scr_04:
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
usart0_init:
  cli
  
  ldi temp,CPU_CCP_IOREG_gc		// disable register security for oscillator update	   
  out CPU_CCP,temp
  
  ;NO NEED - DONE during BOOT ;set periferal devider to 1
  ;lds temp,CLKCTRL_MCLKCTRLB
  ;clr temp
  ;sts CLKCTRL_MCLKCTRLB,temp


  ;input output   
  lds temp,PORTA_DIRSET
  sbr temp,(1<<PIN0)  ;output  Tx  PA0
  cbr temp,(1<<PIN1)  ;input   Rx  PA1 
  sts PORTA_DIRSET,temp


  ldi r20,low(USART_BAUD_RATE)
  ldi r21,high(USART_BAUD_RATE)
  
  
  ;set baud rate
  sts USART0_BAUDL,r20
  sts USART0_BAUDH,r21

  ;enable Tx and Rx
  lds temp,USART0_CTRLB
  ori temp, USART_TXEN_bm | USART_RXEN_bm
  sts USART0_CTRLB,temp

  rcall enable_usart0
   
  sei
ret


enable_usart0:
//enable Rx interrupt
  lds temp,USART0_CTRLA
  ori temp,USART_RXCIE_bm
  sts USART0_CTRLA,temp
ret

disable_usart0:
  lds temp,USART0_CTRLA
  cbr temp,1<<USART_RXCIE_bp
  sts USART0_CTRLA,temp

ret


/*
Rx Recieve Complete interrupt handler
*/
USART0_RXC_Intr:
_PRE_INTERRUPT
    ;store currently interrupted task's CPU context with registers used by queue
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
 
    ;read byte
    lds argument,USART0_RXDATAL  
	;store in queue
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE	
	rcall spc_queue8_push	


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

	_EVENT_SET RX_EVENT_ID, INTERRUPT_CONTEXT

_POST_INTERRUPT
_RETI

.EXIT