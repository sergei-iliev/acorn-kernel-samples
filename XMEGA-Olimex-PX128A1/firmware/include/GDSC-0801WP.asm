/*
GDSC-0801WP
LCD driver
*/

lcd_init:
	
	clr temp
	sbr temp,(1<<7|1<<6|1<<5|1<<4)	;DB4,DB5,DB6,DB7 output
	sts PORTE_OUTCLR,temp

	clr temp
	sbr temp,(1<<7|1<<6|1<<5|1<<4)	;DB4,DB5,DB6,DB7 output
	sts PORTE_DIRSET,temp


	clr temp
	sbr temp,(1<<RS_BIT|1<<RW_BIT|1<<EN_BIT)	;RS,RW,E output
	sts PORTC_DIRSET,temp

	// This first commands have 4 bits Length!!!!! Not Byte!!!
;pass 1

	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall delay

	//RS,RW OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<RS_BIT|1<<RW_BIT) 
	sts PORTC_OUT,temp

	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x30
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

;pass 2
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall delay
	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x30
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

;pass 3
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall delay
	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x30
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

;pass 4 - function set
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall delay
	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x20
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

;FUNCTION SET
    ldi argument,0x28
	rcall lcd_send_cmd

;DISPLAY OFF
    ldi argument,0x08
	rcall lcd_send_cmd

;DISPLAY CLEAR
    ldi argument,0x01
	rcall lcd_send_cmd

;ENTRY MODE SET
    ldi argument,0x06
	rcall lcd_send_cmd

;DISPLAY ON
    ldi argument,0x0C
	rcall lcd_send_cmd


ret
/**************LCD CLEAR SCREEN***************************
*/
lcd_clr_screen:
;DISPLAY CLEAR
    ldi argument,0x01
	rcall lcd_send_cmd
ret


/**************SEND LCD CHAR******************************
Send a single char to LCD
@INPUT: argument - character
@USAGE: X,temp,axl
*/
lcd_send_char:
	mov axl,argument
	andi axl,0xF0		//get upper nible	
	
	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RW OFF
	lds temp,PORTC_OUT
	cbr temp,1<<RW_BIT 
	sts PORTC_OUT,temp

	//RS ON
	lds temp,PORTC_OUT
	sbr temp,(1<<RS_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

	mov axl,argument
	andi axl,0x0F		//get lower nible	
	swap axl

	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RW OFF
	lds temp,PORTC_OUT
	cbr temp,1<<RW_BIT
	sts PORTC_OUT,temp

	//RS ON
	lds temp,PORTC_OUT
	sbr temp,(1<<RS_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall delay

ret

/**************SEND LCD ROM TEXT in LOOP******************************
Send static text written FLASH to LCD
@INPUT: Z - ROM pointer to text ,should add count too but ..... it is a dummy driver
@USAGE: Z,X,temp,axl
*/
lcd_send_rom_text:

lcd_rtxt_00:
	ldi ZH,high(TEXT*2)
	ldi ZL,low(TEXT*2)
	
lcd_rtxt_001:
	ldi YH,high(LCD_FRAME)
	ldi YL,low(LCD_FRAME)
	
	ldi counter,8

lcd_rtxt_01:
	lpm temp,Z+
	st Y+,temp
	;test if END terminator
	cpi temp,0
	breq lcd_rtxt_00

	dec counter
	tst counter
	brne lcd_rtxt_01

	;***show frame from RAM
	
	ldi YH,high(LCD_FRAME)
	ldi YL,low(LCD_FRAME)	
	ldi counter,8

lcd_rtxt_02:
	ld argument,Y+
	rcall lcd_send_char
	dec counter
	tst counter
	brne lcd_rtxt_02

	;sleep
	ldi XL,low(10000)   
	ldi XH,high(10000)
	rcall long_delay
	;lcd clear 
	rcall lcd_clr_screen

	;next frame from Z	
	SUBI16 ZL,ZH,7 
	rjmp lcd_rtxt_001 
 
ret

/**************SEND LCD COMMAND******************************
@INPUT: argument
@USAGE: X,temp,axl
*/
lcd_send_cmd:
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall delay
	
	mov axl,argument
	andi axl,0xF0		//get upper nible	

	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RS,RW OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<RS_BIT|1<<RW_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	mov axl,argument
	andi axl,0x0F		//get lower nible	
	swap axl

	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RS,RW OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<RS_BIT|1<<RW_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall delay


    ldi XL,low(50000)   
	ldi XH,high(50000)
	rcall delay

ret
/*
0.2us single loop
@INPUT: XL,XH
@USAGE: XL,XH,temp
*/
delay:
	DEC16 XL,XH
	CPI16 XL,XH,temp,0
	brne delay 
ret


lcd_send_text:
    ldi argument,'A'
	rcall lcd_send_char 

    ldi argument, 'C'
	rcall lcd_send_char 

    ldi argument, 'O'
	rcall lcd_send_char 

    ldi argument, 'R'
	rcall lcd_send_char

    ldi argument, 'N'
	rcall lcd_send_char

    ldi argument, ' '
	rcall lcd_send_char

    ldi argument, 'v'
	rcall lcd_send_char

    ldi argument, '2'
	rcall lcd_send_char

ret
/*
long loop in loop
@INPUT: XL,XH
@USAGE: XL,XH,axl,axh,counter,temp
*/
long_delay:
    ldi counter,200
long_dly_000:    
	mov axl,XL
	mov axh,XH
	

long_dly_00:
	DEC16 axl,axh
	CPI16 axl,axh,temp,0
	brne long_dly_00 
   
    dec counter
    tst counter
    brne long_dly_000
ret

TEXT: .db "        ACORN micro kernel        ",0