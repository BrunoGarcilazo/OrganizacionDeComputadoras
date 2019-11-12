
 __CONFIG _CONFIG1 & _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF & _CONFIG2 & _BOR4V_BOR21V & _WRT_OFF
;Organizacion de la memoria de datos 
cblock 0x20	;Comienzo a escribir la memoria de datos en la dirección 0x20
    leds
    numero
    numero2
    segundosRestantes
    auxW
endc

;Organizacion de la memoria de programacion
org 0x0000
    goto main

org 0x0004
    goto interrupt
    



    

main
    bsf INTCON,6        ;Configura el peie; PEIE: Peripheral Interrupt Enable bit 
    movlw D'5'
    movwf segundosRestantes 
    MOVLW B'11111111'
    MOVWF leds
    
    
    banksel PIE1 ;Enable de las interrupciones ADC
    bsf PIE1,6
    
    banksel PORTA
    clrf PORTA
    
    banksel TRISA ;Pone RA0 como entrada
    MOVLW b'00000001'
    MOVWF TRISA
    
    banksel TRISE
    MOVLW b'11111001'
    MOVWF TRISE
    
    banksel PORTE
    movlw b'00000100'
    movwf PORTE
    
    banksel ANSEL ;Setea RA0 a analogo
    bsf ANSEL,0
    
    banksel ADCON1
    bcf ADCON1,7
    
    banksel ADCON0
    movlw b'10000001'
    movwf ADCON0
    
    banksel TRISD ;Habilitamos las luces.
    clrf TRISD
    
    banksel PORTD
    clrf PORTD
    call configurar
    goto reiniciar

reiniciar
    BANKSEL ADCON0
    bsf ADCON0, GO ; Empieza la conversion
    BTFSC ADCON0, GO ; Termino la conversion?
    goto $-1 ; No, chequear otra vez.
    BANKSEL ADRESH ;
    MOVF ADRESH, W  
    banksel leds
    movwf leds
    movwf numero
    MOVLW b'00111100'
    ANDWF numero,w
    movwf numero
    
    SWAPF leds,f
    RRF leds,f
    MOVLW b'00000111'
    ANDWF leds,w

    call convertir
    BANKSEL PORTD
    movwf PORTD
    
    
    clrf numero2
    btfsc numero,2
    bsf numero2,2
    btfsc numero,3
    bsf numero2,5
    btfsc numero,4
    bsf numero2,4
    
    clrf numero
    btfsc leds,0
    bsf numero,2
    btfsc leds,1
    bsf numero,5
    btfsc leds,2
    bsf numero,4

    goto reiniciar
    
convertir ; Funcion para "llenar de ceros" el numero devuelto por el conversor A/D. Ej: 00001010 -> 00001111
    BANKSEL PCL
    ADDWF PCL
    retlw b'00000000'
    retlw b'00000001'
    retlw b'00000011'
    retlw b'00000111'
    retlw b'00001111'
    retlw b'00011111'
    retlw b'00111111'
    retlw b'01111111'
    
mostrarIzq
    banksel PORTE
    btfsc PORTE,1
    return
    bsf PORTE,1
    bcf PORTE,2
    banksel PORTA
    movf numero2,w
    movwf PORTA
    return
    
mostrarDer
    banksel PORTE
    btfsc PORTE,2
    return
    bsf PORTE,2
    bcf PORTE,1
    banksel PORTA
    movf numero,w
    movwf PORTA
    return
    
    
;Funcion que, setea los valores en el timer para crear intervalos de 100 ms.
configurar
    movlw b'11100000'
    banksel INTCON
    movwf INTCON
    
    banksel OPTION_REG
    movlw b'00000110'
    movwf OPTION_REG
    
    return
    
;Funcion utilizada como interrupcion cuando el timer, llega a 100 ms
interrupt
    banksel auxW        ;Guardamos lo que traia W en aux W
    movwf auxW
    
    banksel PIR1
    clrf PIR1
    
    bcf INTCON, 2
    
    
    call mostrarDer
    call mostrarIzq
    banksel auxW        ;Devolvemos el valor que tenia W
    movf auxW,w
    retfie
    
END



