/*
Up and Down digit {0-23:0-59:0-59} to manipulate
*/


//Interrupt dispatch vector index
#define BUTTON_PRESS_UPDOWN_PORTD_ID 6

button_updown_digit_task:
  ;input
   lds temp,PORTD_DIR
   cbr temp,(1<<PIN0)	;PORT_INT0_bp
   sts PORTD_DIR,temp
  
  ;internal pullup enable
  lds temp, PORTD_PIN0CTRL
  sbr temp, 1<<PORT_PULLUPEN_bp
  sts PORTD_PIN0CTRL,temp

  ;interrupt
   lds temp,PORTD_PIN0CTRL
   ori temp,PORT_ISC_FALLING_gc
   sts PORTD_PIN0CTRL,temp

   
   	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	_INTERRUPT_DISPATCHER_INIT temp,BUTTON_PRESS_UPDOWN_PORTD_ID



button_updown_digit_main:
 	_INTERRUPT_WAIT BUTTON_PRESS_UPDOWN_PORTD_ID
		lds temp,left_right_button
		tst temp   //is SET active 
		breq butupdo_exit   //nothing to do

		cpi temp,1  //sec
		brne butupdo_10
	    
		lds temp,second
	    inc temp
	    cpi temp,60
	    brne butupdo_1
	    clr temp	//start over	    
butupdo_1:
		sts second,temp
		rjmp butupdo_exit

butupdo_10:
		cpi temp,2  //min
		brne butupdo_20

		lds temp,minute
	    inc temp
	    cpi temp,60
	    brne butupdo_2
	    clr temp	//start over	    
butupdo_2:
		sts minute,temp
		rjmp butupdo_exit

butupdo_20:
		cpi temp,3  //hour
		brne butupdo_exit

		lds temp,hour
	    inc temp
	    cpi temp,24
	    brne butupdo_3
	    clr temp	//start over	    
butupdo_3:
		sts hour,temp
		

butupdo_exit:
	_INTERRUPT_END BUTTON_PRESS_UPDOWN_PORTD_ID
	
   _SLEEP_TASK_EXT 5000
   
   ;interrupt enable
   lds temp,PORTD_PIN0CTRL
   ori temp,PORT_ISC_FALLING_gc
   sts PORTD_PIN0CTRL,temp

rjmp button_updown_digit_main


PORTD_Intr:
_PRE_INTERRUPT
	 
  ;is this comming from PIN5
  lds temp,PORTD_INTFLAGS
  sbrs temp, PORT_INT_0_bp
  rjmp portd_intr_exit

  ;clear intr flag
  lds temp,PORTD_INTFLAGS
  sbr temp,1<<PORT_INT_0_bp
  sts PORTD_INTFLAGS,temp

  ;disable interrupt
  lds temp,PORTD_PIN0CTRL
  andi temp,0b11111000     ;clear ISC bits
  ori temp,PORT_ISC_INTDISABLE_gc
  sts PORTD_PIN0CTRL,temp

  //yes it is pressed - send DPC
  _keDISPATCH_DPC BUTTON_PRESS_UPDOWN_PORTD_ID

portd_intr_exit:
  ;clear intr flag
  lds temp,PORTD_INTFLAGS
  sbr temp,1<<PORT_INT_0_bp
  sts PORTD_INTFLAGS,temp

_POST_INTERRUPT
_RETI
.EXIT