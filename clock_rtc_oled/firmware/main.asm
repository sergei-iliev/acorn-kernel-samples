;
; rtc-oled.asm
;
; Created: 1/30/2025 5:15:54 PM
; Author : Sergey Iliev
;

.include "kernel/interrupt.inc" 
.include "kernel/hardware.inc" 
.include "kernel/kernel.inc"

; Replace with your application code
.cseg
RESET:
	_keBOOT

	_REGISTER_TASK_STACK usart0_task,80
	_REGISTER_TASK_STACK oled_sh1107_task,100	
	_REGISTER_TASK_STACK rtc_task,150
	_REGISTER_TASK_STACK button_select_digit_task,80
	_REGISTER_TASK_STACK button_updown_digit_task,80 

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

.include "tasks/usart0_task.asm"
.include "tasks/oled_sh1107_task.asm"
;.include "tasks/blink_led_task.asm"
.include "tasks/rtc_task.asm"
.include "tasks/button_select_digit_task.asm"
.include "tasks/button_updown_digit_task.asm"
.EXIT

