
/****************************************************
@INPUT:  X - address in EEPROM
         argument - data to write
****************************************************/
EEPROM_write:
;wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write

	out EEARH,XH
	out EEARL,XL

	;write data
	out EEDR,argument
	
	; Write logical one to EEMPE
    sbi EECR,EEMPE
    ; Start eeprom write by setting EEPE
    sbi EECR,EEPE
ret

/****************************************************
@INPUT:  X - address in EEPROM
@OUTPUT: argument - data  
****************************************************/
EEPROM_read:
	sbic	EECR,EEPE			;wait last write operation is done
	rjmp	EEPROM_read			;wait
	
	out EEARH,XH
	out EEARL,XL	

	; Start eeprom read by writing EERE
	sbi EECR,EERE
	; Read data from Data Register
	in argument,EEDR
ret

/******************Write Data from RAM to EEPROM**********************************
@INPUT:  X - init address in EEPROM
         Y - init address in RAM
		 axl - size of input RAM buffer
@USAGE  temp
        counter
		argument - data to write
****************************************************/
EEPROM_write_buffer:
    clr counter            ;counter

    tst axl
	breq ee_wt_buf_02   ;nothing to copy

ee_wt_buf_01:

	ld argument,Y
	rcall  EEPROM_write
		  
	inc counter
	cp counter,axl
	breq ee_wt_buf_02
	
	adiw Y,1
	adiw X,1

	rjmp ee_wt_buf_01


ee_wt_buf_02:

ret

/**************Read Data from EEPROM to RAM**************************************
@INPUT:  X - init address in EEPROM
         Y - init address in RAM
		 axl - size of input RAM buffer
@USAGE  temp
        counter
		argument - data to write
****************************************************/
EEPROM_read_buffer:
    clr counter            ;counter

    tst axl
	breq ee_rd_buf_02   ;nothing to copy

ee_rd_buf_01:
	
	rcall  EEPROM_read
	st Y,argument		  
	
	inc counter
	cp counter,axl
	breq ee_rd_buf_02
	
	adiw Y,1
	adiw X,1

	rjmp ee_rd_buf_01


ee_rd_buf_02:

ret