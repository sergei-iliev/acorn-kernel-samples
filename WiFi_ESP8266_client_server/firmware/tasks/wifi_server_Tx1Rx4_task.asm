;***********************************************USART 0***********************************************
;WiFi Server mode
;Recieve 1 byte ; Transmit 4 bytes
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

recv_byte: .byte 1  ; expecting 1 byte


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

wifi_Tx1Rx4_task:    

    lds temp,PORTD_DIR
	sbr temp,1<<PIN1
	sts PORTD_DIR,temp

    rcall usart0_init
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

    _SLEEP_TASK_EXT 60000 ;3 sec until wifi adaptor init itself
wifi_main:

//SERVER mode

    ldi argument,'?'	;mark begin communiction with wifi
    rcall send_usart_queue 
    rcall send_reset

wfmn_00:
    ldi argument,'?'  ;mark begin communiction with wifi
    rcall send_usart_queue 
	rcall send_disable_echo
	brts    wfmn_01
	_SLEEP_TASK_EXT 10000
    rjmp    wfmn_00  ;repeat in case of initial crap
wfmn_01:	
	

    ldi argument,'?'	
    rcall send_usart_queue 
    rcall send_server_mode	

    ldi argument,'?'	
    rcall send_usart_queue 
    rcall send_multiple_connections

    ldi argument,'?'	
    rcall send_usart_queue 
    rcall send_read_ip_address

    ldi argument,'?'	
    rcall send_usart_queue 
	rcall start_tcp_server       ;start listening server

server_repeat:	
	;wait for incomming data of 1 byte
	rcall recv_tcp_data

	ldi argument,'?'	
    rcall send_usart_queue 

    lds argument,recv_byte	;send byte to UART for debug
    rcall send_usart_queue 

	rcall send_tcp_data		;send 4 bytes to client	

	sbi VPORTD_OUT,PIN1	;LED ON
	
	rjmp server_repeat

rjmp wifi_main
;===================================================
;@INPUT: argument
;@USAGE: argument,temp
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
	
   ;====DEBUG send char to usart queue
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

  lds temp,USART0_CTRLA
  ori temp,USART_RXCIE_bm
  sts USART0_CTRLA,temp
   
  sei
ret


;=========================================================
; Reset ESP chip
;@USAGE: Z,argument,temp,r17,YL,YH
;=========================================================
send_reset:
    ldi     ZH, high(CMD_RST<<1)
    ldi     ZL, low(CMD_RST<<1)
    rcall   uart_send_string_pgm    ; Send command
    rcall   uart_send_crlf          ; Terminate with CRLF

	_SLEEP_TASK_EXT 60000    
ret
;=========================================================
; Disable echo
;@USAGE: Z,argument,temp,cxl,axl,return,bxl,bxh,r0,r1,r17,YL,YH
;=========================================================
send_disable_echo:
    ldi     ZH, high(CMD_ATE0<<1)
    ldi     ZL, low(CMD_ATE0<<1)    
    rcall   send_at_command

ret
;=========================================================
; Set server mode 
;@USAGE: Z,argument,temp,cxl,axl,return,bxl,bxh,r0,r1,r17,YL,YH
;=========================================================
send_server_mode:  
    ldi     ZH, high(CMD_CWMODE<<1)
    ldi     ZL, low(CMD_CWMODE<<1)
    rcall   send_at_command
    brts    ssm_00
    rjmp    error_handler   ;stay forever
ssm_00:
ret
;=========================================================
; Set multiple connections
;@USAGE: Z,argument,temp,cxl,axl,return,bxl,bxh,r0,r1,r17,YL,YH
;=========================================================
send_multiple_connections:  
    ldi     ZH, high(CMD_CIPMUX<<1)
    ldi     ZL, low(CMD_CIPMUX<<1)
    rcall   send_at_command
    brts    smc_00
    rjmp    error_handler   ;stay forever
smc_00:
ret
;=========================================================
;Read IP ADDRESS
;@USAGE: Z,argument,temp,cxl,axl,return,bxl,bxh,r0,r1,r17,YL,YH
;=========================================================
send_read_ip_address:  
    ldi     ZH, high(CMD_CIFSR<<1)
    ldi     ZL, low(CMD_CIFSR<<1)
    rcall   send_at_command
    brts    sria_00
    rjmp    error_handler   ;stay forever
sria_00:
ret

;=========================================================
;Start TCP server
;@USAGE: Z,argument,temp,cxl,axl,return,bxl,bxh,r0,r1,r17,YL,YH
;=========================================================
start_tcp_server:  
    ldi     ZH, high(CMD_CIPSERVER<<1)
    ldi     ZL, low(CMD_CIPSERVER<<1)
    rcall   send_at_command
    brts    stsrv_00
    rjmp    error_handler   ;stay forever
stsrv_00:
ret

;=========================================================
;Send 4 bytes (CIPSEND)
;@USAGE: Z,argument,temp,cxl,axl,return,bxl,bxh,r0,r1,r17,YL,YH
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
	
	
	
	;SEND DATA  4 bytes ABCD
    ldi     argument, 'A'
    rcall   usart0_send
    ldi     argument, 'B'
    rcall   usart0_send
    ldi     argument, 'C'
    rcall   usart0_send
    ldi     argument, 'D'
    rcall   usart0_send
    
	rcall   uart_send_crlf
    
    ; Wait for SEND OK confirmation
    rcall   wait_response
	brtc     std_timeout
    
ret

