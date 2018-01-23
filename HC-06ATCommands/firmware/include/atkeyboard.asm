/*
 * AT keyboard task driver
 *
 */ 

#define PIN_KB  PIND
#define PORT_KB PORTD
#define CLOCKPIN   2         ;PORT2 INT0
#define DATAPIN 7			 ;PORT7	



#define INITIAL_BITCOUNT 11
#define PARITY_BITCOUNT  3

.dseg
kb_buffer:	.byte KB_BUFF_SIZE
kb_buffcnt: .byte 1

bitcount:	.byte 1
scancode:   .byte 1       ;accumulates scan code data
FlagReg:    .byte 1
result:     .byte 1
.cseg

.equ	NewScanCode	=  0
.equ	ShiftFlag	=  1
.equ	BreakFlag	=  2
.equ	AltFlag	=  3
.equ	ControlFlag	=  4
.equ	E0Flag		=  5


.def	WorkReg		= r19


/************************************************
;Hardware and context dependent
;@INPUT 0-> temp reg
************************************************/
_START_TIMEOUT_WATCH:
	in temp,TCCR1B
	sbr temp,(1<<CS12)     ;1/256
	out TCCR1B,temp

	ldi temp,0xA0		 ;about	2 sec at 11MHz
	out TCNT1H,temp
	clr temp
	out TCNT1L,temp
;start
	in temp,TIMSK
	sbr temp,(1<<TOIE1)
	out TIMSK,temp
ret
/************************************************
;Hardware and context dependent
;@INPUT 0-> temp reg
************************************************/
_STOP_TIMEOUT_WATCH:
    in temp,TCCR1B
	cbr temp,(1<<CS12)     ;1/64
	out TCCR1B,temp

	in temp,TIMSK
	cbr temp,(1<<TOIE1)
	out TIMSK,temp
ret 



Keyboard_Task:

  sbi DDRB,PORTB2
  sbi PORTB,PORTB2

 //register Keyboard interrupt DPC
.SET KeyboardIntInd=7
 _INTERRUPT_DISPATCHER_INIT temp,KeyboardIntInd	 

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
 	
	;wait 3 secs until keyboard inits itself
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250
	_SLEEP_TASK 250

	rcall init_kb
main5:
   
   	_INTERRUPT_WAIT	KeyboardIntInd
	 ;don't call if TIMEOUT timer is on
	 in temp,TIMSK
	 sbrc temp,TOIE1
	 rjmp kb_int_end

	 lds argument,result
	 tst argument
	 breq	kb_int_end	; if DecodeValue <> 0, then put DecodeValue out 
	 ;@Input=argument
	 rcall add_buffer_kb

	 _EVENT_SET LCD_UPDATE_EVENT,TASK_CONTEXT
	 
	 ;is this ENTER
	 lds argument,result
	 cpi argument,0x0D
	 brne kb_int_end 
	 

	 ;prepare transmission input buffer
	 rcall reset_input_buffer

	 rcall reset_output_buffer

	 ;move kb buffer to rs232 output
	 rcall prepare_output_buffer
	 
	 _EVENT_SET RS232_READY_EVENT,TASK_CONTEXT
	 	 

    cbi PORTB,PORTB2
    rcall _START_TIMEOUT_WATCH

kb_int_end:	
	
	_INTERRUPT_END KeyboardIntInd  

rjmp main5
ret

/*
Initialize keyboard driver.
*/
init_kb:

	ldi	temp,  (1<<INT0)
	out	GIFR, temp	; clear INT0 interrupt flag
	out	GIMSK,temp	;  enable external INT0
	ldi	temp,(1<<ISC01) ; setup INT0 interrupt on falling edge
	out	MCUCR, temp

    ldi	temp,INITIAL_BITCOUNT ; = 11
	sts bitcount,temp			// 0 = neg.  1 = pos.
ret

//-------------------------------------------------------------------
// Stuff a decoded byte into the keyboard buffer.
//@INPUT:argument
//-------------------------------------------------------------------
add_buffer_kb:
	cpi argument,0x0D   ;is this ENTER
	brne abk00
	ret
