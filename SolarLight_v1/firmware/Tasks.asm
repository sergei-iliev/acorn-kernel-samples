.cseg
	  
;*****DON'T PUT INCLUDE FILES BEFORE TASK 1 DEFINITION
System_Task:

 ;init sleep subsystem
 _SLEEP_CPU_INIT temp

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 


main1:
 _SLEEP_CPU r16,r17
    
_YIELD_TASK
rjmp main1  


.def    argument=r17   
.def    return = r18
.def    t1=r19
.def    t2=r20
.def    counter=r21

.include "include\LCD4bitWinstarDriver.asm"
Task_2:		

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
		 
	rcall lcd4_init
	
	
	;ldi argument,LCD_LINE_1 
	;rcall lcd4_command

	;ldi	argument,'A'
	;rcall lcd4_putchar
	

	;ldi	argument,'c'
	;rcall lcd4_putchar

	;ldi	argument,'o'
	;rcall lcd4_putchar

	;ldi	argument,'r'
	;rcall lcd4_putchar

	;ldi	argument,'1'
	;rcall lcd4_putchar


main2:
;_YIELD_TASK

   ldi	argument,LCD_LINE_1
   rcall	lcd4_command

   lds argument,adcMSB1
   rcall lcd4_hex_out

   lds argument,adcLSB1
   rcall lcd4_hex_out
 

   ldi	argument,LCD_LINE_2
   rcall	lcd4_command


   lds argument,adcMSB2
   rcall lcd4_hex_out

   lds argument,adcLSB2
   rcall lcd4_hex_out


  _SLEEP_TASK 255

rjmp main2




.def counter=r17  
.def axl = r18
.def axh = r19
.def bxl = r20
.def bxh = r21

.include "include\16bitFILO.asm"

/*
Mind the system clock!!!The prescalor is for 8MHz
1.Set up and read ADCL:ADCH 
2.Fire another single mode ADC sampling
*/
.dseg 
adcLSB1:   .byte 1  ;Measure PV input 
adcMSB1:   .byte 1

adcLSB2:   .byte 1	;Measure VBat input
adcMSB2:   .byte 1

BulbState:     .byte 1

DayNightValue: .byte 1
.cseg

.SET ADCIntInd=7
.SET TimeoutIntInd=6

.SET pv_event_id= EXP2(0)
.SET load_event_id= EXP2(1)

.SET HIGH_DARKNESS_TRESHOLD=350
.SET LOW_DARKNESS_TRESHOLD=50

#define DAY  0x00
#define GRAY 0x01
#define NIGHT 0x02

;----------------------
;DAY
;PV is on if Acc is not fully charged
;LED is off
;----------------------  HIGH_DARKNESS_TRESHOLD
;GRAY
;PV is off
;LED is off
;----------------------  LOW_DARKNESS_TRESHOLD
;NIGHT
;PV os off
;LED is on if Acc is not depleted
;----------------------

Task_3: 
		
     //register ADC interrupt DPC
_INTERRUPT_DISPATCHER_INIT temp,ADCIntInd	  	 	 	 
	 
	 ;disable digital input on PORTC4 and PORTC5
	 lds temp, DIDR0
	 sbr temp,(1<<ADC4D)+(1<<ADC5D)
	 sts DIDR0,temp
	 ;select  Avcc with external capacitor at AREF
	 lds temp,ADMUX
	 sbr temp,(1<<REFS0) 	 
	 sts ADMUX,temp

	 lds temp,ADCSRA
	 ;sampling rate at 4Mhz is 125kHz if 32 divisor is picked
	 sbr temp,(1<<ADPS2)+(1<<ADPS0)   ;32 division of system clock		 
     cbr temp,(1<<ADATE)   ;disable free running mode 
	 sts ADCSRA,temp	 	 
     
	 ;init average buffer
	 rcall QueueInit

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	  	 	 	
	 clr r18    ;flag to init queue	 
	 
	 ;init day night value
	 ldi temp,GRAY
	 sts DayNightValue,temp 	      

main3:

     ;disconnect PV transistor to get real measument
	 cbi PORTD,PORTD0


	 rcall sleep_1s	

;measure first channel Pv
	 ;select PORTC.5 as ADC input PV
	 lds temp,ADMUX
	 cbr temp,(1<<MUX3)+(1<<MUX2)+(1<<MUX1)+(1<<MUX0)
	 sbr temp,(1<<MUX2)+(1<<MUX0)	
	 sts ADMUX,temp 


 	 lds temp,ADCSRA
	 sbr temp,(1<<ADEN)+(1<<ADIE)+(1<<ADSC)    ;start ADC
											   ;enable interrupts
											   ;start convertion in single mode    
	 sts ADCSRA,temp

	_INTERRUPT_WAIT	ADCIntInd

	;read result
	;THERE IS NO NEED TO SYNCHRONIZE HERE
	;This portion is executed in a higher privilage level then LCD task which reads the value in RAM	

    lds axl,ADCL
	lds axh,ADCH   

    sts adcLSB1,axl
	sts adcMSB1,axh

	;calculate DAY,GRAY or NIGHT
	 CPI16 axl,axh,temp,HIGH_DARKNESS_TRESHOLD
	 brlo graynight 
	 
	 ldi temp,DAY
	 sts DayNightValue,temp 
	 rjmp exitlightcalculation

graynight:
     CPI16 axl,axh,temp,LOW_DARKNESS_TRESHOLD
	 brlo night

	 ldi temp,GRAY
	 sts DayNightValue,temp      
	 rjmp exitlightcalculation
night:
	 ldi temp,NIGHT
	 sts DayNightValue,temp      

exitlightcalculation:

    _INTERRUPT_END ADCIntInd   

