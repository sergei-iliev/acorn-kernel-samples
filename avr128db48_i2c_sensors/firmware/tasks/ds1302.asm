/*
DS1302 3-wire real time clock. LSB first.
Delay calculated at 24MHz
PC1 is I/O,
PC2 is SCLK,
PC0 is RESET/CE.
SCLK idles low. 
CE is high only while a register is transferred.
Command = 0x80 | (address<<1) | R/W. Bit 0 = 1 reads.

0x00 seconds   bit 7 CH, 1 = oscillator stopped
0x01 minutes
0x02 hours     bit 7 = 1 selects 12-hour mode
0x03 date
0x04 month
0x05 day
0x06 year
0x07 control   bit 7 WP, 1 = writes ignored
0x08 trickle   left disabled (0x00). A primary cell must stay at 0x00.
*/

.equ DS1302_CE_bp = 0			;PC0 RESET
.equ DS1302_IO_bp = 1			;PC1 I/O
.equ DS1302_CLK_bp = 2			;PC2 SCLK
.equ DS1302_IO_bm = (1<<DS1302_IO_bp)
.equ DS1302_CLK_bm = (1<<DS1302_CLK_bp)
.equ DS1302_CE_bm = (1<<DS1302_CE_bp)

.equ DS1302_SEC_REG = 0x00
.equ DS1302_MIN_REG = 0x01
.equ DS1302_HOUR_REG = 0x02
.equ DS1302_DATE_REG = 0x03
.equ DS1302_MONTH_REG = 0x04
.equ DS1302_DAY_REG = 0x05
.equ DS1302_YEAR_REG = 0x06
.equ DS1302_WP_REG = 0x07
.equ DS1302_TCS_REG = 0x08

.equ DS1302_CH_bp = 7
.equ DS1302_PAUSE_N = 14		;~2 us at 24 MHz

/***************************init DS1302************************
I/O input with pull-up, SCLK and CE outputs held low.
Clears write protect. Clears CH when the oscillator is stopped.
@INPUT: none
@USAGE: argument, temp, axl
**************************************************************/
ds1302_init:
	ldi temp,DS1302_CE_bm
	sts PORTC_OUTCLR,temp
	sts PORTC_DIRSET,temp

	ldi temp,DS1302_CLK_bm
	sts PORTC_OUTCLR,temp
	sts PORTC_DIRSET,temp

	ldi temp,DS1302_IO_bm
	sts PORTC_DIRCLR,temp
	ldi temp,PORT_PULLUPEN_bm
	sts PORTC_PIN1CTRL,temp

	rcall ds1302_wp_off

	ldi argument,DS1302_SEC_REG
	rcall ds1302_read_reg
	sbrs axl,DS1302_CH_bp
	rjmp ds1302_init_ok
	andi axl,0x7F
	ldi argument,DS1302_SEC_REG
	rcall ds1302_write_at
ds1302_init_ok:
ret

/***************************CE high***********************************
@USAGE: temp
**************************************************************/
ds1302_reset_on:
	ldi temp,DS1302_CE_bm
	sts PORTC_OUTSET,temp
ret

/***************************CE low************************************
@USAGE: temp
**************************************************************/
ds1302_reset_off:
	ldi temp,DS1302_CE_bm
	sts PORTC_OUTCLR,temp
ret

/***************************clear write protect************************
@USAGE: argument, temp, axl
**************************************************************/
ds1302_wp_off:
	ldi argument,DS1302_WP_REG
	clr axl
	rcall ds1302_write_at
ret

/***************************read one register************************
@INPUT: argument - register address
@USAGE: argument, temp, axl
@OUTPUT: axl - value
**************************************************************/
ds1302_read_reg:
	lsl argument
	ori argument,0x81
	rcall ds1302_begin
	rcall ds1302_write_byte
	rcall ds1302_read_byte
	rcall ds1302_end
ret

/***************************write one register************************
Clears write protect first, except when the target is the WP register.
@INPUT: argument - register address
        axl - value
@USAGE: argument, temp, axl
**************************************************************/
ds1302_write_reg:
	cpi argument,DS1302_WP_REG
	breq ds1302_write_at
	push argument
	push axl
	rcall ds1302_wp_off
	pop axl
	pop argument
	rjmp ds1302_write_at

/***************************write one register, WP unchanged**********
@INPUT: argument - register address
        axl - value
@USAGE: argument, temp, axl
**************************************************************/
ds1302_write_at:
	push axl
	lsl argument
	ori argument,0x80
	rcall ds1302_begin
	rcall ds1302_write_byte
	pop argument
	rcall ds1302_write_byte
	rcall ds1302_end
ret

/***************************read DS1302 time************************
@INPUT: none
@USAGE: argument, temp, axl
@OUTPUT: r8  - seconds (BCD, bit 7 = CH)
         r9  - minutes (BCD)
         r10 - hours (BCD)
**************************************************************/
ds1302_read_time:
	ldi argument,DS1302_SEC_REG
	rcall ds1302_read_reg
	mov r8,axl

	ldi argument,DS1302_MIN_REG
	rcall ds1302_read_reg
	mov r9,axl

	ldi argument,DS1302_HOUR_REG
	rcall ds1302_read_reg
	mov r10,axl
