;tiny402
;tiny acorn micro kernel series 0 testing SLEEP mode
; Author : Sergey Iliev


.include "kernel/interrupt.inc" 
.include "kernel/hardware.inc" 
.include "kernel/kernel.inc" 

.cseg
RESET:

    _keBOOT
	_REGISTER_TASK_STACK blink_task,40 
	_REGISTER_TASK_STACK uart_task,40
	_REGISTER_TASK_STACK rtc_task,40
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
  
  ;clear int flag AVR 0 1 series only
  _CLEAR_TIMER_INT_FLAG
  #ifdef TASK_SLEEP_EXT
  _kePROCESS_SLEEP_INTERVAL_EXT	
  #else
  _kePROCESS_SLEEP_INTERVAL	
  #endif

  _POST_INTERRUPT
rjmp TaskSchedular


.include "tasks/blink_task.asm"
.include "tasks/uart_task.asm"
.include "tasks/rtc_task.asm"

;let the IDE show total RAM byte usage
;.dseg
;layout: .byte 40*TASKS_NUMBER
;.cseg

.EXIT