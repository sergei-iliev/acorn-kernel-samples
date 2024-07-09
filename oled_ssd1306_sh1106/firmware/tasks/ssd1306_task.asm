.include "tasks/twi.asm"
.include "tasks/ssd1306.asm"

.cseg
ssd1306_task:

	_SLEEP_TASK 255		
	call ssd1306_setup

	call ssd1306_clear_screen
ssd1306_main:

   ;rcall test_buffer_pixel_at_x_y  
   
   ;rcall test_buffer_text_out

   ;rcall test_buffer_text_roboto_out

   rcall hello_text_col_page

   /*scroll*/
   ;ser temp
   ;mov char,temp  ; scroll 0
   ;call ssd1306_scroll_onoff
   
   ;rcall test_buffer_fast_change_update
 
   
   ;rcall test_buffer_bytes_screen

w1: rjmp w1   //forever loop

rjmp ssd1306_main

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
  
   rcall ssd1306_draw_buffer_char_roboto 
   
   ldi temp,11+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'G'
  
   rcall ssd1306_draw_buffer_char_roboto 
   
   ldi temp,11+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'I'
  
   rcall ssd1306_draw_buffer_char_roboto 

   ldi temp,11+8+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'N'
  
   rcall ssd1306_draw_buffer_char_roboto 
   ldi temp,11+8+8+8+8
   mov XX,temp  
   ldi temp,47
   mov YY,temp 

   ldi argument,'X'
  
   rcall ssd1306_draw_buffer_char_roboto 
    
  ;update buffer
   call ssd1306_send_buffer

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
   rcall ssd1306_draw_buffer_char
  ;update buffer
   call ssd1306_send_buffer

_SLEEP_TASK 255

   ldi temp,121
   mov XX,temp  
   ldi temp,55
   mov YY,temp 

   ldi argument,'Q'
   rcall ssd1306_draw_buffer_char

  ;update buffer
   call ssd1306_send_buffer

_SLEEP_TASK 255
rjmp test_buffer_text_out


/*
TEST Update buffer with changes
*/
test_buffer_fast_change_update:
   call ssd1306_clear_buffer
;first update
   ser temp
   mov char,temp 
   ldi temp,15
   mov XX,temp  
   ldi temp,0
   mov YY,temp   
   rcall ssd1306_draw_buffer_pixel    

   ser temp
   mov char,temp 
   ldi temp,15
   mov XX,temp  
   ldi temp,1
   mov YY,temp   
   rcall ssd1306_draw_buffer_pixel   

   ser temp
   mov char,temp 
   ldi temp,15
   mov XX,temp
   ldi temp,2
   mov YY,temp
   rcall ssd1306_draw_buffer_pixel    

   clr temp
   mov char,temp 
   ldi temp,15
   mov XX,temp
   ldi temp,3
   mov YY,temp   
   rcall ssd1306_draw_buffer_pixel   

   ldi temp,16
   mov XX,temp
   ldi temp,6
   mov YY,temp   
   rcall ssd1306_draw_buffer_pixel  

   ldi temp,16
   mov XX,temp
   ldi temp,7
   mov YY,temp   
   rcall ssd1306_draw_buffer_pixel  

   
   ldi temp,16
   mov XX,temp
   ldi temp,8
   mov YY,temp   
   rcall ssd1306_draw_buffer_pixel  
   
   ldi temp,16
   mov XX,temp
   ldi temp,9
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   ldi temp,16
   mov XX,temp
   ldi temp,10
   mov YY,temp   
   call ssd1306_draw_buffer_pixel 
;common stuff
   ser temp
   mov char,temp 
   ldi temp,95
   mov XX,temp  
   ldi temp,30
   mov YY,temp   
   call ssd1306_draw_buffer_pixel    

   ldi temp,95
   mov XX,temp  
   ldi temp,31
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,95
   mov XX,temp
   ldi temp,32
   mov YY,temp
   call ssd1306_draw_buffer_pixel    

   ldi temp,95
   mov XX,temp  
   ldi temp,36
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,95
   mov XX,temp  
   ldi temp,37
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   ldi temp,95
   mov XX,temp
   ldi temp,38
   mov YY,temp
   call ssd1306_draw_buffer_pixel  
