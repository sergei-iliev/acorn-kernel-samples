;********************Add byte to input buffer*************
;@USAGE:temp,X,counter
;@WARNING: Up to 1 byte size bytes - 256
;*********************************************************

add_byte_responce_buffer:

  
  ldi XL,low(ResponseBuffer)
  ldi XH,high(ResponseBuffer)  

  ;start from 0 index
  lds counter,RxTail

  ;guard overflow
  cpi counter,(RESPONSE_BUFFER_SIZE-1)  ;'\0' for the last one
  brsh add_byte_in_exit

  clr temp
  ADD16 XL,XH,counter,temp	
  lds temp,RxByte
  st X,temp

  inc counter
  sts RxTail,counter


add_byte_in_exit:

ret

/*******************Load  Response Buffer from Flush ( for TEST only)********************
@INPUT: Z pointer to flash
@USAGE: temp,X,axl,axh,r0
*************************************************************/
load_response_buffer:
	ldi XL,low(ResponseBuffer)
	ldi XH,high(ResponseBuffer)
	ldi axl,'\0'
	ldi axh,RESPONSE_BUFFER_SIZE

	rcall _memset ;zero out memory

	;reset pointer
	ldi XL,low(ResponseBuffer)
	ldi XH,high(ResponseBuffer)
	;read from on
lresb_1:
	lpm
	mov	temp,r0	
	cpi temp,0	;zero terminator
	breq lresb_2
	
	st X+,temp 
	adiw ZH:ZL,1
	rjmp lresb_1

lresb_2:
ret
/*******************Load  Answer Buffer from Flush********************
@INPUT: Z pointer to flash
@USAGE: temp,X,axl,axh
*************************************************************/
load_answer_buffer:
;prepare input
	ldi XL,low(AnswerBuffer)
	ldi XH,high(AnswerBuffer)
	ldi axl,'\0'
	ldi axh,ANSWER_BUFFER_SIZE

	rcall _memset ;zero out memory

	;reset pointer
	ldi XL,low(AnswerBuffer)
	ldi XH,high(AnswerBuffer)
	;read from on
lab_1:
	lpm
	mov	temp,r0	
	cpi temp,0	;zero terminator
	breq lad_2
	
	st X+,temp 
	adiw ZH:ZL,1
	rjmp lab_1

lad_2:	
ret

/*******************Clear Request Buffer********************
@USAGE: temp,X,axl,axh
*************************************************************/
clear_request_buffer:
	ldi XL,low(RequestBuffer)
	ldi XH,high(RequestBuffer)
	ldi axl,'\0'
	ldi axh,REQUEST_BUFFER_SIZE

	rcall _memset ;zero out memory

ret
/*******************Load Web Buffer from Flush********************
@INPUT: Z pointer to flash
@USAGE: temp,X,axl,axh
*************************************************************/
load_web_buffer:
;prepare input
	ldi XL,low(WebBuffer)
	ldi XH,high(WebBuffer)
	ldi axl,'\0'
	ldi axh,WEB_BUFFER_SIZE

	rcall _memset ;zero out memory

	;reset pointer
	ldi XL,low(WebBuffer)
	ldi XH,high(WebBuffer)
	;read from on
lwebrb_1:
	lpm
	mov	temp,r0	
	cpi temp,0	;zero terminator
	breq lwebrd_2
	
	st X+,temp 
	adiw ZH:ZL,1
	rjmp lwebrb_1

lwebrd_2:	
ret
/*******************Load Web Buffer from Flush********************
@INPUT: Z pointer to flash
@USAGE: temp,X,axl
*************************************************************/
append_buffer_to_web_buffer:
	ldi XL,low(WebBuffer)
	ldi XH,high(WebBuffer)
	
	;make sure you don't exceed
	rcall _strlen
	cpi axl,WEB_BUFFER_SIZE-1
	brsh awebbufbrb_1

	;appened to end
	ldi XL,low(WebBuffer)
	ldi XH,high(WebBuffer)
	clr temp	
	;axl position to next free index
	ADD16 XL,XH,axl,temp

