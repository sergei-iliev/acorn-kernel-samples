/**********************************************************************************/
/*    Test task for:															  */
/*	  Board: AVR-PX128A1														  */
/*    Manufacture: OLIMEX                                                   	  */
/*	  COPYRIGHT (C) 2008														  */
/*    Module Name    :  GDSC-0801WP-01-MENT                                       */
/**********************************************************************************/

.SET RS_BIT=1
.SET RW_BIT=2
.SET EN_BIT=3

.include "include\GDSC-0801WP.asm"
//lcd frame for animation
.dseg
LCD_FRAME: .byte 8
.cseg

lcd_task:
_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
    	
	rcall lcd_init  
main_lcd:
	
	;animate text forever
	rcall lcd_send_rom_text

rjmp main_lcd


