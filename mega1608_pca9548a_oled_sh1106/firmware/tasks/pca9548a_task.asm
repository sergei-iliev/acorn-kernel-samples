
.include "tasks/twi.asm"
.include "tasks/sh1106.asm"

.def    argument=r17
.def    axl=r18
.def    axh=r19

.EQU	PCA9548A_ADDRESS =0x70   

psa9548a_task:
	  //---debug LED pin
	lds temp,PORTC_DIR
	sbr temp,1<<PIN1
	sts PORTC_DIR,temp
	  /*-----------DEBUG 
	lds temp,PORTC_OUT
    sbr temp,1<<PIN1
    sts PORTC_OUT,temp	
      -----------------*/

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	
	rcall psa9548a_setup 
	
	ldi axl,0b11100000			;enable channel 7 6 5 
	rcall psa9548a_select_channel	;8 hard codded
		
    _SLEEP_TASK_EXT 10000
    call sh1106_setup 
	call sh1106_clear_screen

	;draw initial screen
    ldi axl,0b10000000			;enable channel 7
	rcall psa9548a_select_channel	
	
	_SLEEP_TASK_EXT 1000
	call sh1106_clear_buffer 
	call sh1106_clear_screen	
	call test_buffer_text_out

	_SLEEP_TASK_EXT 1000

	ldi axl,0b01000000			;enable channel 6
	rcall psa9548a_select_channel	
	
	_SLEEP_TASK_EXT 1000
	call sh1106_clear_buffer 
	call sh1106_clear_screen	
	call test_buffer_text_out

	_SLEEP_TASK_EXT 1000


	ldi axl,0b00100000			;enable channel 5
	rcall psa9548a_select_channel	

	call sh1106_clear_buffer 
	call sh1106_clear_screen	
	call test_buffer_text_roboto_out
	_SLEEP_TASK_EXT 1000

psa9548a_main:
    ;let uart task control LEDS - no need of semaphore
	_YIELD_TASK
	
rjmp psa9548a_main


psa9548a_setup:
	call twi_init	

ret

;@INPUT: axl - channel number
psa9548a_select_channel:
    ;transmit SLA+W
	ldi argument,(PCA9548A_ADDRESS<<1)
    call twi_send_addr

	;expect status ACK		  
	cpi argument, I2C_ACK
	brne slch_exit
    
	;channel
	mov argument,axl
	call twi_send_byte

	;expect status ACK		  
	cpi argument, I2C_ACK
	brne slch_exit

slch_exit:
	;send stop condition
	call twi_send_stop
ret

psa9548a_read_register:
	;transmit SLA+R
	ldi argument,((PCA9548A_ADDRESS<<1) | 0x01)
	call twi_send_addr
				  
	cpi argument, I2C_ACK
	brne rdch_exit

	;read
	call twi_read_byte
	;expect status ACK		  
	cpi argument, I2C_READY
	brne rdch_exit


rdch_exit:
ret

;DELETE - you  have it in oled_sh1106_task
test_buffer_text_out:
   ;X and Y  
   ldi temp,113
   mov XX,temp  
   ldi temp,55
   mov YY,temp 

   ldi argument,'M'
   call sh1106_draw_buffer_char
  ;update buffer
   call sh1106_send_buffer

_SLEEP_TASK_EXT 255

   ldi temp,121
   mov XX,temp  
   ldi temp,55
   mov YY,temp 

   ldi argument,'Q'
   call sh1106_draw_buffer_char

  ;update buffer
   call sh1106_send_buffer

_SLEEP_TASK_EXT 255
ret

/*
;DELETE - you  have it in oled_sh1106_task
Render text on buffer first and then send buffer to OLED
Loop through char changes
*/
test_buffer_text_roboto_out:
   ;X and Y  
   ldi temp,11
   mov XX,temp  
   ldi temp,20
   mov YY,temp 

   ldi argument,'N'
  
   call sh1106_draw_buffer_char_roboto 
   
   ldi temp,11+8
   mov XX,temp  
   ldi temp,20
   mov YY,temp 

   ldi argument,'G'
  
   call sh1106_draw_buffer_char_roboto 
   
   ldi temp,11+8+8
   mov XX,temp  
   ldi temp,20
   mov YY,temp 

   ldi argument,'I'
  
   call sh1106_draw_buffer_char_roboto 

   ldi temp,11+8+8+8
   mov XX,temp  
   ldi temp,20
   mov YY,temp 

   ldi argument,'N'
  
   call sh1106_draw_buffer_char_roboto 
   ldi temp,11+8+8+8+8
   mov XX,temp  
   ldi temp,20
   mov YY,temp 

   ldi argument,'X'
  
   call sh1106_draw_buffer_char_roboto 
   
 
   ldi temp,11+8+8+8+8+8
   mov XX,temp  
   ldi temp,20
   mov YY,temp 

   ldi argument,' '  
   call sh1106_draw_buffer_char_roboto 
   
  
   ldi temp,11+8+8+8+8+8+8
   mov XX,temp  
   ldi temp,20
   mov YY,temp 

   ldi argument,'@'  
   call sh1106_draw_buffer_char_roboto 
    
  ;update buffer
   call sh1106_send_buffer

ret