awebbufbrb_1:
	lpm
	mov	temp,r0	
	cpi temp,0	;zero terminator
	breq awebbufbrb_2
	
	//is buffer available???????????

	st X+,temp 
	adiw ZH:ZL,1
	rjmp awebbufbrb_1

awebbufbrb_2:
ret
/*******************Append Byte To Web Buffer ********************
@INPUT: argument
@USAGE: temp,X,axl,axh
*************************************************************/
append_byte_to_web_buffer:
	ldi XL,low(WebBuffer)
	ldi XH,high(WebBuffer)
	
	;make sure you don't exceed
	rcall _strlen
	cpi axl,WEB_BUFFER_SIZE-1
	brsh awebbrb_1

	;appened
	ldi XL,low(WebBuffer)
	ldi XH,high(WebBuffer)
	clr temp
	
	;axl position to next free index
	ADD16 XL,XH,axl,temp
	
	st X,argument

awebbrb_1:
ret
/***************************Copy eeprom to end of buffer **************
@INPUT: Z - eeprom pointer to read from
        axh - size in bytes to copy
@USAGE: counter,X,argument
**********************************************************/
append_eeprom_to_web_buffer:
	
	ldi XL,low(WebBuffer)
	ldi XH,high(WebBuffer)
	
	;make sure you don't exceed
	rcall _strlen
	cpi axl,WEB_BUFFER_SIZE-1
	brsh aewb_1

	;move pointer to the end
	ldi YL,low(WebBuffer)
	ldi YH,high(WebBuffer)
	clr temp
	;axl position to next free index
	ADD16 YL,YH,axl,temp

	;X points to EEPROM start address
	mov XL,ZL
	mov XH,ZH
	;Y points to next free address in buffer
    mov axl,axh
    call EEPROM_read_buffer 
aewb_1:     
ret
/*******************Load Request Buffer from Flush********************
@INPUT: Z pointer to flash
@USAGE: temp,X,axl,axh
*************************************************************/
load_request_buffer:
;prepare input
	ldi XL,low(RequestBuffer)
	ldi XH,high(RequestBuffer)
	ldi axl,'\0'
	ldi axh,REQUEST_BUFFER_SIZE

	rcall _memset ;zero out memory

	;reset pointer
	ldi XL,low(RequestBuffer)
	ldi XH,high(RequestBuffer)
	;read from on
lrb_1:
	lpm
	mov	temp,r0	
	cpi temp,0	;zero terminator
	breq lrd_2
	
	st X+,temp 
	adiw ZH:ZL,1
	rjmp lrb_1

lrd_2:	
ret

/*******************Append Byte To Request Buffer ********************
@INPUT: argument
@USAGE: temp,X,axl,axh
*************************************************************/
append_byte_to_request_buffer:
	ldi XL,low(RequestBuffer)
	ldi XH,high(RequestBuffer)
	
	;make sure you don't exceed
	rcall _strlen
	cpi axl,REQUEST_BUFFER_SIZE-1
	brsh abrb_1

	;appened
	ldi XL,low(RequestBuffer)
	ldi XH,high(RequestBuffer)
	clr temp
	;axl position to next free index
	ADD16 XL,XH,axl,temp
	st X,argument

abrb_1:
ret
/***************************Copy eeprom to end of buffer **************
@INPUT: Z - eeprom pointer to read from
        axh - size in bytes to copy
@USAGE: counter,X,argument
**********************************************************/
append_eeprom_to_request_buffer:
	
	ldi XL,low(RequestBuffer)
	ldi XH,high(RequestBuffer)
	
	;make sure you don't exceed
	rcall _strlen
	cpi axl,REQUEST_BUFFER_SIZE-1
	brsh aerb_1

	;move pointer to the end
	ldi YL,low(RequestBuffer)
	ldi YH,high(RequestBuffer)
	clr temp
	;axl position to next free index
	ADD16 YL,YH,axl,temp

	;X points to EEPROM start address
	mov XL,ZL
	mov XH,ZH
	;Y points to next free address in buffer
    mov axl,axh
    call EEPROM_read_buffer 
