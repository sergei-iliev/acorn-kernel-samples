/*
 * string.asm
 * Up to byte long size!!!!!!!!!!!!!
 */ 
 
 
 /*****************Convert string (3 chars max) to byte************************
 ;right aligned MSB|MidSB|LSB
 @INPUT:r10,r9,r8
 @USAGE: temp
 @OUTPUT: axl
 @WARNING: Does not handle illegal char digit
 */
_str_to_byte:
	clr axl
	mov temp,r10
	cpi temp,'0'
	brlo _STR_TO_BYTE_10
	subi temp,'0'
	mov r10,temp

_STR_TO_BYTE_10:
    mov temp,r9
	cpi temp,'0'
	brlo _STR_TO_BYTE_20
	subi temp,'0'
	mov r9,temp

_STR_TO_BYTE_20:
    mov temp,r8
	cpi temp,'0'
	brlo _STR_TO_BYTE_21
	subi temp,'0'
	mov r8,temp

_STR_TO_BYTE_21:
    
;now that all a digits accumulate result
    tst r10
	breq _STR_TO_BYTE_30
	ldi temp,100
    add axl,temp
	dec r10

    tst r10
	breq _STR_TO_BYTE_30
	;ldi temp,100
    add axl,temp
	dec r10
	    	 
_STR_TO_BYTE_30:   	
    tst r9
	breq _STR_TO_BYTE_40
	ldi temp,10
    add axl,temp
	dec r9
	rjmp _STR_TO_BYTE_30
   
_STR_TO_BYTE_40:
    tst r8
	breq _STR_TO_BYTE_EXIT
	
    add axl,r8
	
_STR_TO_BYTE_EXIT:
ret
/*
;>--------------------------------------------------------------<
	;| OBJECT     : _STRSTR						|
	;>--------------------------------------------------------------<
	;| FUNCTION   : STRSTR find substring in string(case sensitive) |
	;>--------------------------------------------------------------<
	@INPUT      : X as input string 1				|
		   	    : Y as input substring 				|
	@USAGE      : axl,axh as compare output				|
	@OUTPUT		    : T as match flag
	                : r15:r14 pointer to found substring in string
	@WARNING:	 T = 0 if substring is not found			|
			     1 if substrings found				|	
*/
_strstr:
    push XL
	push XH

    push YL
	push YH

	clt	
_STRSTR_10:
    ld	axh,X					;get char
	tst	axh					;end char '\0'
	breq	_STRSTR_END				;yes, exit

	ld axl,Y      ;find first character equality	

	mov r15,XH
	mov r14,XL

	adiw X,1

	cp	axh,axl				;found ?
	brne _STRSTR_10

	;revert to found
	sbiw X,1

	;all chars must be equal
_STRSTR_20:
    ld axl,Y+			;end of substring?
	tst axl              
	breq _STRSTR_SUCCESS

	ld	axh,X+					;get char
	tst	axh					;end char '\0'
	breq	_STRSTR_END				;yes, exit

	cp	axh,axl				;same again?
	breq _STRSTR_20        ;check next
	
	;reset  substring
	pop YH
	pop YL

	push YL
	push YH
	;revert X to first found char
	mov XH,r15
	mov XL,r14
	adiw X,1

	rjmp _STRSTR_10		;reset Y -> go on looking
_STRSTR_SUCCESS:
    set

_STRSTR_END:
    pop YH
	pop YL

    pop XH
	pop XL
ret

