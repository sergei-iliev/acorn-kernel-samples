;
; oled_sh1106.asm
;
; Created: 10/23/2024 8:36:07 AM
; Author : Sergey Iliev
;
.include "kernel/interrupt.inc" 
.include "kernel/hardware.inc" 
.include "kernel/kernel.inc"


.cseg
RESET:
	_keBOOT

	_REGISTER_TASK_STACK sys_task,100 
	_REGISTER_TASK_STACK psa9548a_task,100
	_REGISTER_TASK_STACK usart_0_task,100



	_START_SCHEDULAR temp
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

.include "tasks/sys_task.asm"
.include "tasks/usart_0_task.asm"
.include "tasks/pca9548a_task.asm"

.EXIT