aerb_1:     
ret
/**********************************************************
@USAGE:  X,temp,axl,axh
***********************************************************/
ESP8266_clear:
	;nullify response buffer
	ldi XL,low(ResponseBuffer)
	ldi XH,high(ResponseBuffer)
	ldi axl,'\0'
	ldi axh,RESPONSE_BUFFER_SIZE

	rcall _memset ;zero out memory	
	
	clr temp 
	sts RxTail,temp
ret

/***********************Send String***************************
@USAGE:  X - request
		   
**********************************************************************/
usart_send_string:	
	ld argument,X+
	cpi argument,'\0'
	breq uss_exit
	
	rcall usart_send_byte
	rjmp usart_send_string
	  
uss_exit:
ret
/***********************Send Buffer over USART***************************
@INPUT:  X - request
         axl - size
@USAGE: argument		   
**********************************************************************/
usart_send_buffer:	  
      ld argument,X+
	  rcall usart_send_byte
	  dec axl
	  tst axl

	  breq uss_buf_exit

	  rjmp usart_send_buffer
uss_buf_exit:
ret
/***********Send byte in polling mode**********************
*@INPUT: argument
*@USAGE: temp
*/
usart_send_byte:
	 ; Wait for empty transmit buffer
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp usart_send_byte
	; Put data (r16) into buffer, sends the data
	sts UDR0,argument
ret
/***********************Send AT Command***************************
@USAGE:  X - request
		 Y - expected response
		 temp  
**********************************************************************/
send_AT:
   ;nulify response buffer
   push XL
   push XH
   rcall ESP8266_clear
   pop XH
   pop XL

   ;send X 
   rcall usart_send_string

ret
/***********************Send AT Command Buffer***************************
@INPUT: X - request buffer
        axl - size
@USAGE:  X - request
		 Y - expected response
		 counter -timeout
		 temp  
**********************************************************************/
send_AT_buffer_expect_response:
   push XL
   push XH
   push axl
   rcall ESP8266_clear
   pop axl
   pop XH
   pop XL

   ;send buffer
   rcall usart_send_buffer

   ;set status to waiting
   ldi temp,ESP8266_RESPONSE_WAITING
   sts WiFiStatus,temp
   
   
   ;load Response string pointer
   ldi XL,low(ResponseBuffer)
   ldi XH,high(ResponseBuffer)

   clr counter
send_buf_resp_1: 
   ;wait 1 s
   rcall wait_100ms
   inc counter  
   cpi counter,DEFAULT_TIMEOUT
   brne send_buf_resp_2 
   ;set timeout
   ldi temp,ESP8266_RESPONSE_TIMEOUT
   sts WiFiStatus,temp

ret
send_buf_resp_2: 
   ;X,Y is input   
   rcall _strstr 
   brtc send_buf_resp_1 

   ;success
   ldi temp,ESP8266_RESPONSE_FINISHED
   sts WiFiStatus,temp
ret
/***********************Send AT Command String***************************
@USAGE:  X - request
		 Y - expected response
		 counter -timeout
		 temp  
**********************************************************************/
send_AT_expect_response:
   ;nulify response buffer
   push XL
   push XH
   rcall ESP8266_clear
   pop XH
   pop XL

   ;send X 
   rcall usart_send_string
   ;set status to waiting
   ldi temp,ESP8266_RESPONSE_WAITING
   sts WiFiStatus,temp
   
   
   ;load Response string pointer
   ldi XL,low(ResponseBuffer)
   ldi XH,high(ResponseBuffer)

   clr counter
sendatresp_1: 
   ;wait 1 s
   rcall wait_100ms
   inc counter  
   cpi counter,DEFAULT_TIMEOUT
   brne sendatresp_2 
   ;set timeout
   ldi temp,ESP8266_RESPONSE_TIMEOUT
   sts WiFiStatus,temp

