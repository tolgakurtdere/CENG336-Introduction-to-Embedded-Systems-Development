;Tolgahan KURTDERE

LIST    P=18F8722

#INCLUDE <p18f8722.inc> 
    
CONFIG OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

 counter   udata 0X20
 counter
 dataportb  udata 0X21
 dataportb
 dataportc  udata 0X22
 dataportc
 result   udata 0X23
 result
 
 UDATA_ACS ; get coppied from recit2
  t1	res 1	; used in delay
  t2	res 1	; used in delay
  t3	res 1	; used in delay

ORG     0x00
goto    main
 
DELAY	; Time Delay Routine with 3 nested loops
    MOVLW 82	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    _loop3:
	MOVLW 0xA0  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	_loop2:
	    MOVLW 0x9F	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    _loop1:
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO _loop1 ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO _loop2 ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO _loop3 ; ELSE Keep counting down
		return

init
movlw b'00010000' ;RA4 is an input
movwf TRISA
clrf LATA
clrf PORTA
 
movlw b'00011000' ;RE3 and RE4 are input
movwf TRISE
clrf LATE
clrf PORTE

movlw h'00' ;B C D are output
movwf TRISB
clrf  LATB
movwf TRISC
clrf  LATC
movwf TRISD
clrf  LATD
		
movlw h'00'
movwf counter
		
movlw h'00'
movwf dataportb
		
movlw h'00'
movwf dataportc
		
movlw h'00'
movwf result

;one second delay at the beginning		
movlw h'0F'  
movwf LATB
movwf LATC
movlw h'FF'
movwf LATD
call DELAY

clrf PORTB
clrf PORTC
clrf PORTD
		
return
		
		
press:
    btfss   PORTA, 4	;check if ra4 pressed
    goto    press	;skip if pressed
    INCF    counter
release:
    btfsc   PORTA, 4	;check if ra4 released
    goto    release	;skip if released
    goto    pressloop
    
pressloop:
    btfsc   PORTA, 4
    goto    press
    btfsc   PORTE, 3
    goto    port_b
    goto    pressloop
    
port_b:
    release1:
	btfsc   PORTE, 3 ;check if re3 released
	goto    release1
    
    pressloop1:  ;have to press re3 or re4
	btfsc   PORTE, 3
	goto    port_c
	btfsc   PORTE, 4
	goto    takeinput1
	goto    pressloop1
    
    takeinput1:
	release2:
	    btfsc   PORTE, 4 ;check if re4 released
	    goto    release2
    
	btfss   PORTB, 0
	goto    b0
	btfss   PORTB, 1
	goto    b1
	btfss   PORTB, 2
	goto    b2
	btfss   PORTB, 3
	goto    b3
	
	goto    cleardata1  ;after 5 presses data should get clear
	
	cleardata1: 
	    clrf PORTB
	    clrf dataportb
	    goto pressloop1
	
	b0:
	    INCF dataportb
	    bsf PORTB, 0
	    goto pressloop1
	    
	b1:
	    INCF dataportb
	    bsf PORTB, 1
	    goto pressloop1
	    
	b2:
	    bsf PORTB, 2
	    INCF dataportb
	    goto pressloop1
	    
	b3:
	    bsf PORTB, 3
	    INCF dataportb
	    goto pressloop1
	    
	
port_c:
    release3:
	btfsc   PORTE, 3 ;check if re3 released
	goto    release3
    
    pressloop2:  ;have to press re3 or re4
	btfsc   PORTE, 3
	goto    port_d
	btfsc   PORTE, 4
	goto    takeinput2
	goto    pressloop2
	
	
    takeinput2:
	release4:
	    btfsc   PORTE, 4 ;check if re4 released
	    goto    release4
    
	btfss   PORTC, 0
	goto    c0
	btfss   PORTC, 1
	goto    c1
	btfss   PORTC, 2
	goto    c2
	btfss   PORTC, 3
	goto    c3
	
	goto    cleardata2 ;after 5 presses data should get clear
	
	cleardata2: 
	    clrf PORTC
	    clrf dataportc
	    goto pressloop2
	
	c0:
	    INCF dataportc
	    bsf PORTC, 0
	    goto pressloop2
	    
	c1:
	    INCF dataportc
	    bsf PORTC, 1
	    goto pressloop2
	    
	c2:
	    bsf PORTC, 2
	    INCF dataportc
	    goto pressloop2
	    
	c3:
	    bsf PORTC, 3
	    INCF dataportc
	    goto pressloop2
	    
    
port_d:
    release5: ;check if re3 released
	btfsc PORTE, 3
	goto release5
	
    btfss counter, 0 ;press number of ra4 is odd or even
    goto substraction
    goto addition
    
addition:
    movf    dataportb, w
    addwf   dataportc
    movf    dataportc, w
    addwf   result
    
    res0:
	movlw	h'00'
	cpfseq	result
	goto	res1
	movlw	b'00000000'
	movwf	LATD
	goto	exit
	
    res1:
	movlw	h'01'
	cpfseq	result
	goto	res2
	movlw	b'00000001'
	movwf	LATD
	goto	exit
	
    res2:
	movlw	h'02'
	cpfseq	result
	goto	res3
	movlw	b'00000011'
	movwf	LATD
	goto	exit
    res3:
	movlw	h'03'
	cpfseq	result
	goto	res4
	movlw	b'00000111'
	movwf	LATD
	goto	exit
    res4:
	movlw	h'04'
	cpfseq	result
	goto	res5
	movlw	b'00001111'
	movwf	LATD
	goto	exit
    res5:
	movlw	h'05'
	cpfseq	result
	goto	res6
	movlw	b'00011111'
	movwf	LATD
	goto	exit
    res6:
	movlw	h'06'
	cpfseq	result
	goto	res7
	movlw	b'00111111'
	movwf	LATD
	goto	exit
    res7:
	movlw	h'07'
	cpfseq	result
	goto	res8
	movlw	b'01111111'
	movwf	LATD
	goto	exit
    res8:
	movlw	h'08'
	cpfseq	result
	goto	res1
	movlw	b'11111111'
	movwf	LATD
	goto	exit
    
    
substraction:    
    movf    dataportc, w
    cpfsgt  dataportb ;Compare f with WREG, Skip >
    goto    case1
    goto    case2

case1: ;dataportb < dataportc
    movf    dataportb, w
    subwf   dataportc
    movf    dataportc, w
    addwf   result
    goto    res0
    
    
case2: ;dataportb > dataportc
    subwf   dataportb
    movf    dataportb, w
    addwf   result
    goto    res0
    
    
exit: ;clear everthing when done
    call DELAY
    clrf counter
    clrf dataportb
    clrf dataportc
    clrf result
    clrf PORTB
    clrf PORTC
    clrf PORTD
    
loop:
    goto press
    goto loop
main:
    call init
    goto loop
end