;update buffer
   call ssd1306_send_buffer

   _SLEEP_TASK 255   

   call ssd1306_draw_buffer_pixel
;second update
   ldi temp,5
   mov XX,temp  
   ldi temp,50
   mov YY,temp   
   call ssd1306_draw_buffer_pixel    

   ldi temp,5
   mov XX,temp  
   ldi temp,51
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,5
   mov XX,temp
   ldi temp,52
   mov YY,temp
   call ssd1306_draw_buffer_pixel    

   ldi temp,5
   mov XX,temp
   ldi temp,53
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,6
   mov XX,temp
   ldi temp,56
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   ldi temp,6
   mov XX,temp
   ldi temp,57
   mov YY,temp   
   call ssd1306_draw_buffer_pixel 

   
   ldi temp,6
   mov XX,temp
   ldi temp,58
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  
   
   ldi temp,6
   mov XX,temp
   ldi temp,59
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   ldi temp,6
   mov XX,temp
   ldi temp,60
   mov YY,temp   
   call ssd1306_draw_buffer_pixel 
;common stuff
   ldi temp,95
   mov XX,temp  
   ldi temp,30
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,95
   mov XX,temp  
   ldi temp,31
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   ldi temp,95
   mov XX,temp
   ldi temp,32
   mov YY,temp
   call ssd1306_draw_buffer_pixel   

   ldi temp,95
   mov XX,temp  
   ldi temp,36
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,95
   mov XX,temp  
   ldi temp,37
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,95
   mov XX,temp
   ldi temp,38
   mov YY,temp
   call ssd1306_draw_buffer_pixel  
;update buffer
   call ssd1306_send_buffer

   _SLEEP_TASK 255
rjmp test_buffer_fast_change_update

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
   call ssd1306_draw_buffer_pixel    

   ldi temp,5
   mov XX,temp  
   ldi temp,1
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,5
   mov XX,temp
   ldi temp,2
   mov YY,temp
   call ssd1306_draw_buffer_pixel    

   ldi temp,5
   mov XX,temp
   ldi temp,3
   mov YY,temp   
   call ssd1306_draw_buffer_pixel   

   ldi temp,6
   mov XX,temp
   ldi temp,6
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   ldi temp,6
   mov XX,temp
   ldi temp,7
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   
   ldi temp,6
   mov XX,temp
   ldi temp,8
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  
   
   ldi temp,6
   mov XX,temp
   ldi temp,9
   mov YY,temp   
   call ssd1306_draw_buffer_pixel  

   ldi temp,6
   mov XX,temp
   ldi temp,10
   mov YY,temp   
   call ssd1306_draw_buffer_pixel 

   call ssd1306_send_buffer
ret


/*
TEST Draw sample byte in buffer and send to screen
*/
test_buffer_color_screen:

	;send 1024 bytes  128x8
	ldi XL,low(0)
	ldi XH,high(0)
;set buffer pointer and fill it in
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

	ldi temp,0x01
lp_000:
	st Y+,temp
    ADDI16 XL,XH,1
    CPI16 XL,XH,r20,GRAPHICS_BUFFER_SIZE
	brne lp_000


	call ssd1306_send_buffer

ret

/*
TEST col and page positioning for text
*/
hello_text_col_page:

   clr XX
   clr YY
   clr r14 ;counter


   ldi	ZH,high(hello_world*2)
   ldi	ZL,low(hello_world*2)

hello_loop_00:

   	     
   lpm axl, Z+ 
   cpi axl,0x0A
   breq nxt_line

   push ZH
   push ZL

   ;send
   mov temp,XX
   subi temp,-8  ;next char offset in roboto
   mov XX,temp ;input

   mov temp,r14
   mov YY,temp  ;input
       
   mov char,axl ;input 
   call ssd1306_send_char_roboto
   
   pop ZL
   pop ZH   
   rjmp hello_loop_00
nxt_line:
   
   inc r14
   inc r14
   mov temp,r14
   cpi temp,8
   breq nxt_ext

   clr XX

   rjmp hello_loop_00

nxt_ext:
ret

hello_world:
.db "GOD IS MY ",0x0A,"SHEPHARD",0x0A,"I SHALL NOT",0x0A,"WANT",0x0A

.EXIT