/*
;>--------------------------------------------------------------<
	;| OBJECT     : _STRFIND						|
	;>--------------------------------------------------------------<
	;| FUNCTION   : STRFND find substring in string(case sensitive) |
	;>--------------------------------------------------------------<
	@INPUT      : X as input string 1				|
		   	    : Y as input substring 				|
	@USAGE      : axl,axh as compare output				|
	@OUTPUT		    : T as match flag
	
	@WARNING:	 T = 0 if substring is not found			|
			     1 if substrings found				|	

_strfind:
    push XL
	push XH

    push YL
	push YH

	clt	
	
_STRFIND_10:
    ld	axh,X+					;get char
	tst	axh					;end char '\0'
	breq	_STRFIND_END				;yes, exit

	ld axl,Y      ;find first character equality	

	cp	axh,axl				;found ?
	brne _STRFIND_10

	adiw Y,1    ;point to next one

;all chars must be equal loop
_STRFIND_20:
	ld axl,Y+			;end of substring?
	tst axl
	breq _STRFIND_SUCCESS

    ld	axh,X+					;get char
	tst	axh					;end char '\0'
	breq	_STRFIND_END				;yes, exit

	cp	axh,axl				;found ?
	breq _STRFIND_20        ;check next

	;reset Y
	pop YH
	pop YL

	push YL
	push YH
	;revert X
	sbiw XH:XL,1

	rjmp _STRFIND_10		;reset Y -> go on looking

_STRFIND_SUCCESS:
    set

_STRFIND_END:
    pop YH
	pop YL

    pop XH
	pop XL
ret
*/
/*
;>--------------------------------------------------------------<
	;| OBJECT     : _STRCMP						|
	;>--------------------------------------------------------------<
	;| FUNCTION   : STRCMP Compare two strings considering the case |
	;>--------------------------------------------------------------<
	@INPUT      : X as input string 1				|
		   	    : Y as input string 2				|
	@USAGE      : temp,axl,axh as comare output				|
	@OUTPUT		    : T as match flag
	
	@WARNING:	 T = 0 if strings not match			|
			     1 if strings match				|	
*/
_strcmp:
    clt

_STRCMP_10:
	ld	axl,X+						;Load X to AccT
	ld  axh,Y+

	mov temp,axl
	sub	temp,axh					;Char match?
	brne _STRCMP_EXIT			;Yes, Jump

	tst	axl						;End of string 1
	brne	_STRCMP_10					;Yes jump
	
	set							;strings match!!!!
	rjmp	_STRCMP_EXIT


_STRCMP_EXIT:
ret

 /*
	;| OBJECT     : _STRLEN						|
	;>--------------------------------------------------------------<
	;| FUNCTION   : StrLen count the number of char on string for 	|
	;|		inform the length.				|
	;>--------------------------------------------------------------<
@INPUT:     X as input string				|
@USAGE:     Temp
@OUTPUT:	axl string length
*/

_strlen:
		
		clr axl		
	
_STRLEN_10:
		
		inc axl  
		ld	temp,X+						;Load X to Temp
		tst	temp						;End of string?
		brne	_STRLEN_10					;No, jump
		dec axl						;Yes, decrement diference and end
		
ret							

/*--------------------------------------------------------------<
	;| OBJECT     : _MEMSET						|
	;>--------------------------------------------------------------<
	;| FUNCTION   : _MEMSET Sets num of bytes in memory pointed 	|
	;|		with specified value.				|
	;>--------------------------------------------------------------<
@INPUT      : X --> memory block				|
 		    : axl  BYTE pattern to fill			|
		    : axh    number of bytes				|
*/

_memset:
		inc	axh					;Y++
_MEMSET_10:
		dec	axh					;Y-- last byte filled?
		breq	_MEMSET_20				;yes, branch
		st	X+,axl					;else fill new position.
		rjmp	_MEMSET_10				;again
_MEMSET_20:
				
ret

;*************************************************************************
;				Convert to dec string
;check for leading zeros and remove them using T flag in SREG
;@INPUT:argument
;@USAGE:temp,argument
;@OUTPUT:r10,r9,r8
;@STACK: 1 level
;*************************************************************************

byte_to_str:
    clr r10
	clr r9
	clr r8

	set   ;used to fascilitate leading ziro removal
	ldi temp, -1 + '0' 

str_ask1: 
	inc temp 
	subi argument, 100 
	brcc str_ask1
;write out first digit
	push argument
	mov argument,temp
;no need of leading ziro
	cpi argument,'0'
	breq str_ask11 
	mov r10,argument
	clt 

str_ask11:		 
	pop argument
	ldi temp, 10 + '0' 

str_ask2: 
	dec temp 
	subi argument, -10 
	brcs str_ask2
	sbci argument, -'0' 
;write out second digit
	push argument
	mov argument,temp           
;test for leading zero - if T is clear stop testing - it is not leading zero
	brtc str_ask222
	cpi argument,'0'		 
	breq str_ask22         

str_ask222:		 
	mov r9,argument

str_ask22:		 
	pop argument
;write out third digit
	mov r8,argument
ret  