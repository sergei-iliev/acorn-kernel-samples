
/*
Select digit {hour:min:sec} to manipulate
*/
.equ PIN0 = 0
.equ PIN1 = 1
.equ PIN2 = 2
.equ PIN3 = 3
.equ PIN4 = 4
.equ PIN5 = 5
.equ PIN6 = 6
.equ PIN7 = 7

//Interrupt dispatch vector index
#define BUTTON_PRESS_PORTC_ID 7

button_select_digit_task:
  //---setup LED pin on PA2
	lds temp,PORTA_DIR
	sbr temp,1<<PIN2
	sts PORTA_DIR,temp	

  ;input
   lds temp,PORTC_DIR
   cbr temp,(1<<PIN0)	;PORT_INT0_bp
   sts PORTC_DIR,temp
  
  ;internal pullup enable
  lds temp, PORTC_PIN0CTRL
  sbr temp, 1<<PORT_PULLUPEN_bp
  sts PORTC_PIN0CTRL,temp

  ;interrupt
   lds temp,PORTC_PIN0CTRL
   ori temp,PORT_ISC_FALLING_gc
   sts PORTC_PIN0CTRL,temp

   
   	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	_INTERRUPT_DISPATCHER_INIT temp,BUTTON_PRESS_PORTC_ID


main_btn_select_evsys:
 	_INTERRUPT_WAIT BUTTON_PRESS_PORTC_ID
      lds temp,left_right_button
	  inc temp
	  cpi temp,4
	  breq btnsel_00
	  sts left_right_button,temp
	  rjmp btnsel_exit
btnsel_00:
	  clr temp		;set to inactive
	  sts left_right_button,temp			
	  
btnsel_exit:
	_INTERRUPT_END BUTTON_PRESS_PORTC_ID
	
   _SLEEP_TASK_EXT 5000
   
   ;interrupt enable
   lds temp,PORTC_PIN0CTRL
   ori temp,PORT_ISC_FALLING_gc
   sts PORTC_PIN0CTRL,temp

rjmp main_btn_select_evsys

PORTC_Intr:
_PRE_INTERRUPT
	 
  ;is this comming from PIN5
  lds temp,PORTC_INTFLAGS
  sbrs temp, PORT_INT_0_bp
  rjmp porta_intr_exit

  ;clear intr flag
  lds temp,PORTC_INTFLAGS
  sbr temp,1<<PORT_INT_0_bp
  sts PORTC_INTFLAGS,temp

  ;disable interrupt
  lds temp,PORTC_PIN0CTRL
  andi temp,0b11111000     ;clear ISC bits
  ori temp,PORT_ISC_INTDISABLE_gc
  sts PORTC_PIN0CTRL,temp

  //yes it is pressed - send DPC
  _keDISPATCH_DPC BUTTON_PRESS_PORTC_ID

porta_intr_exit:
  ;clear intr flag
  lds temp,PORTC_INTFLAGS
  sbr temp,1<<PORT_INT_0_bp
  sts PORTC_INTFLAGS,temp

_POST_INTERRUPT
_RETI

/*
init_event_system:
  ;input
   lds temp,PORTC_DIR
   cbr temp,(1<<PIN0)	;PORT_INT0_bp
   sts PORTC_DIR,temp
   
   lds temp, PORTC_PIN0CTRL
   sbr temp, 1<<PORT_PULLUPEN_bp
   sts PORTC_PIN0CTRL,temp
  
  ;EVENT SYS
  lds temp, EVSYS_CHANNEL3
  ori temp,EVSYS_CHANNEL3_PORTC_PIN0_gc
  sts EVSYS_CHANNEL3,temp

  lds temp,EVSYS_USERTCB0CAPT 
  ori temp, EVSYS_USER_CHANNEL3_gc
  sts EVSYS_USERTCB0CAPT,temp

  ;TIMER
   	ldi temp,low(0xFFFF)
	ldi r17,high(0xFFFF)
    
	sts TCB0_CCMPL,temp
	sts TCB0_CCMPH,r17
	
	
	lds temp,TCB0_CTRLB 
	ori temp, TCB_CNTMODE_SINGLE_gc
	sts TCB0_CTRLB,temp 
	
	lds temp,TCB0_EVCTRL
	ori temp,TCB_FILTER_bm|TCB_CAPTEI_bm | TCB_EDGE_bm
	sts TCB0_EVCTRL,temp
    
	lds temp,TCB0_CTRLA
	ori temp,TCB_CLKSEL_1_bm | TCB_ENABLE_bm
	sts TCB0_CTRLA,temp

   	ldi temp,low(0xFFFF)
	ldi r17,high(0xFFFF)
    
	sts TCB0_CNTL,temp
	sts TCB0_CNTH,r17
	

	lds temp,TCB0_INTCTRL
	ori temp, TCB_CAPT_bm
	sts TCB0_INTCTRL,temp
ret


TCB0_Intr:
_PRE_INTERRUPT
	;clear intr
	lds temp,TCB0_INTFLAGS
	ori temp, TCB_CAPT_bm|TCB_OVF_bm;
	sts TCB0_INTFLAGS,temp

	;LED toggle
	lds temp,PORTA_OUTTGL
    sbr temp,1<<PIN2
    sts PORTA_OUTTGL,temp	 

		


_POST_INTERRUPT
_RETI
*/
.EXIT


