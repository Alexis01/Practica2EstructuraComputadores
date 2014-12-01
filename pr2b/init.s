.global DoUndef
.global DoSWI
.global DoDabort
.global screen
.global DetectaPulsacion

.global	_ISR_STARTADDRESS
.equ	_ISR_STARTADDRESS,	0xC7FFF00				/* GCS6:64M DRAM/SDRAM */
.equ	UserStack,	_ISR_STARTADDRESS-0xF00			/* c7ff000 */
.equ	SVCStack,	_ISR_STARTADDRESS-0xF00+256		/* c7ff000 */
.equ	UndefStack,	_ISR_STARTADDRESS-0xF00+256*2	/* c7ff000 */
.equ	AbortStack,	_ISR_STARTADDRESS-0xF00+256*3	/* c7ff000 */
.equ	IRQStack,	_ISR_STARTADDRESS-0xF00+256*4	/* c7ff000 */
.equ	FIQStack,	_ISR_STARTADDRESS-0xF00+256*5	/* c7ff000 */

.equ	HandleReset,	_ISR_STARTADDRESS
.equ	HandleUndef,	_ISR_STARTADDRESS+4
.equ	HandleSWI,		_ISR_STARTADDRESS+4*2
.equ	HandlePabort,	_ISR_STARTADDRESS+4*3
.equ	HandleDabort,	_ISR_STARTADDRESS+4*4
.equ	HandleReserved,	_ISR_STARTADDRESS+4*5
.equ	HandleIRQ,		_ISR_STARTADDRESS+4*6
.equ	HandleFIQ,		_ISR_STARTADDRESS+4*7

/* Símbolos para facilitar la codificación de los modos de ejecución */
.equ	USERMODE,	0x10
.equ	FIQMODE,	0x11
.equ	IRQMODE,	0x12
.equ	SVCMODE,	0x13
.equ	ABORTMODE,	0x17
.equ	UNDEFMODE,	0x1B
.equ	MODEMASK,	0x1F

.equ	NOINT,		0xC0	/* Máscara para deshabilitar interrupciones */
.equ	IRQ_MODE,	0x40	/* deshabilitar interrupciones en modo IRQ */
.equ	FIQ_MODE,	0x80	/* deshabilitar interrupciones en modo FIQ */

.equ	WTCON,	0x01D30000
.equ	INTMSK,	0x01D3000C
.equ	I_ISPC,	0x01D30024

## Puerto G: conectado a los pulsadores
.equ	PCONG,		0x01D20040
.equ	PUPG,		0x01D2004B
.equ	PDATG,		0x01D20044
.equ	EXINT,		0x01D20050
.equ	EXINTPND,	0x01D20054

## Registros del controlador de instrucciones
.equ	INTCON,	0x01E00000
.equ	INTMOD,	0x01E00008
.equ	INTMSK,	0x01E0000C
.equ	INTPND,	0x01E00004
.equ	I_ISPC,	0x01E00024

## Puerto B: conectado a los leds
.equ	PDATB,	0x1D2000C
.equ	PCONB,	0x1D20008

.data
## Variable que almacena el estado actual de los leds
led_status:	.word 0

.text
start:
	/* El procesador está en modo supervisor */
	BL InitStacks

	/* Seguimos en modo supervisor */
	BL InitISR
	BL init_botones
	BL init_leds
	BL init_controladorInt
	BL borraInt
	/* Pasamos a modo usuario y activamos interrupciones IRQ*/
	MRS r0, cpsr
	BIC r0, r0, #0x9F
	ORR r1, r0, #USERMODE
	MSR cpsr_cxsf, r1	/* UserMode y IRQ activadas*/
	LDR sp, =UserStack
	MOV fp, #0
	
	
	
	
	
/*	.extern Main
	MOV lr, pc
	LDR pc, =Main
	b .*/
		bucleMain:
			B bucleMain

FIN:
	B .
	
	

	
InitStacks:
	MRS r2, cpsr /* Guardamos el registro de estado actual en r2 */
	BIC r0, r2, #MODEMASK

	/* Inicialización del modo FIQ */
	ORR r1, r0, #FIQMODE
	MSR cpsr_cxsf, r1
	LDR sp, =FIQStack
	
	/* Inicialización del modo IRQ */
	ORR r1, r0, #IRQMODE
	MSR cpsr_cxsf, r1
	LDR sp, =IRQStack
	
	/* Inicialización del modo SVC */
	ORR r1, r0, #SVCMODE
	MSR cpsr_cxsf, r1
	LDR sp, =SVCStack
	
	/* Inicialización del modo Abort */
	ORR r1, r0, #ABORTMODE
	MSR cpsr_cxsf, r1
	LDR sp, =AbortStack
	
	/* Inicialización del modo Undef */
	ORR r1, r0, #UNDEFMODE
	MSR cpsr_cxsf, r1
	LDR sp, =UndefStack
	
	MSR cpsr_cxsf, r2 /* Restauramos el registro de estado inicial */
	MOV pc, lr
	
