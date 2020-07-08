;Tolgahan KURTDERE
    
LIST    P=18F8722

#INCLUDE <p18f8722.inc> 
    
CONFIG OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

 hp   udata 0X20
 hp
 level  udata 0X21
 level
 ballNumber udata 0X22
 ballNumber
 tmr0_counter udata 0X23
 tmr0_counter
 tempT1L    udata 0X24
 tempT1L
 tempT1H    udata 0X25
 tempT1H
 temp_bar   udata 0X26
 temp_bar
 L1	udata 0X27
 L1
 L2	udata 0X28
 L2

org	 0x00
goto	 init
 
org	0x08
goto	isr

init:
    clrf    INTCON
    movlw   b'01000111' ;Disable Timer0 by setting TMR0ON to 0 (for now)
			;Configure Timer0 as an 8-bit timer/counter by setting T08BIT to 1
			;Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON
    

    movlw h'00' ;RA RB RC RD are output
    movwf TRISA
    clrf PORTA
    movwf TRISB
    clrf PORTB
    movwf TRISC
    clrf PORTC
    movwf TRISD
    clrf PORTD
    
    clrf TRISH
    clrf TRISJ


    clrf    LATA
    clrf    LATB
    clrf    LATC
    clrf    LATD
    clrf    LATE
    clrf    LATF
    clrf    LATG
    clrf    LATH
    clrf    LATJ

    setf    ADCON1	;ra is all digital

    movlw b'00001101' ;RG0 RG2 RG3 are input
    movwf TRISG
    clrf LATG
    clrf PORTG

    movlw d'5'
    movwf hp

    movlw d'1'
    movwf level

    movlw d'0'
    movwf ballNumber
    movwf temp_bar
    
    clrf tmr0_counter

    movlw b'00100000'
    movwf LATA
    movwf LATB
		
    movlw   b'11100000'
    movwf   INTCON
    movlw   B'10001001'
    movwf   T1CON
    
    call    level_segment
    call    hp_segment
    
main:
    startpress:
	btfss   PORTG, 0	;check if rg0 pressed
	goto    startpress	;skip if pressed

    startrelease:
	btfsc   PORTG, 0	;check if rg0 released
	goto    startrelease    ;skip if released
	movlw	D'0'
	movwf	tmr0_counter
	movff	TMR1L, tempT1L
	movff	TMR1H, tempT1H
	bsf     T0CON, 7    ;Enable Timer0 by setting TMR0ON to 1
	goto	game_loop
	
game_loop:
    tstfsz  tmr0_counter
    goto    move_bar
    
    call    collision_check
    call    move_balls
    call    hp_check
    call    create_ball
    call    is_over
    call    level_check
    call    level_segment
    call    hp_segment
    
finish_game_loop:
    goto    game_loop
    
;############## ISR #############    
isr:
    btfss   INTCON, 2       ;Is this a timer interrupt?
    goto    finish    ;No. Goto finish
    goto    timer0_interrupt ;Yes. Goto timer interrupt handler part
finish:
    retfie

timer0_interrupt:
    bcf	    INTCON, 2
    decf    tmr0_counter
    movlw   D'61'
    movwf   TMR0
    retfie
    
    
    
;################ HELPERS #################
move_bar:
    rightleft:  ;pressed rg2 or rg3 or nothing
	btfsc   PORTG, 2
	goto    rightmove
	btfsc   PORTG, 3
	goto    leftmove
	goto	game_loop
	
    rightmove:
	releaseright:
	    btfsc   PORTG, 2
	    goto    releaseright

	movlw   d'0'
	cpfseq  temp_bar
	goto	orta_veya_sag
	goto    ensolda 
	orta_veya_sag:
	    movlw   d'1'
	    cpfseq  temp_bar
	    goto    ensagda
	    goto    ortada
	    ensolda:
		bcf	PORTA, 5
		bsf	PORTC, 5
		movlw	d'1'
		movwf	temp_bar
		goto    rightleft

	    ensagda:
		goto    rightleft

	    ortada:
		bcf	PORTB, 5
		bsf	PORTD, 5
		movlw	d'2'
		movwf	temp_bar
		goto    rightleft

    leftmove:
	releaseleft:
	    btfsc   PORTG, 3
	    goto    releaseleft

	movlw   d'0'
	cpfseq  temp_bar
	goto	orta_veya_sag1
	goto    ensolda1
	orta_veya_sag1:
	    movlw   d'1'
	    cpfseq  temp_bar
	    goto    ensagda1
	    goto    ortada1
	    ensolda1:
		goto    rightleft

	    ensagda1:
		bcf	PORTD, 5
		bsf	PORTB, 5
		movlw	d'1'
		movwf	temp_bar
		goto    rightleft

	    ortada1:
		bcf	PORTC, 5
		bsf	PORTA, 5
		movlw	d'0'
		movwf	temp_bar
		goto    rightleft
    
