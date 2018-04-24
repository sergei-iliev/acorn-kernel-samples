/*
Define the number of interrupts that will be processed at DEVICE level
@IMPORTANT - schedule and clock timers does not count.They are processed 
in the interrupt handler as it is.
*/

.CSEG

.ORG        0x00  
	 rjmp    RESET      ;OS entry point

;.ORG INT0addr           	
;     rjmp int0INT 

;.ORG INT1addr           
;     rjmp int1INT    

.ORG OVF1addr
     rjmp TimerOVF1      

.ORG OVF0addr
     rjmp SystemTickInt   ;kernel task scheduler

.ORG ADCCaddr	        ;task
     rjmp adcINT

;.ORG TWIaddr
;     rjmp twiINT        ;2 wire interrupt 

;.ORG  INT2addr
;   rjmp extINT2   

.EXIT 