std_timeout:
     rjmp    error_handler

ret
;=========================================================
; Receive 1 bytes from server
; Parse +IPD,link_id,length:data
;@USAGE: temp,cxl,Z,axl,return,bxl,bxh,r0,r1,r17,YL,YH
;=========================================================
recv_tcp_data:
rcv_00:    
    ldi temp, 200        ; ~6 second timeout (adjust as needed)
	mov cxl,temp
rcv_01:
   _SLEEP_TASK_EXT 500
   dec     cxl
   breq    rcv_timeout

   ldi ZL,low(wifi_queue)
   ldi ZH,high(wifi_queue)	  	
   ldi axl,WIFI_QUEUE_MAX_SIZE		

   rcall spc_queue8_pop
   brtc rcv_01					;it is empty nothing to read

   ; Wait for '+' prompt    
   cpi     return, '+'
   brne    rcv_00              ;reset wait var

rcv_02:	
    ; 'I'
	
    ldi ZL,low(wifi_queue)
    ldi ZH,high(wifi_queue)	  	
    ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc rcv_02					;it is empty nothing to read

    cpi     return, 'I'		  
	brne    rcv_00       ;start again

rcv_03:	
    ; 'P'	
    ldi ZL,low(wifi_queue)
    ldi ZH,high(wifi_queue)	  	
    ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc rcv_03					;it is empty nothing to read

    cpi     return, 'P'		  
	brne    rcv_00       ;start again
	
rcv_04:	
    ; 'D'	
    ldi ZL,low(wifi_queue)
    ldi ZH,high(wifi_queue)	  	
    ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc rcv_04					;it is empty nothing to read

    cpi     return, 'D'		  
	brne    rcv_00       ;start again

rcv_05:	
    ; ':'	skip (link_id,<len>) bytes
    ldi ZL,low(wifi_queue)
    ldi ZH,high(wifi_queue)	  	
    ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc rcv_05					;it is empty nothing to read

    cpi     return, ':'		  
	breq    rcv_06       ;start again
	rjmp rcv_05			;forever loop???????
	
rcv_06:
	;read 1 bytes
	
rcv_06_00:
    ldi ZL,low(wifi_queue)
    ldi ZH,high(wifi_queue)	  	
    ldi axl,WIFI_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc rcv_06_00					;it is empty nothing to read
	 
	
	sts recv_byte,return
	

ret
rcv_timeout:
     rjmp    error_handler

ret
;===============================================================================
; Send AT command and wait for OK response
; @INPUT: Z pointer to command (without CRLF) in flash
; @OUTPUT: esp_status = 1 if OK
; @USAGE: Z,argument,temp,cxl,axl,return,bxl,bxh,r0,r1,r17,YL,YH
;===============================================================================
send_at_command:
    rcall   uart_send_string_pgm    ; Send command
    rcall   uart_send_crlf          ; Terminate with CRLF
    rcall   wait_response       ; Wait for OK
ret
;===============================================================================
; Send string from program memory (flash)
; @INPUT: Z pointer to null-terminated string in flash
; @USAGE: Z,argument,temp
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
; @USAGE: X,argument,temp
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
; @USAGE: argument,temp
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
;@USAGE: temp,cxl,Z,axl,return,bxl,bxh,r0,r1,r17,YL,YH
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
;@USAGE: r17,temp,YL,YH
;=============================================
error_handler:
  sbi VPORTD_OUT,PIN1		
  _SLEEP_TASK_EXT 10000
  cbi VPORTD_OUT,PIN1		
  _SLEEP_TASK_EXT 10000

rjmp error_handler






;=============================================
;USART0 RX complete interrupt
;@USAGE: ZH,ZL,cxh,cxl,dxh,dxl,axh,axl,argument,bxl,bxh,r0,r1,r2,r3
;=============================================
USART0_RXC_Intr:
_PRE_INTERRUPT
    ;store currently interrupted task's CPU context with registers used by queue
	push ZH
	push ZL
	push axl
    push argument
	push bxl
	push bxh
	push r0
	push r1


 
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
  

	pop r1
	pop r0
	pop bxh
	pop bxl
	pop argument
	pop axl
	pop ZL
	pop ZH
_POST_INTERRUPT
_RETI


;===============================================================================
; AT Command Strings (Stored in Flash)
;===============================================================================
CMD_ATE0:
	.db     "ATE0", 0              ; Disable echo
CMD_RST:
    .db     "AT+RST",0			;reset module	
CMD_RESTORE:
    .db     "AT+RESTORE",0			;perge cache
CMD_CWMODE:
    .db     "AT+CWMODE=3", 0		; Station + AP mode
;CMD_CWJAP:
;    .db "AT+CWJAP=",'"','A','1','_','D','6','4','E','"',',','"','2','X','H','2','4','H','3','6','6','H','"',0
;CMD_CIPSTART:
;    .db     "AT+CIPSTART=",'"','T','C','P','"',',','"','1','9','2','.','1','6','8','.','0','.','5','0','"',',','9','0','9','0', 0
CMD_CIPSEND:
    .db     "AT+CIPSEND=0,4", 0
CMD_CIPCLOSE:
    .db     "AT+CIPCLOSE", 0
CMD_CIPMUX:
    .db     "AT+CIPMUX=1", 0		;multiple connections

CMD_CIPSERVER:  .db "AT+CIPSERVER=1,9090", 0  ; TCP server port 8080

CMD_CIFSR:      .db "AT+CIFSR", 0
.EXIT