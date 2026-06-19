;***********************************************USART 0***********************************************
;Transmit 1 byte ; Recieve 0 bytes
;*****************************************************************************************************
.include "kernel/single-producer-consumer.asm"

//PLEASE SET PERIFERAL DEVIDER TO 1
#define PRESCALE 1
#define F_PER (SYSTEM_CLOCK/PRESCALE)
#define BAUD_RATE 115200
#define USART_BAUD_RATE  (F_PER * 4 /BAUD_RATE)  ;8333

.def    cxl=r14
.def    cxh=r15

.def    argument=r17
.def    axl=r18
.def    axh=r19
.def    bxl = r20
.def    bxh = r21
.def    dxl=r22
.def    dxh=r23
.def    return=r24 


.dseg
#define USART_QUEUE_MAX_SIZE  250 

#define WIFI_QUEUE_MAX_SIZE  250 
wifi_queue: .byte 2+WIFI_QUEUE_MAX_SIZE			;8 bit input queue

.equ PIN0 = 0
.equ PIN1 = 1
.equ PIN2 = 2
.equ PIN3 = 3
.equ PIN4 = 4
.equ PIN5 = 5
.equ PIN6 = 6
.equ PIN7 = 7

.def    argument=r17

.cseg

wifi_Tx1_task:    
    lds temp,PORTD_DIR
	sbr temp,1<<PIN1
	sts PORTD_DIR,temp

    rcall usart0_init
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
    
wifi_main:
    

wfmn_00:
    ldi argument,'?'  ;mark begin communiction with wifi
    rcall send_usart_queue 
	rcall send_disable_echo
	brts    wfmn_01
	_SLEEP_TASK_EXT 10000
    rjmp    wfmn_00  ;repeat in case of initial crap
wfmn_01:

    ldi argument,'?'	;mark begin communiction with wifi
    rcall send_usart_queue 
    rcall send_start 	

    ldi argument,'?'	;mark begin communiction with wifi
    rcall send_usart_queue 
    rcall send_client_mode	


    ldi argument,'?'	;mark begin communiction with wifi
    rcall send_usart_queue 			 	
	rcall send_connect_wifi
	
wfmn_02:  //resend byte again
    ldi argument,'?'	;mark begin communiction with wifi
    rcall send_usart_queue 						
	rcall send_tcp_connect	

    ldi argument,'?'	;mark begin communiction with wifi
    rcall send_usart_queue 
	rcall send_tcp_data

    rjmp wfmn_02    


rjmp wifi_main
;===================================================
;@INPUT: argument
;===================================================
usart0_send:
    sts USART0_TXDATAL,argument
u0_wait_send:    
	lds temp,USART0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp u0_wait_send	
	
	lds temp,USART0_STATUS
	sbr temp, (1<<USART_TXCIF_bp)
	sts USART0_STATUS,temp
	
   ;====DEBUG request in usart queue
   rcall send_usart_queue 
   ;=====
ret

;=========================================================
;USART0 init 
;@USAGE:temp,r20,r21
;=========================================================
usart0_init:
  cli
 


  ;input output   
  lds temp,PORTA_DIRSET
  sbr temp,(1<<PIN0)  ;output  Tx  PA0
  cbr temp,(1<<PIN1)  ;input   Rx  PA1 
  sts PORTA_DIRSET,temp


  ldi r20,low(USART_BAUD_RATE)
  ldi r21,high(USART_BAUD_RATE)
  
  
  ;set baud rate
  sts USART0_BAUDL,r20
  sts USART0_BAUDH,r21

  ;enable Tx and Rx
  lds temp,USART0_CTRLB
  ori temp, USART_TXEN_bm | USART_RXEN_bm
  sts USART0_CTRLB,temp

  rcall enable_usart0
   
  sei
ret


enable_usart0:
//enable Rx interrupt
  lds temp,USART0_CTRLA
  ori temp,USART_RXCIE_bm
  sts USART0_CTRLA,temp
ret

disable_usart0:
//disable Rx interrupt
  lds temp,USART0_CTRLA
  cbr temp,1<<USART_RXCIE_bp
  sts USART0_CTRLA,temp

