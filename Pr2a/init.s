.global DoUndef
.global DoSWI
.global DoDabort
.global screen

.global _ISR_STARTADDRESS
.equ 	  _ISR_STARTADDRESS,	0xc7fff00		/* GCS6:64M DRAM/SDRAM 	*/
.equ    UserStack,   _ISR_STARTADDRESS-0xf00         /* c7ff000 */
.equ    SVCStack,    _ISR_STARTADDRESS-0xf00+256     /* c7ff100 */
.equ    UndefStack,  _ISR_STARTADDRESS-0xf00+256*2   /* c7ff200 */
.equ    AbortStack,  _ISR_STARTADDRESS-0xf00+256*3   /* c7ff300 */
.equ    IRQStack,    _ISR_STARTADDRESS-0xf00+256*4   /* c7ff400 */
.equ    FIQStack,    _ISR_STARTADDRESS-0xf00+256*5   /* c7ff500 */

.equ    HandleReset,    _ISR_STARTADDRESS
.equ    HandleUndef,    _ISR_STARTADDRESS+4
.equ    HandleSWI,      _ISR_STARTADDRESS+4*2
.equ    HandlePabort,   _ISR_STARTADDRESS+4*3
.equ    HandleDabort,   _ISR_STARTADDRESS+4*4
.equ    HandleReserved, _ISR_STARTADDRESS+4*5
.equ    HandleIRQ,      _ISR_STARTADDRESS+4*6
.equ    HandleFIQ,      _ISR_STARTADDRESS+4*7

/* Simbolos para facilitar la codificación
de los modos de ejecución */
.equ 	USERMODE,	0x10
.equ 	FIQMODE,	0x11
.equ 	IRQMODE,	0x12
.equ 	SVCMODE,	0x13
.equ 	ABORTMODE,	0x17
.equ 	UNDEFMODE,	0x1b
.equ 	MODEMASK,	0x1f

.equ 	  NOINT,	0xc0   /* Máscara para deshabilitar interrupciones */
.equ    IRQ_MODE,	0x40   /* deshabilitar interrupciones en modo IRQ  */
.equ    FIQ_MODE,	0x80   /* deshabilitar interrupciones en modo FIQ  */

.equ	WTCON,	0x01D30000
.equ	INTMSK,	0x01E0000C
.equ	I_ISPC,	0x01E00024
.arm
start:
    /* Si comenzamos con un reset
     el procesador esta en modo supervisor */
    bl InitStacks
	
    /* Seguimos en modo supervisor, configuramos
       las direcciones de las rutinas de tratamiento
       de excepciones */
    bl InitISR

    /* Pasamos a modo usuario, inicializamos su pila
      y ponemos a cero el frame pointer*/
    mrs	r0,cpsr
    bic	r0,r0,#MODEMASK
    orr	r1,r0,#USERMODE
    msr	cpsr_cxsf,r1 	    /* SVCMode */
    ldr sp,=UserStack
    mov fp,#0

    /* Saltamos a Main */
    .extern Main

    ldr r0,=Main
    mov lr,pc
    mov pc,r0
	b .
InitStacks:
    /* Código de la primera parte */
    /*RUTINA QUE INICIALICE LAS PILAS DE TODOS LOS MODOS*/

	/* UNDEF */
	mrs r0, cpsr /* Llevamos el registro de estado a r0 */
	bic r0, r0, #MODEMASK /* Borramos los bits 4:0 de r0; R0 = R0 AND NOT #MODEMASK *
	orr r1, r0, #UNDEFMODE /* Añadimos el código de modo Undef y copiamos en r1 */
	msr cpsr_cxsf, r1 /* Escribimos el resultado en el registro de estado
						cambiando de este los bits del campo de control,
						de extensión, de estado y los de flag */
	ldr sp,=UndefStack /* Una vez en modo Undef copiamos la dirección de
						comienzo de la pila. OJO: el sp es el sp de Undef*/
						/* El resto de pilas las tiene que inicializar el alumno en la práctica */
	
	/* ABORT */
	mrs r0, cpsr 
	bic r0, r0, #MODEMASK 
	orr r1, r0, #ABORTMODE 
	msr cpsr_cxsf, r1 
	ldr sp,=AbortStack
	
	/* IRQ */
	mrs r0, cpsr 
	bic r0, r0, #MODEMASK 
	orr r1, r0, #IRQMODE 
	msr cpsr_cxsf, r1 
	ldr sp,=IRQStack
	
	/* FIQ */
	mrs r0, cpsr 
	bic r0, r0, #MODEMASK 
	orr r1, r0, #FIQMODE 
	msr cpsr_cxsf, r1 
	ldr sp,=FIQStack
	
	/* SVC */
	mrs r0, cpsr 
	bic r0, r0, #MODEMASK 
	orr r1, r0, #SVCMODE 
	msr cpsr_cxsf, r1 
	ldr sp,=SVCStack
    
    mov pc, lr

InitISR:
    /* Código de la primera parte */
 	/*RUTINA QUE CARGUE EN MEMORIA LA TABLAS DE DIRECCIONES DE SUBRUTINA*/
 	
 /*prólogo */
str ip, [sp, #-4]!  @ salvamos ip en la pila
mov ip, sp
stmdb sp!, {r0-r10, fp, ip, lr, pc} @ salvamos el resto del contexto
sub fp, ip, #4
	
@@ DATA ABORT
	/* cuerpo de la rutina */
	ldr r0,=ISR_Dabort
	ldr r1,=HandleDabort
	str r0,[r1]
@@ FIQ
	/* cuerpo de la rutina */
	ldr r0,=ISR_FIQ
	ldr r1,=HandleFIQ
	str r0,[r1]	
@@ IRQ
	/*prólogo */
	/* cuerpo de la rutina */
	ldr r0,=ISR_IRQ
	ldr r1,=HandleIRQ
	str r0,[r1]		
@@ PREFETCH ABORT
	/* cuerpo de la rutina */
	ldr r0,=ISR_Pabort
	ldr r1,=HandlePabort
	str r0,[r1]
@@ UNDEF
	/* cuerpo de la rutina */
	ldr r0,=ISR_Undef
	ldr r1,=HandleUndef
	str r0,[r1]
	
@@ SWI
	/* cuerpo de la rutina */
	ldr r0,=ISR_SWI
	ldr r1,=HandleSWI
	str r0,[r1]
/* epílogo */
ldmdb fp, {r0-r10, fp, sp, lr} @restauramos contexto'
ldmia sp!, {ip} @ restauramos ip'
	
	mov pc,lr

DoSWI:
	swi
	mov pc,lr

DoUndef:
	.word 0xE6000010
	mov pc,lr

DoDabort:
	ldr r0,=0x0a333333
	str r0,[r0]
	mov pc,lr


screen:
	.space 1024

.end
