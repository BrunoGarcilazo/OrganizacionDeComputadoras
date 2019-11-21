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
    temp
    primerLetra
    segundaLetra
    tercerLetra
    contador10segundos
    STATUS_TEMP
    W_TEMP
    cola
    cabeza
    datoGuardar
    contDir
    direccionDirMemoria
    direccion
    
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
    movlw d'10'
    banksel contador10segundos
    movwf contador10segundos
    
    
    movlw 0xFF
    banksel direccionDirMemoria
    movwf direccionDirMemoria
    
    bsf INTCON,GIE
    bsf INTCON,PEIE
    banksel PIE2
    bsf PIE2,EEIE
    
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
    call configurarTMR1
    call obtenerCont1EraVez
    
    
loop
    call obtenerAD
    banksel datoGuardar
    movwf datoGuardar
    banksel PIR1
    btfsc PIR1, RCIF 
    goto verificoInput
    goto loop

    
verificoInput
    banksel RCREG
    movf RCREG,w	
    sublw 0x41
    btfsc STATUS,Z
    call mostrarConversion
    goto loop
;    
obtenerAD
    banksel ADCON0
    bsf ADCON0, GO ; Empieza la conversion
    BTFSC ADCON0, GO ; Termino la conversion?
    goto $-1 ; No, chequear otra vez.
    banksel ADRESH 
    movf ADRESH, W
    return
    
mostrarConversion        ; Tomar el dato del Conversor A/D y colocarlo en TXREG (lo envia a la PC)
    movf direccion,w
    call leer
    
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
    
;    banksel ADRESH
;    movf ADRESH,w
;    banksel tercerLetra
;    movwf tercerLetra
    
    
    banksel primerLetra
    movf primerLetra,w
    call conversionNumero
    movwf primerLetra

    banksel segundaLetra
    movf segundaLetra,w
    call conversionNumero
    movwf segundaLetra
    
;    banksel tercerLetra
;    movf tercerLetra,w
;    call conversionNumero
;    movwf tercerLetra
    
    call mostrarLetras
    
    return
    
    
mostrarLetras    
;    banksel tercerLetra
;    movf tercerLetra,w
;    call enviar
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
    

    
configurarTMR1
    
    banksel T1CON
    movlw b'00110001'
    movwf T1CON
    banksel PIE1
    bsf PIE1,TMR1IE
    bsf INTCON,PEIE
    banksel TMR1H
    movlw 0x0B
    movwf TMR1H
    banksel TMR1L
    movlw 0xDC
    movwf TMR1L
    
    return
    
    

interrupt
    MOVWF  W_TEMP           ;Copy W to TEMP register
    SWAPF  STATUS,W         ;Swap status to be saved into W ;Swaps are used because they do not affect the status 
		            ;Save status to bank zero STATUS_TEMP register
    MOVWF  STATUS_TEMP
    
    banksel PIR2
    btfsc PIR2,EEIF
    goto bajarEscritura
    
    call actualizarTimer
    
    
    
terminar
    SWAPF  STATUS_TEMP,W    ;Swap STATUS_TEMP register into W ;(sets bank to original state)
    MOVWF  STATUS           ;Move W into STATUS register
    SWAPF  W_TEMP,F         ;Swap W_TEMP
    SWAPF  W_TEMP,W         ;Swap W_TEMP into W
    retfie
    
actualizarTimer
    banksel TMR1H
    movlw 0x0B
    movwf TMR1H
    banksel TMR1L
    movlw 0xDC
    movwf TMR1L
    banksel PIR1
    bcf PIR1,TMR1IF
    decfsz contador10segundos
    goto terminar
    goto pasaron10s

    
pasaron10s
    movlw d'10'
    movwf contador10segundos
    
    call obtenerCont
    call actualizarDir
    banksel contDir
    movf contDir,w
    banksel PORTD
    movwf PORTD
    call obtenerDireccion
;    banksel direccion
;    movwf direccion
;    call leer
    
;    
;;    call escribir
    movlw d'1'
    banksel contDir
    addwf contDir
    movf contDir,w
    call guardarCont
    goto terminar
    
bajarEscritura
    bcf PIR2,EEIF
    goto terminar
    
    
escribir
    banksel EEADR
    movwf EEADR
    banksel datoGuardar
    movf datoGuardar,w
    banksel EEDAT
    movwf EEDAT
    banksel EECON1
    bcf EECON1,EEPGD
    bsf EECON1,WREN
    
    
    bcf INTCON,GIE
    btfsc INTCON,GIE
    goto $-2
    
    movlw 0x55
    movwf EECON2
    movlw 0xAA
    movwf EECON2
    bsf EECON1,WR
    bsf INTCON,GIE
    
    sleep
    
    banksel EECON1
    bcf EECON1,WREN
    return
    
    
leer
    banksel EEADR
    movwf EEADR
    banksel EECON1
    bcf EECON1,EEPGD
    bsf EECON1,RD
    banksel EEDAT
    movf EEDAT,w
    return
    
    
obtenerDireccion    
    banksel PCL
;    ADDWF PCL
    retlw 0x10
    retlw 0x11
    retlw 0x12
    retlw 0x13
    retlw 0x14
    retlw 0x15
    retlw 0x16
    retlw 0x17
    retlw 0x18
    retlw 0x19
    
actualizarDir
    banksel contDir
    movf contDir,w
    sublw d'10'
    btfsc STATUS,Z
    call resetearCont
    return
    
obtenerCont1EraVez
    banksel direccionDirMemoria
    movf direccionDirMemoria,w
    call leer
    movwf temp
    sublw d'10'
    btfss STATUS,C
    goto esMayorQue10
    movf temp,w
    return
    
obtenerCont
    banksel direccionDirMemoria
    movf direccionDirMemoria,w
    call leer
    movwf contDir
    return

guardarCont
    banksel contDir
    movf contDir,w
    banksel datoGuardar
    movwf datoGuardar
    banksel direccionDirMemoria
    movf direccionDirMemoria,w
    call escribir
    return
    
esMayorQue10
    call resetearCont
    call guardarCont
    movf contDir,w
    return

resetearCont
    banksel contDir
    movlw d'0'
    movwf contDir
    return

end