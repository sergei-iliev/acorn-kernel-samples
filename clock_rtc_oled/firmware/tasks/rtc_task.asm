
#define RTC_TASK_ID 5


rtc_task:

  //---setup LED pin on PA3
  ;lds temp,PORTA_DIR
  ;sbr temp,1<<PIN3
  ;sts PORTA_DIR,temp

  //---init RTC
  rcall rtc_init
  
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	_INTERRUPT_DISPATCHER_INIT temp,RTC_TASK_ID

rtc_main:

 	_INTERRUPT_WAIT RTC_TASK_ID
	/**skip if button SET is active***/ 
	  lds temp,left_right_button
	  tst temp
	  brne	rtcend
	;every second tick
	  lds temp,second
	  inc temp
	  cpi temp,60
	  breq rtcmin_00
	  sts second,temp
	  rjmp rtcend
rtcmin_00:
      clr temp			;nulify seconds to start over
	  sts second,temp
      
	  lds temp,minute
	  inc temp

	  cpi temp,60
	  breq rtcmin_01
	  sts minute,temp
	  rjmp rtcend
rtcmin_01:
      clr temp			;nulify minutes to start over
	  sts minute,temp
      
	  lds temp,hour
	  inc temp

	  cpi temp,24
	  breq rtcmin_02
	  sts hour,temp
	  rjmp rtcend
rtcmin_02:
      clr temp			;nulify hour to start over
	  sts hour,temp
      

rtcend:
      
	_INTERRUPT_END RTC_TASK_ID

rjmp rtc_main


;*********************
;USAGE: temp,r17
;*********************
rtc_init:
 lds temp,RTC_STATUS     /* Wait for all register to be synchronized */
 tst temp
 brne rtc_init


 ori temp, 1 << RTC_RTCEN_bp; /* Enable: enabled */
 sts RTC_CTRLA,temp


 ldi temp,low(0x3ff)   
 ldi r17,high(0x3ff)

 sts RTC_PERL,r16
 sts RTC_PERH,r17

 ldi temp,RTC_CLKSEL_OSC1K_gc
 sts RTC_CLKSEL,temp

 ldi temp, 1 << RTC_OVF_bp
 sts RTC_INTCTRL,temp

ret

;1 second interrupt
RTC_CNT_Intr:
_PRE_INTERRUPT

  ;clear intr flag
  lds temp,RTC_INTFLAGS
  sbr temp, 1<<RTC_OVF_bp
  sts RTC_INTFLAGS,temp 

  //let the usart send current timing
  _EVENT_SET SECOND_EVENT_ID, INTERRUPT_CONTEXT

  _keDISPATCH_DPC RTC_TASK_ID

.EXIT