;***measure second channel ACC
	 ;select PORTC.4 as ADC input ACCU
	 lds temp,ADMUX
	 cbr temp, (1<<MUX3)+(1<<MUX2)+(1<<MUX1)+(1<<MUX0)
	 sbr temp,(1<<MUX2)	     
	 sts ADMUX,temp 

 	 lds temp,ADCSRA
	 sbr temp,(1<<ADEN)+(1<<ADIE)+(1<<ADSC)    ;start ADC
											   ;enable interrupts
											   ;start convertion in single mode    
	 sts ADCSRA,temp


	_INTERRUPT_WAIT	ADCIntInd

//calculate averige
    lds axl,ADCL
	lds axh,ADCH  
	
	sts adcLSB2,axl
	sts adcMSB2,axh
	 
    rcall QueuePush 
;is this first measurement?   
    tst r18
    brne calc_average 
    rcall QueuePush
	rcall QueuePush
	rcall QueuePush
	ser r18 
calc_average:
    rcall QueueAvgSum


	
    _INTERRUPT_END ADCIntInd

   ;connect PV transistor back
   ;lds bxl,PinFlag
   ;tst bxl
   ;breq TransistorPV_off
   ;sbi PORTD,PORTD0
   ;TransistorPV_off:

    ;PV control
	_EVENT_SET pv_event_id,TASK_CONTEXT
    
	;Load control
	_EVENT_SET load_event_id,TASK_CONTEXT
	
	;wait for the PV task and LOAD task to execute
	_CYCLICBARRIER_WAIT  synchbarrier,3
		
	;put circuit into sleep
	_SLEEP_CPU_REQUEST VOID_CALLBACK,VOID_CALLBACK,temp

rjmp main3


/*
Power Transistor control(PV to Acc) at PD.0
*/
.SET MAX_VOLTAGE_ACCUMULATOR=700   ;13.7V
;.SET MIN_VOLTAGE_ACCUMULATOR=675   ;13.V

//min voltage to connect PV to accumulator
.SET PV_VOLTAGE_THRESHHOLD=700 ;13.7V ;767   ;15.0

Task_4:
   sbi DDRD,DDD0
   cbi PORTD,PORTD0  ;turn off TR

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main4:
;wait measurement
    _EVENT_WAIT pv_event_id    ;simple event

	;is it day
	lds temp,DayNightValue
	cpi temp,DAY
	brne pvdark 
	
	;check PV voltage - is it above the threshhold
	lds axl,adcLSB1
	lds axh,adcMSB1
	CPI16 axl,axh,temp,PV_VOLTAGE_THRESHHOLD
	brlo pvdark

    ;charge or discharge depending on ACC state
	lds axl,adcLSB2
	lds axh,adcMSB2
    CPI16 axl,axh,temp,MAX_VOLTAGE_ACCUMULATOR
    brsh pvready
    ;acc is below standby voltage - start charging
	;turn on MOSFET
	sbi PORTD,PORTD0 	
	rjmp pvtaskend	   

pvready:
	;turn off MOSFET
    cbi PORTD,PORTD0 	 
	rjmp pvtaskend 
pvdark:
    ;turn off charging when dark
	cbi PORTD,PORTD0  ;turn off TR

pvtaskend:

	_CYCLICBARRIER_WAIT  synchbarrier,3


rjmp main4
 

//MOSFET to control the load.
//In case of a lamp - it should fire at dark until batery diplition
.SET VOLTAGE_LOAD_THRESHOLD=544   ;10.6V

.SET BULB_ENABLE=0xFF
.SET BULB_DISABLE=0x00
Task_5:

  sbi DDRB,DDB0   
  cbi PORTB,PORTB0  ;turn off Lamp
  
  ldi temp,BULB_ENABLE
  sts BulbState,temp 		

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main5:
    ;wait for notification from the voltage measuring
    _EVENT_WAIT load_event_id

	;is it day
	lds temp,DayNightValue
	cpi temp,NIGHT
	brne lampday 
	;night
	;is batery LOW?
    lds axl,adcLSB2
	lds axh,adcMSB2
    CPI16 axl,axh,temp,VOLTAGE_LOAD_THRESHOLD
	brsh lampbatteryhigh	
    
	cbi PORTB,PORTB0   ;disconnect load		
	;disable until day light
	ldi temp,BULB_DISABLE
    sts BulbState,temp 
	rjmp lamptaskend  

lampbatteryhigh:    	
    ;let the BULB ON
	lds temp,BulbState 
	cpi temp,BULB_ENABLE
	brne lamptaskend

    sbi PORTB,PORTB0	;reconnect load(night)	 
	rjmp lamptaskend

lampday:
	;day or gray
	cbi PORTB,PORTB0  ;turn off Lamp
	
	;set flag to enable in DAY only
	lds temp,DayNightValue
	cpi temp,DAY
	brne lamptaskend

	ldi temp,BULB_ENABLE
    sts BulbState,temp 
lamptaskend:

	_CYCLICBARRIER_WAIT  synchbarrier,3

rjmp main5


sleep_1s:
  _SLEEP_TASK 200
  _SLEEP_TASK 200
  
  _SLEEP_TASK 200
  _SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

  ;_SLEEP_TASK 200
  ;_SLEEP_TASK 200

ret
;------------------ADC complete------------------------------
;happens in arbitrary context
adcINT:
   _PRE_INTERRUPT
	lds temp,ADCSRA
	cbr temp,(1<<ADEN)    ;stop ADC
	cbr temp,(1<<ADIE)    ;disable ADC interrupts		
    sts ADCSRA,temp
   _keDISPATCH_DPC ADCIntInd

;break out from sleep
TimerOVF1:	
   _PRE_INTERRUPT
        
   _POST_INTERRUPT
reti

.EXIT