ret
;=========================================================
; Disable echo
;=========================================================
send_reset:
    ldi     ZH, high(AT_RESTORE<<1)
    ldi     ZL, low(AT_RESTORE<<1)
    rcall   uart_send_string_pgm    ; Send command
    rcall   uart_send_crlf          ; Terminate with CRLF

	_SLEEP_TASK_EXT 60000
    ;rcall   send_at_command
    ;brts    srs_00
    ;rjmp    error_handler
;srs_00:
ret
;=========================================================
; Disable echo
;=========================================================
send_disable_echo:
    ldi     ZH, high(CMD_ATE0<<1)
    ldi     ZL, low(CMD_ATE0<<1)    
    rcall   send_at_command

ret
;=========================================================
;Send AT command test communication
;@USAGE:Z
;=========================================================
send_start:
    ldi     ZH, high(CMD_AT<<1)
    ldi     ZL, low(CMD_AT<<1)
    rcall   send_at_command    
	brts  sst_00 
	rjmp error_handler  ;stay forever 
sst_00:
ret

;=========================================================
; Set station mode (client only)
;@USAGE:Z
;=========================================================
send_client_mode:  
    ldi     ZH, high(CMD_CWMODE<<1)
    ldi     ZL, low(CMD_CWMODE<<1)
    rcall   send_at_command
    brts    scm_00
    rjmp    error_handler   ;stay forever
scm_00:
ret
 ;=========================================================
 ;Connect to WiFi (MUST configure credentials first!)
 ; Note: For production, read SSID/password from EEPROM
 ;@USAGE:Z
 ;=========================================================
send_connect_wifi:
    ldi     ZH, high(CMD_CWJAP<<1)
    ldi     ZL, low(CMD_CWJAP<<1)
    rcall   send_at_command
    brts    scw_00		
	rjmp    error_handler
	
    ; Wait for WiFi connection to stabilize
    ldi     temp, 200
	mov cxl,temp
scw_wifi_wait:
    _SLEEP_TASK_EXT 500
    dec     cxl
    brne    scw_wifi_wait

scw_00:
ret
;=========================================================
; Establish TCP connection
;=========================================================
send_tcp_connect:
    ldi     ZH, high(CMD_CIPSTART<<1)
    ldi     ZL, low(CMD_CIPSTART<<1)
    rcall   send_at_command
    brts     sct_00
    rjmp    error_handler
sct_00:

ret
;=========================================================
; Prepare to send 1 byte (CIPSEND)
;=========================================================
send_tcp_data:
    ldi     ZH, high(CMD_CIPSEND<<1)
    ldi     ZL, low(CMD_CIPSEND<<1)
    rcall   uart_send_string_pgm
    rcall   uart_send_crlf

std_00:    
    ldi temp, 200        ; ~6 second timeout (adjust as needed)
	mov cxl,temp
std_01:
   _SLEEP_TASK_EXT 500
   dec     cxl
   breq    std_timeout

   ldi ZL,low(wifi_queue)
   ldi ZH,high(wifi_queue)	  	
   ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc std_01					;it is empty nothing to read

    ; Wait for '>' prompt    
	cpi     return, '>'
    brne    std_00              ;reset wait var
	;SEND DATA  
    ldi     argument, 'L'
    rcall   usart0_send
    rcall   uart_send_crlf
    
    ; Wait for SEND OK confirmation
    rcall   wait_response
	brtc     std_timeout
    
	;close connection
    ldi     ZH, high(CMD_CIPCLOSE<<1)
    ldi     ZL, low(CMD_CIPCLOSE<<1)
    rcall   send_at_command

ret
std_timeout:
     rjmp    error_handler
ret


ret

;===============================================================================
; Send AT command and wait for OK response
; @INPUT: Z pointer to command (without CRLF) in flash
; @OUTPUT: esp_status = 1 if OK
;===============================================================================
send_at_command:
    rcall   uart_send_string_pgm    ; Send command
    rcall   uart_send_crlf          ; Terminate with CRLF
    rcall   wait_response       ; Wait for OK
ret
;===============================================================================
; Send string from program memory (flash)
; @INPUT: Z pointer to null-terminated string in flash
; @USAGE: argument
;===============================================================================
uart_send_string_pgm:
    lpm     argument, Z+                ; Load byte from flash
    tst     argument
    breq    ussp_done
    rcall   usart0_send
    rjmp    uart_send_string_pgm
