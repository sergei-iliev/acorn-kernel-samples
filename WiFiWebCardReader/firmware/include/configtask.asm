.include "include/eeprom.asm"

/*
Configuration task to communicate using factory settings with android to
obtain real server settings
*/

Config_Task:	

	//clear 
   cbi DDRD,PD4
   cbi PORTD,PD4
   	
      ;upper led
   sbi DDRB,PB0
   ;lower led
   sbi DDRB,PB1

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 


main2:
    ;enable pull up for configuration mode 
   cbi DDRD,PD4
   sbi PORTD,PD4
   ;read data pin
   sbis PIND,PD4
   rjmp configuration_mode
   rjmp normal_mode

rjmp main2  


;************************************************
;Configuration mode over Android hot spot
;************************************************
configuration_mode:
	//clear 
   cbi DDRD,PD4
   cbi PORTD,PD4

   sbi PORTB,PORTB0
config_wifi_reset:	
	call usart_disable
    ;wait some time 
	sbi PORTB,PORTB1	
	rcall wait_1s
	rcall wait_1s
	rcall wait_1s
	
	call usart_init
	call usart_enable

	rcall config_wifi_init 
	lds temp,WiFiStatus	

	
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne config_wifi_reset

	cbi PORTB,PORTB1

    ;******enter read / write config mode
	call wifi_connection
	lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne config_wf_error
	  
	  
	rcall config_wifi_start
	lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne config_wf_error

	rcall config_wifi_send			;send EEPROM
	lds temp,WiFiStatus
	cpi temp,ESP8266_RESPONSE_FINISHED
	brne config_wf_error
	
	rcall config_wifi_read			;read data
	;lds temp,WiFiStatus
	;cpi temp,ESP8266_RESPONSE_FINISHED
	;brne config_wf_error

	call wifi_close

config_wf_success:
	cbi PORTB,PORTB1	
    _SUSPEND_TASK
      
config_wf_error: 

	;sbi PORTB,PORTB1	
    _SUSPEND_TASK

rjmp configuration_mode

/*******************WiFi Begin****************
*@INFO:Register to a WiFi access point
*@USAGE:
****************************************/
config_wifi_init:
  call wifi_begin
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne config_wf_init_exit

  call wifi_mode
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne config_wf_init_exit

  call wifi_connection
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne config_wf_init_exit

  call wifi_application
  lds temp,WiFiStatus
  cpi temp,ESP8266_RESPONSE_FINISHED
  brne config_wf_init_exit
  
  rcall config_wifi_join_access_point
  
config_wf_init_exit:

ret

/*******************WiFi Connect to Access Point****************
*@INFO: WiFi Connect to router using factory hard codded flash data for Android hot spot
*@INPUT:
*@USAGE:
****************************************/
config_wifi_join_access_point:
  ldi	ZH,high(FACTORY_AT_CWJAP*2)            ;android hot spot
  ldi	ZL,low(FACTORY_AT_CWJAP*2)
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

/*******************WiFi Open TCP connection to Android hot spot****************
*@INFO: WiFi Open TCP connection/socket
*@INPUT:
*@USAGE:
****************************************/
config_wifi_start:
  ldi	ZH,high(FACTORY_AT_CIPSTART*2)
  ldi	ZL,low(FACTORY_AT_CIPSTART*2)
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

/*******************WiFi Send EEPROM Config Data ****************
*@INFO: WiFi Send config eeprom data
*@INPUT: 
*@USAGE: Z
****************************************/
config_wifi_send:
;send size in the form AT+CIPSEND=xxx	
  ldi	ZH,high(AT_CIPSEND*2)
  ldi	ZL,low(AT_CIPSEND*2)
  rcall load_request_buffer

    ;convert to str
  ldi argument,102    ; send 100 bytes + 2 \r\n 
  rcall byte_to_str

  mov argument,r10
  tst argument
  breq cf_send_1
  rcall append_byte_to_request_buffer

cf_send_1:
  mov argument,r9
  tst argument
  breq cf_send_2
  rcall append_byte_to_request_buffer

cf_send_2:
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
  
  ;send EEPROM info to request buffer -100 bytes
  rcall config_copy_eeprom_info

    ;add \r\n to the end of the buffer
  ldi YL,low(RequestBuffer)
  ldi YH,high(RequestBuffer)

  ADDI16 YL,YH,100

  ldi argument,0x0D
  st Y+,argument

  ldi argument,0x0A
  st Y,argument
  

  ldi	ZH,high(AT_OK*2)
  ldi	ZL,low(AT_OK*2)
  rcall load_answer_buffer

  ;set input
  ldi	XH,high(RequestBuffer)
  ldi	XL,low(RequestBuffer)

  ldi	YH,high(AnswerBuffer)
  ldi	YL,low(AnswerBuffer)
  
  ldi axl,102    ; send 100 bytes + 2 \r\n 
  rcall send_AT_buffer_expect_response
ret

/*******************WiFi Read Config  ****************
*@INFO: WiFi TCP read data from remote host
*@USAGE:X input buffer with data
        Z
*@OUTPUT:X reference to output
****************************************/
config_wifi_read:
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
   brne cf_read_exit

   ;read +IDF pos it is available! 
   ldi XL,low(ResponseBuffer)
   ldi XH,high(ResponseBuffer)
      
   ldi	YH,high(AnswerBuffer)
   ldi	YL,low(AnswerBuffer)
   rcall _strstr
   
   mov XH,r15
   mov XL,r14
   adiw X,5     ;skip +IDF=,

   ;dont change X	
   rcall read_length		;investigate for timeout?
    
   ;align length in chars
   rcall align_length_bytes 

   ;r10,r9,r8 to byte in axl
   rcall _str_to_byte   
   mov axh,axl           ;keep length in local variable

   ;move pointer to begging of data
