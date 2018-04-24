/*
SIMPLE and INCOMPLETE
Define unsigned 16bit buffer.
Make sure number of entries is devisable by 2(No need if 16 bit division is involved) 
CAPACITY MUST BE BIGGER THEN 2
Last out,first in  LSB:MSB order
*/

#define BUFFER_CAPACITY 4  ;capacity in 2 bytes per element

#define MULTIPLICITY (BUFFER_CAPACITY%2)
 
#if MULTIPLICITY!=0
   .EQU BUFFER_SIZE=BUFFER_CAPACITY-MULTIPLICITY
#else
   .EQU BUFFER_SIZE= BUFFER_CAPACITY
#endif 
 
.EQU MEMORY_SIZE=BUFFER_SIZE*2

.EQU DIVISOR=LOG2(BUFFER_SIZE)
.dseg

QUEUE:   .byte MEMORY_SIZE

.cseg

/*
Zero out the buffer
INPUT:
OUTPUT:
USE:temp,RAM buffer,X,Y,counter
*/
QueueInit:
	ldi XL,low(QUEUE)
	ldi XH,high(QUEUE)
	clr temp
	ldi counter,MEMORY_SIZE
qi:	
	st X+,temp
	dec counter
	brne qi	
ret


/*
FILO shift word(16 bit) downwords with one position
INPUT:axl:ahh
OUTPUT:
USAGE: X,Y,counter,temp
*/
QueuePush:
;last out
	ldi YL,low(QUEUE+MEMORY_SIZE)
	ldi YH,high(QUEUE+MEMORY_SIZE)
	ldi XL,low(QUEUE+MEMORY_SIZE-2)
	ldi XH,high(QUEUE+MEMORY_SIZE-2)
    ldi counter,MEMORY_SIZE-1*2
   
qp:
    ld temp,-X
    st -Y,temp
    dec counter
    brne qp

;first in  LSB:MSB order
	;ldi XL,low(QUEUE)
	;ldi XH,high(QUEUE)    	        
    st X+,axl
	st X,axh
ret

/*
Get sum of all 16bit entries
INPUT:
OUTPUT:axl;axl  - accumulated result     
USAGE:X,ax,bx
*/

QueueSum:
	ldi XL,low(QUEUE)
	ldi XH,high(QUEUE)
    ldi counter,BUFFER_SIZE   ;size in words

;accumulate result in ax register
    clr axl
	clr axh

qs:
	ld bxl,X+
	ld bxh,X+
	
    add axl,bxl ; first add the two low-bytes
    adc axh,bxh ; then the two high-bytes

    dec counter
    brne qs

ret

/*
Get AVARAGE sum of all 16bit entries
INPUT:
OUTPUT:ax  - accumulated result     
USAGE:X,ax,bx
*/

QueueAvgSum:
	ldi XL,low(QUEUE)
	ldi XH,high(QUEUE)
    ldi counter,BUFFER_SIZE   ;size in words

;accumulate result in ax register
    clr axl
	clr axh

qas:
	ld bxl,X+
	ld bxh,X+
	
    add axl,bxl ; first add the two low-bytes
    adc axh,bxh ; then the two high-bytes

    dec counter
    brne qas

//***devide by BUFFER_SIZE -> size in words

    ldi temp,DIVISOR 
qas1:
    lsr axh
	ror axl
	dec temp
    brne qas1

ret

