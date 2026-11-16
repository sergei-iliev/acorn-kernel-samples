/*
AVR128DA32 SPI1 master, polling.
Default route: PC0 MOSI, PC1 MISO, PC2 SCK, PC3 /CS.
SPI mode 0, MSB first, /S active low.
fSCK = SYSTEM_CLOCK / 4 = 6 MHz.
Set SPI_CLK2X_bm as well for 12 MHz.
*/

/**************INIT SPI1 ******************
*@USAGE: temp
*/
spi1_init:
	;PC0 MOSI, PC1 MISO, PC2 SCK, PC3 /S
	lds temp,PORTMUX_SPIROUTEA
	andi temp,~PORTMUX_SPI1_gm
	ori temp,PORTMUX_SPI1_DEFAULT_gc
	sts PORTMUX_SPIROUTEA,temp

	lds temp,PORTC_DIR
	sbr temp,(1<<PIN0)|(1<<PIN2)	;MOSI, SCK
	cbr temp,(1<<PIN1)						;MISO
	sts PORTC_DIR,temp

	ldi temp,PORT_PULLUPEN_bm
	sts PORTC_PIN1CTRL,temp

	;SSD: PC3 low must not force slave mode.
	ldi temp,SPI_MODE_0_gc | SPI_SSD_bm
	sts SPI1_CTRLB,temp

	;MSB first (DORD = 0). Enable after mode and pins are set.
	ldi temp,SPI_MASTER_bm | SPI_PRESC_DIV4_gc | SPI_ENABLE_bm
	sts SPI1_CTRLA,temp
ret

/**************************TRANSFER BYTE SPI1*************************
;@INPUT:  argument - byte to send
;@USAGE:  temp
;@OUTPUT: argument - byte received
*****************************************************************/
spi1_transfer:
	sts SPI1_DATA,argument
spi1_tr_wait:
	lds temp,SPI1_INTFLAGS
	sbrs temp,SPI_IF_bp
	rjmp spi1_tr_wait
	lds argument,SPI1_DATA
ret
