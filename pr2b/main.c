extern char screen[];

char *Screen = (char*) screen;

void ISR_SWI(void) __attribute__ ((interrupt ("SWI")));
void ISR_Undef(void) __attribute__ ((interrupt ("UNDEF")));
void ISR_IRQ(void) __attribute__ ((interrupt ("IRQ")));
void ISR_FIQ(void) __attribute__ ((interrupt ("FIQ")));
void ISR_Pabort(void) __attribute__ ((interrupt ("ABORT")));
void ISR_Dabort(void) __attribute__ ((interrupt ("ABORT")));


void write(char* text, char* address)
{
	while( *text != 0 ){
		*address++ = *text++;
		}
}

void DoUndef();
void DoDabort();
void DoSWI();
extern int DetectaPulsacion();

void Main(void)
{
    while(1){
    }
}

void ISR_Undef(void)
{
    write("Undef ",Screen);
}

void ISR_IRQ(void)
{
   //write("IRQ   ",Screen);
    DetectaPulsacion();
}

void ISR_FIQ(void)
{
    write("FIQ   ",Screen);
}

void ISR_SWI(void)
{
    write("SWI   ",Screen);
}

void ISR_Pabort(void)
{
    write("Pabort",Screen);
}

void ISR_Dabort(void)
{
    write("Dabort",Screen);
}
