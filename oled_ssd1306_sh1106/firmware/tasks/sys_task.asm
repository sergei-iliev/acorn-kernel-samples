sys_task:
	;debug output
	sbi DDRD,PD2

sys_main:
    nop
	;sbi PORTC,PC0
	;_SLEEP_TASK 255
	;cbi PORTC,PC0
	;_SLEEP_TASK 255
rjmp sys_main