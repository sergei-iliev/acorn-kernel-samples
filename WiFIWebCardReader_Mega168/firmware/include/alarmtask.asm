

/*********Play alarm music******************
It is a timeout alarm, in case RS232 or Network connection is down
*/
Alarm_Task:

 sbi DDRB,PB3
 cbi PORTB,PB3

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

rcall init_timer2
  
al_main:
   ;wait for rs232 timeout event 
   _EVENT_WAIT WIFI_RESULT_EVENT
   
   lds temp,WiFiResult
   cpi temp,RESPONSE_FAILURE
   brne al_ok
   rcall alarm_error_on
rjmp al_main
   
al_ok:
   rcall alarm_success_on   
rjmp al_main


alarm_success_on:
 call start_timer2
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 call stop_timer2
 ret

/*****SET ALARM ON********************/

alarm_error_on:

 call start_timer2
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 call stop_timer2
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 call start_timer2	
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 call stop_timer2
 
ret

router_error_on:

 call start_timer2
 _SLEEP_TASK 255
 call stop_timer2
 _SLEEP_TASK 255
 call start_timer2
 _SLEEP_TASK 255
 call stop_timer2
 _SLEEP_TASK 255
 call start_timer2
 _SLEEP_TASK 255
 call stop_timer2
 _SLEEP_TASK 255
 call start_timer2
 _SLEEP_TASK 255
 call stop_timer2
 _SLEEP_TASK 255
 call start_timer2
 _SLEEP_TASK 255
 call stop_timer2

ret

/*
*Toggle output pin
*/
init_timer2:

	lds temp,TCCR2A
	sbr temp,(1<<COM2A0)+(1<<WGM21)   ;CTC on channel OC2A,toggle pin OC2A
	sts TCCR2A,temp

	;lds temp,TCCR2B
	;sbr temp,(1<<CS22)+(1<<CS20)   ;1/128
	;sts TCCR2B,temp

	ldi temp,0
	sts TCNT2,temp

	ldi temp,4
	sts OCR2A,temp

;enable it   
ret

start_timer2:
	lds temp,TCCR2B
	sbr temp,(1<<CS22)+(1<<CS21)   ;1/1024
	sts TCCR2B,temp 

	ldi temp,4
    sts OCR2A,temp
ret

stop_timer2:
	lds temp,TCCR2B
	cbr temp,(1<<CS22)+(1<<CS21)   ;1/1024
	sts TCCR2B,temp 
ret