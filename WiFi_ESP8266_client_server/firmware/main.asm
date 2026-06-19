;
; esp-01-adaptor.asm
;
; Created: 5/3/2026 6:42:22 PM
; Author : sergei
;


.include "kernel/interrupt.inc" 
.include "kernel/hardware.inc" 
.include "kernel/kernel.inc" 

;.EQU TCP_MODE=1  ;client

.EQU TCP_MODE=2 ;server

.cseg
RESET:
	_keBOOT

	_REGISTER_TASK_STACK wifi_Tx1Rx4_task,150 
	_REGISTER_TASK_STACK usart_task,150


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

.IF TCP_MODE==1
	.include "tasks/wifi_client_Tx1Rx4_task.asm"
.ELIF TCP_MODE==2
	.include "tasks/wifi_server_Tx1Rx4_task.asm"
.ELSE
   .error "---------------------------Define a mode (server or client)-----------------------------------"
.ENDIF

.include "tasks/usart_task.asm"


.EXIT
