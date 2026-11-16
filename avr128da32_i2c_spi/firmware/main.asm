;Acorn Mega Kernel 3.0
;
; Author : Sergey Iliev
;
.include "kernel/arch/interrupt.inc" 
.include "kernel/arch/hardware.inc" 
.include "kernel/kernel.inc"



.cseg
RESET:
	_keBOOT
	_REGISTER_TASK_STACK blink_led_task,60 
	_REGISTER_TASK_STACK usart0_task,100 
	_REGISTER_TASK_STACK fm24c04_task,100 
	//_REGISTER_TASK_STACK fm25040_task,100 
	_REGISTER_TASK_STACK m23lc512_task,100 

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


.include "kernel/lock-ts.inc"
.dseg
usart_lock: .byte 1
.cseg

.include "tasks/blink_led_task.asm"
.include "tasks/usart0_task.asm"
.include "tasks/fm24c04b_task.asm"
//.include "tasks/fm25040b_task.asm"
.include "tasks/23lc512_task.asm"

.EXIT
