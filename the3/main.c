//Tolgahan KURTDERE

/* In summary, we used Timer0 to calculate 50ms for ADC, Timer1 to calculate 500ms for blink session and 5s for game processing time, Timer2 to calculate 10ms for button debouncing.
At the beginning init function is called to to make necessary initializations, and then infitinite while loop (in the main function) is started until correct guess or game over (5s).
For the wrong guesses there are two helper function to arrange 7segment as upArrow or downArrow (hints). When the user push correct guess or 5s is passed, go to gameOver helper function.
In there, blink session is started. After blink session, reset and init helper function make game ready to start again. In the ISR, there are five different if blocks to catch differents interrupts.
TMR0 interrupt controls the ADC start (GO=1), TMR1 interrupt controls the game over and blink session after that, TMR2 interrupt controls the RB4 debouncing (if still pressed after 10ms rb4_handled()),
RB interrupt controls the RB4 button pressed and released, ADC interrupt controls the ADC. */

#pragma config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

#include <xc.h>
#include "breakpoints.h"

volatile char special;
volatile int adc_value;

unsigned char tmr0_ADC_counter = 0; //when been 10, ADC readings (per 50ms)
unsigned char tmr1_5s_counter = 0; //when been 100, game over (50ms*100=5s)
unsigned char tmr1_50ms_counter = 0; //when been 10
unsigned char tmr2_counter = 0;
unsigned int userValue = 10;
unsigned char segment_value=10;
unsigned char pressed;
unsigned char blink=1;
unsigned char blink_counter=0;
unsigned int isOver=0;
unsigned int isCorrect=0;
void reset();
void gameOver();
void update7Segment();

void init(){
    reset(); //reset all
    GIE = 0; // Disable interrupts   
    PEIE = 0; // Disable peripheral interrupt
    INTCON = 0; //clear intcon
        
    /* Inputs/Outputs */
    ADCON1 = 0; //pins analog
    TRISB = 0;
    TRISB4 = 1; //RB4 is input
    TRISC = 0;
    TRISD = 0;
    TRISE = 0;    
    RBIE = 1; // Enable port b trigger on change interrupt
    RBIF = 0; // Clear RB interrupt flag
    
    /* Timer0 */
    T0CON = 0;      // clear t0con
    TMR0IE = 1;     //enable timer0
    T08BIT = 1;     // make t0 8bit
    PSA = 0;        // enable prescaler
    T0PS0 = T0PS1 = T0PS2 = 1;  //prescaler : 256
    TMR0 = 61;     //start value (5ms)
    TMR0IF = 0;       //clear tmr0 flag
    TMR0ON = 1;     //Enable Timer0 to start ADC acquisition
    
    /* Timer1 */
    T1CON = 0;
    TMR1IE = 1;     //enable tmr1
    T1CKPS0 = T1CKPS1 = 1; // Prescaler 1:8
    TMR1L = 220;    //preload with 3036 so that we have 8*62500 = 500000clockcycles (50ms)
    TMR1H = 11;
    TMR1IF = 0;
    TMR1ON = 1;     //tmr1 is on
    
    /* Timer2 */
    T2CKPS1 =0; T2CKPS0 =1; //prescaler 1:4
    
    /* ADC */
    ADCON0 = 0x30; //channel 12
    ADIE = 1; // Enable ADC interrupt   
    ADCON2 = 0x82; //right justified - 0 t_ad - f_osc/32
    ADIF = 0; //clear interrupt flag
    ADON = 1; //enabled
    
    /* 7-Segment */
    TRISH = 0xF0; // PORTH<3:0> is used as output
    TRISJ = 0; // All of PORTJ is used as output
    
    GIE = 1; // Enable interrupts   
    PEIE = 1; // Enable peripheral interrupt
    
    init_complete();
}

