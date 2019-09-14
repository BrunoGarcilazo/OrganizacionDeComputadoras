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
cblock 0x20	;Comienzo a escribir la memoria de datos en la dirección 0x20
endc

;Organizacion de la memoria de programacion
org 0x0000
    goto main

org 0x0004
    goto interrupt    

main
    banksel T1CON ;Configuracion del registro de timer 1 (Ver dataSheet)
    movlw b'010110101'
    movwf T1CON
    
    banksel PIE1
    bsf PIE1,0
    
    bsf INTCON,6
    bsf INTCON,7
    
    
__main
    
loop1
    call Delay
    banksel PORTB
    
    btfss PORTB,0
    btfsc PORTB,0
    goto loop2
    goto sumarBinaroALosLeds
    
sumarBinarioALosLeds
    banksel sum
    movf sum,w
    ADDLW D'1'
    movwf sum
    banksel STATUS
    btfss STATUS,0
    btfsc STATUS,0
    call luces
    banksel sum
    movf sum,w
    banksel PORTD
    movwf PORTD 
    goto presionado
    
botonPresionado
    call Delay
    banksel PORTB
    btfsc PORTB,0
    btfss PORTB,0
    goto presionado
    goto loop1

interrupt
    banksel PIR1
    
END
