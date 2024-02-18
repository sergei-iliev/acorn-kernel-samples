.EQU PIN3 =3

#define  RTC_TASK_ID 3   ;in main.asm task position is 3
rtc_task:
  //---init RTC
  rcall rtc_init
  //---setup LED pin on PB1
  lds temp,PORTA_DIR
  sbr temp,1<<PIN3
  sts PORTA_DIR,temp

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER


rtc_main:

  _INTERRUPT_WAIT RTC_TASK_ID
    lds temp,PORTA_IN
	sbrs temp,PIN3
	rjmp rtc_led_on
	//OF
	lds temp,PORTA_OUT
	cbr temp,1<<PIN3
	sts PORTA_OUT,temp

	rjmp rtc_end_00

rtc_led_on:
	//ON
	lds temp,PORTA_OUT
	sbr temp,1<<PIN3
	sts PORTA_OUT,temp
rtc_end_00:
  _INTERRUPT_END RTC_TASK_ID

  ;is sleep requested
  	_SLEEP_CPU_TASK disable_rtc,enable_rtc,temp
rjmp rtc_main



;USAGE: temp,r17
rtc_init:
 
 lds temp,RTC_STATUS     /* Wait for all register to be synchronized */
 tst temp
 brne rtc_init
 
 lds temp,RTC_CTRLA
 ori temp,RTC_PRESCALER_DIV32_gc| 1 << RTC_RTCEN_bp| 0 << RTC_RUNSTDBY_bp
 sts RTC_CTRLA,temp

 ldi temp,low(0x3f4)   
 ldi r17,high(0x3f4)

 sts RTC_PERL,r16
 sts RTC_PERH,r17
 
 lds temp,RTC_INTCTRL
 ori temp, 0 << RTC_CMP_bp | 1 << RTC_OVF_bp  /* Overflow Interrupt enable: enabled */ 
 sts RTC_INTCTRL,temp

loop_rtc_0:
 lds temp,RTC_STATUS     /* Wait for all register to be synchronized */
 tst temp
 brne loop_rtc_0


 ori temp,RTC_PERIOD_OFF_gc | 1 << RTC_PITEN_bp; /* Enable: enabled */
 sts RTC_PITCTRLA,temp

ret

enable_rtc:
 ori temp,RTC_PERIOD_OFF_gc | 1 << RTC_PITEN_bp; /* Enable: enabled */
 sts RTC_PITCTRLA,temp
ret

disable_rtc:
 cbr temp, 1 << RTC_PITEN_bp; /* disable */
 sts RTC_PITCTRLA,temp
ret

RTC_PIT_Intr:
_PRE_INTERRUPT

  ;clear intr flag
  lds temp,RTC_INTFLAGS
  sbr temp,1<<PORT_INT0_bp | 1<<PORT_INT1_bp
  sts RTC_INTFLAGS,temp 

 _keDISPATCH_DPC RTC_TASK_ID
