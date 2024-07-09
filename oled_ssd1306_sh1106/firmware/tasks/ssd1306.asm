
/******************************************************************************
 SSD1306 ID and Command List
 ******************************************************************************/
#define SSD1306_WIDTH 128
#define SSD1306_HEIGHT 64

#define SSD1306_COLS 128
#define SSD1306_PAGES 8

#define SSD1306_COMMAND 0x00
#define SSD1306_DATA 0xC0
#define SSD1306_DATA_CONTINUE 0x40

#define SSD1306_SET_CONTRAST_CONTROL 0x81
#define SSD1306_DISPLAY_ALL_ON_RESUME 0xA4
#define SSD1306_DISPLAY_ALL_ON 0xA5
#define SSD1306_NORMAL_DISPLAY 0xA6
#define SSD1306_INVERT_DISPLAY 0xA7
#define SSD1306_DISPLAY_OFF 0xAE
#define SSD1306_DISPLAY_ON 0xAF
#define SSD1306_NOP 0xE3

#define SSD1306_HORIZONTAL_SCROLL_RIGHT 0x26
#define SSD1306_HORIZONTAL_SCROLL_LEFT 0x27
#define SSD1306_HORIZONTAL_SCROLL_VERTICAL_AND_RIGHT 0x29
#define SSD1306_HORIZONTAL_SCROLL_VERTICAL_AND_LEFT 0x2A
#define SSD1306_DEACTIVATE_SCROLL 0x2E
#define SSD1306_ACTIVATE_SCROLL 0x2F
#define SSD1306_SET_VERTICAL_SCROLL_AREA 0xA3

#define SSD1306_SET_LOWER_COLUMN 0x00
#define SSD1306_SET_HIGHER_COLUMN 0x10
#define SSD1306_MEMORY_ADDR_MODE 0x20
#define SSD1306_SET_COLUMN_ADDR 0x21
#define SSD1306_SET_PAGE_ADDR 0x22

#define SSD1306_SET_START_LINE 0x40
#define SSD1306_SET_SEGMENT_REMAP 0xA0
#define SSD1306_SET_MULTIPLEX_RATIO 0xA8
#define SSD1306_COM_SCAN_DIR_INC 0xC0
#define SSD1306_COM_SCAN_DIR_DEC 0xC8
#define SSD1306_SET_DISPLAY_OFFSET 0xD3
#define SSD1306_SET_COM_PINS 0xDA
#define SSD1306_CHARGE_PUMP 0x8D

#define SSD1306_SET_DISPLAY_CLOCK_DIV_RATIO 0xD5
#define SSD1306_SET_PRECHARGE_PERIOD 0xD9
#define SSD1306_SET_VCOM_DESELECT 0xDB

#define SSD1306_COMM_HORIZ_NORM     0xA0
#define SSD1306_COMM_HORIZ_FLIP     0xA1

#define SSD1306_COMM_SCAN_NORM      0xC0
#define SSD1306_COMM_SCAN_REVS      0xC8


#define GRAPHICS_BUFFER_SIZE (SSD1306_WIDTH*(SSD1306_HEIGHT/8)) 
.dseg
graphics_buffer:   .byte GRAPHICS_BUFFER_SIZE
.cseg

.EQU	SSD1306_ADDRESS =0x3C   ;SSD1306


.def    argument=r17
.def    axl=r18
.def    axh=r19
.def    XX = r2
.def    YY = r3
.def    char=r4

;***** DIV Subroutine Register Variables

.def	drem8u	=r15		;remainder
.def	dres8u	=r16		;result
.def	dd8u	=r16		;dividend
.def	dv8u	=r17		;divisor
.def	dcnt8u	=r18		;loop counter