;##############################################
create_ball:
    movlw   d'30'
    cpfslt  ballNumber
    return
    tstfsz  ballNumber
    goto    not_first_ball
    goto    first_ball
    
    first_ball:
	INCF    ballNumber
	btfss   tempT1L, 0
	goto    a_veya_c
	goto    b_veya_d

	b_veya_d:
	    btfss   tempT1L, 1
	    goto    b
	    goto    d
	    d:
		bsf	PORTD, 0
		return
	    b:
		bsf	PORTB, 0
		return
	a_veya_c:
	    btfss   tempT1L, 1
	    goto    a
	    goto    c
	    a:
		bsf	PORTA, 0
		return
	    c:
		bsf	PORTC, 0
		return
		
    not_first_ball:
	movlw   d'1'
	cpfsgt  level
	goto    shift1
	movlw   d'2'
	cpfsgt  level
	goto    shift3
	goto    shift5
	shift1:
	    rrcf    tempT1L
	    btfss   STATUS, 0
	    goto    no_carry_low
	    goto    yes_carry_low
	    
	    no_carry_low:
		bcf	tempT1L, 7
		rrcf	tempT1H
		btfss   STATUS, 0
		goto	first_ball
		bcf	tempT1H, 7
		bsf	tempT1L, 7
		goto	first_ball
	    yes_carry_low:
		bcf	tempT1L, 7
		rrcf	tempT1H
		btfss   STATUS, 0
		goto	no_carry_high
		bsf	tempT1H, 7
		bsf	tempT1L, 7
		goto	first_ball
		no_carry_high:
		    bsf	    tempT1H, 7
		    goto    first_ball
	shift3:
	    call    shift_one_time
	    call    shift_one_time
	    call    shift_one_time
	    goto    first_ball
	shift5:
	    call    shift_one_time
	    call    shift_one_time
	    call    shift_one_time
	    call    shift_one_time
	    call    shift_one_time
	    goto    first_ball
	shift_one_time:
	    rrcf    tempT1L
	    btfss   STATUS, 0
	    goto    no_carry_low1
	    goto    yes_carry_low1
	    no_carry_low1:
		bcf	tempT1L, 7
		rrcf	tempT1H
		btfss   STATUS, 0
		return
		bcf	tempT1H, 7
		bsf	tempT1L, 7
		return
	    yes_carry_low1:
		bcf	tempT1L, 7
		rrcf	tempT1H
		btfss   STATUS, 0
		goto	no_carry_high1
		bsf	tempT1H, 7
		bsf	tempT1L, 7
		return
		no_carry_high1:
		    bsf	    tempT1H, 7
		    return
;##########################################
level_check:
    movlw   d'4'  ;said 4 and 14 because cpfsgt is used
    cpfsgt  ballNumber
    goto    l1
    movlw   d'14'
    cpfsgt  ballNumber
    goto    l2
    goto    l3
    
    l1:
	movlw   d'1'
	movwf	level
	goto	set_500ms
    l2:
	movlw   d'2'
	movwf	level
	goto	set_400ms
    l3:
	movlw   d'3'
	movwf	level
	goto	set_350ms
		  
;########################################
    move_balls:
	movlw   d'0'
	cpfsgt  temp_bar
	goto    move_ball1
	movlw   d'1'
	cpfsgt  temp_bar
	goto    move_ball2
	goto    move_ball3
	move_ball1:
	   rlncf PORTA
	   rlncf PORTB
	   rlncf PORTC
	   rlncf PORTD
	   bsf  PORTA,5
	   bsf	PORTB,5
	   bcf	PORTA,6
	   bcf	PORTB,6
	   bcf	PORTC,6
	   bcf	PORTD,6
	   return 
	move_ball2:
	   rlncf PORTA
	   rlncf PORTB
	   rlncf PORTC
	   rlncf PORTD
	   bsf  PORTB,5
	   bsf	PORTC,5 
	   bcf	PORTA,6
	   bcf	PORTB,6
	   bcf	PORTC,6
	   bcf	PORTD,6
	   return
	move_ball3:
	   rlncf PORTA
	   rlncf PORTB
	   rlncf PORTC
	   rlncf PORTD
	   bsf  PORTC,5
	   bsf	PORTD,5
	   bcf	PORTA,6
	   bcf	PORTB,6
	   bcf	PORTC,6
	   bcf	PORTD,6
	   return
;########################################
    collision_check:
	movlw   d'0'
	cpfsgt  temp_bar
	goto    collision_check1
	movlw   d'1'
	cpfsgt  temp_bar
	goto    collision_check2
	goto    collision_check3
	collision_check1:
	    btfsc   PORTC,5
	    decf    hp
	    btfsc   PORTD,5
	    decf    hp
	    return
	collision_check2:
	    btfsc   PORTA,5
	    decf    hp
	    btfsc   PORTD,5
	    decf    hp
	    return
	collision_check3:
	    btfsc   PORTA,5
	    decf    hp
	    btfsc   PORTB,5
	    decf    hp
	    return
	    
;########################################
hp_check:
    tstfsz  hp
    return
    goto    init
