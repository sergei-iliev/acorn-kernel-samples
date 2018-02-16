

/*********Play alarm music******************
*/
Alarm_Task:

 sbi DDRD,PORTD7
 cbi PORTD,PORTD7

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

al_main:
   ;wait for rs232 timeout event 
   _EVENT_WAIT RS232_AVAILABILITY_TIMEOUT_EVENT
   
   lds temp,RS232Status
   cpi temp,RESPONSE_NONE
   brne al_ok
   rcall alarm_on

al_ok:
rjmp al_main

/*****SET ALARM ON********************
*/
alarm_on:
  cbi PORTD,PORTD7	
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 sbi PORTD,PORTD7	
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 cbi PORTD,PORTD7
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 sbi PORTD,PORTD7	
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 cbi PORTD,PORTD7
ret