cf_read_01:   
   ld temp,X+   
   cpi temp,':'   ;end?
   brne cf_read_01   


   ;ALL DATA is in buffer and X points to beggining
   ld temp,X   
   cpi temp,READ_EEPROM     ;do nothing in read mode
   breq cf_read_exit

   ;write buffer to eeprom,skipping 1 mode byte
   adiw X,1
   
   ;write in eeprom   
   mov	YH,XH
   mov	YL,XL
   
   ;write
   ldi XL,low(EEPROM_CONFIG_ADDR)
   ldi XH,high(EEPROM_CONFIG_ADDR)
         
   ;size
   ldi axl,EEPROM_MAX_BUFFER_SIZE
   rcall EEPROM_write_buffer 
cf_read_exit:

ret
/***************************move eeprom info of 100 bytes **************
@USAGE: counter,X,argument
**********************************************************/
config_copy_eeprom_info:
   ;clr counter
   ldi XL,low(EEPROM_CONFIG_ADDR)
   ldi XH,high(EEPROM_CONFIG_ADDR)

   ldi YL,low(RequestBuffer)
   ldi YH,high(RequestBuffer)

   ldi axl,EEPROM_MAX_BUFFER_SIZE	
   rcall EEPROM_read_buffer
   
ret

/*
;************************************************
;configuration mode
;************************************************
configuration_mode:
	sbi PORTB,PORTB0
	rcall ESP8266_clear  ;clear buffer

	
    rcall usart_init
    rcall usart_enable

	;wait until 100 bytes are recieved
cmode_00:
    _SLEEP_TASK 255
	lds temp,RxTail
	tst temp
	breq cmode_00    ;no byte has arrived

    ldi	YH,high(ResponseBuffer)
    ldi	YL,low(ResponseBuffer)
    ;inspect 1st byte
    ld argument,Y	
    cpi argument,WRITE_EEPROM
    brne cmode_read_02          ;read


;collect 99 bytes
cmode_01:
    _SLEEP_TASK 2
	lds temp,RxTail
	cpi temp,EEPROM_MAX_BUFFER_SIZE
	brlo cmode_01

	
	;write in eeprom   
   ldi	YH,high(ResponseBuffer)
   ldi	YL,low(ResponseBuffer)
   ;inspect 1st byte
   ld argument,Y	
   cpi argument,WRITE_EEPROM
   brne cmode_read_02          ;read

   ;write
   ldi XL,low(EEPROM_CONFIG_ADDR)
   ldi XH,high(EEPROM_CONFIG_ADDR)
   ;skip mode byte
   adiw Y,1   
   ;size
   ldi axl,EEPROM_MAX_BUFFER_SIZE
   rcall EEPROM_write_buffer


   ldi argument,'O'
   rcall usart_send_byte

   ldi argument,'K'
   rcall usart_send_byte
   rjmp cmode_exit_04

cmode_read_02:

   ;send router info
   rcall send_router_info

   ldi argument,','			;separator
   rcall usart_send_byte

   ;send server info
   rcall send_server_info

   ;append line feed
   ldi argument,0x0A
   rcall usart_send_byte
	 
cmode_exit_04:

	rcall ESP8266_clear  ;clear buffer

rjmp cmode_00

rjmp configuration_mode

*/

/***************************send router info**************
@USAGE: counter,X,argument
*/
send_router_info:
   clr counter
   ldi XL,low(EEPROM_CONFIG_ADDR)
   ldi XH,high(EEPROM_CONFIG_ADDR)
send_router_00:
   	rcall EEPROM_read		 	
	;send only <> '\0'
	cpi argument,0
	breq send_router_01	
	rcall usart_send_byte

send_router_01:
	inc counter
	cpi counter,49				;WHY 98 and not 100
	breq send_router_exit

	adiw X,1
	rjmp send_router_00

send_router_exit:
ret

/***************************send server info**************
@USAGE: counter,X,argument
**********************************************************/
send_server_info:
   clr counter
   ldi XL,low(EEPROM_CONFIG_ADDR)
   ldi XH,high(EEPROM_CONFIG_ADDR)
   ;add offset to server info
   adiw X,49
send_server_00:
   	rcall EEPROM_read		 	
	;send only <> '\0'
	cpi argument,0
	breq send_server_01	
	rcall usart_send_byte

send_server_01:
	inc counter
	cpi counter,49				;WHY 98 and not 100
	breq send_server_exit

	adiw X,1
	rjmp send_server_00

send_server_exit:
ret 

;***********************************************
;normal mode of operation
;***********************************************
normal_mode:
	//clear 
   cbi DDRD,PD4
   cbi PORTD,PD4

    _EVENT_SET NORMAL_MODE_EVENT,TASK_CONTEXT
	
normal_mode_01:

	sbi PORTB,PORTB0	
	rcall wait_100ms
	cbi PORTB,PORTB0	 
	rcall wait_100ms
rjmp normal_mode_01


FACTORY_AT_CWJAP:       .db "AT+CWJAP_CUR=",'"','A','n','d','r','o','i','d','A','P','"',',','"','1','2','3','4','5','6','7','8','0','"',0x0D,0x0A,0
FACTORY_AT_CIPSTART:    .db "AT+CIPSTART=",'"','T','C','P','"',',','"','1','9','2','.','1','6','8','.','4','3','.','1','"',',','7','7','7','7',0x0D,0x0A,0

