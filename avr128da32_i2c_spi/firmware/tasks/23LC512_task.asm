


.include "tasks/23lc512_spi0.asm"

m23lc512_task:
	 
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	rcall m23lc512_spi0_init

m23lc512_main:
  
	ldi temp,0			;chip 0, /CS = PA7
	mov r2,temp
	
	ldi temp,5			;value
	mov r3,temp

	;rcall spi_single_byte_read_test
	
	

	rcall spi_buffer_write_buffer_read_test

rjmp m23lc512_main

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
	
	rcall m23lc512_spi0_write_byte

spi_sbr_00:
;read from address 0x01
	ldi temp,low(500)
	mov r8,temp
	ldi temp,high(500)
	mov r9,temp
	rcall m23lc512_spi0_read_byte
	
	;sent to UART
	mov argument,axl
	rcall usart0_send


	_SLEEP_TASK_EXT 20000
ret

.dseg
m23lc512_in_buf: .byte 6
m23lc512_out_buf: .byte 6
.cseg

/****TEST****
Write 6 bytes from the input buffer at SRAM address 498.
Read them back into the output buffer and send that buffer to USART.
*/
spi_buffer_write_buffer_read_test:
	;fill in buffer with test data
	LDI16 ZL,ZH,m23lc512_in_buf
	LDI16 bxl,bxh,6
	mov temp,r3		;global number to distinct calls
spi_bwbr_fill:
	st Z+,temp
	inc temp
	DEC16 bxl,bxh
	brne spi_bwbr_fill

	;write buffer
	LDI16 ZL,ZH,m23lc512_in_buf
	LDI16 XL,XH,498		;SRAM address
	LDI16 axl,axh,6
	rcall m23lc512_spi0_write_buffer

	;read buffer
spi_bwbr_read:
	LDI16 ZL,ZH,m23lc512_out_buf
	LDI16 XL,XH,498
	LDI16 axl,axh,6
	rcall m23lc512_spi0_read_buffer
	brtc spi_bwbr_next

	;send buffer to USART
	_LOCK usart_lock

	LDI16 ZL,ZH,m23lc512_out_buf
	LDI16 bxl,bxh,6
spi_bwbr_send:
	ld argument,Z+
	rcall usart0_send
	_SLEEP_TASK_EXT 200
	DEC16 bxl,bxh
	brne spi_bwbr_send

	_UNLOCK usart_lock

spi_bwbr_next:
	_SLEEP_TASK_EXT 20000
ret