/**************************************************************************
;Initialize ssd1306
;@USED: axl,temp
***************************************************************************/
ssd1306_setup:
	
	rcall twi_init

	ldi axl,SSD1306_MEMORY_ADDR_MODE		;set memory address mode
	rcall ssd1306_send_command

	ldi axl,0		;set horizontal addr mode
	rcall ssd1306_send_command

	ldi axl,SSD1306_SET_MULTIPLEX_RATIO		;set multiplex ratio
	rcall ssd1306_send_command

	ldi axl,0x3F
	rcall ssd1306_send_command

	ldi axl,SSD1306_SET_DISPLAY_OFFSET
	rcall ssd1306_send_command

	ldi axl,0x00
	rcall ssd1306_send_command

	ldi axl,SSD1306_SET_START_LINE
	rcall ssd1306_send_command

	ldi axl,0xA1
	rcall ssd1306_send_command

	ldi axl,SSD1306_COM_SCAN_DIR_DEC
	rcall ssd1306_send_command

	ldi axl,SSD1306_SET_COM_PINS
	rcall ssd1306_send_command
	
	ldi axl,0x12
	rcall ssd1306_send_command

	ldi axl,SSD1306_SET_CONTRAST_CONTROL
	rcall ssd1306_send_command
	
	ldi axl,0x7F
	rcall ssd1306_send_command

	ldi axl,SSD1306_DISPLAY_ALL_ON_RESUME
	rcall ssd1306_send_command

	ldi axl,SSD1306_NORMAL_DISPLAY
	rcall ssd1306_send_command

	ldi axl,SSD1306_SET_DISPLAY_CLOCK_DIV_RATIO
	rcall ssd1306_send_command
	
	ldi axl,0xF0
	rcall ssd1306_send_command

	ldi axl,SSD1306_SET_PRECHARGE_PERIOD
	rcall ssd1306_send_command
	
	ldi axl,0xF1
	rcall ssd1306_send_command

	ldi axl,SSD1306_CHARGE_PUMP
	rcall ssd1306_send_command
	
	ldi axl,0x14
	rcall ssd1306_send_command

	ldi axl,SSD1306_DISPLAY_ON
	rcall ssd1306_send_command

	
ret
/**************************************************************************************
;Send byte command
;@INPUT: axl- command to send
;@USED: temp,argument
;
***************************************************************************************/
ssd1306_send_command:
    ;transmit start condition
	rcall twi_start

	;transmit SLA+W
	ldi argument,(SSD1306_ADDRESS<<1)
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_ADR_ACK
	brne snd_cmd_00


    ;command
	ldi argument,SSD1306_COMMAND
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne snd_cmd_00

	
	;VALUE
	mov argument,axl
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne snd_cmd_00

snd_cmd_00:
	;send stop condition
	rcall twi_send_stop
ret

/************************************************************************************************
;Send byte data
;@INPUT: axl 
;@USED: argument,temp
************************************************************************************************/
ssd1306_send_data:
    ;transmit start condition
	rcall twi_start

	;transmit SLA+W
	ldi argument,(SSD1306_ADDRESS<<1)
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_ADR_ACK
	brne snd_dta_00

    ;data
	ldi argument,SSD1306_DATA
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne snd_dta_00

	
	;VALUE
	mov argument,axl
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne snd_dta_00

	
	ldi argument,0xFF
	rcall twi_send_byte
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne snd_dta_00
	
snd_dta_00:
	;send stop condition
	rcall twi_send_stop    
   
ret
/***********************************************************************************************
;Clear local buffer
;@USED: argument,temp,X,Y
************************************************************************************************/
ssd1306_clear_buffer:
	;clear 1024 bytes  128x8
	ldi XL,low(GRAPHICS_BUFFER_SIZE)
	ldi XH,high(GRAPHICS_BUFFER_SIZE)
	
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

	ldi argument,0x00   ;0 data to clear bit by bit

buf_clr_loop_00:		
	st Y+,argument
	
	
	SUBI16 XL,XH,1
	CPI16 XL,XH,temp,0
	brne buf_clr_loop_00 
ret
/***********************************************************************************************
;Clear entire screen area
;@USED: axl,argument,temp,X
************************************************************************************************/
ssd1306_clear_screen:
    ;set columns
	ldi axl,SSD1306_SET_COLUMN_ADDR
	rcall ssd1306_send_command
	ldi axl,0x00
	rcall ssd1306_send_command
	ldi axl,(SSD1306_COLS-1)		;zero based index
	rcall ssd1306_send_command
	  
	;set rows
	ldi axl,SSD1306_SET_PAGE_ADDR
	rcall ssd1306_send_command
	ldi axl,0x00
	rcall ssd1306_send_command
	ldi axl,(SSD1306_PAGES-1)
	rcall ssd1306_send_command

    ;transmit start condition
	rcall twi_start

	;transmit SLA+W
	ldi argument,(SSD1306_ADDRESS<<1)
	rcall twi_send_byte
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_ADR_ACK
	brne snd_clr_00

    ;data continue
	ldi argument,SSD1306_DATA_CONTINUE
	rcall twi_send_byte
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne snd_clr_00

	;send 1024 bytes  128x8
	ldi XL,low(GRAPHICS_BUFFER_SIZE)
	ldi XH,high(GRAPHICS_BUFFER_SIZE)

