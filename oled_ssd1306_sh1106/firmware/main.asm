;
; SSD1306 and SH1106 OLED
;
; Created: 5/13/2024 1:10:26 PM
; Author : Sergey Iliev
;


.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"

/*
Target OLED display
*/

;#define SSD1306
#define SH1106 




.cseg
RESET:	

	_keBOOT
	_REGISTER_TASK sys_task,100
	#ifdef  SSD1306
		_REGISTER_TASK ssd1306_task,100		
	#endif
	#ifdef  SH1106
		_REGISTER_TASK sh1106_task,100		
	#endif

	_REGISTER_TASK rs232_task,100

	

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

reti

SystemTickInt:
  _PRE_INTERRUPT   
   
  _kePROCESS_SLEEP_INTERVAL	
  
  _POST_INTERRUPT
rjmp TaskSchedular

#ifdef SSD1306
.include "tasks/ssd1306_task.asm"
#endif

#ifdef SH1106
.include "tasks/sh1106_task.asm"
#endif
.include "tasks/sys_task.asm"
.include "tasks/rs232_task.asm"

.EXIT


