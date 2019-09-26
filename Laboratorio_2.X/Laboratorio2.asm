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
auxW
cuentaRegresiva ;Lleva la cuenta del tiempo a ser mostrado
segundosRestantes
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
    
    banksel segundosRestantes
    movlw D'10'
    movwf segundosRestantes
    
    ;Antes de habilitar las interrupciones hay que hacer clear del reloj
    
    
    
    ;Ponemos los leds como salidas
    banksel TRISD
    clrf TRISD
    
    ;Pone las luces apagadas
    banksel PORTD
    clrf PORTD
    
    ;Ponemos el boton RB0 como entrada
    banksel TRISB
    clrf TRISB	;Selecciono el banco de memoria de TRISC
    movlw b'00111111'
    movwf TRISB
    
    ;generamos una variable para dar tiempo para setear
    banksel cuentaRegresiva
    clrw
    movwf cuentaRegresiva   
    goto iniciar

;    goto prueba
;prueba
;    banksel PORTB
;    movf PORTB, w
;    banksel PORTD
;    movwf PORTD
;    goto prueba
iniciar
    call Delay
    banksel PORTB   
    btfss PORTB,1
    btfsc PORTB,1
    goto iniciar
    call configurar
    goto loop1
    
loop1
    ;Hay que arreglar para que cuando termine la cuenta se activen las interrupciones
    ;pero que se pueda sumar en el medio
    call Delay
    call encenderLeds
    banksel PORTB   
    btfss PORTB,0
    btfsc PORTB,0
    goto loop1
    goto sumarTiempo
    
configurar
    banksel T1CON ;Configuracion del registro de timer 1 (Ver dataSheet).
    movlw b'00110100'
    movwf T1CON
    banksel TMR1H
    clrf TMR1H
    
    banksel TMR1L
    clrf TMR1L
    
    banksel PIR1
    bcf PIR1,0	;Ponemos a cero el registro TMR1IF
    
    banksel PIE1 ;Configura el pie.
    bsf PIE1,0
    
    bsf INTCON,6      ;Configura el peie
    bsf INTCON,7      ;Configura el Gie.
    
    return
 
prender
    banksel T1CON      
    bsf T1CON,0
    return
    
apagar
    banksel T1CON       
    bcf T1CON,0
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
    call prender
    banksel cuentaRegresiva
    movf cuentaRegresiva,w
    ADDLW D'5'
    movwf cuentaRegresiva
    goto presionado
    
encenderLeds
    banksel cuentaRegresiva
    movf cuentaRegresiva,w
    banksel PORTD
    movwf PORTD
    return
mostrarTiempo
    banksel segundosRestantes
    movlw D'10'
    movwf segundosRestantes
    banksel cuentaRegresiva
    decfsz cuentaRegresiva,f
    goto $+2
    call apagar
    call encenderLeds
    return
    
presionado
    call Delay
    banksel PORTB
    btfsc PORTB,0
    btfss PORTB,0
    goto presionado
    goto loop1
    
interrupt
    banksel auxW
    movwf auxW
    banksel TMR1H
    clrf TMR1H
    
    banksel TMR1L
    clrf TMR1L
    
    banksel PIR1
    bcf PIR1,0	;Ponemos a cero el registro TMR1IF
    
    bsf INTCON,6    ;Configura el peie
    banksel segundosRestantes
    decfsz segundosRestantes,f
    goto $+2
    call mostrarTiempo
    banksel auxW
    movf auxW,w
    retfie
    
END
