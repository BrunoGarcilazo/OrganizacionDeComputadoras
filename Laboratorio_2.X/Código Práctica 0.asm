; Codigo de muestra
; Organización de Computadoras 2019
; Práctica 0
    
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
variable_1	;Defino dos variables
variable_2
 
endc

;Organizacion de la memoria de programacion
org 0x0000

main
    banksel TRISD	;Selecciono el banco de memoria de TRISD
    clrf TRISD		;Hago un clear del registro TRISD. TRISD = 0x00
    banksel TRISC	;Selecciono el banco de memoria de TRISC
    clrf TRISC		;Hago un clear del registro TRISC. TRISC = 0x00
    banksel variable_1	;Selecciono el banco de memoria de variable_1
    movlw b'00001111'	;Muevo el literal binario al registro W
    movwf variable_1	;Muevo lo que habia en el registro de W a variable_1
    banksel variable_2	;Selecciono el banco de memoria de variable_2
    movlw b'11110000'	;Muevo el literal binario al registro W
    movwf variable_2	;Muevo lo que habia en el registro W a variable_2
 
__main
    banksel variable_1
    movf variable_1, w
    banksel PORTD
    movwf PORTD
    
    banksel variable_2
    movf variable_2, w
    banksel PORTC
    movwf PORTC
    goto __main
 
END