ussp_done:
ret
;===============================================================================
; Send string from SRAM/register (for dynamic strings)
; @INPUT: X pointer to string in SRAM
; @USAGE: temp
;===============================================================================
uart_send_string_ram:
    ld      argument, X+
    tst     argument
    breq    ussr_done
    rcall   usart0_send
    rjmp    uart_send_string_ram
ussr_done:
ret
;===============================================================================
; Send CR+LF (common AT command terminator)
;===============================================================================
uart_send_crlf:
    ldi     argument, 0x0D              ; Carriage return
    rcall   usart0_send
    ldi     argument, 0x0A              ; Line feed
    rcall   usart0_send
    ret
;===============================================================================
; Wait for expected response from ESP-01 with timeout 
;'OK' response
;@OUTPUT: T flag 0 - failure
;				1 - success
;@WARNING: Timeout may be longer depending on local WiFi Router 
;===============================================================================
wait_response:
	clt
    ldi temp, 250        ; ~2 second timeout (adjust as needed)
	mov cxl,temp
wrp_00:
   _SLEEP_TASK_EXT 1000
   dec     cxl
   breq    wrp_timeout

   ldi ZL,low(wifi_queue)
   ldi ZH,high(wifi_queue)	  	
   ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc wrp_00					;it is empty nothing to read
  
	; Check if we received 'O' (first char of OK)    
    cpi     return,'O' ;79
    breq    wrp_01    
	rjmp    wait_response       ;start again 
    
wrp_01:	
    ; Poll for 'K'
	
    ldi ZL,low(wifi_queue)
    ldi ZH,high(wifi_queue)	  	
    ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc wrp_01					;it is empty nothing to read

    cpi     return, 'K'
    breq    wrp_success	  
		    ;sbi VPORTD_OUT,PIN1  
	rjmp    wait_response       ;start again

wrp_timeout:
    clt
ret
    
wrp_success:
    set	
ret


;=============================================
;WiFi communication error - set LED blinking

error_handler:
  sbi VPORTD_OUT,PIN1		
  _SLEEP_TASK_EXT 10000
  cbi VPORTD_OUT,PIN1		
  _SLEEP_TASK_EXT 10000

rjmp error_handler






USART0_RXC_Intr:
_PRE_INTERRUPT
    ;store currently interrupted task's CPU context with registers used by queue
	push ZH
	push ZL
	push cxh
	push cxl
	push dxh
	push dxl
	push axh
	push axl
    push argument
	push bxl
	push bxh
	push r0
	push r1
    push r2
	push r3

 
 lds argument,USART0_RXDATAL  ;read the byte to enable the next interrupt
 
	;store in queue
   ldi ZL,low(wifi_queue)
   ldi ZH,high(wifi_queue)	  	
   ldi axl,WIFI_QUEUE_MAX_SIZE	
   rcall spc_queue8_push

   ;send response to terminal program
   ldi ZL,low(usart_queue)
   ldi ZH,high(usart_queue)	  	
   ldi axl,USART_QUEUE_MAX_SIZE	
   rcall spc_queue8_push
  
	pop r3
	pop r2
	pop r1
	pop r0
	pop bxh
	pop bxl
	pop argument
	pop axl
	pop axh
	pop dxl
	pop dxh
	pop cxl
	pop cxh
	pop ZL
	pop ZH
_POST_INTERRUPT
_RETI


;===============================================================================
; AT Command Strings (Stored in Flash)
;===============================================================================
CMD_ATE0:
	.db     "ATE0", 0              ; Disable echo
CMD_AT:
    .db     "AT", 0
AT_RESTORE:
    .db     "AT+RESTORE",0			;perge cache
CMD_CWMODE:
    .db     "AT+CWMODE=1", 0
CMD_CWJAP:
    .db "AT+CWJAP=",'"','A','1','_','D','6','4','E','"',',','"','2','X','H','2','4','H','3','6','6','H','"',0
CMD_CIPSTART:
    .db     "AT+CIPSTART=",'"','T','C','P','"',',','"','1','9','2','.','1','6','8','.','0','.','5','0','"',',','9','0','9','0', 0
CMD_CIPSEND:
    .db     "AT+CIPSEND=1", 0
CMD_CIPCLOSE:
    .db     "AT+CIPCLOSE", 0
CMD_CIPMUX:
    .db     "AT+CIPMUX=0", 0

.EXIT