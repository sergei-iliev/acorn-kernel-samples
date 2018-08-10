/*
ESP8862 WiFi
*/
#define RESPONSE_NONE 0x00
#define RESPONSE_OK 0x01
#define RESPONSE_FAILURE 0x80

.def    argument=r17  
.def    return = r18
.def    axl=r19
.def    axh=r20

.def	bxl=r21
.def    bxh=r22


;115200   ;U2X0=1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Due to the error
#define UBRR_VAL    8 /*8 MHz*/ 

#define RESPONSE_BUFFER_SIZE  200

#define ANSWER_BUFFER_SIZE    50

#define REQUEST_BUFFER_SIZE   160

.dseg

RxByte: .byte 1 
RxTail:  .byte 1
WiFiStatus: .byte 1
WiFiResult: .byte 1

debug:     .byte 3

ResponseBuffer: .byte RESPONSE_BUFFER_SIZE
RequestBuffer:  .byte REQUEST_BUFFER_SIZE
AnswerBuffer:   .byte ANSWER_BUFFER_SIZE
.cseg

.include "include/strings.asm"
.include "include/wifiop.asm"


WiFi_Task:
 

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

;wait for non configuration event
 _EVENT_WAIT NORMAL_MODE_EVENT


wifi_reset:
	rcall usart_disable
 
 ;wait some time 
	sbi PORTD,PD4
	rcall wait_1s
	rcall wait_1s
	rcall wait_1s

	rcall usart_init
	rcall usart_enable

	rcall wifi_init
    lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne wifi_reset

	cbi PORTD,PD4
wifi_main:
    cbi PORTD,PD4
    _EVENT_WAIT DATA_READY_EVENT
	sbi PORTD,PD4
	ldi temp,RESPONSE_NONE
    sts WiFiResult,temp

	
 	rcall wifi_check_AP_availability		;check connection to AP
    brts wf_error_router 
		
	rcall wifi_connection		;set up connection
	lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne wf_error
	  	  
		  
	rcall wifi_start			;check if server is available       
	brts wf_error_router
	lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne wf_error
	

	rcall wifi_send			;send Card data, 3 bytes
	;read response
	rcall wifi_read			;read response, 1 byte
	lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne wf_error

	rcall wifi_close
	;lds temp,WiFiStatus
	;cpi temp,ESP8266_RESPONSE_FINISHED
	;brne wf_error

 
rjmp wifi_main

wf_error: 
 rcall wait_1s
 rcall wait_1s
 rcall wait_1s
 rcall wait_1s
rjmp wifi_main

wf_error_router:
 rcall router_error_on
rjmp wifi_main

/*****USART Init Interrupt mode********************
*Enable Interrupt at recieve byte only
*@USAGE:temp
*/
usart_init:
	ldi temp,high(UBRR_VAL)
	sts UBRR0H,temp 

	ldi temp,low(UBRR_VAL)
	sts UBRR0L,temp

	; Disable receiver interrupt
	rcall usart_disable

	lds temp,UCSR0A
	sbr temp,(1<<U2X0)
	sts UCSR0A,temp
		
	ldi temp, (1 << UCSZ01) | (1 << UCSZ00)	
	sts UCSR0C,temp

ret
/*
*@USAGE:temp
*/
usart_disable:
    lds temp,UCSR0B
	cbr temp,(1 << RXCIE0)|(1<<RXEN0)|(1<<TXEN0)
	sts UCSR0B,temp
ret
/*
*@USAGE:temp
*/
usart_enable:
    lds temp,UCSR0B
	sbr temp,(1 << RXCIE0)|(1<<RXEN0)|(1<<TXEN0)
	sts UCSR0B,temp
ret
/*******************WiFi Begin****************
*@INFO:Register to a WiFi access point
*@USAGE:
****************************************/
wifi_init:
  rcall wifi_begin
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne wf_init_exit

  rcall wifi_mode
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne wf_init_exit

  rcall wifi_connection
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne wf_init_exit

  rcall wifi_application
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne wf_init_exit

  rcall wifi_join_access_point
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne wf_init_exit

wf_init_exit:
ret

/*******************WiFi Begin****************
*@INFO:Send AT command to disable echo
*@USAGE:
****************************************/

wifi_begin:
  ;AT_ECHO_OFF
  ldi	ZH,high(AT_ECHO_OFF*2)
  ldi	ZL,low(AT_ECHO_OFF*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

    ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)

  rcall send_AT_expect_response
  
 
ret

