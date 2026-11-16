/*
Task to control SPI communication with FRAM FM25040B
*/
.include "tasks/fm25040b.asm"

fm25040_task:
	  
	  rcall fm25040_init
	  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	


fm25040_main:
	
	ldi temp,0			;chip 0, /S = PA7
	mov r2,temp

	ldi temp,2 
	mov r3,temp ;task global number

	rcall spi_buffer_write_buffer_read_test
	
	
	;ldi temp,1			;chip 1, /S = PA3
	;mov r2,temp

	;ldi temp,123  
	;mov r3,temp ;task global number

	;rcall spi_single_byte_read_test
	
rjmp fm25040_main


/****TEST*****
Store a single byte at random address XX and read in loop
*/
spi_single_byte_read_test:
;store at address 0x01 data 24
	ldi temp,low(500)
	mov r8,temp
	ldi temp,high(500)
	mov r9,temp
	mov argument,r3		;task global number
	rcall fm25040_write_byte

spi_sbr_00:
;read from address 0x01
	ldi temp,low(500)
	mov r8,temp
	ldi temp,high(500)
	mov r9,temp
	rcall fm25040_read_byte
	
	;sent to UART
	mov argument,axl
	rcall usart0_send


	_SLEEP_TASK_EXT 20000

ret


.dseg
fm25040_in_buf: .byte 6
fm25040_out_buf: .byte 6
.cseg

/****TEST****
Write 6 bytes from the input buffer at FRAM address 498.
Read them back into the output buffer and send that buffer to USART.
*/
spi_buffer_write_buffer_read_test:
	LDI16 ZL,ZH,fm25040_in_buf
	LDI16 bxl,bxh,6
	mov temp,r3
spi_bwbr_fill:
	st Z+,temp
	inc temp
	DEC16 bxl,bxh
	brne spi_bwbr_fill

	LDI16 ZL,ZH,fm25040_in_buf
	LDI16 XL,XH,498
	LDI16 axl,axh,6
	rcall fm25040_write_buffer

	LDI16 ZL,ZH,fm25040_out_buf
	LDI16 XL,XH,498
	LDI16 axl,axh,6
	rcall fm25040_read_buffer

	_LOCK usart_lock
	LDI16 ZL,ZH,fm25040_out_buf
	LDI16 bxl,bxh,6
spi_bwbr_send:
	ld argument,Z+
	rcall usart0_send
	_SLEEP_TASK_EXT 200
	DEC16 bxl,bxh
	brne spi_bwbr_send
	_UNLOCK usart_lock

	_SLEEP_TASK_EXT 20000
ret