void __interrupt() my_isr() {
    if (TMR1IE && TMR1IF) { //tmr1 interrupt
        tmr1_50ms_counter++;
        if(tmr1_50ms_counter == 10){ //500ms
            blink=!blink;
            hs_passed();
            
            if(isCorrect || isOver){ //blink session is here
                if(blink && blink_counter!=4){
                    segment_value=special_number();
                    update7Segment();
                }
                if(!blink && blink_counter!=4){
                    segment_value=10;
                    update7Segment(); 
                }
            }
         
            tmr1_5s_counter++;
            tmr1_50ms_counter = 0;
            blink_counter++;
        }
        if(tmr1_5s_counter == 10){ //5s
            isOver=1;
            // gameOver(); //our gameover func
            //game_over();
        }
        TMR1L = 220;
        TMR1H = 11;
        TMR1IF = 0; //clear interrupt flag
    }
    if (TMR0IE && TMR0IF) { //tmr0 interrupt
        tmr0_ADC_counter++;
        if(tmr0_ADC_counter == 10){
            tmr0_ADC_counter = 0; //reset
            GO = 1; //start ADC
        }
        TMR0L = 61; //count again 61 to 255
        TMR0IF = 0; //clear interrupt flag
    }
    if (RBIE && RBIF) {
        /* 1.read portB 2.clear flag */
        unsigned char a = PORTBbits.RB4;
        RBIF = 0; //clear flag
        
        /////////////////
        if(!pressed){  //if pressed
            if(a){
                TMR2 = 0;  //start value (10ms)
                TMR2ON = 1; //start tmr2
                TMR2IE = 1; //enable tmr2 interrupt
            }
            else{
                TMR2 = 0;  
                TMR2ON = 0; //stop tmr2
                TMR2IE = 0; //disable tmr2 interrupt
            }
        }
        else if(pressed){ //if released
            if(a){
                TMR2 = 0;
                TMR2ON = 0;
                TMR2IE = 0;
                
            }
            else{  
                TMR2 = 0;
                TMR2ON = 1;
                TMR2IE = 1;
            }
        }
         /////////////////////////
        
    }
    if(TMR2IE && TMR2IF){
        TMR2IF = 0; //clear flag
        tmr2_counter++;
        if(tmr2_counter == 95){ //if still pressed after 10ms go in
            if(!pressed){
                if(PORTBbits.RB4){
                    rb4_handled();
                    latcde_update_complete();

                    ///////////////
                if(adc_value <= 102){ //arrange adc_value
                    userValue=0;
                }
                else if(adc_value <= 204){
                    userValue=1;
                }
                else if(adc_value <= 306){
                    userValue=2;
                }
                else if(adc_value <= 408){
                    userValue=3;
                }
                else if(adc_value <= 510){
                    userValue=4;
                }
                else if(adc_value <= 612){
                    userValue=5; 
                }
                else if(adc_value <= 714){
                    userValue=6;
                }
                else if(adc_value <= 816){
                    userValue=7;
                }
                else if(adc_value <= 918){
                    userValue=8;
                }
                else if(adc_value <= 1023){
                    userValue=9;
                }
                /////////////// 
                    pressed = 1;
                }
                tmr2_counter = 0;
                TMR2ON = 0;
                TMR2IE = 0;
            }
            else if(pressed){
                if(!PORTBbits.RB4){
                    pressed = 0;
                }
                tmr2_counter = 0;
                TMR2ON = 0;
                TMR2IE = 0;
            }
        }
        TMR2=0;//start count again
    }
    if (ADIF && ADIE) {
        ADIF = 0; //clear interrupt flag
        adc_value = (ADRESH << 8) | ADRESL; //read value after ADC as decimal
        adc_complete();
        
        ///////////////
            if(adc_value <= 102){ //arrange segment_value
                segment_value=0;
            }
            else if(adc_value <= 204){
                segment_value=1;
            }
            else if(adc_value <= 306){
                segment_value=2;
            }
            else if(adc_value <= 408){
                segment_value=3;
            }
            else if(adc_value <= 510){
                segment_value=4;
            }
            else if(adc_value <= 612){
                segment_value=5; 
            }
            else if(adc_value <= 714){
                segment_value=6;
            }
            else if(adc_value <= 816){
                segment_value=7;
            }
            else if(adc_value <= 918){
                segment_value=8;
            }
            else if(adc_value <= 1023){
                segment_value=9;
            }
            /////////////// 
          update7Segment();
    }
}

void gameOver(){
     ADIE=0;
     RBIE=0;
     TMR0IE=0;
     TMR1L = 220;
     TMR1H = 11;
     TMR1IF = 0; //clear interrupt flag
     PORTC = 0;
     PORTD = 0;
     PORTE = 0;
     TMR2IE=0;
     TMR2IF=0;
     blink_counter=0;
     blink=0;
     tmr1_50ms_counter=0;
     tmr1_5s_counter=0;
     tmr2_counter = 0;
     tmr1_50ms_counter=9;
     TMR1IF = 1;
     while(1){ //infinite loop until blink session is end
         if(blink_counter == 5){
            latcde_update_complete();
             break;
         }
         
     }
     
     init();
     restart();
}

void reset(){ //reset all variables as default
    tmr0_ADC_counter = tmr1_5s_counter = tmr1_50ms_counter = tmr2_counter = 0;
    userValue = 10;
    isOver=0;
    isCorrect=0;
    //pressed = 0;
    segment_value=10;
    //PORTB = 0;
    PORTC = 0;
    PORTD = 0;
    PORTE = 0;
    latcde_update_complete();
}

void upArrow(){
    //firstly reset all
    /*PORTC = 0;
    PORTD = 0;
    PORTE = 0;*/
    
    PORTC = 0x02;
    PORTD = 0x0F;
    PORTE = 0x02;
    latcde_update_complete();
}

void downArrow(){
    //firstly reset all
    /*PORTC = 0;
    PORTD = 0;
    PORTE = 0;*/
    
    PORTC = 0x04;
    PORTD = 0x0F;
    PORTE = 0x04;
    latcde_update_complete();
}

unsigned char get7SegmentValues(unsigned char c){ //helper to arrange 7segment value
    switch(c){
        case 0: return 0x3F;
        case 1: return 0x06;
        case 2: return 0x5B;
        case 3: return 0x4F;
        case 4: return 0x66;
        case 5: return 0x6D;
        case 6: return 0x7D;
        case 7: return 0x07;
        case 8: return 0x7F;
        case 9: return 0x67;
        case 10:return 0x00;
    }    
    return 0x00;
}

void update7Segment() { //update 7segment as segment_value
    LATH = 0x0F & 8; //select D0 (rightmost bit)
    LATJ = get7SegmentValues(segment_value);
    latjh_update_complete();
}

void main(void) {
    init();
    while(1){ //infinite loop so game is processing until shut down
        if(isOver==1){
            game_over();
            gameOver();
        }
        if(userValue!=10){ //userValue=10 is default because it can be between 0 and 9
            if(userValue == special_number()){ 
                isCorrect=1; //user win the game
                correct_guess();
                gameOver();
            }   
            else if(userValue > special_number()){
                downArrow();
            }
            else if(userValue < special_number()){
                upArrow();
            }
        }
        
        
        
    }
    return;
}
