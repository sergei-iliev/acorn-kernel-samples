/***********Send byte in polling mode**********************
*@INPUT: argument
*/
rs232_send_byte:
	; Wait for empty transmit buffer
	sbis UCSRA,UDRE
	rjmp rs232_send_byte
	; Put data into buffer, sends the data
	out UDR,argument
ret

/***************flash buffers********************
*/
usart_flush:
	sbis UCSRA, RXC
ret
	in temp, UDR
	//rjmp usart_flush
ret

;********************Read text from buffer to task register*******************
;@INPUT:ZH,ZL,argument
;@USAGE:line1char/line2char,r0,temp,Z,return
;@OUTPUT:return
read_byte:		
	clr temp
	ADD16 ZL,ZH,argument,temp	
	ld  return,Z	
ret

;********************Write text from Rx232 to input buffer*******************
;@INPUT:ZH,ZL,
;      return -> byte to save
;	   argument ->next byte count	
;@USAGE:
;@OUTPUT:return

write_byte:
	clr temp
	ADD16 ZL,ZH,argument,temp	
    st Z,return
ret

;********************Add byte to input buffer*************
;@INPUT:argument
;USAGE:temp,X,counter
add_byte_input_buffer:

  ;start from 0 index
  lds counter,RxTail
  cpi counter,RS232_BUFF_SIZE
  brsh add_byte_in_exit

  
  ldi XL,low(rs232_input)
  ldi XH,high(rs232_input)  

  clr temp
  ADD16 XL,XH,counter,temp	
  st X,argument

  inc counter
  sts RxTail,counter


add_byte_in_exit:

ret

;********************Copy  kb buffer to output buffer*******************
;@INPUT:
;@USAGE:temp,X,Y,bxl,bxh
;@OUTPUT:return
prepare_output_buffer:
    clr temp
	sts TxCurrentRef,temp

    lds temp,kb_buffcnt 
    sts TxTail,temp
	mov bxh,temp
	;source
	ldi XL,low(kb_buffer)
	ldi XH,high(kb_buffer)
	;destination
	ldi YL,low(rs232_output)
	ldi YH,high(rs232_output)
	clr bxl

prepare_out_buffer:
	cp bxl,bxh
	breq prepare_out_exit    

	ld temp,X+
	st Y+,temp 
	inc bxl

	rjmp prepare_out_buffer 

prepare_out_exit:
ret

;********************Reset input buffer*******************
;@INPUT:
;@USAGE:temp,X,counter
;@OUTPUT:return
reset_input_buffer:
    clr counter
    ldi temp,0x00   
    sts RxTail,temp
	
	ldi XL,low(rs232_input)
	ldi XH,high(rs232_input)    		   
    
res_in_buffer:
    ldi temp,0x00
	st X,temp
	adiw XH:XL,1 
	inc counter
	cpi counter,RS232_BUFF_SIZE
	breq res_in_exit    
	rjmp res_in_buffer

res_in_exit:
ret

;********************Reset output buffer*******************
;@INPUT:
;@USAGE:temp,X,counter
;@OUTPUT:return
reset_output_buffer:
    clr counter
    ldi temp,0x00   
    sts TxTail,temp
	
	ldi XL,low(rs232_output)
	ldi XH,high(rs232_output)    		   
    
res_out_buffer:
	ldi temp,0x00
	st X,temp
	adiw XH:XL,1 
	inc counter
	cpi counter,RS232_BUFF_SIZE
	breq res_out_exit    
	rjmp res_out_buffer

res_out_exit:
ret