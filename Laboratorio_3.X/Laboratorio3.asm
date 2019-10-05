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
endc

;Organizacion de la memoria de programacion
org 0x0000
    goto main



main
;Configuraçao:
    
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
    MOVLW b'00000110'
    MOVWF PORTE
    
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
    MOVLW b'00111111'
    ANDWF numero,w
    movwf numero
    
    SWAPF leds,f
    RRF leds,f
    MOVLW b'00000111'
    ANDWF leds,w

    call convertir
    BANKSEL PORTD
    movwf PORTD
    
    RLF numero,f
    RLF numero,f
    movf numero,w
    BANKSEL PORTA
    movwf PORTA

    
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
    
    
__main
    
END



