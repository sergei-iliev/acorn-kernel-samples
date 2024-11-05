.equ PIN0 = 0
.equ PIN1 = 1
.equ PIN2 = 2
.equ PIN3 = 3
.equ PIN4 = 4
.equ PIN5 = 5
.equ PIN6 = 6
.equ PIN7 = 7

sys_task:
  //---setup LED pin on PC0
  lds temp,PORTC_DIR
  sbr temp,1<<PIN0
  sts PORTC_DIR,temp



  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

sys_main:
  lds temp,PORTC_OUT
  sbr temp,1<<PIN0
  sts PORTC_OUT,temp

  _SLEEP_TASK_EXT 10000 

  lds temp,PORTC_OUT
  cbr temp,1<<PIN0
  sts PORTC_OUT,temp

  _SLEEP_TASK_EXT 10000

  ;participate in SLEEP CPU
  _SLEEP_CPU_TASK VOID_CALLBACK,VOID_CALLBACK,temp
rjmp sys_main