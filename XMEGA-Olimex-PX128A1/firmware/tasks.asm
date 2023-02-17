
.LISTMAC ; Enable macro expansion 
/* Is this task needed */
task1:

	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER

main1:
	_YIELD_TASK
rjmp main1


.include "kernel/single-producer-consumer.asm"

.include "/include/usart_task_D.asm"
.include "/include/usart_task_E.asm"
.include "/include/lcd_task.asm"

.EXIT