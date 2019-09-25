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
;Variables usadas por los delays
d0
d1
d2
 
limiteParaSetear ;limite de tiempo para setear la cuenta regresiva
cuentaRegresiva ;Lleva la cuenta del tiempo a ser mostrado
endc

;Organizacion de la memoria de programacion
org 0x0000
    goto main

org 0x0004
    goto interrupt    

__main
    

main   
    banksel ANSELH ;Con esto andan los botones
    clrf ANSELH
    
    ;Antes de habilitar las interrupciones hay que hacer clear del reloj
    banksel TMR1H
    clrf TMR1H
    
    banksel TMR1L
    clrf TMR1L
    
    banksel PIR1
    bcf PIR1,0	;Ponemos a cero el registro TMR1IF
    
    
    ;Ponemos los leds como salidas
    banksel TRISD
    clrf TRISD
    
    ;Pone las luces apagadas
    banksel PORTD
    clrf PORTD
    
    ;Ponemos el boton RB0 como entrada
    banksel TRISB
    clrf TRISB
    movlw b'10000000'
    movwf TRISB
    
    ;generamos una variable para dar tiempo para setear
    movlw d'255'
    movwf limiteParaSetear
    movwf cuentaRegresiva   
    clrw
    call activarInterrupciones
    goto loop1
    
loop1
    ;Hay que arreglar para que cuando termine la cuenta se activen las interrupciones
    ;pero que se pueda sumar en el medio
    call Delay
    banksel PORTB   
    btfss PORTB,0
    btfsc PORTB,0
    goto loop1
    goto sumarTiempo
    goto mostrarTiempo
    goto loop1
 
activarInterrupciones
    banksel T1CON ;Configuracion del registro de timer 1 (Ver dataSheet).
    movlw b'01110101'
    movwf T1CON
    
    banksel PIE1 ;Configura el pie.
    bsf PIE1,0
    
    bsf INTCON,6    ;Configura el peie
    bsf INTCON,7    ;Configura el Gie.
    return
    
Delay ;49993 cycles
    movlw 0x0E
    movwf d1
    movlw 0x28
    movwf d2    
    banksel STATUS
    bcf STATUS,0
    return

sumarTiempo 
    banksel cuentaRegresiva
    movf cuentaRegresiva,w
    ADDLW D'5'
    movwf cuentaRegresiva
 
mostrarTiempo
    banksel cuentaRegresiva
    movf cuentaRegresiva,w
    banksel PORTD
    movwf PORTD
    
presionado
    call Delay
    banksel PORTB
    btfsc PORTB,0
    btfss PORTB,0
    goto presionado
    goto loop1
        
interrupt
    banksel TMR1H
    clrf TMR1H
    
    banksel TMR1L
    clrf TMR1L
    
    banksel PIR1
    bcf PIR1,0	;Ponemos a cero el registro TMR1IF
    
    bsf INTCON,6    ;Configura el peie
    banksel cuentaRegresiva
    decf cuentaRegresiva
    goto mostrarTiempo
    retfie
    
END
