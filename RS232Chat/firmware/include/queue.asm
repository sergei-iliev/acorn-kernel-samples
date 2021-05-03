/***************************************************QUEUE 8/16 bit******************************************************************
8 bit queue

memory structure
1.byte - head index points to next occupied slot to be read,starts from 0 index
1.byte - tail index points to next free slot to be written, starts from 0 index
1.byte - counter to measure current size
N < 256 size byte array (each element 1 byte long)

16 bit queue

memory structure
2.byte - head index points to next occupied slot to be read,starts from 0 index
2.byte - tail index points to next free slot to be written, starts from 0 index
2.byte - counter to measure current size
0<N < 2^16  size byte array (each element 2 byte long MSB:LSB order)

*/
#define HEAD_OFFSET 0
#define TAIL_OFFSET 1
#define SIZE_OFFSET 2
 
#define HEAD_OFFSET16 0
#define TAIL_OFFSET16 2
#define SIZE_OFFSET16 4

.cseg
/**********************************************************************16 bit Queue*****************************************************/

/***************************init queue************************
@INPUT: Z - queue pointer		
@USAGE: temp
		
*************************************************************/
queue16_init:    
    clr temp

	std Z+(HEAD_OFFSET),temp     ;head MSB 
	std Z+(HEAD_OFFSET+1),temp   ;head LSB
	std Z+(HEAD_OFFSET+2),temp	 ;tail MSB   
	std Z+(HEAD_OFFSET+3),temp	 ;tail LSB  	 
	std Z+(HEAD_OFFSET+4),temp	 ;size MSB   
	std Z+(HEAD_OFFSET+5),temp	 ;size LSB  
	
ret

/******************************enqueue***********************
@INPUT: Z - queue pointer 
		axh:axl - MAX size of backing static array
		dxh:dxl - value
@USAGE: bxl,bxh,r0,r1,r2,r3
@OUTPUT: T flag 0 - failure
				1 - success
*************************************************************/
queue16_enqueue:   
	rcall queue16_is_full	;mind input params
	brts que16enq_0					;it is full

	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH

	ldd bxh,Z+TAIL_OFFSET16		;tail index
	ldd bxl,Z+TAIL_OFFSET16+1	;tail index

	adiw ZH:ZL,6			;position to beginning of buffer

	;2 byte value -> multiply by 2 to real buffer index
	mov r2,bxl	
	mov r3,bxh
	LSL16 r3,r2

	ADD16 ZL,ZH,r2,r3
	
	st Z+,dxh				;store 16 bit value
	st Z,dxl
	;fix tail index->move to next free index slot in array
	ADDI16 bxl,bxh,1
	
	CP16 bxl,bxh,axl,axh		; >MAX
	brlo que16enq_1	
	;start from 0 index
	clr bxl
	clr bxh		 
que16enq_1:	

	mov ZL,r0
	mov ZH,r1	

	std Z+TAIL_OFFSET16,bxh  ;store new tail index
	std Z+TAIL_OFFSET16+1,bxl  ;store new tail index

	
	ldd bxh,Z+SIZE_OFFSET16	;size 
	ldd bxl,Z+SIZE_OFFSET16+1	;size
	;increment size
	ADDI16 bxl,bxh,1

	std Z+SIZE_OFFSET16,bxh  ;store new size
	std Z+SIZE_OFFSET16+1,bxl  ;store new size

	set					;value inserted
ret

que16enq_0:
	clt				;buffer is full
ret
/*************************dequeue************************
@INPUT: Z - queue pointer 
		axl - length of backing static array
@USAGE: bxl,bxh,r0,r1,r2,r3			
@OUTPUT: T flag 0 - failure
				1 - success
		dxh:dxl - value
*********************************************************/
queue16_dequeue:
	rcall queue16_is_empty
	brts que16deq_0					;it is empty

		;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH
	
	ldd bxh,Z+HEAD_OFFSET16		;tail index
	ldd bxl,Z+HEAD_OFFSET16+1	;tail index

	adiw ZH:ZL,6			;position to beginning of buffer

	;2 byte value -> multiply by 2 to real buffer position
	mov r2,bxl	
	mov r3,bxh
	LSL16 r3,r2

	ADD16 ZL,ZH,r2,r3
	ld dxh,Z+				;read 16 bit value
	ld dxl,Z


	;move to next data index slot in array
	ADDI16 bxl,bxh,1

	CP16 bxl,bxh,axl,axh		; >MAX
	brlo que16deq_1	
	;start from 0 index
	clr bxl
	clr bxh		 