ret
sendatresp_2: 
   ;X,Y is input   
   rcall _strstr 
   brtc sendatresp_1 

   ;success
   ldi temp,ESP8266_RESPONSE_FINISHED
   sts WiFiStatus,temp
ret

/***********************Expect Response***************************
@INFO: expect read marker, length availability and string length of up to buffer size
@USAGE:  X - response buffer	
		 Y - expected response	 
		 counter -timeout
		 temp  
**********************************************************************/
expect_read_response:
   clr counter
   
   ldi temp,ESP8266_RESPONSE_WAITING
   sts WiFiStatus,temp
expresp_10: 
   ;wait 200 ms
   rcall wait_100ms
   inc counter  
   cpi counter,DEFAULT_TIMEOUT
   brne expresp_20 
   ;set timeout
   ldi temp,ESP8266_RESPONSE_TIMEOUT
   sts WiFiStatus,temp
   
ret
expresp_20: 
   ;X,Y is input   make sure _strstr does not modify pointers
   
   rcall _strstr 
   brtc expresp_10 

   ;success
   ldi temp,ESP8266_RESPONSE_FINISHED
   sts WiFiStatus,temp

ret
/***********************Check if read marker and length is available***************************
@INFO: Expect 3 chars , byte length string size 
@INPUT:  X - response buffer after IDF marker			 		
@USAGE:  Y
		 temp,counter
@OUTPUT: r10,r9,r8
**********************************************************************/
read_length:
   clr counter

   ldi temp,ESP8266_RESPONSE_WAITING
   sts WiFiStatus,temp

isreadav_10:
   clr r10
   clr r9
   clr r8

   mov YL, XL
   mov YH, XH

   ;step over
   ld temp,Y+
   mov r10,temp   
   cpi temp,':'   ;end?
   brne isreadav_11
   clr r10
   rjmp  isreadav_20  ;yes the end has come   

isreadav_11:
   ld temp,Y+
   mov r9,temp
   cpi temp,':'
   brne isreadav_12
   clr r9
   rjmp  isreadav_20  ;yes the end has come 1 digit
   
isreadav_12:     
   ld temp,Y+
   mov r8,temp
   cpi temp,':'
   brne isreadav_13
   clr r8
   rjmp  isreadav_20  ;yes the end has come 2 digit   

isreadav_13:
   ld temp,Y+
   cpi temp,':'                   
   breq  isreadav_20  ;yes the end has come 3 digit   

;if here it is NOT available
   ;wait 200 ms
   rcall wait_100ms
   inc counter  
   cpi counter,DEFAULT_TIMEOUT
   brne isreadav_10 
   ;set timeout
   ldi temp,ESP8266_RESPONSE_TIMEOUT
   sts WiFiStatus,temp					   
ret
    
isreadav_20:
   ;success
   ldi temp,ESP8266_RESPONSE_FINISHED
   sts WiFiStatus,temp
ret

.SET MIN_HTTP_HEADER_LENGTH=20
/***********************Read and wait the length of available chars in buffer***************************
@INFO: Read and wait the number of characters that have come over the wire into the buffer
@INPUT:  X - response buffer after IDF marker and char length aka "+IDF,xxx:"			 		
@USAGE:  r15,r14 
		 temp,counter	
		
@OUTPUT: WiFiStatus
**********************************************************************/
wait_http_status_length:
   clr counter

   ldi temp,ESP8266_RESPONSE_WAITING
   sts WiFiStatus,temp

   mov r15,XH
   mov r14,XL

rab_01: 
   mov XH,r15
   mov XL,r14

   rcall _strlen
   cpi axl,MIN_HTTP_HEADER_LENGTH   
   brsh rab_02     ; status line is available  
   

   ;if here we need to wait
   rcall wait_100ms
   inc counter  
   cpi counter,DEFAULT_TIMEOUT
   brne rab_01 

   ;set timeout
   ldi temp,ESP8266_RESPONSE_TIMEOUT
   sts WiFiStatus,temp	
   rjmp rab_exit

rab_02:
   ;success
   ldi temp,ESP8266_RESPONSE_FINISHED
   sts WiFiStatus,temp

