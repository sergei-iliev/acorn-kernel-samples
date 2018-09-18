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


;115200
#define UBRR_VAL    5 /*11.0592*/ 

#define RESPONSE_BUFFER_SIZE  200

#define ANSWER_BUFFER_SIZE    50

#define REQUEST_BUFFER_SIZE   160

#define WEB_BUFFER_SIZE   126

.dseg

RxByte: .byte 1 
RxTail:  .byte 1
WiFiStatus: .byte 1
WiFiResult: .byte 1

;debug:     .byte 3

ResponseBuffer: .byte RESPONSE_BUFFER_SIZE
RequestBuffer:  .byte REQUEST_BUFFER_SIZE
AnswerBuffer:   .byte ANSWER_BUFFER_SIZE

WebBuffer:   .byte WEB_BUFFER_SIZE

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
	sbi PORTB,PORTB1
	rcall wait_1s
	rcall wait_1s
	rcall wait_1s

	rcall usart_init
	rcall usart_enable
	
	rcall wifi_init
    lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne wifi_reset

	
	

wifi_main:

    cbi PORTB,PORTB1
    _EVENT_WAIT DATA_READY_EVENT

	sbi PORTB,PORTB1
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
	
	;WEB request
	rcall wifi_web_send	;send Card data, 3 bytes
		
	;read response
	rcall wifi_web_read			;read status byte in response header
	lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne wf_error


//send Web REST request
   
	rcall wifi_close

 
rjmp wifi_main

wf_error: 
 ;sbi PORTB,PORTB1
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
	out UBRRH,temp 

	ldi temp,low(UBRR_VAL)
	out UBRRL,temp

	; Disable receiver interrupt
	rcall usart_disable
	;ldi temp,(1 << RXCIE)|(1<<RXEN)|(1<<TXEN)
	;out UCSRB,temp

	
	;default blue thooth setting 9600N81  BLUETOOTH communication  (DEFAULT HC_06 seting)	
	ldi temp, (1<<URSEL)|(1 << UCSZ1) | (1 << UCSZ0)
	
	out UCSRC,temp

ret

/*******************WiFi Send Web Data ****************
*@INFO: WiFi Send data in the form of Rest request.All 3 bytes are converted to HEX representation in 6 bytes
*@INPUT: 
*@USAGE: Z
****************************************/
wifi_web_send:
;****prepare web buffer
  ldi	ZH,high(REST_START_PRE*2)
  ldi	ZL,low(REST_START_PRE*2)
  rcall load_web_buffer  

;****add data to buffer  
  ;lds argument,facilityCode
  ;rcall append_byte_to_web_buffer
  
;****convert to hex
  lds argument,facilityCode
  rcall byte_to_hex_str

  mov argument,r10
  rcall append_byte_to_web_buffer

  mov argument,r9
  rcall append_byte_to_web_buffer
  

  ;lds argument,cardCode
  ;rcall append_byte_to_web_buffer
  lds argument,cardCode
  rcall byte_to_hex_str

  mov argument,r10
  rcall append_byte_to_web_buffer

  mov argument,r9
  rcall append_byte_to_web_buffer


  ;lds argument,cardCode+1
  ;rcall append_byte_to_web_buffer
  lds argument,cardCode+1
  rcall byte_to_hex_str

  mov argument,r10
  rcall append_byte_to_web_buffer

  mov argument,r9
  rcall append_byte_to_web_buffer


;****add the rest of the header
  ldi ZL,low(REST_START_POST*2)
  ldi ZH,high(REST_START_POST*2)
  rcall append_buffer_to_web_buffer

  ldi ZL,low(REST_END*2)
  ldi ZH,high(REST_END*2)
  rcall append_buffer_to_web_buffer

 
;send size in the form AT+CIPSEND=xxx	
  ldi	ZH,high(AT_CIPSEND*2)
  ldi	ZL,low(AT_CIPSEND*2)
  rcall load_request_buffer

;length to send?
  ldi XL,low(WebBuffer)
  ldi XH,high(WebBuffer)	
  rcall _strlen
  
  ;convert to str the total length to send
  mov argument,axl    
  rcall byte_to_str

  mov argument,r10
  tst argument
  breq wfw_send_1
  rcall append_byte_to_request_buffer

