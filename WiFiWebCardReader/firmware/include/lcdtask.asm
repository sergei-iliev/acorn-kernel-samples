.def    argument=r17   
.def    return = r18
.def    t1=r19
.def    t2=r20
.def    counter=r21

.include "include/LCD4bitWinstarDriver.asm"

LCD_Task:

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
	
	_SLEEP_TASK 250
	rcall lcd4_init

	
	ldi	argument,'W'
	rcall lcd4_putchar

	ldi	argument,'e'
	rcall lcd4_putchar

	ldi	argument,'b'
	rcall lcd4_putchar

    ldi	argument,'v'
	rcall lcd4_putchar

	ldi	argument,'1'
	rcall lcd4_putchar

main3:
	
	;_EVENT_WAIT LCD_UPDATE_EVENT
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	rcall scr_clear

	ldi argument,LCD_LINE_1 
	rcall lcd4_command




	;lds argument,debug
	;rcall lcd4_hex_out

	ldi argument,LCD_LINE_2 
	rcall lcd4_command

	;lds argument,debug
	;rcall lcd4_dec_out
	
	;ldi XL,low(ResponseBuffer)
	;ldi XH,high(ResponseBuffer)
	;adiw XH:XL,1
	;rcall lcd4_str_out 

	/*
	clr counter
	ldi XL,low(EEPROM_CONFIG_ADDR)
    ldi XH,high(EEPROM_CONFIG_ADDR)
	ADDI16 XL,XH,49
lcd_01:	
    rcall EEPROM_read		
	cpi counter,8
	breq lcd_02 
	rcall lcd4_putchar
	adiw X,1
	inc counter
	rjmp lcd_01
	*/

lcd_02:
rjmp main3

/*********************STRING OUT**********************
*@INPUT: X - str pointer  \0 terminated
*@USAGE: argument,counter  
******************************************************/
lcd4_str_out:
   clr counter

lcd4_str_0:   
   ld argument,X+
   tst argument  ;end of string
   breq lcd4_str_exit
   
   ;let it out
   rcall lcd4_putchar
   ;rcall lcd4_hex_out
   
   inc counter
   cpi counter,MAX_CHAR_LENGTH
   brlo lcd4_str_0

    
lcd4_str_exit:
ret
/*******************CLEAR LCD SCREEN*******************************
*@USAGE:argument
*/
scr_clear:

	ldi argument,LCD_LINE_1 
	rcall lcd4_command	
	
	rcall scr_clear_line

	ldi argument,LCD_LINE_2
	rcall lcd4_command

	rcall scr_clear_line

ret

/*
*@USAGE:argument,temp
*/
scr_clear_line:
    ldi temp,0

clr_loop:
	ldi	argument,' '
	rcall lcd4_putchar

	inc temp
	cpi temp,MAX_CHAR_LENGTH
	
	brlo clr_loop	
ret