que16deq_1:	

	mov ZL,r0
	mov ZH,r1	

	std Z+HEAD_OFFSET16,bxh  ;store new head index
	std Z+HEAD_OFFSET16+1,bxl  ;store new head index

	ldd bxh,Z+SIZE_OFFSET16	;size 
	ldd bxl,Z+SIZE_OFFSET16+1	;size
	;decrement size
	ADDI16 bxl,bxh,-1

	std Z+SIZE_OFFSET16,bxh  ;store new size
	std Z+SIZE_OFFSET16+1,bxl  ;store new size

	set
ret
que16deq_0:		
	clt  
ret
/********************************Peek the head*******************
Get the head byte without removing it from the queue
@INPUT: Z queue pointer 
@USAGE: bxl,bxh	 
@OUTPUT: dxl,dxh - value at head position
                T flag 0 - failure
					   1 - success
********************************/
queue16_peek:
	rcall queue16_is_empty
	brts que16pk_0					;it is empty

	ldd bxh,Z+HEAD_OFFSET16		;tail index
	ldd bxl,Z+HEAD_OFFSET16+1	;tail index

	adiw ZH:ZL,6			;position to beginning of buffer

	;2 byte value -> multiply by 2 to real buffer position
	mov r2,bxl	
	mov r3,bxh
	LSL16 r3,r2

	ADD16 ZL,ZH,r2,r3
	ld dxh,Z+				;read 16 bit value
	ld dxl,Z

   set
que16pk_0:
   clt
ret
/*********Read current filled/occupied size*******
@INPUT: Z queue pointer 
        axh:axl - MAX size of backing buffer		
@USAGE: cxh,chl
@OUTPUT: T flag 0 - not full
				1 - full
***************************************************/
queue16_is_full:
    clt
    ldd cxh,Z+SIZE_OFFSET16		;current counter
	ldd cxl,Z+SIZE_OFFSET16+1	;current counter
	
	CP16 cxl,cxh,axl,axh
	brlo que16full_0 
	set 
ret
que16full_0:

ret
/*********Is queue empty*******
@INPUT: Z queue pointer 
@USAGE: test,bxh,bxl 
@OUTPUT: T flag 0 - not empty
				1 - empty
********************************/
queue16_is_empty:
  clt
  ldd bxh,Z+SIZE_OFFSET16		;current counter
  ldd bxl,Z+SIZE_OFFSET16+1	;current counter
  
  CPI16 bxl,bxh,temp,0
  breq que16ty_0
ret
que16ty_0:
  set
ret
/************************************************************8 bit Queue********************************************/

/***************************init queue************************
@INPUT: Z - queue pointer		
@USAGE: temp
		
*************************************************************/
queue8_init:    
    clr temp

	std Z+HEAD_OFFSET,temp   ;head
	std Z+TAIL_OFFSET,temp	 ;tail    
	std Z+SIZE_OFFSET,temp	     
ret
/******************************enqueue***********************
@INPUT: Z - queue pointer 
		axl - length of backing static array
		argument - value
@USAGE: bxl,bxh,r0,r1
@OUTPUT: T flag 0 - failure
				1 - success
*************************************************************/
queue8_enqueue:    
	rcall queue8_is_full	;mind input params
	brts que8enq_0					;it is full
    
	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH

	ldd bxl,Z+TAIL_OFFSET  ;tail index
	adiw ZH:ZL,3			;position to beginning of buffer

	clr bxh
	ADD16 ZL,ZH,bxl,bxh
	st Z,argument
	;move to next free index slot in array
	inc bxl
	cp bxl,axl		; >MAX
	brlo que8enq_1	
	//start from 0 index
	clr bxl			 