clr_loop_00:		
	ldi argument,0x00   ;0 data to clear bit by bit
	rcall twi_send_byte
	;expect status
	
	lds temp,TWSR
	andi temp, 0xF8
	cpi temp, MTX_DATA_ACK
	brne snd_clr_00
	
	SUBI16 XL,XH,1
	CPI16 XL,XH,temp,0
	brne clr_loop_00 
		
snd_clr_00:
	rcall twi_send_stop   	
ret

/******************************************************************************************
;Position 0=<Col=<127 and 0=<Page=<7 
;@INPUT  XX column
;		YY page
;@USED:  axl,temp
******************************************************************************************/
ssd1306_position_col_page:
	ldi axl,SSD1306_SET_COLUMN_ADDR
	rcall ssd1306_send_command
	mov axl,XX
	rcall ssd1306_send_command
	ldi axl,(SSD1306_COLS-1)
	rcall ssd1306_send_command

	;set rows
	ldi axl,SSD1306_SET_PAGE_ADDR
	rcall ssd1306_send_command
	mov axl,YY
	rcall ssd1306_send_command
	ldi axl,(SSD1306_PAGES-1)
	rcall ssd1306_send_command
		

	;DON"T SEND STOP condition
ret

/******************************************************************************************
;Scroll screen ON or OFF
;@INPUT: char  - 0 or 1
;		
;@USED: argument,temp,axl
******************************************************************************************/
ssd1306_scroll_onoff:
    ;transmit start condition
	rcall twi_start

	;transmit SLA+W
	ldi argument,(SSD1306_ADDRESS<<1)
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_ADR_ACK
	brne scrll_cmd_00


    ;command
	ldi argument,SSD1306_COMMAND
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne scrll_cmd_00

	tst char						;0 or 1
	brne scroll_on_00						;disable scroll
	;VALUE
	ldi argument,SSD1306_DEACTIVATE_SCROLL
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne scrll_cmd_00
	
	rjmp scrll_cmd_00
scroll_on_00:					;enable scroll
	
	;VALUE
	ldi argument,SSD1306_ACTIVATE_SCROLL
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne scrll_cmd_00

scrll_cmd_00:	
	;send stop condition
	rcall twi_send_stop

ret
/******************************************************************************************
;Rotate screen only 0 and 180 allowed
;@INPUT: char  - 0 or 180
;		
;@USED: argument,temp,axl
******************************************************************************************/
ssd1306_screen_rotate:
    ;transmit start condition
	rcall twi_start

	;transmit SLA+W
	ldi argument,(SSD1306_ADDRESS<<1)
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_ADR_ACK
	brne rot_cmd_00


    ;command
	ldi argument,SSD1306_COMMAND
	rcall twi_send_byte
	
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne rot_cmd_00

	tst char						;0 or 180
	brne rot_180_00
	;VALUE
	ldi argument,SSD1306_COMM_HORIZ_FLIP
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne rot_cmd_00

	;VALUE
	ldi argument,SSD1306_COMM_SCAN_REVS
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne rot_cmd_00
	
	rjmp rot_cmd_00
rot_180_00:
	
	;VALUE
	ldi argument,SSD1306_COMM_HORIZ_NORM
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne rot_cmd_00

	;VALUE
	ldi argument,SSD1306_COMM_SCAN_NORM
	rcall twi_send_byte

	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne rot_cmd_00


rot_cmd_00:	
	;send stop condition
	rcall twi_send_stop
ret

#define ROBOTO_CHAR_COLS_LEN        8                 // number of columns for a chars (bits)
#define ROBOTO_CHARS_ROWS_LEN        2*8                 // number of rows for chars   (bits)
#define ROBOTO_CHAR_SIZE        16         //16 bytes according to the table

/******************************************************************************************
;Send single ROBOTO single char to display
;@INPUT: XX,YY,char
;		
;@USED: argument,Z,r20,r21,r0,r1,temp,axl
;STACK
******************************************************************************************/
ssd1306_send_char_roboto:
   ;position to XX and YY   
   call ssd1306_position_col_page 

   mov argument,char
   subi argument,32   //ASCI to row number in fonts table
   

   ;translate to bytes representation in fonts table
   ldi	ZH,high(roboto_mono_8x16*2)
   ldi	ZL,low(roboto_mono_8x16*2)

   ldi r20,ROBOTO_CHAR_SIZE	   //cols const in table each char is represented by 16 bytes
   mov r21,argument                    //row number variable
   MUL r20,r21
	  
   ADD16 ZL,ZH,r0,r1

   ldi temp,ROBOTO_CHAR_COLS_LEN   //loop throu 8 columns 
   mov r1,temp
