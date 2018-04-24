;sergei_iliev@yahoo.com
;Ask questions or give ideas!!!
;BEWARE SRAM_START	= 0x0100
/*
Lead acid battery 50Ah
*/
.include "m88PAdef.inc"
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
;****************init Task_1
	.IFDEF TCB_1
	_REGISTER_TASK System_Task,1,TCB_1 
    .ENDIF
;********************init Task_2
    .IFDEF TCB_2
	_REGISTER_TASK Task_2,2,TCB_2 
	.ENDIF
;********************init Task_3
	.IFDEF TCB_3
	_REGISTER_TASK Task_3,3,TCB_3 
	.ENDIF
;********************init Task_4
	.IFDEF TCB_4
	_REGISTER_TASK Task_4,4,TCB_4 
	.ENDIF
;********************init Task_5
	.IFDEF TCB_5
	_REGISTER_TASK Task_5,5,TCB_5 
	.ENDIF
;*******************************

;set up Timer0
    _INIT_TASKSHEDUAL_TIMER temp
;start timers

;start Timer0(Schedualing and time ticking)	
	_ENABLE_TASKSHEDUAL_TIMER temp	


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

	_keOS_SAVE_CONTEXT
;start LIMBO state 
    ;_DISABLE_TASKSHEDUAL_TIMER
    
	_keSWITCH_TASK

    ;_ENABLE_TASKSHEDUAL_TIMER
;end LIMBO state
	_keOS_RESTORE_CONTEXT

reti

SystemTickInt:
  _PRE_INTERRUPT   
   
  _kePROCESS_SLEEP_INTERVAL	
  
  _POST_INTERRUPT
rjmp TaskSchedular

;#ifdef DEBUG
;.dseg
;total_stack:   .byte TASKS_NUMBER*TASK_STACK_DEPTH
;.cseg
;#endif 
.EXIT








