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
contadorTiempo
endc

;Organizacion de la memoria de programacion
org 0x0000
    goto main

org 0x0004
    goto interrupt    

main
    banksel ANSELH ;Con esto andan los botones
    clrf ANSELH
    
    banksel T1CON ;Configuracion del registro de timer 1 (Ver dataSheet).
    movlw b'010110101'
    movwf T1CON
    
    banksel PIE1 ;Configura el peie.
    bsf PIE1,0
    
    bsf INTCON,4    ;Configura el bit INTE para usar la interrupcion del boton
    bsf INTCON,6    ;Configura el Gie.
    bsf INTCON,7
    
    ;Ponemos los leds como salidas
    banksel TRISD
    clrf TRISD
    
    ;Ponemos el boton RB0 como entrada
    banksel TRISB
    clrf TRISB
    movlw '0000001'
    movwf TRISB
    
    ;Dejar en espera hasta que se aprete el boton RB0
    ;La idea es que cada vez que se aprete el boton se genera una interrupcion
    ;
    sleep
    nop
    
__main
    
sumarBinarioALosLeds
    banksel contadorTiempo
    movf contadorTiempo,w
    ADDLW D'1'
    movwf contadorTiempo
    banksel STATUS
    btfss STATUS,0
    btfsc STATUS,0
    call luces
    banksel contadorTiempo
    movf contadorTiempo,w
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

presionado
    call Delay
    banksel PORTB
    btfsc PORTB,0
    btfss PORTB,0
    goto presionado
    goto loop1

interrupt
    banksel PIR1
    clrf PIR1
    
END
