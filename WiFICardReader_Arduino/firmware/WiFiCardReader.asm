;Look at http://www.acorn-kernel.net/ for sample Applications
;3 demo tasks are included to demostrate sleep mode integration
;sergei_iliev@yahoo.com
;Ask questions or give ideas!!!
.include "m328Pdef.inc"
.include "16bitMath.inc"






.include "INTERRUPTS.inc" 
.include "Kernel.inc"

.cseg
.def    temp=r16    ;temp reg.

.include "HARDWARE.inc"

RESET:     
    ;One rcall depth for the stack during system init 
	ldi     temp,high(RAMEND-2)        ;Set stack pointer to bottom of RAM-2 for system init
    out     SPH,temp
    ldi     temp,low(RAMEND-2)
    out     SPL,temp
     	       
;clear SRAM
	ldi XL,low(RAMEND+1)
	ldi XH,high(RAMEND+1)    		   
    clr r0
initos:
	st -X,r0
	cpi XH,high(SRAM_START) 
    brne initos
    cpi XL,low(SRAM_START)
	brne initos

	_REGISTER_TASK_STACK System_Task,1,50
	_REGISTER_TASK Config_Task,2 
	_REGISTER_TASK LCD_Task,3 
	_REGISTER_TASK CardReader_Task,4 
	_REGISTER_TASK WiFi_Task,5
	_REGISTER_TASK Alarm_Task,6 

/*	 
;****************init Task_1
	.IFDEF TCB_1
	_REGISTER_TASK System_Task,1,TCB_1 
    .ENDIF
;********************init Task_2
    .IFDEF TCB_2
	_REGISTER_TASK Config_Task,2,TCB_2 
	.ENDIF
;********************init Task_3
	.IFDEF TCB_3
	_REGISTER_TASK LCD_Task,3,TCB_3 
	.ENDIF
;********************init Task_4
	.IFDEF TCB_4
	_REGISTER_TASK CardReader_Task,4,TCB_4 
	.ENDIF
;********************init Task_5
	.IFDEF TCB_5
	_REGISTER_TASK WiFi_Task,5,TCB_5 
	.ENDIF
;********************init Task_6
	.IFDEF TCB_6
	_REGISTER_TASK Alarm_Task,6,TCB_6 
	.ENDIF
*/

;set up Timer0
    _INIT_TASKSHEDUAL_TIMER
;start timers

;start Timer0(Schedualing and time ticking)	
	_ENABLE_TASKSHEDUAL_TIMER


;initialize current task pointer with Task_1
	ldi     temp,high(RAMEND)
    out     SPH,temp
    ldi     temp,low(RAMEND)
    out     SPL,temp

    ldi XL,low(TCB_1) 
	
	sts pxCurrentTCB,XL
	
	sei      



//***curent stack pointer is at the begining of Task_1
.include "Tasks.asm"

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


;.dseg
;stacksize: .byte TASK_STACK_DEPTH*TASKS_NUMBER 
;.cseg


.EXIT



