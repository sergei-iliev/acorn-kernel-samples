//I2C temperature sensor
.include "tasks/tc74a1.asm"



tc74a1_task:

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
	rcall tc74a1_init

tc74a1_main:

	rcall tc74a1_wakeup	
	_SLEEP_TASK_EXT 5000   ;give it some time before reading temp after wake up
	rcall tc74a1_read_temp
	
	mov argument,axl
	rcall usart0_send

	rcall tc74a1_sleep

	_SLEEP_TASK_EXT 50000
rjmp tc74a1_main

