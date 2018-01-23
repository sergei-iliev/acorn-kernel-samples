.def    argument=r17   
.def    return = r18
.def    t1=r19
.def    t2=r20
.def    counter=r21
.def    lcdWork=r22

.include "include/LCD4bitWinstarDriver.asm"

LCD_Task:

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
	
	_SLEEP_TASK 250
	rcall lcd4_init

	ldi	argument,'+'
	rcall lcd4_putchar
main3:
	
	_EVENT_WAIT LCD_UPDATE_EVENT

	ldi argument,LCD_DISPLAY_CLEAR
	rcall lcd4_command

	rcall clear_screen

	ldi argument,LCD_LINE_1 
	rcall lcd4_command

	ldi	argument,'>'
	rcall lcd4_putchar

	
	
	;************text out the kb_buffer buffer    
	lds lcdWork,kb_buffcnt

	;if no record, jump to next line
	tst lcdWork
	breq end_line1

	clr counter
line1_next:	 
    ldi	ZH,high(kb_buffer)
    ldi	ZL,low(kb_buffer)
	clr temp
	ADD16 ZL,ZH,counter,temp	
    ld argument,Z
	
	tst argument
	breq char1_next
	
	rcall lcd4_putchar
 
char1_next:	
    inc counter	
	cp counter,lcdWork
    brlo line1_next    
   
end_line1:



	ldi argument,LCD_LINE_2
	rcall lcd4_command
	
	ldi	argument,':'
	rcall lcd4_putchar

	;check if there is a WORKS char from remote peer
	lds lcdWork,RxTail 
	tst lcdWork
	breq end_line2

	;text out the input buffer
    clr counter
line2_next:	 
    ldi	ZH,high(rs232_input)
    ldi	ZL,low(rs232_input)
	clr temp
	ADD16 ZL,ZH,counter,temp	
    ld argument,Z

	tst argument
	breq char2_next

	rcall lcd4_putchar 

char2_next:	
	inc counter
	cp counter,lcdWork
    brlo line2_next
	
end_line2:

rjmp main3

/*******************CLEAR LCD SCREEN*******************************
*@USAGE:argument
*/
clear_screen:

	ldi argument,LCD_LINE_1 
	rcall lcd4_command	
	
	rcall clr_line

	ldi argument,LCD_LINE_2
	rcall lcd4_command

	rcall clr_line

ret

/*
*@USAGE:argument,temp
*/
clr_line:
    ldi temp,0

clr_loop:
	ldi	argument,' '
	rcall lcd4_putchar

	inc temp
	cpi temp,MAX_CHAR_LENGTH
	
	brlo clr_loop	
ret