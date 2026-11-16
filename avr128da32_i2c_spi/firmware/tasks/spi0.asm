/*
AVR128DA32 SPI0 master, polling.
Default route: PA4 MOSI, PA5 MISO, PA6 SCK, PA7 /CS.
FM25040B uses SPI mode 0 or 3, MSB first, /S active low.
fSCK = SYSTEM_CLOCK / 4 = 6 MHz. FM25040B maximum is 20 MHz.
Set SPI_CLK2X_bm as well for 12 MHz.
*/

/**************INIT SPI0 ******************
*@USAGE: temp
*/
spi0_init:
	;PA4 MOSI, PA5 MISO, PA6 SCK, PA7 /S
	lds temp,PORTMUX_SPIROUTEA
	andi temp,~PORTMUX_SPI0_gm
	ori temp,PORTMUX_SPI0_DEFAULT_gc
	sts PORTMUX_SPIROUTEA,temp

	lds temp,PORTA_DIR
	sbr temp,(1<<PIN4)|(1<<PIN6)	;MOSI, SCK
	cbr temp,(1<<PIN5)						;MISO
	sts PORTA_DIR,temp

	ldi temp,PORT_PULLUPEN_bm
	sts PORTA_PIN5CTRL,temp

	;SSD: PA7 is the FRAM /CS. A low on SS must not force slave mode.
	ldi temp,SPI_MODE_0_gc | SPI_SSD_bm
	sts SPI0_CTRLB,temp

	;MSB first (DORD = 0). Enable after mode and pins are set.
	ldi temp,SPI_MASTER_bm | SPI_PRESC_DIV4_gc | SPI_ENABLE_bm
	sts SPI0_CTRLA,temp
ret

/**************************TRANSFER BYTE SPI0*************************
;@INPUT:  argument - byte to send
;@USAGE:  temp
;@OUTPUT: argument - byte received
*****************************************************************/
spi0_transfer:
	sts SPI0_DATA,argument
spi0_tr_wait:
	lds temp,SPI0_INTFLAGS
	sbrs temp,SPI_IF_bp
	rjmp spi0_tr_wait
	lds argument,SPI0_DATA
ret
