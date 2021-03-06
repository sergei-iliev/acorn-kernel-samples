.dseg
bitCount: .byte 1
bit:      .byte 1	;zero or one
dataBits: .byte 4

;delete
;debug: .byte 1
;debugOne: .byte 1
;debugZero:  .byte 1

cardCode: .byte 2
facilityCode: .byte 1
 
.cseg

#define WIEGAND_MAX_BITS 32
#define WIEGAND_BIT_COUNT 26

#define BIT_ONE 1
#define BIT_ZERO 0

/*
*shift left 4 byte memory location
*/
MLSL:
 clc
 lds temp,dataBits+3	;least significat byte		
 lsl temp   
 sts dataBits+3,temp

 lds temp,dataBits+2
 rol temp
 sts dataBits+2,temp

 lds temp,dataBits+1
 rol temp
 sts dataBits+1,temp

 lds temp,dataBits		;most significant byte
 rol temp
 sts dataBits,temp
ret

CardReader_Task:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
 
 ;set INT0 and INT1 lines
 rcall init_external_interrupt

 rcall reset_reader

cr_main:
    _EVENT_WAIT WIEGAND_READY_EVENT
    
	rcall decode

	_EVENT_SET DATA_READY_EVENT,TASK_CONTEXT

cr_int_end:  



rjmp cr_main

/*************************Card Reader decoder****************************
*@USAGE: r4,r5,r6 -> accumulated bit count     
*/
decode:
   ;card code
   lds r4,dataBits+3   ;least significant
   lds r5,dataBits+2   
   lds r6,dataBits+1   ;most significant
   
   
   lsr r6
   ror r5
   ror r4

   sts cardCode,r5
   sts cardCode+1,r4

   ;facility code
   lds r5,dataBits+1   
   lds r6,dataBits   ;most significant

   lsr r6
   ror r5

   sts facilityCode,r5

ret

/*
Reset card reader data
*/
;@USAGE: temp
reset_reader:
  clr temp
  sts bitCount,temp    ;bitCount=0

  sts cardCode,temp
  sts cardCode+1,temp

  sts facilityCode,temp

  sts dataBits,temp
  sts dataBits+1,temp
  sts dataBits+2,temp
  sts dataBits+3,temp
ret

;@USAGE: temp
init_external_interrupt:

	lds temp,EICRA
	sbr temp, (1<<ISC11)+(1<<ISC01)   ;falling edge of INT0 and INT1 generate int
	sts EICRA,temp

	in temp,EIMSK
	sbr temp,(1<<INT1)+(1<<INT0)
	out EIMSK,temp

ret

/************************************************
;Hardware and context dependent
;@USAGE temp reg
************************************************/
start_timeout_watch:

	lds temp,TCCR1B
	sbr temp,(1<<CS12)+(1<<CS10)   
	sts TCCR1B,temp

	ldi temp,0xDF		 ;0xA0 about	2 sec at 11MHz
	sts TCNT1H,temp
	clr temp
	sts TCNT1L,temp
;start
	lds temp,TIMSK1
	sbr temp,(1<<TOIE1)
	sts TIMSK1,temp
ret
/************************************************
;Hardware and context dependent
;@USAGE temp reg
************************************************/
stop_timeout_watch:
    lds temp,TCCR1B
	cbr temp,(1<<CS12)+(1<<CS10)   
	sts TCCR1B,temp

	lds temp,TIMSK1
	cbr temp,(1<<TOIE1)
	sts TIMSK1,temp
ret 

TimerOVF1:	
   _PRE_INTERRUPT
   ;sbi PORTB,PORTB2
   ;@USAGE:temp
   rcall stop_timeout_watch
   ;@USAGE:temp
   rcall reset_reader
  
   ;check if RS232 is available 
   ;_EVENT_SET RS232_AVAILABILITY_TIMEOUT_EVENT,INTERRUPT_CONTEXT

   _POST_INTERRUPT
reti

;D0 line interrup
int0INT:
   _PRE_INTERRUPT    

    ;all bits above maximum are discarded
	lds temp,bitCount
	cpi temp,WIEGAND_BIT_COUNT
	breq int0_exit

    lds temp,bitCount
	cpi temp,0				;first bit start timeout watch
	brne int0_count_bits

	;first bit strat timeout and move on
	;cbi PORTB,PORTB2 
	rcall start_timeout_watch
	
int0_count_bits:
	lds temp,bitCount
	inc temp
	sts bitCount,temp
    
   ;ZERO
   rcall MLSL
   ;is this the last bit
   lds temp,bitCount
   cpi temp,WIEGAND_BIT_COUNT
   brne int0_exit

   _EVENT_SET WIEGAND_READY_EVENT,INTERRUPT_CONTEXT

int0_exit:
_POST_INTERRUPT
reti



;D1 line interrup
int1INT:
   _PRE_INTERRUPT
    ;all bits above maximum are discarded
	lds temp,bitCount
	cpi temp,WIEGAND_BIT_COUNT
	breq int1_exit

    lds temp,bitCount
	cpi temp,0				;first bit start timeout watch
	brne int1_count_bits

	;first bit strat timeout and move on
	;cbi PORTB,PORTB2 
	rcall start_timeout_watch
	
int1_count_bits:
	lds temp,bitCount
	inc temp
	sts bitCount,temp

   ;ONE
    rcall MLSL
    lds temp,dataBits+3      ;add 1 to least significant bit
    ori temp,0b00000001
    sts dataBits+3,temp

	;is this the last bit
    lds temp,bitCount
	cpi temp,WIEGAND_BIT_COUNT
	brne int1_exit
	
	_EVENT_SET WIEGAND_READY_EVENT,INTERRUPT_CONTEXT
int1_exit:

_POST_INTERRUPT
reti



.EXIT        