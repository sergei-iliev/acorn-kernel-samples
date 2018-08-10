

/*********Play alarm music******************
It is a timeout alarm, in case RS232 or Network connection is down
*/
Alarm_Task:

 sbi DDRB,PB4
 cbi PORTB,PB4

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

al_main:
   ;wait for rs232 timeout event 
   _EVENT_WAIT WIFI_RESULT_EVENT

   lds temp,WiFIResult
   cpi temp,RESPONSE_FAILURE
   brne al_ok
   rcall alarm_error_on
rjmp al_main
   
al_ok:
   rcall alarm_success_on   
rjmp al_main

alarm_success_on:
 sbi PORTB,PB4	
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 cbi PORTB,PB4
 ret

/*****SET ALARM ON********************
*/
alarm_error_on:
 sbi PORTB,PB4	
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 cbi PORTB,PB4
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 sbi PORTB,PB4	
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
 cbi PORTB,PB4
ret

router_error_on:
 sbi PORTB,PB4	
 _SLEEP_TASK 255
 cbi PORTB,PB4
 _SLEEP_TASK 255
 sbi PORTB,PB4
 _SLEEP_TASK 255
 cbi PORTB,PB4
 _SLEEP_TASK 255
 sbi PORTB,PB4
 _SLEEP_TASK 255
 cbi PORTB,PB4
 _SLEEP_TASK 255
 sbi PORTB,PB4
 _SLEEP_TASK 255
 cbi PORTB,PB4
 _SLEEP_TASK 255
 sbi PORTB,PB4
 _SLEEP_TASK 255
 cbi PORTB,PB4
ret