abk00:
	cpi argument,0x08   ;is this backspace
	brne abk0
	lds return,kb_buffcnt ;at begining?
	tst return
	breq abk2
	dec return
	sts kb_buffcnt,return
	
	;save BACKSPACE character
    ldi	ZH,high(kb_buffer)
    ldi	ZL,low(kb_buffer)
	clr temp
	ADD16 ZL,ZH,return,temp	
    ldi argument,' '
	st Z,argument
    ret
abk0:
	lds return,kb_buffcnt   ;is buffer full
	cpi return,KB_BUFF_SIZE
	brne abk1 
	ret

abk1:
    lds return,kb_buffcnt

    ;save character
    ldi	ZH,high(kb_buffer)
    ldi	ZL,low(kb_buffer)
	clr temp
	ADD16 ZL,ZH,return,temp	    
	st Z,argument
	
	;save next free byte
	inc return
	sts kb_buffcnt,return
		
abk2:
ret

/***********************Resolve char by scan code*****************
*@INPUT:argument,FlagReg
*@USED:temp,Z,R0,WorkReg
*@OUTPUT:return,FlagReg 
*/
decode_kb:
        lds WorkReg,FlagReg
		
		;check for initial BAT sequence
		cpi argument,0xAA
		brne DecodeStart
        rjmp setZero

DecodeStart:
   ;Check for the one key on the PS2 keyboard (Function 7) whose scancode is outside of the table range 00-7f.
		cpi	argument, $83
		brne	InRange
		rjmp	setZero  ; function keys are ignored in this program

;   first check that Break flag is clear. if yes, then keypress down received
InRange:
		sbrc	WorkReg, BreakFlag   ; the previous scancode was $f0 when break_flag is set => key released
		rjmp	Break_set

		;  Break is clear, so do check the special conditions: F0, 12, 14, 59, 58, E0,
		cpi	argument,$f0  ; 	$F0 =Breakcode key-release identifier
		brne	ChkShift
		sbr	WorkReg, (1<<BreakFlag)  ; set Break flag  so that the next scancode will not be seen a keypress down
		rjmp	setZero
ChkShift:
		sbrc	WorkReg, ShiftFlag   ; the shift key is being held down and another key was just pressed
		rjmp	Shift_set
		sbrc	WorkReg, ControlFlag   ; the control key is being held down and another key was just pressed
		rjmp	Control_set

notF0:
		cpi	argument,$12  ; 12 =Left Shift
		brne	notLS
		sbr	WorkReg, (1<<ShiftFlag)
		rjmp	setZero

notLS:	
		cpi	argument,$59  ; Right Shift
		brne	notRS
		sbr	WorkReg, (1<<ShiftFlag)
		rjmp	setZero

notRS:
		cpi	argument, $11 ; left Alt key is being pressed down. Alt_flag gets set.
		brne	notSft
		sbr	WorkReg, (1<<AltFlag)
		rjmp	setZero

notSft:
		cpi	argument,$14  ; Right Control
		brne	isCapsLock
		sbr	WorkReg, (1<<ControlFlag)
		rjmp	setZero

isCapsLock:	; CapsLock key pressed
		cpi	argument, $58  ; caps lock key
		brne	isExtendedCode
		rjmp 	setZero

isExtendedCode: ; check for E0 flag
		cpi	argument,$e0  ;  $e0  extended char table
		brne	isE0set  ; scancode is not one of the special cases
		sbr	WorkReg,(1<<E0Flag) ; set E0 flag
		rjmp	setZero

isE0set: ; if the E0_flag is set then E0 (extended char scancode) was the last previously sent
		sbrc	WorkReg,E0Flag 	; test extended char flag
		rjmp	get_E0char	; determine the action to take for the extended keypress

;not shift, $E0, or $F0, and no flags are set;  so do a table lookup
TableLookUp:
		ldi	ZL, low(2 * ScanTable)
		ldi	ZH, high(2 * ScanTable)
		add	ZL, argument
		brcc	TL0
		inc	ZH
