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
    primerLetra
    segundaLetra
    tercerLetra
    bar
    foo
    contador10segundos
    STATUS_TEMP
    W_TEMP
    
endc
    
org 0x0000
    goto main
org 0x0004
    goto interrupt
 
eusart_init
    banksel TXSTA
    bsf TXSTA, TXEN  ; enable transmitter
    bcf TXSTA, SYNC  ; asynchronous
    banksel RCSTA
    bsf RCSTA, CREN
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
    movlw d'50'
    banksel contador10segundos
    movwf contador10segundos
    
    
    
    banksel ADCON0
    movlw b'10000001'
    movwf ADCON0
    
    banksel TRISD ;Habilitamos las luces.
    clrf TRISD
    banksel PORTD
    clrf PORTD
    
    movlw d'129'
    call eusart_baud_rate
    call eusart_init
    
loop
    goto loop
esperarInput
    call supero3V
    banksel PIR1
    btfsc PIR1, RCIF 
    goto verificoInput
    goto esperarInput
    
verificoInput
    banksel RCREG
    movf RCREG,w	
    sublw 0x41
    btfsc STATUS,Z
    call mostrarConversion
    goto esperarInput
	
	
mostrarConversion        ; Tomar el dato del Conversor A/D y colocarlo en TXREG (lo envia a la PC)
    banksel ADCON0
    bsf ADCON0, GO ; Empieza la conversion
    BTFSC ADCON0, GO ; Termino la conversion?
    goto $-1 ; No, chequear otra vez.
    banksel ADRESL 
    MOVF ADRESL, W
    
    banksel primerLetra
    movwf primerLetra
    banksel segundaLetra
    movwf segundaLetra
    
    
    movlw b'00001111'
    banksel primerLetra
    andwf primerLetra,f
    banksel segundaLetra
    swapf segundaLetra,f
    andwf segundaLetra,f
    
    banksel ADRESH
    movf ADRESH,w
    banksel tercerLetra
    movwf tercerLetra
    
    
    banksel primerLetra
    movf primerLetra,w
    call conversionNumero
    movwf primerLetra

    banksel segundaLetra
    movf segundaLetra,w
    call conversionNumero
    movwf segundaLetra
    
    banksel tercerLetra
    movf tercerLetra,w
    call conversionNumero
    movwf tercerLetra
    
    call mostrarLetras
    
    return
    
    
mostrarLetras    
    banksel tercerLetra
    movf tercerLetra,w
    call enviar
    banksel segundaLetra
    movf segundaLetra,w
    call enviar
    banksel primerLetra
    movf primerLetra,w
    call enviar
    return
    
enviar
    banksel PIR1
    btfss PIR1, TXIF
    goto $-1
    banksel TXREG
    movwf TXREG
    return
    
conversionNumero
    BANKSEL PCL
    ADDWF PCL
    retlw 0x30
    retlw 0x31
    retlw 0x32
    retlw 0x33
    retlw 0x34
    retlw 0x35
    retlw 0x36
    retlw 0x37
    retlw 0x38
    retlw 0x39
    retlw 0x41
    retlw 0x42
    retlw 0x43
    retlw 0x44
    retlw 0x45
    retlw 0x46
    
supero3V  ;614 aproximado 3V binario = 10 0110 0110
    banksel PORTD
    clrf PORTD
    
    banksel ADCON0
    bsf ADCON0, GO ; Empieza la conversion
    BTFSC ADCON0, GO ; Termino la conversion?
    goto $-1 ; No, chequear otra vez.
    banksel ADRESH 
    
    movlw b'00000010'
    subwf ADRESH,w
    banksel STATUS
    
    btfss STATUS,C
    goto $+2
    call prenderLed
    
    btfss STATUS,Z
    goto fin
    
    
    banksel ADRESL 
    
    movlw b'01100110'
    subwf ADRESL,w
    
    banksel STATUS
    btfsc STATUS,C
    call prenderLed
    
    fin
    return
    
prenderLed
    banksel PORTD
    movlw b'00000001'
    movwf PORTD
    return

    
    
    
    
configurarTMR1
    banksel T1CON
    movlw b'00110001'
    banksel PIE1
    bsf PIE1,TMR1IE
    banksel INTCON
    bsf INTCON,GIE
    bsf INTCON,PEIE
    banksel TMR1H
    movlw 0x0B
    movwf TMR1H
    banksel TMR1L
    movlw 0xDC
    movwf TMR1L
    
    
    
interrupt
    
    MOVWF  W_TEMP           ;Copy W to TEMP register
    SWAPF  STATUS,W         ;Swap status to be saved into W ;Swaps are used because they do not affect the status 
		            ;Save status to bank zero STATUS_TEMP register
    MOVWF  STATUS_TEMP
    
    banksel TMR1H
    movlw 0x0B
    movwf TMR1H
    banksel TMR1L
    movlw 0xDC
    movwf TMR1L
    banksel PIR1
    bcf PIR1,TMR1IF
    decfsz contador10segundos
    call finalizar
    goto guardar          
finalizar
    SWAPF  STATUS_TEMP,W    ;Swap STATUS_TEMP register into W ;(sets bank to original state)
    MOVWF  STATUS           ;Move W into STATUS register
    SWAPF  W_TEMP,F         ;Swap W_TEMP
    SWAPF  W_TEMP,W         ;Swap W_TEMP into W
    retfie
    
guardar
    bcf INTCON,GIE
    banksel EEADR
    movlw 0xFF
    movwf EEADR
    banksel EEDAT
    movlw 0xDA
    movwf EEDAT
    banksel EECON1
    bcf EECON1,EEPGD
    bsf EECON1,WREN
    banksel EECON2
    movlw 0x55
    movwf EECON2
    movlw 0xAA
    movwf EECON2
    banksel EECON1
    bsf EECON1,WR
    banksel PIR2
    btfss PIR2,EEIF
    goto $-1
    bcf PIR2,EEIF
    bsf INTCON,GIE
    return
    
    

    
end
	
	
	