wfw_send_1:
  mov argument,r9
  tst argument
  breq wfw_send_2
  rcall append_byte_to_request_buffer

wfw_send_2:
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

;send real content, which is in web buffer
  
  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(WebBuffer)
  ldi	XL,low(WebBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  rcall send_AT_expect_response
ret

/*******************WiFi Web Response Read  ****************
*@INFO: WiFi Web response read data from remote host
*@OUTPUT:X reference to output
*@USAGE: Y,Z,temp,r15,r14
****************************************/
wifi_web_read: 
  
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
   brne wfw_read_exit

   ;read +IDF pos
   ldi XL,low(ResponseBuffer)
   ldi XH,high(ResponseBuffer)
      
   ldi	YH,high(AnswerBuffer)
   ldi	YL,low(AnswerBuffer)
 

/*   
   ldi	ZH,high(DEBUG_ANSWER*2)
   ldi	ZL,low(DEBUG_ANSWER*2)
   call load_web_buffer
   
   ldi	ZH,high(IPD*2)
   ldi	ZL,low(IPD*2)
   call load_answer_buffer
   
   ;load Response string pointer
   ldi XL,low(WebBuffer)
   ldi XH,high(WebBuffer)
      
   ldi	YH,high(AnswerBuffer)
   ldi	YL,low(AnswerBuffer)
 */     
   
   rcall _strstr
   
   mov XH,r15
   mov XL,r14
   adiw X,5     ;skip +IDF,

   ;dont change X	
   rcall read_length		
   lds temp,WiFiStatus
   cpi temp,ESP8266_RESPONSE_FINISHED
   brne wtw_result_failure    ;this is failure
    
   ;align length in chars
   rcall align_length_bytes 

   ;r10,r9,r8 to byte in axl
   rcall _str_to_byte   
   

   ;move pointer to begining of data
wfw_read_01:   
   ld temp,X+   
   cpi temp,':'   ;end?
   brne wfw_read_01   


   ;wait for status http line
   rcall wait_http_status_length   ;keep X intact
   lds temp,WiFiStatus
   cpi temp,ESP8266_RESPONSE_FINISHED
   brne wtw_result_failure    ;this is failure

   ;skip 'HTTP/1.1' 
   adiw XH:XL,8
   ;skip ' '
wfw_skip_space:
   ld temp,X+
   cpi temp,' '
   breq wfw_skip_space
   
   ;read the status number
   cpi temp,'2'            ;status code 200 -> success
   breq wfw_result_ok	

wtw_result_failure:   
   //set the alarm on
   ldi bxl,RESPONSE_FAILURE
   sts WiFiResult,bxl   
   rjmp wfw_read_exit

wfw_result_ok:	
	//success
   ldi bxl,RESPONSE_OK
   sts WiFiResult,bxl


wfw_read_exit:
 _EVENT_SET WIFI_RESULT_EVENT,TASK_CONTEXT
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


/*
*@USAGE:temp
*/
usart_disable:
    in temp,UCSRB
	cbr temp,(1 << RXCIE)|(1<<RXEN)|(1<<TXEN)
	out UCSRB,temp
ret
/*
*@USAGE:temp
*/
usart_enable:
    in temp,UCSRB
	sbr temp,(1 << RXCIE)|(1<<RXEN)|(1<<TXEN)
	out UCSRB,temp
ret

/***************flash buffers********************
*@USAGE:temp
*/
usart_flush:
	sbis UCSRA, RXC
ret
	in temp, UDR
ret


RxComplete:
_PRE_INTERRUPT
	//error check
    in temp,UCSRA
	sbrs temp,FE
	rjmp rxi_dor
	rjmp rxi_error 
rxi_dor:
	sbrs temp,DOR 
	rjmp rxi_pe
	;dor error
	rjmp rxi_error        
rxi_pe:
	sbrs temp,PE 
	rjmp rxi_char
	;pe error
	rjmp rxi_error

rxi_char: 
 	in temp, UDR
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
 rcall usart_flush 

rxi_exit:

_POST_INTERRUPT
reti