roboto_ch_10:  
   tst r1
   breq roboto_ch_11

   lpm					;read next col from font 8x16
   mov	axl,r0	     
   rcall ssd1306_send_data   ;send to lcd

   adiw ZH:ZL,1         //move to next column
   dec r1
   rjmp roboto_ch_10

   ;go to second half
roboto_ch_11:
   inc YY
   call ssd1306_position_col_page
   
   mov argument,char
   subi argument,32   //calc row number in table
	     
   ;translate to bytes representation in fonts table
   ldi	ZH,high(roboto_mono_8x16*2)
   ldi	ZL,low(roboto_mono_8x16*2)

   ldi r20,ROBOTO_CHAR_SIZE	   //cols const in table each char is represented by 16 bytes
   mov r21,argument                    //row number variable
   MUL r20,r21
	  
   ADD16 ZL,ZH,r0,r1
   ;!!!!second half
   ADDI16 ZL,ZH,ROBOTO_CHAR_COLS_LEN

   ldi temp,ROBOTO_CHAR_COLS_LEN   //loop throu next lower 8 columns 
   mov r1,temp
roboto_ch_20:  
   tst r1
   breq roboto_ch_22

   lpm					;read next col from font 8x16
   mov	axl,r0	     
   rcall ssd1306_send_data  ;send to lcd

   adiw ZH:ZL,1         //move to next column
   dec r1
   rjmp roboto_ch_20

roboto_ch_22:   

ret

#define CHARS_COLS_LEN        6                 // number of columns for chars
#define CHARS_ROWS_LEN        8                 // number of rows for chars
#define CHAR_SIZE        8         //8 bytes according to the table
/******************************************************************************************
;Send single char to display
;@INPUT: argument
;		
;@USED: argument,Z,r20,r21,r0,r1,temp,axl
******************************************************************************************/
ssd1306_send_char:
   ;input char from ASCI table 
   subi argument,32   //calc row number

   ;translate to bytes representation in fonts table
   ldi	ZH,high(default_font*2)
   ldi	ZL,low(default_font*2)

   ldi r20,CHARS_COLS_LEN	   //cols const
   mov r21,argument             //row number variable
   MUL r20,r21
	  
   ADD16 ZL,ZH,r0,r1

   ldi temp,CHARS_COLS_LEN   //loop throu 6 columns 
   mov r1,temp
snd_ch_00:  
   tst r1
   breq snd_ch_01

   lpm					;read next col from font 8x6
   mov	axl,r0	     
   rcall ssd1306_send_data

   adiw ZH:ZL,1         //move to next column
   dec r1
   rjmp snd_ch_00

snd_ch_01:

ret

/******************************************************************************************
;Send buffer to oled
;@INPUT: 
;		
;@USED: X,Y,argument,temp,axl
******************************************************************************************/
ssd1306_send_buffer:
    ;set columns
	ldi axl,SSD1306_SET_COLUMN_ADDR
	rcall ssd1306_send_command
	ldi axl,0x00
	rcall ssd1306_send_command
	ldi axl,(SSD1306_COLS-1)
	rcall ssd1306_send_command
	  
	;set rows
	ldi axl,SSD1306_SET_PAGE_ADDR
	rcall ssd1306_send_command
	ldi axl,0x00
	rcall ssd1306_send_command
	ldi axl,(SSD1306_PAGES-1)
	rcall ssd1306_send_command

    ;transmit start condition
	rcall twi_start

	;transmit SLA+W
	ldi argument,(SSD1306_ADDRESS<<1)
	rcall twi_send_byte
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_ADR_ACK
	brne buffer_ext_00

    ;data continue
	ldi argument,SSD1306_DATA_CONTINUE
	rcall twi_send_byte
	;expect status ACK	
	lds temp,TWSR
	andi temp, 0xF8
    cpi temp, MTX_DATA_ACK
	brne buffer_ext_00

	;X counter - send 1024 bytes  128x8 
	ldi XL,low(GRAPHICS_BUFFER_SIZE)
	ldi XH,high(GRAPHICS_BUFFER_SIZE)

	;position buffer
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

