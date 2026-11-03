
;1 DEVICES on TWI0
.include "tasks/ds1307_twi0.asm"

.dseg
ds1307_buf: .byte 6 ;store result in there before sending to usart
.cseg

ds1307_task:	

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	rcall ds1307_init

	;start oscillator (CH=0) and set 00:00:00 BCD
	ldi temp,0x10		
	mov r8,temp
	ldi temp,0x02		
	mov r9,temp
	ldi temp,0x03		
	mov r10,temp
	rcall ds1307_write_time

	
	ldi temp,0x17		; 17
	mov r8,temp
	ldi temp,0x03		; March
	mov r9,temp
	ldi temp,0x26		; 2026
	mov r10,temp
	rcall ds1307_write_date

ds1307_main:
	rcall ds1307_read_time
	brtc ds1307_next
	LDI16 ZL,ZH,ds1307_buf
	st Z+,r8		;seconds
	st Z+,r9		;minutes
	st Z+,r10		;hours

	rcall ds1307_read_date
	brtc ds1307_next
	st Z+,r8		;date
	st Z+,r9		;month
	st Z+,r10		;year

	;send to usart
	_LOCK usart_lock	;synchronize access to usart resource
	rcall ds1307_print
	_UNLOCK usart_lock

ds1307_next:
	_SLEEP_TASK_EXT 20000
rjmp ds1307_main




ds1307_print:
	LDI16 ZL,ZH,ds1307_buf
	ldi bxl,6
ds1307_print_byte:
	ld argument,Z+
	rcall usart0_send
	dec bxl
	brne ds1307_print_byte
ret
