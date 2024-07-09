.include "tasks/twi.asm"
.include "tasks/sh1106.asm"




sh1106_task:
	_SLEEP_TASK 255		
	call sh1106_setup    

	call sh1106_clear_screen

sh1106_main:
	
	rcall hello_buffer_multiline_text

	;rcall test_buffer_text_out

	;rcall test_buffer_text_roboto_out
	
	
	;rcall test_buffer_sent
	;rcall test_buffer_pixel_at_x_y

stop: rjmp stop		

rjmp sh1106_main





/*
TEST buffer text roboto out
Render text on buffer first and then send buffer to OLED
Loop through char changes
*/
test_buffer_text_roboto_out:
   ;X and Y  
   ldi temp,11
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'N'
  
   call sh1106_draw_buffer_char_roboto 
   
   ldi temp,11+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'G'
  
   call sh1106_draw_buffer_char_roboto 
   
   ldi temp,11+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'I'
  
   call sh1106_draw_buffer_char_roboto 

   ldi temp,11+8+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'N'
  
   call sh1106_draw_buffer_char_roboto 
   ldi temp,11+8+8+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'X'
  
   call sh1106_draw_buffer_char_roboto 

   call sh1106_draw_buffer_char_roboto 
   ldi temp,11+8+8+8+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,' '  
   call sh1106_draw_buffer_char_roboto 

   call sh1106_draw_buffer_char_roboto 
   ldi temp,11+8+8+8+8+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'$'  
   call sh1106_draw_buffer_char_roboto 
    
  ;update buffer
   call sh1106_send_buffer

debug: rjmp debug
ret

/*
TEST buffer text out
Render text on buffer first and then send buffer to OLED
Loop through char changes
*/
test_buffer_text_out:
   ;X and Y  
   ldi temp,121
   mov XX,temp  
   ldi temp,55
   mov YY,temp 

   ldi argument,'y'
   rcall sh1106_draw_buffer_char
  ;update buffer
   call sh1106_send_buffer

_SLEEP_TASK 255

   ldi temp,121
   mov XX,temp  
   ldi temp,55
   mov YY,temp 

   ldi argument,'Q'
   call sh1106_draw_buffer_char

  ;update buffer
   call sh1106_send_buffer

_SLEEP_TASK 255
rjmp test_buffer_text_out


/*
TEST Draw pixel at X and Y
*/
test_buffer_pixel_at_x_y:
   ser temp
   mov char ,temp
   ldi temp,5
   mov XX,temp  
   ldi temp,0
   mov YY,temp   
   call sh1106_draw_buffer_pixel  

   ldi temp,5
   mov XX,temp  
   ldi temp,1
   mov YY,temp   
   call sh1106_draw_buffer_pixel   

   ldi temp,5
   mov XX,temp
   ldi temp,2
   mov YY,temp
   call sh1106_draw_buffer_pixel    

   ldi temp,5
   mov XX,temp
   ldi temp,3
   mov YY,temp   
   call sh1106_draw_buffer_pixel   

   ldi temp,6
   mov XX,temp
   ldi temp,6
   mov YY,temp   
   call sh1106_draw_buffer_pixel  

   ldi temp,6
   mov XX,temp
   ldi temp,7
   mov YY,temp   
   call sh1106_draw_buffer_pixel  

   
   ldi temp,6
   mov XX,temp
   ldi temp,8
   mov YY,temp   
   call sh1106_draw_buffer_pixel  
   
   ldi temp,6
   mov XX,temp
   ldi temp,9
   mov YY,temp   
   call sh1106_draw_buffer_pixel  

   ldi temp,6
   mov XX,temp
   ldi temp,10
   mov YY,temp   
   call sh1106_draw_buffer_pixel 

   call sh1106_send_buffer
ret


/*
TEST buffer content sent
*/
test_buffer_sent:
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

	
	ldi temp,0xFF  ;data
	
	ADDI16 YL,YH,609      ;address
	st Y+,temp

	ldi temp,0b01111111
	st Y+,temp

	ldi temp,0b00111111
	st Y+,temp

	ldi temp,0b00011111
	st Y+,temp

	call sh1106_send_buffer
ret


/*
TEST col and page positioning for text
*/
hello_buffer_multiline_text:

   clr XX
   clr YY
   clr r14 ;counter


   ldi	ZH,high(hello_world*2)
   ldi	ZL,low(hello_world*2)

hello_loop_00:

   	     
   lpm argument, Z+ 
   cpi argument,0x0A
   breq nxt_line

   push ZH
   push ZL

   ;coordinates for next char
   mov temp,XX
   subi temp,-8  ;next char offset in roboto
   mov XX,temp ;input

   mov temp,r14
   mov YY,temp  ;input
       
   ;input   argument 
   call sh1106_draw_buffer_char_roboto

   pop ZL
   pop ZH   
   rjmp hello_loop_00
nxt_line:
   
   ;calculate next Y pos
   mov temp,r14
   subi temp,-15  ;next line
   mov r14,temp 

   cpi temp,(64-16)
   brsh nxt_ext

   clr XX

   rjmp hello_loop_00

nxt_ext:

  ;update buffer
   call sh1106_send_buffer
ret

hello_world:
.db "GOD IS MY ",0x0A,"SHEPHARD",0x0A,"I SHALL NOT",0x0A,"WANT",0x0A

.EXIT