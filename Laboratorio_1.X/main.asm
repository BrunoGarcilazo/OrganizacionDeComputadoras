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
cblock 0x20 ;Comienzo a escribir la memoria de datos en la dirección 0x20
sum	;Defino dos variables
d0
d1
d2
contadorLuces
iterarLuces
endc

;Organizacion de la memoria de programacion
org 0x0000

main
    banksel TRISD	;Selecciono el banco de memoria de TRISD
    clrf TRISD		;Hago un clear del registro TRISD. TRISD = 0x00
    banksel TRISB
    clrf TRISB	;Selecciono el banco de memoria de TRISC
    movlw b'00111111'
    movwf TRISB
    banksel sum
    clrf sum
    banksel ANSELH
    clrf ANSELH
    banksel PORTD
    clrf PORTD
    banksel contadorLuces
    movlw D'10'
    movwf contadorLuces
    
;    goto prueba
;prueba
;    banksel PORTB
;    movf PORTB, w
;    banksel PORTD
;    movwf PORTD
;    goto prueba
__main
    movf contadorLuces,w
    call __destello
    decfsz contadorLuces, f
    goto $-2
    banksel sum
    movf sum, w
    banksel PORTD  
    movwf PORTD
    goto loop1
loop1
    call Delay
    banksel PORTB
    
    btfss PORTB,0
    btfsc PORTB,0
    goto loop2
    goto sumar1
loop2 
    call Delay
    banksel PORTB
    
    btfss PORTB,1
    btfsc PORTB,1
    goto loop3
    goto sumar10
loop3
    call Delay
    banksel PORTB
    
    btfss PORTB,2
    btfsc PORTB,2
    goto loop1
    goto sumar100
luces
    banksel PORTD
    clrf PORTD
    banksel iterarLuces
    movlw D'8'
    movwf iterarLuces
    
    movlw D'5'
    call DelayNuevo
    RLF PORTD
    DECFSZ iterarLuces,f
    goto $-4
    
    movlw D'8'
    movwf iterarLuces
    
    movlw D'5'
    call DelayNuevo
    RRF PORTD
    DECFSZ iterarLuces,f
    goto $-4
    
    banksel STATUS
    bcf STATUS,0
    return

sumar1 
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
sumar10 
    banksel sum
    movf sum,w
    ADDLW D'10'
    movwf sum
    banksel STATUS
    btfss STATUS,0
    btfsc STATUS,0
    call luces
    banksel sum
    movf sum,w
    banksel PORTD
    movwf PORTD 
    goto presionado2
sumar100 
    banksel sum
    movf sum,w
    ADDLW D'100'
    movwf sum
    banksel STATUS
    btfss STATUS,0
    btfsc STATUS,0
    call luces
    banksel sum
    movf sum,w
    banksel PORTD
    movwf PORTD 
    goto presionado3
presionado
    call Delay
    banksel PORTB
    btfsc PORTB,0
    btfss PORTB,0
    goto presionado
    goto loop1
presionado2
    call Delay
    banksel PORTB
    btfsc PORTB,1
    btfss PORTB,1
    goto presionado2
    goto loop1
presionado3
    call Delay
    banksel PORTB
    btfsc PORTB,2
    btfss PORTB,2
    goto presionado3
    goto loop1
DelayNuevo
    banksel d0
    movwf d0
    call Delay
    decfsz d0,f
    goto $-2
    return
Delay ;49993 cycles
    movlw 0x0E
    movwf d1
    movlw 0x28
    movwf d2
Delay_0
    decfsz d1, f
    goto $+2
    decfsz d2, f
    goto Delay_0

    goto $+1 ;3 cycles
    nop
    return
    
Delay3ms
    call Delay
    call Delay
    call Delay
    return
    
;Difencia con respecto al inicial, llamada a Delay3ms son 2 ciclos y return son 4 ciclos
;la suma final seria: 6 ciclos de más
    
__destello
    banksel PORTD
    bcf PORTD,0
    movlw D'10' 
    call DelayNuevo
    
    bsf PORTD,0
    movlw D'10'
    call DelayNuevo
    
    return
END