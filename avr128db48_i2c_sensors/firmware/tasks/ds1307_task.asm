;1 DEVICES on TWI1
.include "tasks/ds1307.asm"  	
//.include "tasks/tc74a1.asm"

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
;time
	mov argument,r10
	rcall usart0_send
	mov argument,r9
	rcall usart0_send
	mov argument,r8
	rcall usart0_send
;date
	rcall ds1307_read_date
	brtc ds1307_next

	mov argument,r10
	rcall usart0_send
	mov argument,r9
	rcall usart0_send
	mov argument,r8
	rcall usart0_send

;temperature
//	rcall tc74a1_read_temp
	
//	mov argument,axl
//	rcall usart0_send

ds1307_next:
	_SLEEP_TASK_EXT 20000
rjmp ds1307_main
