/*global counter**/
//.def    counter=r10    ;

.equ PIN0 = 0
.equ PIN1 = 1
.equ PIN2 = 2
.equ PIN3 = 3
.equ PIN4 = 4
.equ PIN5 = 5
.equ PIN6 = 6
.equ PIN7 = 7

blink_led_task:	

  lds temp,PORTA_DIR
  sbr temp,1<<PIN2
  sts PORTA_DIR,temp

  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main2:  

  lds temp,PORTA_OUT
  sbr temp,1<<PIN2
  sts PORTA_OUT,temp

  _SLEEP_TASK_EXT 20000 

  lds temp,PORTA_OUT
  cbr temp,1<<PIN2
  sts PORTA_OUT,temp

  _SLEEP_TASK_EXT 20000  


rjmp main2