TL0:		
        lpm
		tst	R0
		brmi	setZero
		;success
		mov return,R0
		rjmp 	exit_decode

Shift_set:
		ldi	ZL, low(2 * ShiftTable)  ; do a table lookup from the ShiftTable
		ldi	ZH, high(2 * ShiftTable)
		add	ZL, argument
		brcc	TL1
		inc	ZH
TL1:		
		lpm
		tst	R0
		brmi	setZero

		;success
		mov return,R0
		rjmp 	exit_decode

Control_set:
		ldi	ZL, low(2 * ScanTable)  ; Control key is held while another key pressed.  Assume the 2nd key is alphabetical
		ldi	ZH, high(2 * ScanTable) ; Find the ASCII and subtract 0x60
		add	ZL, argument
		brcc	TL2
		inc	ZH
TL2:		
		lpm
		tst	R0
		brmi	setZero
		mov	temp, R0
		subi	temp, $60   ;  'b' = 0x62 in ASCII --  Control-B = 0x02 in ASCII
		mov	return, temp
		rjmp 	exit_decode

;  Break flag is set - this means the previous scancode was $f0 (a key release)
;   This scancode is either the Extended sentinel ($e0) or the number of the key being released.
Break_set:	
        cbr	WorkReg,(1<<BreakFlag) ; clear Break flag
		cpi	argument, $11	; left Alt flag is released
		brne	isShift
		cbr	WorkReg, (1<<AltFlag)
		rjmp	setZero

isShift:
		cpi	argument, $12
		brne	isSh0
		cbr	WorkReg, (1<<ShiftFlag)
		rjmp	setZero
isSh0:
		cpi	argument, $59
		brne	isCntrl
		cbr	WorkReg, (1<<ShiftFlag)
		rjmp	setZero

isCntrl:
		cpi	argument, $14
		brne	isE0
		cbr	WorkReg, (1<<ControlFlag)
		rjmp	setZero

; If scancode is E0, then set the Break flag so that the next scancode is recognized
; as the last of an extended release sequence instead of a normal keypress down.
isE0:		
        cpi	argument, $e0	; extended key press sentinel
		brne	isE0flagOn
		sbr	WorkReg,(1<<BreakFlag)
		sbr	WorkReg,(1<<E0Flag) ; set extended flag
		rjmp	setZero

; if the E0flag is on then this scancode is the extended character number that is being released.  Just clear flags.
isE0flagOn:	
        sbrs	WorkReg, E0Flag   ; Extended flag on?
		rjmp	ReleaseKey  ;no, a non-extended key is being released.
		cbr	WorkReg,(1<<BreakFlag) ; yes, clear Break flag
		cbr	WorkReg,(1<<E0Flag) ; clear extended flag
		cpi	argument, $14 ; Right Control key
		brne	chkRAltUp
		cbr	WorkReg,(1<<ControlFlag) ; clear control flag
		rjmp	setZero

chkRAltUp:
		cpi	argument, $11 ; Right Alt key
		brne	setZero
		cbr	WorkReg,(1<<AltFlag) ; Right Alt key released
		rjmp	setZero

ReleaseKey:  	
		cbr	WorkReg,(1<<BreakFlag) ; yes, clear Break flag
		

setZero:  	
        clr	return	; When Decode sub returns zero in DecodeValue reg, the main program ignores the scancode.
exit_decode: 	
		sts FlagReg,WorkReg
		ret

;  the previous scancode was E0, and no extended keys are handled by the Tiny11 code.
get_E0char:	
		cbr	WorkReg,(1<<E0Flag)  ; clear the E0 flag
		rjmp	setZero ; change to RET if using this function with an AVR with a stack


int0INT:
_PRE_INTERRUPT
		lds temp,bitcount
		cpi 	temp,INITIAL_BITCOUNT ; falling edge FIRST pulse from kbd -start bit so do nothing
		breq	ir_kb_scan
		cpi	temp,PARITY_BITCOUNT ; = 3  ; test for parity bit and stop bit
		brlo	ir_kb_scan  			;  must use bitcount 3 for compare because branch tests only for lower
		
			//read next bit
	    push return						//arbitrary context
	    lds return,scancode

	    lsr	return   			;  shift data right one bit - data bit 7 gets 0
	    sbic PIN_KB,DATAPIN  		;  set scancode bit if keyboard data bit is set
	    ori	return,$80 		;  if data from kbrd is 1, then set bit 7 only and let other bits unchanged

	
	    //save data
	    sts scancode,return
	    pop return