buffer_loop_01:		
	
	ld argument,Y+	
	rcall twi_send_byte
	
	;expect status	
	lds temp,TWSR
	andi temp, 0xF8
	cpi temp, MTX_DATA_ACK
	brne buffer_ext_00
	
	SUBI16 XL,XH,1
	CPI16 XL,XH,temp,0
	brne buffer_loop_01 

buffer_ext_00:
    call twi_send_stop 
ret

/******************************************************************************************
;Send single ROBOTO font char to buffer
;Position 0=<X=<127 and 0=<Y=<63 and draw pixel into buffer
;@INPUT  XX 
;		 YY
;		 argument - default font charecter to draw
 
;@USED:  temp,char,Z,r20,r21,r0,r1,r6,r7,r8,r9,r10,r11
******************************************************************************************/
ssd1306_draw_buffer_char_roboto:
    ;test if outside of drawing area
	mov temp,XX				;test XX
	subi temp,-1*ROBOTO_CHAR_COLS_LEN
	cpi temp,(SSD1306_WIDTH)     
	brlo buf_char_roboto_yy
ret
buf_char_roboto_yy:        
	mov temp,YY				;test YY
	subi temp,-1*ROBOTO_CHARS_ROWS_LEN
	cpi temp,(SSD1306_HEIGHT)     
	brlo buf_char_roboto_ok
ret

buf_char_roboto_ok:
   subi argument,32
   
   ;translate to bytes representation in fonts table
   ldi	ZH,high(roboto_mono_8x16*2)
   ldi	ZL,low(roboto_mono_8x16*2)

   ldi r20,ROBOTO_CHAR_SIZE	   //cols const in table each char is represented by 16 bytes
   mov r21,argument             //row number variable
   mul r20,r21

   ADD16 ZL,ZH,r0,r1

   ldi temp, 2      //font roboto has 2 rows by 8 bits each or 16 bits height
   mov r6,temp

buf_next_half_char_roboto_00:
   tst r6				//are 2 halfs by 8 bits done?
   breq buf_next_half_char_roboto_end

   ldi temp,ROBOTO_CHAR_COLS_LEN   //loop throu 8 columns 
   mov r10,temp              //r10 counter 

   ;preserve XX
   mov r7,XX


   ;preserve YY
   mov r8,YY

buf_char_roboto_00: 
   tst r10
   breq buf_next_half_char_roboto_01   	

   lpm					;read next col from font 8x8
   mov	r11,r0	        ;r11 is char byte

   ldi temp,8				 //loop through 8 bits
   mov r9,temp               //r9 counter

   ;start from Y init pos for each new letter byte
   mov YY,r8

buf_8bit_roboto_loop:			; send bits one by one	
   tst r9
   breq buf_8bit_roboto_end

   ror r11
   brcs	black_out_roboto_00	
						//WHITE pixel
   clr temp
   mov char,temp
   rcall ssd1306_draw_buffer_pixel   ;input=X,Y,char   							
   rjmp black_end_roboto_00

black_out_roboto_00:			//BLACK pixel
   ser temp
   mov char,temp
   call ssd1306_draw_buffer_pixel	;input=X,Y,char

black_end_roboto_00:
   ;increment Y pos for next bit
   inc YY

   dec r9
   rjmp buf_8bit_roboto_loop

buf_8bit_roboto_end:
   adiw ZH:ZL,1         //move to next column
   dec r10
   inc XX
   rjmp buf_char_roboto_00

buf_next_half_char_roboto_01:
  dec r6    //next font half
  mov XX,r7
  //subi YY,-1*8

  rjmp buf_next_half_char_roboto_00

buf_next_half_char_roboto_end:


ret

/******************************************************************************************
;Send single default font char to buffer
;Position 0=<X=<127 and 0=<Y=<63 and draw pixel into buffer
;@INPUT  XX 
;		 YY
;		 argument - default font charecter to draw
 
;@USED:  temp,char,Z,r20,r21,r0,r1,r8,r9,r10,r11
******************************************************************************************/
ssd1306_draw_buffer_char:
    ;test if outside of drawing area
	mov temp,XX				;test XX
	subi temp,-1*CHARS_COLS_LEN
	cpi temp,(SSD1306_WIDTH)     
	brlo buf_char_yy
ret

buf_char_yy:        
	mov temp,YY				;test YY
	subi temp,-1*CHARS_ROWS_LEN
	cpi temp,(SSD1306_HEIGHT)     
	brlo buf_char_ok
