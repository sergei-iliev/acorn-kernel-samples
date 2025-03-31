.include "tasks/twi.asm"
.include "tasks/sh1107.asm"

.dseg
hour: .byte 1
minute: .byte 1
second: .byte 1

oled_digit_x: .byte 1
oled_digit_y: .byte 1

//ascii character 0-255
oled_digit_1:  .byte 1
oled_digit_2:  .byte 1 
oled_digit_3:  .byte 1


left_right_button: .byte 1
updown_button: .byte 1
.cseg

oled_sh1107_task:


	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

   	_SLEEP_TASK_EXT 255		 

	call sh1107_setup  
	call sh1107_clear_screen

main_oled:
     
	//render clock	 
	rcall render_oled_hour
	rcall render_oled_minute		
	rcall render_oled_second

	rcall render_set_mode   //are we in a SET mode
	
	//render Sofia
	ldi temp,62
    mov XX,temp  
    ldi temp,84
    mov YY,temp 
	ldi	ZH,high(sofia_text*2)
    ldi	ZL,low(sofia_text*2)
	rcall render_rom_text
	//render Bulgaria
	ldi temp,62
    mov XX,temp  
    ldi temp,100
    mov YY,temp 
	ldi	ZH,high(bulgaria_text*2)
    ldi	ZL,low(bulgaria_text*2)
	rcall render_rom_text


	call sh1107_send_buffer
	
	_SLEEP_TASK_EXT 2000
	call sh1107_clear_buffer
	

rjmp main_oled

/**Render text in ROM**/
;@INPUT: XX,YY,
;         Z - points to text address
;@USED argument,temp
;@STACK:3
;
render_rom_text:   	     
   lpm argument, Z+ 
   cpi argument,0x0A
   breq rrom_exit

   push ZH
   push ZL
   push YY
   ;coordinates for next char
   mov temp,XX
   subi temp,-8  ;next char offset in roboto
   mov XX,temp ;input

   call sh1107_draw_buffer_char_roboto

   pop YY
   pop ZL
   pop ZH   
   rjmp render_rom_text

rrom_exit:

ret

/*****Render * char if in SET mode******/
render_set_mode:
		lds temp,left_right_button
		tst temp   //is SET active 
		breq setmod_exit   //nothing to do

		cpi temp,1  //sec
		brne setmod_01
	
		ldi temp,98
        mov XX,temp  
		ldi temp,26
		mov YY,temp

		rjmp render_set_char
setmod_01:
		cpi temp,2  //min
		brne setmod_02
	
		ldi temp,50
        mov XX,temp  
		ldi temp,26
		mov YY,temp

		rjmp render_set_char
setmod_02:
					//hour
		ldi temp,10
        mov XX,temp  
		ldi temp,26
		mov YY,temp
       
render_set_char:
	    ldi argument,'*'
		call sh1107_draw_buffer_char_dejavu

setmod_exit:
ret
/*****Render hour******/
render_oled_hour:
	lds argument,hour
	rcall dec_to_asci  //output is in RAM
	
    ldi temp,1
    sts oled_digit_x,temp  
    ldi temp,50
    sts oled_digit_y,temp
	 
	rcall send_buffer_ascii_dejavu_out
	
	//add semicolon		  
	ldi argument,':'

	ldi temp,32
	mov XX,temp
	
    ldi temp,48
	mov YY,temp
	call sh1107_draw_buffer_char_dejavu 

ret
/*****Render min******/
render_oled_minute:
	lds argument,minute
	rcall dec_to_asci  //output is in RAM
	
    ldi temp,44
    sts oled_digit_x,temp  
    ldi temp,50
    sts oled_digit_y,temp
	 
	rcall send_buffer_ascii_dejavu_out
	
	//add semicolon		  
	ldi argument,':'

	ldi temp,76
	mov XX,temp
	
    ldi temp,48
	mov YY,temp
	call sh1107_draw_buffer_char_dejavu 

ret

/*****Render sec******/
render_oled_second:
	lds argument,second
	rcall dec_to_asci  //output is in RAM
	
    ldi temp,92
    sts oled_digit_x,temp  
    ldi temp,50
    sts oled_digit_y,temp
	 
	rcall send_buffer_ascii_dejavu_out
		
ret

/*
Send ascii  digit out
Use RAM memory to pass X,Y and digits
*/
send_buffer_ascii_dejavu_out:
   ;X and Y     
   lds XX,oled_digit_x
   lds YY,oled_digit_y

   lds argument,oled_digit_2
  
   call sh1107_draw_buffer_char_dejavu 
   lds XX,oled_digit_x
   lds YY,oled_digit_y
   
   mov temp,XX   //move on X axies
   subi temp,-16
   mov XX,temp  
   

   lds argument,oled_digit_3
  
   call sh1107_draw_buffer_char_dejavu 

ret

;*************************************************************************
;				Display byte as 1..3 digits 0..255
;check for leading zeros and remove them using T flag in SREG
;@INPUT:argument
;@USAGE:temp,argument
;@OUTPUT: oled_digit_1,oled_digit_2,oled_digit_3
;STACK: 1 level
;*************************************************************************
dec_to_asci:         
		 ldi temp, -1 + '0' 
_asc1: 
         inc temp 
         subi argument, 100 
         brcc _asc1
;write out first digit		 
		 sts oled_digit_1,temp		 		 		 

         ldi temp, 10 + '0' 
_asc2: 
         dec temp 
         subi argument, -10 
         brcs _asc2
		 sbci argument, -'0' 
;write out second digit         
		 sts oled_digit_2,temp		 
;write out third digit
         sts oled_digit_3,argument		 
ret  

hello_world:
.db "FOR GOD SO ",0x0A,"LOVED THE WORLD",0x0A,"THAT HE GAVE",0x0A,"HIS ONLY SON",0x0A
.db "THAT WHOEVER",0x0A,"BELIEVES IN HIM",0x0A,"MAY NOT PERISH",0x0A,"BUT HAVE ETERNAL LIVE",0x0A

sofia_text:
.db "Sofia",0x0A
bulgaria_text:
.db "Bulgaria",0x0A
.EXIT