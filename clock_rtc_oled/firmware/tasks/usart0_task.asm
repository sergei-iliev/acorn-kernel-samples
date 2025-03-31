/*
Scan i2c and send result to serial terminal
*/

;***********************************************USART 0***********************************************
#define BAUD_RATE 57600
#define USART0_BAUD_RATE ((SYSTEM_CLOCK * 64 / (16 * BAUD_RATE)) + 0.5)


.SET SECOND_EVENT_ID=7


.dseg
//ascii character 0-255
usart_digit_1:  .byte 1
usart_digit_2:  .byte 1 
usart_digit_3:  .byte 1
.cseg

usart0_task:	
cli
	rcall usart_init
sei
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

	
uart0_main:
	//wait until second interrupt arrives	
_EVENT_WAIT  SECOND_EVENT_ID
	//send clock over usart
    rcall send_usart_hour
	rcall send_usart_minute		
	rcall send_usart_second

rjmp uart0_main

/*Send hour digits to USART use RAM vars*/
send_usart_hour:
	//transform hour to ascii
	lds argument,hour
	rcall usart_dec_to_asci  //output is in RAM
	    
	 
	rcall usart_send_ascii_out
	
	//add semicolon		  
	ldi argument,':'
	rcall usart0_send	
ret

/*Send minute digits to USART use RAM vars*/
send_usart_minute:
	//transform minute to ascii
	lds argument,minute
	rcall usart_dec_to_asci  //output is in RAM
	    
	 
	rcall usart_send_ascii_out
	
	//add semicolon		  
	ldi argument,':'
	rcall usart0_send
ret

/*Send second digits to USART use RAM vars*/		
send_usart_second:
	//transform second to ascii
	lds argument,second
	rcall usart_dec_to_asci  //output is in RAM
	    
	rcall usart_send_ascii_out
		
ret

/*
Send ascii  digit out
Use RAM memory to pass X,Y and digits
*/
usart_send_ascii_out:
  
   lds argument,usart_digit_2  
   rcall usart0_send
      

   lds argument,usart_digit_3
   rcall usart0_send

ret

;*************************************************************************
;				Display byte as 1..3 digits 0..255
;check for leading zeros and remove them using T flag in SREG
;@INPUT:argument
;@USAGE:temp,argument
;@OUTPUT: oled_digit_1,oled_digit_2,oled_digit_3
;STACK: 1 level
;*************************************************************************
usart_dec_to_asci:         
		 ldi temp, -1 + '0' 
_uasc1: 
         inc temp 
         subi argument, 100 
         brcc _uasc1
;write out first digit		 
		 sts usart_digit_1,temp		 		 		 

         ldi temp, 10 + '0' 
_uasc2: 
         dec temp 
         subi argument, -10 
         brcs _uasc2
		 sbci argument, -'0' 
;write out second digit         
		 sts usart_digit_2,temp		 
;write out third digit
         sts usart_digit_3,argument		 
ret  


;@INPUT: argument
usart0_send:
    sts USART0_TXDATAL,argument
u0_wait_send:    
	lds temp,USART0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp u0_wait_send	
	
	lds temp,USART0_STATUS
	sbr temp, (1<<USART_TXCIF_bp)
	sts USART0_STATUS,temp
	
ret

;default is 8N1
usart_init:  

  ;input output   
  lds temp,PORTA_DIR
  sbr temp,(1<<PIN0)  ;output  Tx  PA0
  sts PORTA_DIR,temp
  ;output
  lds temp,PORTA_DIR
  cbr temp,(1<<PIN1)  ;input   Rx  PA1 
  sts PORTA_DIR,temp


  ;8 bit
  ;ERROR FOR SOME REASON I DON:T KNOW
  ;ldi temp,USART_CMODE_ASYNCHRONOUS_gc | USART_NORMAL_CHSIZE_8BIT_gc | USART_NORMAL_PMODE_DISABLED_gc | USART_NORMAL_SBMODE_1BIT_gc
  ;sts USART0_CTRLC,temp
     
  ldi r20,low(USART0_BAUD_RATE)
  ldi r21,high(USART0_BAUD_RATE)
  
  
  ;set baud rate
  sts USART0_BAUDL,r20
  sts USART0_BAUDH,r21

  ;enable Tx and Rx
  ;lds temp,USART0_CTRLB
  ori temp, USART_TXEN_bm | USART_RXEN_bm | USART_RXMODE_NORMAL_gc
  sts USART0_CTRLB,temp

  ;rcall enable_uart
  
  
ret

enable_uart:
//enable Rx interrupt
  lds temp,USART0_CTRLA
  ori temp,USART_RXCIE_bm
  sts USART0_CTRLA,temp
ret

disable_uart:
  lds temp,USART0_CTRLA
  cbr temp,1<<USART_RXCIE_bp
  sts USART0_CTRLA,temp

ret
