; PIC16F887 Configuration Bit Settings
; Assembly source line config statements

#include "p16f887.inc"

; CONFIG1
; __config 0xE0F2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

cblock 0x20	;Comienzo a escribir la memoria de datos en la dirección 0x20
    auxiliarA
 
endc
    
org 0x0000
    goto main
 
eusart_init
    banksel TXSTA
    bsf TXSTA, TXEN  ; enable transmitter
    bcf TXSTA, SYNC  ; asynchronous
    banksel RCSTA
    bsf RCSTA, CREN  ; enable receiver
    bsf RCSTA, SPEN  ; enable EUSART, TX/CK/IO as output
    return
    
; baud rate setting is in w
; check TABLE 12-5: BAUD RATES FOR ASYNCHRONOUS MODES
eusart_baud_rate
    banksel TXSTA
    bsf TXSTA, BRGH      ; BRGH=1
    banksel BAUDCTL
    bcf BAUDCTL, BRG16   ; BRG16=0
    banksel SPBRGH
    clrf SPBRGH
    banksel SPBRG        
    movwf SPBRG
    return
 
main
    
    banksel ADCON1
    bcf ADCON1,7
    
    banksel ADCON0
    movlw b'10000001'
    movwf ADCON0
    
    banksel auxiliarA ;Configuro auxiliarA (verificarInput)
    movlw b'10000000'
    movwf auxiliarA
    
    banksel TRISD ;Habilitamos las luces.
    clrf TRISD
    
    movlw d'129'
    call eusart_baud_rate
    call eusart_init

_main_loop	    ; 'A' en binario: b'10000000'
	
	banksel RCREG
	movfw RCREG
	banksel TXREG
	;movfw b'11001010'
	;movwf TXREG
	goto _main_loop
end

verificoInput
	banksel RCREG
	movfw RCREG	
	banksel auxiliarA	
	ANDWF auxiliarA,0
	decfsz w
	goto verificoInput
	call mostrarConversion
	
end	
	
mostrarConversion ; Tomar el dato del Conversor A/D y colocarlo en TXREG (lo envia a la PC)
	
	
	