ret

/***************************write DS1302 time************************
Write protect is cleared. CH is cleared so the oscillator runs.
Hour bit 7 is cleared so the chip is in 24-hour mode before the
rest of the time is written.
@INPUT: r8  - seconds (BCD)
        r9  - minutes (BCD)
        r10 - hours (BCD, 00-23)
@USAGE: argument, temp, axl
**************************************************************/
ds1302_write_time:
	rcall ds1302_wp_off

	mov axl,r10
	andi axl,0x7F
	ldi argument,DS1302_HOUR_REG
	rcall ds1302_write_at

	mov axl,r9
	ldi argument,DS1302_MIN_REG
	rcall ds1302_write_at

	mov axl,r8
	andi axl,0x7F
	ldi argument,DS1302_SEC_REG
	rcall ds1302_write_at
ret

/***************************read DS1302 calendar************************
@INPUT: none
@USAGE: argument, temp, axl
@OUTPUT: r8  - date (BCD, 01-31)
         r9  - month (BCD, 01-12)
         r10 - day (BCD, 01-07)
         r11 - year (BCD, 00-99)
**************************************************************/
ds1302_read_calendar:
	ldi argument,DS1302_DATE_REG
	rcall ds1302_read_reg
	mov r8,axl

	ldi argument,DS1302_MONTH_REG
	rcall ds1302_read_reg
	mov r9,axl

	ldi argument,DS1302_DAY_REG
	rcall ds1302_read_reg
	mov r10,axl

	ldi argument,DS1302_YEAR_REG
	rcall ds1302_read_reg
	mov r11,axl
ret

/***************************write DS1302 calendar************************
Write protect is cleared.
@INPUT: r8  - date (BCD, 01-31)
        r9  - month (BCD, 01-12)
        r10 - day (BCD, 01-07)
        r11 - year (BCD, 00-99)
@USAGE: argument, temp, axl
**************************************************************/
ds1302_write_calendar:
	rcall ds1302_wp_off

	mov axl,r8
	ldi argument,DS1302_DATE_REG
	rcall ds1302_write_at

	mov axl,r9
	ldi argument,DS1302_MONTH_REG
	rcall ds1302_write_at

	mov axl,r10
	ldi argument,DS1302_DAY_REG
	rcall ds1302_write_at

	mov axl,r11
	ldi argument,DS1302_YEAR_REG
	rcall ds1302_write_at
ret

/***************************CE high, SCLK low************************
@USAGE: temp
**************************************************************/
ds1302_begin:
	ldi temp,DS1302_CLK_bm
	sts PORTC_OUTCLR,temp
	ldi temp,DS1302_CE_bm
	sts PORTC_OUTSET,temp
	rcall ds1302_pause
	rcall ds1302_pause
ret

/***************************CE low, release I/O************************
@USAGE: temp
**************************************************************/
ds1302_end:
	rcall ds1302_pause
	ldi temp,DS1302_CE_bm
	sts PORTC_OUTCLR,temp
	ldi temp,DS1302_IO_bm
	sts PORTC_DIRCLR,temp
	rcall ds1302_pause
	rcall ds1302_pause
ret

/***************************shift out one byte************************
LSB first. The bit is set up, then SCLK rises and latches it.
@INPUT: argument - byte
@USAGE: argument, temp, axl
**************************************************************/
ds1302_write_byte:
	ldi temp,DS1302_IO_bm
	sts PORTC_DIRSET,temp	;set direction
	ldi axl,8
ds1302_wb0:
	lsr argument
	ldi temp,DS1302_IO_bm
	brcs ds1302_wb1
	sts PORTC_OUTCLR,temp
	rjmp ds1302_wb2
ds1302_wb1:
	sts PORTC_OUTSET,temp
ds1302_wb2:
	rcall ds1302_pause
	ldi temp,DS1302_CLK_bm
	sts PORTC_OUTSET,temp
	rcall ds1302_pause
	ldi temp,DS1302_CLK_bm
	sts PORTC_OUTCLR,temp
	dec axl
	brne ds1302_wb0
ret

/***************************shift in one byte************************
The chip drives bit 0 after the last command clock falls.
@USAGE: argument, temp, axl
@OUTPUT: axl - byte
**************************************************************/
ds1302_read_byte:
	ldi temp,DS1302_IO_bm
	sts PORTC_DIRCLR,temp
	rcall ds1302_pause
	clr argument
	ldi axl,8
ds1302_rb0:
	lds temp,PORTC_IN
	lsr argument
	sbrc temp,DS1302_IO_bp
	ori argument,0x80
	ldi temp,DS1302_CLK_bm
	sts PORTC_OUTSET,temp
	rcall ds1302_pause
	ldi temp,DS1302_CLK_bm
	sts PORTC_OUTCLR,temp
	rcall ds1302_pause
	dec axl
	brne ds1302_rb0
	mov axl,argument
ret

/***************************~2 us at 24 MHz************************
@USAGE: temp
**************************************************************/
ds1302_pause:
	ldi temp,DS1302_PAUSE_N
ds1302_pause_l:
	dec temp
	brne ds1302_pause_l
ret