/*******************WiFi Mode****************
*@INFO:Set WiFi mode /3 = Both (AP and STA)/
*@INPUT:
*@USAGE:
****************************************/
wifi_mode:
;AT_MODE	
  ldi	ZH,high(AT_MODE*2)
  ldi	ZL,low(AT_MODE*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response


ret
/*******************WiFi Connection Mode****************
*@INFO:Set WiFi connection /0 = Single connection 1= multiple connections
*@INPUT:
*@USAGE:
****************************************/
wifi_connection:
;AT_MODE	
  ldi	ZH,high(AT_CIPMUX*2)
  ldi	ZL,low(AT_CIPMUX*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response
ret
/*******************WiFi Application Mode****************
*@INFO:Set WiFi connection /0 = Single connection 1= multiple connections
*@INPUT:
*@USAGE:
****************************************/
wifi_application:
;AT_CIPMODE	
  ldi	ZH,high(AT_CIPMODE*2)
  ldi	ZL,low(AT_CIPMODE*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response

ret
/*******************WiFi Check Status****************
*@INFO:Read WiFi connection status and compare to input param
 /2 = Got IP, connected to AP
  3 = Connected via TCP or UDP
  4 = Disconnected
  5 = WiFi dos not connect to AP
*@INPUT:Y input param to check against
*@USAGE:
*@OUTPUT: T  flag
****************************************/
wifi_check_AP_availability:	
  ldi	ZH,high(AT_CIPSTATUS*2)
  ldi	ZL,low(AT_CIPSTATUS*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response


  ;lost AP in answer buffer?
  
  ldi	ZH,high(CONNECTION_STATUS_5*2)
  ldi	ZL,low(CONNECTION_STATUS_5*2)
  rcall load_answer_buffer

  ldi	XH,high(ResponseBuffer)
  ldi	XL,low(ResponseBuffer)

  ldi	YH,high(AnswerBuffer)		
  ldi	YL,low(AnswerBuffer)

   ;X,Y is input   
   rcall _strstr    
   ;output T 
ret

/*******************WiFi Status****************
*@INFO:Read WiFi connection status 
 /2 = Got IP, connected to AP
  3 = Connected via TCP or UDP
  4 = Disconnected
  5 = WiFi dos not connect to AP
*@INPUT:
*@USAGE:
****************************************/
/*
wifi_connection_status:
;AT_CIPSTATUS	
  ldi	ZH,high(AT_CIPSTATUS*2)
  ldi	ZL,low(AT_CIPSTATUS*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response
ret
*/
/*******************WiFi Connect to Access Point from configuration EEPROM****************
*@INFO: WiFi Connect to router using EEPROM config data
*@INPUT:
*@USAGE:
****************************************/
wifi_join_access_point:
;AT_CWJAP	
  ldi	ZH,high(VAR_AT_CWJAP*2)
  ldi	ZL,low(VAR_AT_CWJAP*2)
  rcall load_request_buffer

  ;read access point config
  ldi ZL,low(EEPROM_CONFIG_ADDR)
  ldi ZH,high(EEPROM_CONFIG_ADDR)
    
  ldi axh,49 ; size of AP string
  rcall append_eeprom_to_request_buffer

  ;add \r\n
  ldi argument,0x0D
  rcall append_byte_to_request_buffer
  ldi argument,0x0A
  rcall append_byte_to_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response
  
ret
/*******************WiFi Start ****************
*@INFO: WiFi Start TCP connection, using EEPROM config data
*@INPUT:
*@USAGE:Z,X,Y
****************************************/
wifi_start:
;AT_CIPSTART	
  ldi	ZH,high(VAR_AT_CIPSTART*2)
  ldi	ZL,low(VAR_AT_CIPSTART*2)
  rcall load_request_buffer

  ;add eeprom config data
  ;read access point config
  ldi ZL,low(EEPROM_CONFIG_ADDR+49)
  ldi ZH,high(EEPROM_CONFIG_ADDR+49)
    
  ldi axh,25 ; size of AP string
  rcall append_eeprom_to_request_buffer

  ;add \r\n
  ldi argument,0x0D
  rcall append_byte_to_request_buffer
  ldi argument,0x0A
  rcall append_byte_to_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response

  ;lost connection with server?  
  ldi	ZH,high(ERROR*2)
  ldi	ZL,low(ERROR*2)
  rcall load_answer_buffer

  ldi	XH,high(ResponseBuffer)
  ldi	XL,low(ResponseBuffer)

  ldi	YH,high(AnswerBuffer)		
  ldi	YL,low(AnswerBuffer)

   ;X,Y is input   
   rcall _strstr    
   ;output T 
ret

/*******************WiFi Send Data ****************
*@INFO: WiFi Send data
*@INPUT: 
*@USAGE: Z
****************************************/
wifi_send:
;send size in the form AT+CIPSEND=xxx	
  ldi	ZH,high(AT_CIPSEND*2)
  ldi	ZL,low(AT_CIPSEND*2)
  rcall load_request_buffer

  ;convert to str
  ldi argument,3    ; send 3 bytes
  rcall byte_to_str

  mov argument,r10
  tst argument
  breq wf_send_1
  rcall append_byte_to_request_buffer

wf_send_1:
  mov argument,r9
  tst argument
  breq wf_send_2
  rcall append_byte_to_request_buffer

wf_send_2:
  mov argument,r8  
  rcall append_byte_to_request_buffer

  ;add \r\n
  ldi argument,0x0D
  rcall append_byte_to_request_buffer
  ldi argument,0x0A
  rcall append_byte_to_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response      ;TIMEOUT !!!!!!!!!!!!!!!!!!!

;send real content
  ;clear buffer
  rcall clear_request_buffer

  ;add data to buffer
  lds argument,facilityCode
  rcall append_byte_to_request_buffer

  lds argument,cardCode
  rcall append_byte_to_request_buffer

  lds argument,cardCode+1
  rcall append_byte_to_request_buffer
  
  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response
ret

/*******************WiFi Read  ****************
*@INFO: WiFi TCP read data from remote host
*@INPUT:X input buffer with data
*@OUTPUT:X reference to output
*@USAGE:
****************************************/
wifi_read:   
   ;check for +IPD 	
   ldi	ZH,high(IPD*2)
   ldi	ZL,low(IPD*2)
   rcall load_answer_buffer
   
   ;load Response string pointer
   ldi XL,low(ResponseBuffer)
   ldi XH,high(ResponseBuffer)
      
   ldi	YH,high(AnswerBuffer)
   ldi	YL,low(AnswerBuffer)
   
   rcall expect_read_response
   lds temp,WiFiStatus
   cpi temp,ESP8266_RESPONSE_FINISHED
   brne wf_read_exit

   ;read +IDF pos it is available! 
   ldi XL,low(ResponseBuffer)
   ldi XH,high(ResponseBuffer)
      
   ldi	YH,high(AnswerBuffer)
   ldi	YL,low(AnswerBuffer)
   rcall _strstr
   
   mov XH,r15
   mov XL,r14
   adiw X,5     ;skip +IDF,

   ;dont change X	
   rcall read_length		;investigate for timeout?
    
   ;align length in chars
   rcall align_length_bytes 

   ;r10,r9,r8 to byte in axl
   rcall _str_to_byte   
   mov axh,axl

   ;move pointer to begging of data
wf_read_01:   
   ld temp,X+   
   cpi temp,':'   ;end?
   brne wf_read_01   


   ;read available string length
   
   
   mov r15,XH
   mov r14,XL

wf_read_02: 
   mov XH,r15
   mov XL,r14

   rcall _strlen
   cp axl,axh
   brlo wf_read_02        ;DANGER -> TIMEOUT is not measured!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   mov XH,r15
   mov XL,r14

   ;READ response byte
   ld temp,X
   ;sts debug+1,temp

   cpi temp,RESPONSE_FAILURE
   brne wifi_result_ok	
   
   //set the alarm on
   ldi bxl,RESPONSE_FAILURE   
   rjmp wifi_save_result

wifi_result_ok:	
	//success
   ldi bxl,RESPONSE_OK
   	
wifi_save_result:
   sts WiFiResult,bxl


wf_read_exit:
 _EVENT_SET WIFI_RESULT_EVENT,TASK_CONTEXT
ret

/*******************WiFi Close  ****************
*@INFO: WiFi TCP close
*@INPUT:
*@USAGE:
****************************************/
wifi_close:
;AT_CIPSTART	
  ldi	ZH,high(AT_CIPCLOSE*2)
  ldi	ZL,low(AT_CIPCLOSE*2)
  rcall load_request_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)
  
  rcall send_AT
ret

;----------------------------------------------------------------------------TESTS----------------------------------------------
/*******************WiFi Connect to Access Point****************
*@INFO: WiFi Connect to router using hard codded flash data
*@INPUT:
*@USAGE:
****************************************/

test_wifi_join_access_point:
;AT_CWJAP	
  ldi	ZH,high(AT_CWJAP*2)
  ldi	ZL,low(AT_CWJAP*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response
  
ret

/*******************WiFi Start ****************
*@INFO: WiFi Start TCP connection, check if server is available
*@INPUT:
*@USAGE:
****************************************/

test_wifi_start:
  ldi	ZH,high(AT_CIPSTART*2)
  ldi	ZL,low(AT_CIPSTART*2)
  rcall load_request_buffer

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response

  ;lost connection with server?  
  ldi	ZH,high(ERROR*2)
  ldi	ZL,low(ERROR*2)
  rcall load_answer_buffer

  ldi	XH,high(ResponseBuffer)
  ldi	XL,low(ResponseBuffer)

  ldi	YH,high(AnswerBuffer)		
  ldi	YL,low(AnswerBuffer)

   ;X,Y is input   
   rcall _strstr    
   ;output T 
ret


/***************flash buffers********************
*@USAGE:temp
*/
;usart_flush:
;	sbis UCSR0A, RXC0
;ret
;	in temp, UDR0
;ret


RxComplete:	
_PRE_INTERRUPT
	//error check
    lds temp,UCSR0A
	sbrs temp,FE0
	rjmp rxi_dor
	rjmp rxi_error 
rxi_dor:
	sbrs temp,DOR0 
	rjmp rxi_pe
	;dor error
	rjmp rxi_error        
rxi_pe:
	sbrs temp,UPE0 
	rjmp rxi_char
	;pe error
	rjmp rxi_error

rxi_char: 
 	lds temp, UDR0
	sts RxByte,temp	
    
	//add to response buffer
	push counter
	push XL
	push XH
	rcall add_byte_responce_buffer
	pop XH
	pop XL
	pop counter

	rjmp rxi_exit

rxi_error:
 ;rcall usart_flush 

rxi_exit:

 lds temp,debug
 inc temp
 sts debug,temp

_POST_INTERRUPT
reti