que8enq_1:	
	mov ZL,r0
	mov ZH,r1
	
	std Z+TAIL_OFFSET,bxl  ;store new tail index
 
	;increment size
	ldd bxl,Z+SIZE_OFFSET  ;current byte length
	inc bxl
	std Z+SIZE_OFFSET,bxl  ;current byte length
	set					;value inserted
ret
que8enq_0:
	clt					;buffer is full
ret
/*************************dequeue************************
@INPUT: Z - queue pointer 
		axl - length of backing static array
@USAGE: bxl,bxh,r0,r1			
@OUTPUT: T flag 0 - failure
				1 - success
		return - value
*********************************************************/
queue8_dequeue:
	rcall queue8_is_empty
	brts que8deq_0					;it is empty
	
	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH

	ldd bxl,Z+HEAD_OFFSET  ;head index
	adiw ZH:ZL,3			;position to beginning of buffer

	clr bxh
	ADD16 ZL,ZH,bxl,bxh
	ld return,Z
	;move to next data index slot in array
	inc bxl
	cp bxl,axl		; >MAX
	brlo que8deq_1	
	//start from 0 index
	clr bxl			 
que8deq_1:	
	mov ZL,r0
	mov ZH,r1

	std Z+HEAD_OFFSET,bxl  ;store new head index

	;decrement size
	ldd bxl,Z+SIZE_OFFSET  ;current byte length
	dec bxl
	std Z+SIZE_OFFSET,bxl  ;current byte length

	set
ret
que8deq_0:		
	clt  
ret

/*********Read current filled/occupied size*******
@INPUT: Z queue pointer 
        axl - MAX size of backing buffer		
@OUTPUT: T flag 0 - not full
				1 - full
***************************************************/
queue8_is_full:
    clt
    ldd temp,Z+SIZE_OFFSET	;current counter
	cp temp,axl
	brlo que8full_0 
	set 
ret
que8full_0:
ret

/*********Is queue empty*******
@INPUT: Z queue pointer 
@USAGE: temp 
@OUTPUT: T flag 0 - not empty
				1 - empty
********************************/
queue8_is_empty:
  clt
  ldd temp,Z+SIZE_OFFSET	;current counter
  tst temp
  breq que8ty_0
ret
que8ty_0:
  set
ret

/*********Peek the head*******
Get the head byte without removing it from the queue
@INPUT: Z queue pointer 
@USAGE: bxl,bxh	 
@OUTPUT: return - byte at head position
                T flag 0 - failure
					   1 - success
********************************/
queue8_peek:
	rcall queue8_is_empty
	brts que8pk_0					;it is empty

	ldd bxl,Z+HEAD_OFFSET  ;head index
	adiw ZH:ZL,3			;position to beginning of buffer

	clr bxh
	ADD16 ZL,ZH,bxl,bxh
	ld return,Z

   set
ret
que8pk_0:
   clt
ret
/*********Peek the tail - last inserted byte*******
Get the tail byte without removing it from the queue
@INPUT: Z queue pointer 
@USAGE: bxl,bxh	 
@OUTPUT: return - byte at tail position
                T flag 0 - failure
					   1 - success
********************************/
queue8_peek_last:
	rcall queue8_is_empty
	brts que8pk_lst_0					;it is empty

	ldd bxl,Z+TAIL_OFFSET  ;head index
	adiw ZH:ZL,3			;position to beginning of buffer

	clr bxh
	ADD16 ZL,ZH,bxl,bxh
	ld return,Z

	set
ret
que8pk_lst_0:
    clt 
ret
/*********Get current queue size*******
Get the current size in bytes(how many readable bytes) 
@INPUT: Z queue pointer 	 
@OUTPUT: return - queue current size
********************************/
queue8_size:
   ldd return,Z+SIZE_OFFSET	;current counter
ret

.EXIT
