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
    contador
    unos
    boolean
endc

;Organizacion de la memoria de programacion
org 0x0000
    goto main

org 0x0004
    goto interrupt

main
;Configuraçao:
    
    MOVLW B'11111111'
    MOVWF unos
    
    banksel PIR1
    bcf PIR1,6 ;Deja el flag del conversor en 0
    
    banksel PIE1 ;Enable de las interrupciones ADC
    bsf PIE1,6
    
    
    banksel TRISA ;Pone RA0 como entrada
    bsf TRISA,0
    
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
    
    bsf ADCON0, GO ; Empieza la conversion
    BTFSC ADCON0, GO ; Termino la conversion?
    GOTO $-1 ; No, chequear otra vez.
    BANKSEL ADRESH ;
    MOVF ADRESH, W   
    BANKSEL PORTD
    MOVWF PORTD
    
convertir ; Funcion para "llenar de ceros" el numero devuelto por el conversor A/D. Ej: 00001010 -> 00001111
    
    MOVWF unos
    MOVLW d'128'
    MOVWF contador
    decfsz unos,f  ; Decrementar el A/D
    decfsz contador,f ; Decrementar 128 veces
    MOVF unos,w
    ADDLW w
    MOVWF boolean
    goto $-2
    goto $-5
    
    
    
__main
    
END



