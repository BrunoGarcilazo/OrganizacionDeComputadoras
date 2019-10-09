; PIC16F887 Configuration Bit Settings
; Assembly source line config statements
#include "p16f887.inc"
    
; Bits de configuracion

; CONFIG1
; __config 0xE0C2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
 
;Organizacion de la memoria de datos 
cblock 0x20	;Comienzo a escribir la memoria de datos en la direcciÃ³n 0x20
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
;Configuraçao:  
    
    movlw D'5'
    movwf segundosRestantes 
    MOVLW B'11111111'
    MOVWF leds
    
    banksel PIR1
    bcf PIR1,6 ;Deja el flag del conversor en 0
    
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
    retlw b'00000001'
    retlw b'00000011'
    retlw b'00000111'
    retlw b'00001111'
    retlw b'00011111'
    retlw b'00111111'
    retlw b'01111111'
    retlw b'11111111'
    
intercalar
    banksel PORTE
    btfsc PORTE,1
    btfss PORTE,1
    bsf PORTE,1
    bcf PORTE,1
    banksel PORTA
    movf numero2,w
    movwf PORTA
    banksel PORTE
    btfsc PORTE,2
    btfss PORTE,2
    bsf PORTE,2
    bcf PORTE,2
    banksel PORTA
    movf numero,w
    movwf PORTA
    return
    
;Funcion que, setea los valores en el timer para crear intervalos de 100 ms.
configurar
    banksel T1CON ;Configuracion del registro de timer 1 (Ver dataSheet pag: 81).
    movlw b'00010101'
    movwf T1CON
    
    ;Antes de habilitar las interrupciones hay que hacer clear del reloj
    banksel TMR1H
    movlw b'11000000'
    movwf TMR1H
    
    banksel TMR1L       ;Ponemos a cero el registro TMR1H: Holding Register for the Most Significant Byte of the 16-bit TMR1 Register
    clrf TMR1L
    
    banksel PIR1        
    bcf PIR1,0	        ;TMR1IF: Timer1 Overflow Interrupt Flag bit ;1 =   The TMR1 register overflowed (must be cleared in software); 0 =   The TMR1 register did not overflow
    
    banksel PIE1        ;Configura el pie.
    bsf PIE1,0          ;TMR1IE: Timer1 Overflow Interrupt Enable bit
    
    bsf INTCON,6        ;Configura el peie; PEIE: Peripheral Interrupt Enable bit 
    bsf INTCON,7        ;Configura el Gie; GIE: Global Interrupt Enable bit
    
    return
    
;Funcion utilizada como interrupcion cuando el timer, llega a 100 ms
interrupt
    banksel auxW        ;Guardamos lo que traia W en aux W
    movwf auxW
    
    ;Clear al Timer
    banksel TMR1H       ;Ponemos a cero el registro TMR1H: Holding Register for the Most Significant Byte of the 16-bit TMR1 Register
    movlw b'11000000'
    movwf TMR1H
    
    banksel TMR1L       ;Ponemos a cero el registro TMR1L: Holding Register for the Least Significant Byte of the 16-bit TMR1 Register
    clrf TMR1L          
    
    banksel PIR1
    clrf PIR1        ;Ponemos a cero el registro TMR1IF: Timer1 Overflow Interrupt Flag bit

    
    bsf INTCON,6        ;Configura el peie; PEIE: Peripheral Interrupt Enable bit 

    call intercalar
    banksel auxW        ;Devolvemos el valor que tenia W
    movf auxW,w
    retfie
    
END