rab_exit:
   mov XH,r15
   mov XL,r14
ret
/***************************************
*Align chars MSB,LSB to the right
*@INPUT: r10,r9,r8
*@USAGE: r10,r9,r8
****************************************/

align_length_bytes:
   tst r8
   brne astrb_10   ;3 digit

   mov r8,r9
   mov r9,r10
   clr r10

   tst r8
   brne astrb_10   ;2 digit
   
   mov r8,r9
   mov r9,r10
   clr r10
   clr r9                 ;1 digit

astrb_10:
   	
ret

wait_1s:
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255

 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255

 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255

 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255

 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 _SLEEP_TASK 255
ret

wait_100ms:
 _SLEEP_TASK 255
 _SLEEP_TASK 255
 ;_SLEEP_TASK 255
 ;_SLEEP_TASK 255
ret

AT:				.db "AT",0x0D,0x0A,0
AT_ECHO_OFF:    .db "ATE0",0x0D,0x0A,0
AT_MODE:		.db "AT+CWMODE=3",0x0D,0x0A,0
AT_CIPMUX:      .db "AT+CIPMUX=0",0x0D,0x0A,0	;single connection
AT_CIPMODE:     .db "AT+CIPMODE=0",0x0D,0x0A,0  ;normal application mode
AT_CIPSTATUS:   .db "AT+CIPSTATUS",0x0D,0x0A,0  ;connection status
AT_CIPCLOSE:    .db "AT+CIPCLOSE",0x0D,0x0A,0              // disconnect

VAR_AT_CWJAP:       .db "AT+CWJAP_CUR=",0
AT_CWJAP:       .db "AT+CWJAP_CUR=",'"','M','T','E','L','-','7','A','5','3','"',',','"','0','1','2','4','7','3','C','9','F','F','"',0x0D,0x0A,0

VAR_AT_CIPSTART:  .db "AT+CIPSTART=",'"','T','C','P','"',',',0
;AT_CIPSTART:     .db "AT+CIPSTART=",'"','T','C','P','"',',','"','b','i','t','s','l','i','b','.','n','e','t','"',',','8','0',0x0D,0x0A,0
AT_CIPSTART:    .db "AT+CIPSTART=",'"','T','C','P','"',',','"','1','9','2','.','1','6','8','.','8','.','9','9','"',',','7','7','7','1',0x0D,0x0A,0


;AT_CIPSEND:     .db "AT+CIPSEND=5",0x0D,0x0A,0 ;send DATA {how long?}
AT_CIPSEND:     .db "AT+CIPSEND=",0
HELLO:           .db 'H','e','l','l','o',0
WORLD:           .db 'W','o','r','l','d',0
HELLO_WORLD:		.db "HELLO WORLD",0	


CONNECTION_STATUS_2: .db "STATUS:2",0   ;Got IP
CONNECTION_STATUS_3: .db "STATUS:3",0	;Connected
CONNECTION_STATUS_4: .db "STATUS:4",0	;Disconnected
CONNECTION_STATUS_5: .db "STATUS:5",0	;Wi-Fi connection fail

ERROR:	.db "ERROR",0

WIFI_CONNECTED: .db "WIFI CONNECTED",0x0D,0x0A,0
CWJAP:          .db "+CWJAP",0

AT_OK:		.db "OK",0x0D,0x0A,0

SSID:       .db	"MTEL-7A53",0
PASSWORD:	.db	"012473C9FF",0

IPD:        .db "+IPD,",0
 
DEBUG_ANSWER: .db "SEND OK",0x0D,"+IPD,500:HTTP/1.1   400 OK skfjdhks ksfhskjhfk sdkjh",0


//web based request
REST_START_PRE:	    .db "POST ",0
REST_START_POST:	.db " HTTP/1.1 ",0x0D,0x0A,0
REST_END:   .db "Host: CardReader",0x0D,0x0A,"Content-Length: 0",0x0D,0x0A,"Connection: Close",0x0D,0x0A,0x0D,0x0A,0
