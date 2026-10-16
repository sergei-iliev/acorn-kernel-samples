
.include "tasks/ds1302.asm"

ds1302_task:
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

	rcall ds1302_reset_on
	rcall ds1302_init

	;18:30:00, 24-hour, BCD
	ldi temp,0x00
	mov r8,temp
	ldi temp,0x30
	mov r9,temp
	ldi temp,0x17
	mov r10,temp
	rcall ds1302_write_time

	;5 Oct 2026, Monday. Day 01 = Sunday
	ldi temp,0x05
	mov r8,temp
	ldi temp,0x10
	mov r9,temp
	ldi temp,0x02
	mov r10,temp
	ldi temp,0x26
	mov r11,temp
	rcall ds1302_write_calendar

	rcall ds1302_reset_off

ds1302_main:
;marker 0xFF
	ldi argument,0xFF
	rcall usart0_aux_queue

	rcall ds1302_reset_on
	rcall ds1302_read_time
;time
	mov argument,r10
	rcall usart0_aux_queue
	mov argument,r9
	rcall usart0_aux_queue
	mov argument,r8
	rcall usart0_aux_queue
;date
	rcall ds1302_read_calendar
	mov argument,r11
	rcall usart0_aux_queue
	mov argument,r9
	rcall usart0_aux_queue
	mov argument,r8
	rcall usart0_aux_queue
	mov argument,r10
	rcall usart0_aux_queue
	
	rcall ds1302_reset_off

	_SLEEP_TASK_EXT 20000
rjmp ds1302_main