InitISR:
	/* ISR para excepciones Undef */
	LDR r0, =ISR_Undef
	LDR r1, =HandleUndef
	STR r0, [r1]
	
	/* ISR para excepciones SWI */
	LDR r0, =ISR_SWI
	LDR r1, =HandleSWI
	STR r0, [r1]
	
	/* ISR para excepciones Pabort */
	LDR r0, =ISR_Pabort
	LDR r1, =HandlePabort
	STR r0, [r1]
	
	/* ISR para excepciones Dabort */
	LDR r0, =ISR_Dabort
	LDR r1, =HandleDabort
	STR r0, [r1]
	
	/* ISR para excepciones IRQ */
	LDR r0, =ISR_IRQ
	LDR r1, =HandleIRQ
	STR r0, [r1]
	
	/* ISR para excepciones FIQ */
	LDR r0, =ISR_FIQ
	LDR r1, =HandleFIQ
	STR r0, [r1]
	
	MOV pc, lr
	
/* Rutinas de generación de excepciones */
DoSWI:
	SWI
	MOV pc, lr

DoUndef:
	.word 0xE6000010
	MOV pc, lr
	
DoDabort:
	LDR r0, =0x0a333333
	STR r0, [r0]
	MOV pc, lr
	
screen:
	.space 1024
	
## Configura PUPG y PCONG como entrada, y configura EXINT
init_botones:
	MOV r0, #0
	LDR r1, =PUPG /*Activación del pull-up*/
	STR r0, [r1]
	LDR r1, =PCONG   /*Generar interrupciones*/
	MOV r0, #0xFFFFFFFF  
	STR r0, [r1]
	LDR r0, =0x22222222
	LDR r1, =EXINT  /*Detección interr. por flanco de bajada*/
	STR r0, [r1]
	BX lr
	
## Configura bits 9 y 10 de PCONB como salida,
## enciende ambos leds y actualiza la variable led_status
init_leds:
	LDR r1, =0x1CF  /* 0x0000...1cf  0001 1100 1111*/
	LDR r0, =PCONB /*Como salida*/
	STR r1, [r0]
	MOV r2, #0x0000  /* Encender leds */
	LDR r0, =PDATB
	STR r2, [r0]
	LDR r0, =led_status  /*Guardar el estado de los leds*/
	STR r2, [r0]
	BX lr

## Inicializa interrupciones del controlador
init_controladorInt:

	MOV r0, #0x5
	LDR r1, =INTCON  /*Interrupt Control Register*/
	STR r0, [r1]
	MOV r0, #0     /*Linea 21 modo IRQ =0 */
	LDR r1, =INTMOD /*Interrupt Mode Register*/
	STR r0, [r1]
	LDR r0, =0x03dFFFFF  /*INTMSK=0b011110111111111111111111111=0x3dfffff -- linea 26 y 21 a 0*/
	LDR r1, =INTMSK    /*Interrupt Mask Register*/
	STR r0, [r1]
	BX lr

## Borra interrupciones del controlador y del dispositivo	
borraInt:
	MOV r0, #0xFFFFFFFF /* Borra el bit correspondiente en el reg INTPND escribiendo un 1 en el bit correspondiente*/
	LDR r1, =I_ISPC   /*IRQ Int. Service Pending Clear register*/
	STR r0, [r1]      /* Se borra la interrupción escribiendo 1 en el bit correspondiente.*/
	LDR r1, =EXINTPND /*External Int. Pending register*/
	STR r0, [r1]      /*Sirve tanto para consultar como para borrar el bit de interrupción pendiente*/
	
## Detecta pulsaciones en algun boton mediante espera activa
## (hace un bucle hasta que se pulsa un boton)
## Devuelve:	1 -> boton 1 pulsado
##				2 -> boton 2 pulsado
##				3 -> ambos pulsados
DetectaPulsacion:
	SUB sp, sp, #4
	STR lr, [sp]
	LDR r0, =PDATG
	LDR r1, [r0]
	MVN r1, r1
	AND r1, r1, #0x000000C0
	##CMP r1, #0
	##BEQ bucleDet
	MOV r0, r1, LSR #6
	CMP r0, #1
	BNE else1
	BL switch_led1
	BL eliminaRebotes
	B fin_if
		else1:
			CMP r0, #2
			BNE else2
			BL switch_led2
			BL eliminaRebotes
			B fin_if
		else2:
			CMP r0, #3
			BNE fin_if
			BL switch_led1
			BL switch_led2
			BL eliminaRebotes
	fin_if:
		#BL eliminaRebotes
		BL borraInt
		LDR lr, [sp]
		ADD sp, sp, #4
		BX lr
	
## Elimina rebotes: crea un retardo tras la deteccion haciendo iteraciones
eliminaRebotes:
	LDR r2, =200000
	MOV r3, #0
	bReb:
		CMP r3, r2
		BEQ finR
		MUL r1, r0, r1
		ADD r3, r3, #1
		B bReb
	finR:
		BX lr
		
## Cambia estado del led que correspone a la pulsacion detectada
switch_led1:
	LDR r0, =led_status
	LDR r1, [r0]
	LDR r2, =0x200
	EOR r1, r1, r2
	STR r1, [r0]
	LDR r0, =PDATB
	STR r1, [r0]
	BX lr
	
switch_led2:
	LDR r0, =led_status
	LDR r1, [r0]
	LDR r2, =0x400
	EOR r1, r1, r2
	STR r1, [r0]
	LDR r0, =PDATB
	STR r1, [r0]
	BX lr
	
.end
