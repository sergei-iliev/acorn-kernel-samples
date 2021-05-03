
;.include "m2560def.inc"
.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"

.cseg
RESET:
	_BOOT
	
	_REGISTER_TASK System_Task

	_REGISTER_TASK_STACK rs232_ch1_task_producer,100  

	_REGISTER_TASK_STACK rs232_ch1_task_consumer,80

	_REGISTER_TASK_STACK rs232_ch2_task_producer,100  

	_REGISTER_TASK_STACK rs232_ch2_task_consumer,80


	_START_SCHEDULAR
	  

.include "include/tasks.asm"


DispatchDPCExtension:

TaskSchedular:

;is schedular suspended?    
	_keSKIP_SWITCH_TASK task_switch_disabled

	_keOS_SAVE_CONTEXT
;start LIMBO state 
    
	_keSWITCH_TASK

;end LIMBO state
	_keOS_RESTORE_CONTEXT

task_switch_disabled:         ;no task switching

reti

SystemTickInt:
  _PRE_INTERRUPT   
   
  _kePROCESS_SLEEP_INTERVAL	
  
  _POST_INTERRUPT
rjmp TaskSchedular



.EXIT