;########################################
is_over:
    movlw   d'0'
    cpfsgt  temp_bar
    goto    is_over1
    movlw   d'1'
    cpfsgt  temp_bar
    goto    is_over2
    goto    is_over3
    is_over1:
	tstfsz	PORTC
	return
	tstfsz	PORTD
	return
	btfsc	PORTA, 0
	return
	btfsc	PORTA, 1
	return
	btfsc	PORTA, 2
	return
	btfsc	PORTA, 3
	return
	btfsc	PORTB, 0
	return
	btfsc	PORTB, 1
	return
	btfsc	PORTB, 2
	return
	btfsc	PORTB, 3
	return
	goto	init
    is_over2:
	tstfsz	PORTA
	return
	tstfsz	PORTD
	return
	btfsc	PORTC, 0
	return
	btfsc	PORTC, 1
	return
	btfsc	PORTC, 2
	return
	btfsc	PORTC, 3
	return
	btfsc	PORTB, 0
	return
	btfsc	PORTB, 1
	return
	btfsc	PORTB, 2
	return
	btfsc	PORTB, 3
	return
	goto	init
    is_over3:
	tstfsz	PORTA
	return
	tstfsz	PORTB
	return
	btfsc	PORTC, 0
	return
	btfsc	PORTC, 1
	return
	btfsc	PORTC, 2
	return
	btfsc	PORTC, 3
	return
	btfsc	PORTD, 0
	return
	btfsc	PORTD, 1
	return
	btfsc	PORTD, 2
	return
	btfsc	PORTD, 3
	return
	goto	init
;########################################
    level_segment:
	movlw   d'1'
	cpfsgt  level
	goto    level_1
	movlw   d'2'
	cpfsgt  level
	goto    level_2
	goto    level_3
	level_1:
    	    bsf LATH,0
	    bcf	LATH,3
	    bcf	LATH,1
	    bcf	LATH,2
	    movlw b'00000110' 
	    movwf PORTJ
	    call  DELAY
	    return    
	level_2:
	    bsf PORTH,0
	    bcf	PORTH,3
	    bcf	PORTH,1
	    bcf	PORTH,2
	    movlw b'01011011' 
	    movwf PORTJ
	    call  DELAY
	    return
	level_3:
	    bsf PORTH,0
	    bcf	PORTH,3
	    bcf	PORTH,1
	    bcf	PORTH,2
	    movlw b'01001111'
	    movwf PORTJ
	    call    DELAY
	    return
;################################################
    hp_segment:
	movlw	d'0'
	cpfsgt  hp
	goto	hp_0
	movlw   d'1'
	cpfsgt  hp
	goto    hp_1
	movlw   d'2'
	cpfsgt  hp
	goto    hp_2
	movlw	d'3'
	cpfsgt  hp
	goto    hp_3
	movlw	d'4'
	cpfsgt  hp
	goto	hp_4
	goto	hp_5
	
	hp_0:
	    return
	hp_1:
	    bsf PORTH,3
	    bcf	PORTH,0
	    bcf	PORTH,1
	    bcf	PORTH,2
	    movlw b'00000110' 
	    movwf PORTJ
	    call  DELAY
	    return
	hp_2:
    	    bsf PORTH,3
	    bcf	PORTH,0
	    bcf	PORTH,1
	    bcf	PORTH,2
	    movlw b'01011011' 
	    movwf PORTJ
	    call  DELAY
	    return
	hp_3:
	    bsf PORTH,3
	    bcf	PORTH,0
	    bcf	PORTH,1
	    bcf	PORTH,2
	    movlw b'01001111' 
	    movwf PORTJ
	    call  DELAY
	    return    
	hp_4:
	    bsf PORTH,3
	    bcf	PORTH,0
	    bcf	PORTH,1
	    bcf	PORTH,2
	    movlw b'01100110' 
	    movwf PORTJ
	    call  DELAY
	    return
	hp_5:
	    bsf PORTH,3
	    bcf	PORTH,0
	    bcf	PORTH,1
	    bcf	PORTH,2
	    movlw b'01101101' 
	    movwf PORTJ
	    call  DELAY
	    return
;#########################################
set_500ms:
    movlw   D'100'
    movwf   tmr0_counter
    return
    
set_400ms:
    movlw   D'80'
    movwf   tmr0_counter
    return
    
set_350ms:
    movlw   D'70'
    movwf   tmr0_counter
    return
;#######################################
DELAY:                          ; Time Delay Routines
    movlw d'150'                     ; Copy 150 to W
    movwf L2                    ; Copy W into L2

LOOP2:
    movlw d'255'                  ; Copy 255 into W
    movwf L1                    ; Copy W into L1

LOOP1:
    decfsz L1,F                    ; Decrement L1. If 0 Skip next instruction
        goto LOOP1                ; ELSE Keep counting down
    decfsz L2,F                    ; Decrement L2. If 0 Skip next instruction
        goto LOOP2                ; ELSE Keep counting down
    return
end
