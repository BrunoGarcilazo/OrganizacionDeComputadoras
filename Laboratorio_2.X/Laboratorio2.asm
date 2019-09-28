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
cblock 0x20	;Comienzo a escribir la memoria de datos en la direccion 0x20

d1                  ;Variable usada para el Delay
d2                  ;Variable usada para el Delay
auxW                ;Auxiliar para guardar el valor de W en la interrupcion
cuentaRegresiva     ;Lleva la cuenta del tiempo a ser mostrado
segundosRestantes   ;Contador para mostrar Leds cada 1 segundo (conversor de miliSegundo a segundo)

endc

;Organizacion de la memoria de programacion
org 0x0000
    goto main

org 0x0004
    goto interrupt    

__main
    

main   
    ;Con esto andan los botones (Conversion de Analogico a Digital)
    banksel ANSELH 
    clrf ANSELH
    
    
    ;Se setea el valor a multiplicar los miliSegundos
    banksel segundosRestantes       
    movlw D'10'
    movwf segundosRestantes                             
    
    ;Ponemos los leds como salidas
    banksel TRISD
    clrf TRISD
    
    ;Pone las luces apagadas
    ;banksel PORTD
    ;clrf PORTD
    
    goto prueba
    ;Ponemos todos los botones como entrada
    banksel TRISB
    movlw b'00111111'
    movwf TRISB
    
    ;Generamos una variable en 0, esta cuenta el tiempo ingresado por le usuario
    banksel cuentaRegresiva
    clrf cuentaRegresiva   
    goto iniciar


    goto prueba
;la funcion prueba muestra el correcto funcionamiento de los leds con sus respectivos botones
prueba  
    MOVLW B'00010111'
    RRF W,0
    
    banksel PORTD
    movwf PORTD
    goto prueba

;Funcion que, deja a el pic en un loop hasta que el usuario presiona el Segundo Boton de la Placa (IZQ a DER)
;Al presionarlo configura el timer y espera a que setee un tiempo para iniciar
iniciar
    call Delay
    banksel PORTB   
    btfss PORTB,1
    btfsc PORTB,1
    goto iniciar
    call configurar
    goto loop1

;Funcion que, deja a el pic en un loop hasta que el usuario presiona el Primer Boton de la Placa (IZQ a DER)
;Al presionarlo suma un tiempo (Por defecto 5)
loop1
    call Delay
    call encenderLeds
    banksel PORTB   
    btfss PORTB,0
    btfsc PORTB,0
    goto loop1
    goto sumarTiempo
    
;Funcion que, setea los valores en el timer para crear intervalos de 100 ms.
configurar
    banksel T1CON ;Configuracion del registro de timer 1 (Ver dataSheet pag: 81).
    movlw b'00110100'
    movwf T1CON
    
    ;Antes de habilitar las interrupciones hay que hacer clear del reloj
    banksel TMR1H
    clrf TMR1H
    
    banksel TMR1L       ;Ponemos a cero el registro TMR1H: Holding Register for the Most Significant Byte of the 16-bit TMR1 Register
    clrf TMR1L
    
    banksel PIR1        
    bcf PIR1,0	        ;TMR1IF: Timer1 Overflow Interrupt Flag bit ;1 =   The TMR1 register overflowed (must be cleared in software); 0 =   The TMR1 register did not overflow
    
    banksel PIE1        ;Configura el pie.
    bsf PIE1,0          ;TMR1IE: Timer1 Overflow Interrupt Enable bit
    
    bsf INTCON,6        ;Configura el peie; PEIE: Peripheral Interrupt Enable bit 
    bsf INTCON,7        ;Configura el Gie; GIE: Global Interrupt Enable bit
    
    return
    
;Funcion que, enciende el contador del Timer
prender
    banksel T1CON      
    bsf T1CON,0
    return
    
;Funcion que, apaga el contador del Timer
apagar
    banksel T1CON       
    bcf T1CON,0
    return

;Delay proporcionado por los profesores tiempo: 1ms
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

;Funcion que, carga un valor en la cuenta regresiva (en este caso 5) y prende el Timer
sumarTiempo 
    banksel cuentaRegresiva
    movf cuentaRegresiva,w
    ADDLW D'5'
    movwf cuentaRegresiva
    call prender
    goto presionado


;Funcion que, coloca el valor de la cuenta regresiva en los LEDS
encenderLeds
    banksel cuentaRegresiva
    movf cuentaRegresiva,w
    banksel PORTD
    movwf PORTD
    return

;Funcion auxiliar utilizada por las interrupciones.
;Vuelve el conversor a 10, decrementa la cuenta regresiva, cambia los leds y si la cuenta regresiva es 0, apaga el timer
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

;Funcion para estar en loop, hasta que el usuario suelte el boton seleccionado, esto se utiliza para que no hayan
;errores en ingreso de datos
presionado
    call Delay
    banksel PORTB
    btfsc PORTB,0
    btfss PORTB,0
    goto presionado
    goto loop1

;Funcion utilizada como interrupcion cuando el timer, llega a 100 ms
interrupt
    banksel auxW        ;Guardamos lo que traia W en aux W
    movwf auxW
    
    ;Clear al Timer
    banksel TMR1H       ;Ponemos a cero el registro TMR1H: Holding Register for the Most Significant Byte of the 16-bit TMR1 Register
    clrf TMR1H
    
    banksel TMR1L       ;Ponemos a cero el registro TMR1L: Holding Register for the Least Significant Byte of the 16-bit TMR1 Register
    clrf TMR1L          
    
    banksel PIR1
    bcf PIR1,0	        ;Ponemos a cero el registro TMR1IF: Timer1 Overflow Interrupt Flag bit
    
    bsf INTCON,6        ;Configura el peie; PEIE: Peripheral Interrupt Enable bit 
    banksel segundosRestantes
    decfsz segundosRestantes,f
    goto $+2
    call mostrarTiempo
    banksel auxW        ;Devolvemos el valor que tenia W
    movf auxW,w
    retfie
    
END
