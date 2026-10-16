;
;Acorn Mega Kernel 3.0
;
; Author : Sergey Iliev
;
.include "kernel/arch/interrupt.inc" 
.include "kernel/arch/hardware.inc" 
.include "kernel/kernel.inc"

; Replace with your application code

.cseg
RESET:
	_keBOOT
	_REGISTER_TASK_STACK blink_led_task,60 
	_REGISTER_TASK_STACK usart0_task,60 
	_REGISTER_TASK_STACK ds1302_task,100
	_REGISTER_TASK_STACK ds1307_tc74a1_task,100
	_keSTART_SCHEDULAR
;never get here



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

_RETI

SystemTickInt:  	 
  _PRE_INTERRUPT   
  
  ;clear int flag AVR 0 1 series only
  _CLEAR_TIMER_INT_FLAG

  _kePROCESS_SLEEP_INTERVAL	

  _POST_INTERRUPT
rjmp TaskSchedular


.include "tasks/blink_led_task.asm"
.include "tasks/usart0_task.asm"
//.include "tasks/ds1307_task.asm"
.include "tasks/ds1307_tc74a1_task.asm"
.include "tasks/ds1302_task.asm"
//.include "tasks/tc74a1_task.asm"
.EXIT
