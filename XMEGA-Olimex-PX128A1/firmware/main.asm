;
; OLIMEX-PX128A1.asm
;
;
; Created: 3/29/2022 11:55:18 AM
; Author : Sergey Iliev
;

.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"

.cseg
.include "tasks.asm"


RESET:
	_keBOOT
	
	_REGISTER_TASK task1
	_REGISTER_TASK usart_task_D
	_REGISTER_TASK usart_task_E
	_REGISTER_TASK lcd_task
	
;initialize current task pointer with Task #1
	_START_SCHEDULAR

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
   
  _kePROCESS_SLEEP_INTERVAL	
  
  _POST_INTERRUPT
rjmp TaskSchedular