ret

buf_char_ok:
	subi argument,32

   ;translate to bytes representation in fonts table
	ldi	ZH,high(default_font*2)
    ldi	ZL,low(default_font*2)

   ldi r20,CHARS_COLS_LEN	   //cols const
   mov r21,argument             //row number variable
   mul r20,r21

   ADD16 ZL,ZH,r0,r1

   ldi temp,CHARS_COLS_LEN   //loop throu 6 columns 
   mov r10,temp              //r10 counter 

   ;preserve YY
   mov r8,YY
buf_char_00:  
   tst r10
   breq buf_char_01

   lpm					;read next col from font 8x6
   mov	r11,r0	        ;r11 is char byte

   ldi temp,8				 //loop through 8 bits
   mov r9,temp               //r9 counter

   ;start from Y init pos for each new letter byte
   mov YY,r8

buf_8bit_loop:			; send bits one by one	
   tst r9
   breq buf_8bit_end

   ror r11
   brcs	black_out_00	
						//WHITE pixel
   clr temp
   mov char,temp
   rcall ssd1306_draw_buffer_pixel   ;input=X,Y,char   							
   rjmp black_end_00

black_out_00:			//BLACK pixel
   ser temp
   mov char,temp
   call ssd1306_draw_buffer_pixel	;input=X,Y,char

black_end_00:
   ;increment Y pos for next bit
   inc YY

   dec r9
   rjmp buf_8bit_loop

buf_8bit_end:

   adiw ZH:ZL,1         //move to next column
   dec r10
   inc XX
   rjmp buf_char_00

buf_char_01:


ret

/***************************Set pixel to BLACK***************************************************************
;Position 0=<X=<127 and 0=<Y=<63 and draw pixel into buffer
;@INPUT  XX 
;		 YY
;		 char - pixel color 0x00 BLACK(no light no pixel drawn) 0xFF WHITE
;@USED:  Y,axl,axh,temp,r0,r1,r15,r17,r18,argument
******************************************************************************************/
ssd1306_draw_buffer_pixel:
    
	;position buffer at 0
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)
	
	;(pos_x+((pos_y/8)*SSD1306_WIDTH))	
	mov dres8u,YY			;keep result in r16 and remainder in r15
	ldi dv8u,8				;devide by 8
    rcall div8u

    ;multiply by lcd width
	ldi axl,SSD1306_WIDTH
	mul axl,r16				;r16 comes from above
	;add it to pointer
	ADD16 YL,YH,r0,r1

	;add pos X to pointer
	clr axh
	ADD16 YL,YH,XX,axh

	//read byte from buffer
	ld argument,Y
	
	mov temp,r15    ;remainder number to byte mask conv
	clr r15
	inc r15         ;start from 1
drpxy_00:    
    tst temp
	breq drpxy_01
	lsl r15 
	dec temp
	rjmp drpxy_00

drpxy_01:
    tst char
	breq drpxy_white
						;WHITE pixel
    or argument,r15		;set bit to color in byte
	;save back in buffer
	st Y,argument


ret

drpxy_white:			
	                    ;BLACK pixel
    com r15						     
	and argument,r15
	;save back in buffer
	st Y,argument
ret

;***************************************************************************
;*
;* "div8u" - 8/8 Bit Unsigned Division
;*
;* This subroutine divides the two register variables "dd8u" (dividend) and
;* "dv8u" (divisor). The result is placed in "dres8u" and the remainder in
;* "drem8u".
;*
;* Number of words	:14
;* Number of cycles	:97
;* Low registers used	:1 (drem8u)
;* High registers used  :3 (dres8u/dd8u,dv8u,dcnt8u)
;*
;***************************************************************************


div8u:	
    sub	drem8u,drem8u	;clear remainder and carry
	ldi	dcnt8u,9	;init loop counter
d8u_1:	rol	dd8u		;shift left dividend
	dec	dcnt8u		;decrement counter
	brne	d8u_2		;if done
	ret			;    return
d8u_2:	rol	drem8u		;shift dividend into remainder
	sub	drem8u,dv8u	;remainder = remainder - divisor
	brcc	d8u_3		;if result negative
	add	drem8u,dv8u	;    restore remainder
	clc			;    clear carry to be shifted into result
	rjmp	d8u_1		;else
d8u_3:	sec			;    set carry to be shifted into result
	rjmp	d8u_1


.include "tasks/font.inc"
