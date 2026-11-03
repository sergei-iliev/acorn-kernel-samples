/*
fm24c04 memory 4k 512x8
Test Cases of read/write single byte and a buffer at random FRAM address
*/
.include "tasks/fm24c04b.asm"

fm24c04_task:
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	rcall fm24c04_init
	

fm24c04_main:
	ldi temp,FM24C04_ADDRESS_00		
	mov r2,temp  //r2 is task global variable

	rcall buffer_write_buffer_read_test

	ldi temp,FM24C04_ADDRESS_11		
	mov r2,temp  //r2 is task global variable

	rcall buffer_write_buffer_read_test
rjmp fm24c04_main

/****TEST*****
Store a single byte at random address XX and read in loop
*/
single_byte_read_test:
	;store at address 500 (0x1F4, A8 = 1)
	ldi temp,low(500)
	mov r8,temp
	ldi temp,high(500)
	mov r9,temp
	ldi argument,200	;value
	rcall fm24c04_write_byte

sbr_read:
	;read from address 500
	ldi temp,low(500)
	mov r8,temp
	ldi temp,high(500)
	mov r9,temp
	rcall fm24c04_read_byte
	brtc sbr_next

	mov argument,axl
	rcall usart0_send

sbr_next:
	_SLEEP_TASK_EXT 20000
rjmp sbr_read
ret

.dseg
fm24c04_buf: .byte 12
fm24c04_in_buf: .byte 6
fm24c04_out_buf: .byte 6
.cseg

/****TEST****
Test FRAM page 0 and 1 transition.
Store RAM bytes 1..12 at FRAM address 498, then read them back.
*/
buffer_write_page0_page1_test:
	;fill ram buffer
	LDI16 ZL,ZH,fm24c04_buf
	ldi temp,1
bwt_fill:
	st Z+,temp
	inc temp
	cpi temp,13
	brne bwt_fill

	LDI16 ZL,ZH,fm24c04_buf
	LDI16 XL,XH,498		;FRAM address
	LDI16 axl,axh,12
	rcall fm24c04_write_buffer

bwt_read:
	LDI16 XL,XH,498
	ldi bxl,12
bwt_rdbyte:
	mov r8,XL
	mov r9,XH
	rcall fm24c04_read_byte
	brtc bwt_rdnext

	mov argument,axl
	rcall usart0_send
	_SLEEP_TASK_EXT 200		;PC uasrt is slow 
bwt_rdnext:
	
	ADDI16 XL,XH,1
	dec bxl
	brne bwt_rdbyte

	_SLEEP_TASK_EXT 20000

rjmp bwt_read

/****TEST****
Write 6 bytes from the input buffer at FRAM address 498.Test transitoion from page 0 to page1 
and transition from 512 to 0 address
Read them back into the output buffer and send that buffer to USART.
*/
buffer_write_buffer_read_test:
    ;fill in buffer with test data
	LDI16 ZL,ZH,fm24c04_in_buf
	LDI16 bxl,bxh,6
	ldi temp,1
bwbr_fill:
	st Z+,temp
	inc temp
	DEC16 bxl,bxh
	brne bwbr_fill

	;write buffer
	LDI16 ZL,ZH,fm24c04_in_buf  ;RAM address
	LDI16 XL,XH,498	;FRAM address
	LDI16 axl,axh,6 ;bytes count
	rcall fm24c04_write_buffer
	
	;read buffer
bwbr_read:
	LDI16 ZL,ZH,fm24c04_out_buf
	LDI16 XL,XH,498
	LDI16 axl,axh,6
	rcall fm24c04_read_buffer
	brtc bwbr_next

	;send buffer to USART
	_LOCK usart_lock ;synchronize access to usart resource
	
	LDI16 ZL,ZH,fm24c04_out_buf
	LDI16 bxl,bxh,6
bwbr_send:
	ld argument,Z+
	rcall usart0_send
	_SLEEP_TASK_EXT 200
	DEC16 bxl,bxh
	brne bwbr_send
	
	_UNLOCK usart_lock

bwbr_next:
	_SLEEP_TASK_EXT 20000
ret