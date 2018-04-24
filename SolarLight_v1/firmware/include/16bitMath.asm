;*********************16bit Arithmetic*********************************


;***************************************************************************
;*
;* "add16" - Adding 16-bit registers
;*
;* INPUT:	axl,axh,bxl,bxh 
;* OUTPUT:	axl,axh
;* 
;* Low registers used :None
;* High registers used :4
;*
;* Note: The sum and the addend share the same register.  This causes the
;* addend to be overwritten by the sum.
;*
;***************************************************************************

;**** Register Variables
;.def axl = r16
;.def axh = r17
;.def bxl = r18
;.def bxh = r19

/*
add16: 
	add axl, bxl ;Add low bytes
	adc axh, bxh ;Add high bytes with carry
ret
*/


;***************************************************************************
;*
;* "cp16" - Comparing two 16-bit numbers
;*
;* This example compares the register pairs (axl,axh) with the register
;* pairs (bxl,bxh)  If they are equal the zero flag is set(one)
;* otherwise it is cleared(zero)
;*
;* INPUT:	axl,axh,bxl,bxh 
;* OUTPUT:	axl,axh
;*	
;* Low registers used :None
;* High registers used :4
;*
;* Note: The contents of "ax" will be overwritten.
;*
;***************************************************************************


cp16:
	cp axl,bxl;Compare low byte
	cpc axh,bxh;Compare high byte with carry from previous operation
ret
;Expected result is Z=0


;***************************************************************************
;*
;* "neg16" - Negating 16-bit register
;*
;* This example negates the register pair (axl,axh)  The result will
;* overwrite the register pair.
;*
;* Number of words :4
;* Number of cycles :4
;* Low registers used :None
;* High registers used :2
;*
;***************************************************************************


;***** Code
ng16:
	com axl ;Invert low byte;Calculated by
	com axh ;Invert high byte;incverting all
	subi axl,low(-1);Add 0x0001, low byte;bits then adding
	sbci axh,high(-1);Add high byte ;one (0x0001)
ret
;Expected result is 0xCBEE



;***************************************************************************
;*
;* "addS16" - Signed 16-bit
;* INPUT: axl,axh,bxl,bxh
;* OUTPUT: axl,axh 
;* addition of 2 signed 16 bit with overflow protection
;* add into 24 bit then test
;*
;* result:= Z^, S16:=Y^, Z^:=Z^+Y^  16 bit as little endian
;*
;* there is no overflow bigger than 0x7FFF or smaller 0x8000
;*
;***************************************************************************

addSigned16:
	tst axh 
	brpl	as16_1
; neg Z
	tst	bxh
	brpl	as16_2
; neg + neg
	add	axl,bxl
	adc	axh,bxh
	brmi	as16_end
; neg + neg overflow
	ldi	axl,0x00
	ldi	axh,0x80
; ok
	rjmp	as16_end
; neg + pos
as16_2: 
	add	axl,bxl
	adc	axh,bxh
	rjmp	as16_end
; pos + neg
as16_3:
	add	axl,bxl
	adc	axh,bxh
	rjmp	as16_end
; pos Z
as16_1:
	tst	bxh
	brmi	as16_3
; pos + pos
	add	axl,bxl
	adc	axh,bxh
	brpl	as16_end
; pos + pos overflow
	ldi	axl,0xFF
	ldi	axh,0x7F
as16_end:
	ret

;***************************************************************************
;*
;* "div16s" - 16/16 Bit Signed Division
;*
;* This subroutine divides signed the two 16 bit numbers 
;* "axh:axl" (dividend) and "bxh:bxl" (divisor). 
;* The result is placed in "cxh:cxl" and the remainder in
;* "dxh:dxl".
;*  
;* Number of words	:39
;* Number of cycles	:247/263 (Min/Max)
;* Low registers used	:3 (d16s,drem16sL,drem16sH)
;* High registers used  :7 (dres16sL/dd16sL,dres16sH/dd16sH,dv16sL,dv16sH,
;*			    dcnt16sH)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	d16s	=r13		;sign register
.def	dxl=r14;drem16sL=r14		;remainder low byte		
.def	dxh=r15;drem16sH=r15		;remainder high byte
.def	cxl=r22;dres16sL=r16		;result low byte
.def	cxh=r23;dres16sH=r17		;result high byte
.def	axl=r22;dd16sL	=r16		;dividend low byte
.def	axh=r23;dd16sH	=r17		;dividend high byte
.def	bxl=r24;dv16sL	=r18		;divisor low byte
.def	bxh=r25;dv16sH	=r19		;divisor high byte
.def	counter=r20;dcnt16s	=r20		;loop counter

;***** Code

divSigned16:	
    mov	d16s,axh	;move dividend High to sign register
	eor	d16s,bxh	;xor divisor High with sign register
	sbrs	axh,7	;if MSB in dividend set
	rjmp	d16s_1
	com	axh		;    change sign of dividend
	com	axl		
	subi	axl,low(-1)
	sbci	axl,high(-1)
d16s_1:	
    sbrs	bxh,7	;if MSB in divisor set
	rjmp	d16s_2
	com	bxh		;    change sign of divisor
	com	bxl		
	subi	bxl,low(-1)
	sbci	bxh,high(-1)
d16s_2:	
    clr	dxl	;clear remainder Low byte
	sub	dxh,dxh;clear remainder High byte and carry
	ldi	counter,17	;init loop counter

d16s_3:	
    rol	axl		;shift left dividend
	rol	axh
	dec	counter		;decrement counter
	brne	d16s_5		;if done
	sbrs	d16s,7		;    if MSB in sign register set
	rjmp	d16s_4
	com	cxh	;        change sign of result
	com	cxl
	subi	cxl,low(-1)
	sbci	cxh,high(-1)
d16s_4:	
    ret			;    return
d16s_5:
 	rol	dxl	;shift dividend into remainder
	rol	dxh
	sub	dxl,bxl	;remainder = remainder - divisor
	sbc	dxh,bxh	;
	brcc	d16s_6		;if result negative
	add	dxl,bxl	;    restore remainder
	adc	dxh,bxh
	clc			;    clear carry to be shifted into result
	rjmp	d16s_3		;else
d16s_6:	
    sec			;    set carry to be shifted into result
	rjmp	d16s_3