ir_kb_scan:
		dec temp
	    sts bitcount,temp
	    cpi temp,0		        ;all bits recieved?		
		brne	ir_kb_end			;  All bits received?		

		ldi temp,INITIAL_BITCOUNT	;reset count
	    sts bitcount,temp

		;keep vars	
		
		push argument
	    push WorkReg
	    push ZL
 	    push ZH
	    push r0
	    push temp
	    push return
	
	   lds argument,scancode
	
	   rcall decode_kb
	
	   sts result,return

	   pop return
	   pop temp
	   pop r0
	   pop ZH
	   pop ZL
	   pop WorkReg
	   pop argument
	   
	
	_keDISPATCH_DPC KeyboardIntInd  ;dispatch to dpc
ir_kb_end:    

_POST_INTERRUPT
reti


TimerOVF1:	
   _PRE_INTERRUPT
   sbi PORTB,PORTB2
   rcall _STOP_TIMEOUT_WATCH
   _POST_INTERRUPT
reti

ScanTable:  ; ASCII values that correspond to the PC keyboard's transmitted scancode
;    0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
.db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$09,$60,$ff ; 00-0f
.db $ff,$ff,$ff,$ff,$ff,$71,$31,$ff,$ff,$ff,$7a,$73,$61,$77,$32,$ff ; 10-1f
.db $ff,$63,$78,$64,$65,$34,$33,$ff,$ff,$20,$76,$66,$74,$72,$35,$ff ; 20-2f
.db $ff,$6e,$62,$68,$67,$79,$36,$ff,$ff,$ff,$6d,$6a,$75,$37,$38,$ff ; 30-3f
.db $ff,$2c,$6b,$69,$6f,$30,$39,$ff,$ff,$2e,$2f,$6c,$3b,$70,$2d,$ff ; 40-4f
.db $ff,$ff,$27,$ff,$5b,$3d,$ff,$ff,$ff,$ff,$0d,$5d,$ff,$ff,$ff,$ff ; 50-5f
.db $ff,$ff,$ff,$ff,$ff,$ff,$08,$ff,$ff,$31,$ff,$34,$37,$ff,$ff,$ff ; 60-6f
.db $30,$ff,$32,$35,$36,$38,$1b,$ff,$ff,$ff,$33,$ff,$ff,$39,$ff,$ff ; 70-7f

ShiftTable:     ; ASCII values that correspond to the PC keyboard's transmitted scancode when shift key held down
;    0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
.db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$09,$7e,$ff ; 00-0f
.db $ff,$ff,$ff,$ff,$ff,$51,$21,$ff,$ff,$ff,$5a,$53,$41,$57,$40,$ff ; 10-1f
.db $ff,$43,$58,$44,$45,$24,$23,$ff,$ff,$20,$56,$46,$54,$52,$25,$ff ; 20-2f
.db $ff,$4e,$42,$48,$47,$59,$5e,$ff,$ff,$ff,$4d,$4a,$55,$26,$2a,$ff ; 30-3f
.db $ff,$3c,$4b,$49,$4f,$29,$28,$ff,$ff,$3e,$3f,$4c,$3a,$50,$5f,$ff ; 40-4f
.db $ff,$ff,$22,$ff,$7b,$2b,$ff,$ff,$ff,$ff,$0d,$7d,$ff,$7c,$ff,$ff ; 50-5f
.db $ff,$ff,$ff,$ff,$ff,$ff,$08,$ff,$ff,$31,$ff,$34,$37,$ff,$ff,$ff ; 60-6f
.db $30,$ff,$32,$35,$36,$38,$1b,$ff,$ff,$ff,$33,$ff,$ff,$39,$ff,$ff ; 70-7f