.EQU PIN2 =2

blink_task:
  //---setup LED pin on PB0
  lds temp,PORTA_DIR
  sbr temp,1<<PIN2
  sts PORTA_DIR,temp


  	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main1:  

  lds temp,PORTA_OUT
  sbr temp,1<<PIN2
  sts PORTA_OUT,temp

  _SLEEP_TASK 250
  _SLEEP_TASK 250 
  _SLEEP_TASK 250 

  lds temp,PORTA_OUT
  cbr temp,1<<PIN2
  sts PORTA_OUT,temp

  _SLEEP_TASK 250
  _SLEEP_TASK 250 
  _SLEEP_TASK 250 
rjmp main1