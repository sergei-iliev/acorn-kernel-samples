//Arduino at 16MHz
/*
Recieve bytes from Web Browser serial port
Use single producer single consumer pattern 
*/


.include "tasks/single-producer-consumer.asm"
#define UBRR_VAL    16 /* 57600 at   16 MHz*/ 

.SET RX_EVENT_ID=7

#define CLEAR_SCREEN_COMMAND    0x10
#define DRAW_PIXEL_COMMAND    0x20
#define RENDER_SCREEN_COMMAND    0x30
#define DRAW_BUFFER_COMMAND    0x40

#define ROTATE_SCREEN_COMMAND    0x50
#define HORIZONTAL_SCROLL_SCREEN_COMMAND    0x60
#define INVERT_COLOR_SCREEN_COMMAND    0x70

.dseg
#define USART_QUEUE_MAX_SIZE  255 
usart_queue: .byte 2+USART_QUEUE_MAX_SIZE			;8 bit input queue

.cseg

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



rs232_task:

	_SLEEP_TASK 255
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)
	call spc_queue8_init

	rcall rs232_init
	
rs232_main:

rs_read_wait_00:
	_EVENT_WAIT  RX_EVENT_ID
rs_read_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc rs_read_wait_00					;it is empty nothing to send
	
	cpi return,CLEAR_SCREEN_COMMAND
	brne rs_read_cmd_00
	rcall clear_screen_command
	rjmp rs_read_loop_00

rs_read_cmd_00:		 
	cpi return,DRAW_PIXEL_COMMAND
	brne rs_read_cmd_11
	rcall draw_pixel_command
	rjmp rs_read_loop_00
	
rs_read_cmd_11:
	cpi return,RENDER_SCREEN_COMMAND
	brne rs_read_cmd_22
	rcall render_screen_command
	rjmp rs_read_loop_00	
	
rs_read_cmd_22:
	cpi return,DRAW_BUFFER_COMMAND
	brne rs_read_cmd_33
	rcall draw_buffer_command
	rjmp rs_read_loop_00

rs_read_cmd_33:	
	cpi return,ROTATE_SCREEN_COMMAND
	brne rs_read_cmd_44
	rcall rotate_screen_command
	rjmp rs_read_loop_00

rs_read_cmd_44:	
	cpi return,HORIZONTAL_SCROLL_SCREEN_COMMAND
	brne rs_read_cmd_55
	rcall horz_scroll_screen_command
	rjmp rs_read_loop_00

rs_read_cmd_55:	
	cpi return,INVERT_COLOR_SCREEN_COMMAND
	brne rs_read_cmd_66
	rcall invert_color_screen_command
	rjmp rs_read_loop_00

rs_read_cmd_66:
	
    rjmp rs_read_loop_00            ;repeat untill queue is empty

rjmp rs232_main

/******************INVERT COLOR SCREEN COMMAND****************************
Execute invert color screen 0 or 0xFF
Size structure 2 bytes only
   1. Command type
   2. No invert 0 or 0xFF   
***********************************************************/
invert_color_screen_command:
invclr_scr_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE
	
		
	rcall spc_queue8_pop
	brtc invclr_scr_loop_00					;it is empty nothing to read, keep looping

	mov char,return
	tst char	
	brne inv_clr_00
	
	#ifdef SSD1306	
	  ldi axl,SSD1306_NORMAL_DISPLAY
	  call ssd1306_send_command
    #endif 

	#ifdef SH1106
	 ldi axl,SET_NORMAL_DISPLAY
	 call sh1106_send_command 	
	#endif	
ret

inv_clr_00:
   	#ifdef SSD1306
	  ldi axl,SSD1306_INVERT_DISPLAY
	  call ssd1306_send_command 
	#endif

	#ifdef SH1106
	 ldi axl,SET_INVERT_DISPLAY
	 call sh1106_send_command 	
	#endif	
ret

/******************HORIZ SCROLL SCREEN COMMAND****************************
Execute horizontal scroll screen 0 or 0xFF
Size structure 2 bytes only
   1. Command type
   2. No scroll 0 or 0xFF horizontal scroll   
***********************************************************/
horz_scroll_screen_command:
hscroll_scr_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE
	
		
	rcall spc_queue8_pop
	brtc hscroll_scr_loop_00					;it is empty nothing to read, keep looping

	mov char,return      
    ;call ssd1306_scroll_onoff

ret

/******************ROTATE SCREEN COMMAND****************************
Execute rotate screen 0 or 180
Size structure 2 bytes only
   1. Command type
   2. Degree 0 or 180   
***********************************************************/
rotate_screen_command:
;1. degree byte
rot_scr_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE
	
		
	rcall spc_queue8_pop
	brtc rot_scr_loop_00					;it is empty nothing to read, keep looping

	mov char,return
	;call ssd1306_screen_rotate 
ret
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
/******************DRAW PIXEL COMMAND****************************
Execute draw pixel command
Size structure 4 bytes long
   1. Command type
   2. X coord
   3. Y coord
   4. color 0xFF - black 0x00 - white
***********************************************************/
draw_pixel_command:
    
;read next 3 bytes from structure
;1. X coord
drw_pxl_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc drw_pxl_loop_00					;it is empty nothing to read, keep looping

	mov XX,return
;2. Y coord	
drw_pxl_loop_11:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc drw_pxl_loop_11					;it is empty nothing to read, keep looping

	mov YY,return

;3. color
drw_pxl_loop_22:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc drw_pxl_loop_22					;it is empty nothing to read, keep looping

	;?mov color,return
	
	;execute command
;	call ssd1306_draw_pixel_x_y 

    

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

	;execute command
	#ifdef SSD1306
	call ssd1306_clear_screen	
	;clear local buffer    	
	call ssd1306_clear_buffer
	#endif

	#ifdef SH1106
	call sh1106_clear_screen
	;clear local buffer
	call sh1106_clear_buffer
	#endif

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

	;execute command
	#ifdef SSD1306
	call ssd1306_send_buffer
	#endif

	;execute command
	#ifdef SH1106
	call sh1106_send_buffer
	#endif

ret










/*****USART Init Interrupt mode********************
*Enable Interrupt at recieve byte only
*@USAGE:temp
*/
rs232_init:
	;disable power reduction on USART (enable USART)
	lds temp,PRR
	cbr temp,1<<PRUSART0
	sts PRR,temp

	ldi temp,high(UBRR_VAL)
	sts UBRR0H,temp 

	ldi temp,low(UBRR_VAL)
	sts UBRR0L,temp


	; Enable receiver	
	ldi   temp,(1 << RXCIE0)|(1<<RXEN0)|(1<<TXEN0) 		
	sts UCSR0B,temp
	
	; Set frame format: Async, no parity, 8 data bits, 1 stop bit	
	ldi temp, (1 << UCSZ01) | (1 << UCSZ00)	
	sts UCSR0C,temp

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

/*
Rx Recieve Complete interrupt handler
*/
RxComplete:
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

	lds argument, UDR0
		
	
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
reti