/*
Define the number of interrupts that will be processed at DEVICE level
@IMPORTANT - schedule timer does not count.It is processed 
in the interrupt handler as it is.
*/

.CSEG

.ORG        0x00  
	 rjmp    RESET      ;OS entry point

;.ORG RTC_PIT_vect
;     rjmp RTC_PIT_Intr


.ORG RTC_CNT_vect
     jmp RTC_CNT_Intr

.ORG        TCA0_OVF_vect
     rjmp SystemTickInt

.ORG PORTD_PORT_vect
     jmp PORTD_Intr

.ORG PORTC_PORT_vect
     jmp PORTC_Intr


;.ORG TCB0_INT_vect
;     jmp TCB0_Intr

;.ORG  USART0_RXC_vect
;     rjmp USART0_RXC_Intr

;.ORG PORTC_PORT_vect
;     rjmp PORTC_Intr


;.ORG OVF1addr
;     rjmp T1OVF       ;ordinary timer

;.ORG OVF5addr
;     rjmp T5OVF       ;ordinary timer


;.ORG TWIaddr
;    jmp TWI_Int

;.ORG OVF5addr
;     jmp Timer5OverflowInt 

;.ORG SPIaddr
;   jmp SPIComplete
.EXIT 
