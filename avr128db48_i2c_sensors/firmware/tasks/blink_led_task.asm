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



.def    cxl=r14
.def    cxh=r15

.def    argument=r17
.def    axl=r18
.def    axh=r19
.def    bxl = r20
.def    bxh = r21
.def    dxl=r22
.def    dxh=r23
.def    return=r24 

blink_led_task:	
  //---setup LED pin on PB4
  lds temp,PORTB_DIR
  sbr temp,1<<PIN4
  sts PORTB_DIR,temp




  	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

main1:  
	ldi temp,1<<PIN4
	sts PORTB_OUTTGL,temp
  
  _SLEEP_TASK_EXT 20000  

rjmp main1



