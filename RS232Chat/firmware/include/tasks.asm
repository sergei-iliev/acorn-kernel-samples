.include "include/rs232_ch1_task.asm"
.include "include/rs232_ch2_task.asm"


.def    argument=r17
.def    return=r18
.def    counter=r19  

.def	axl=r20
.def	axh=r21

.def	bxl=r22
.def	bxh=r23

.def	cxl=r14
.def	cxh=r15

.def	dxl=r12
.def	dxh=r13

System_Task: 
	sbi DDRF,PF0
	sbi DDRF,PF1

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
    
main1:

    sbi PORTF,PF0
	_SLEEP_TASK 255
	cbi PORTF,PF0
	_SLEEP_TASK 255
rjmp main1  

.include "include\queue.asm"
.EXIT