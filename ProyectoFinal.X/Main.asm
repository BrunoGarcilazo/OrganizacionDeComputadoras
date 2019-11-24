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
    datoGuardar ; Variable que sera utilizada para almacenar el dato a guardarse en EEPROM
    contDir
    direccionDirMemoria
    direccion
    contadorH
    
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
    banksel SPBRGH	 ; limpiamos SPBRGH
    clrf SPBRGH
    banksel SPBRG        ; movemos SPBRG a w
    movwf SPBRG
    return

main
    movlw d'10'	    ; Movemos el decimal 10 a w
    banksel contador10segundos	; Movemos d'10' a contador10segundos
    movwf contador10segundos
    
    movlw 0xFF		
    banksel direccionDirMemoria ; Guardamos 0xFF en direccionDirMemoria
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
    banksel PORTD ; Vacia el registro de LEDs
    clrf PORTD
    
    movlw d'129'
    call eusart_baud_rate
    call eusart_init
    call configurarTMR1
    call obtenerCont1EraVez
    
    
loop
    call obtenerAD	; Obtiene el dato AD
    banksel datoGuardar
    movwf datoGuardar	; Mueve el resultado de obtenerAD a datoGuardar
    banksel PIR1
    btfsc PIR1, RCIF	; Verifica el Receive Interrupt Flag bit
    goto verificoInput	; 
    goto loop

    
verificoInput	; Verifica el dato recibid
    banksel RCREG
    movf RCREG,w	
    sublw 0x41 ; A
    btfsc STATUS,Z ; Si la resta dio 0 (bit en 1), se llamara a mostrarConversion
    call mostrarConversion
    ;Si la resta no dio 0 es porque RCREG no es 'A'
    movf RCREG,w
    sublw 0x48 ; H
    btfsc STATUS,Z ; Verifica si RCREG era H
    call mostrarH  ; Era H, llamo a mostrarH
    goto loop	   ; Si no era A ni H, vuelvo a loop
    

mostrarH
    movlw d'11'
    movwf contadorH
    banksel contDir
    movf contDir,w
    movwf temp
    sublw d'10'
    btfsc STATUS,Z
    movwf temp
    
    seguirMostrando
    decfsz contadorH
    goto $+2
    goto loop
    movf temp,w
    call obtenerDireccion
    movwf direccion
    call mostrarConversion
    movlw d'1'
    addwf temp
    movf temp,w
    sublw d'10'
    btfsc STATUS,Z
    movwf temp
    goto seguirMostrando
    
   
obtenerAD  ; Obtiene el dato devuelto por el conversor A/D
    banksel ADCON0
    bsf ADCON0, GO ; Empieza la conversion
    BTFSC ADCON0, GO ; Termino la conversion?
    goto $-1 ; No, chequear otra vez.
    banksel ADRESH 
    movf ADRESH, W
    return
    
mostrarConversion        ; Tomar el dato del Conversor A/D y colocarlo en TXREG (lo envia a la PC)
    movf direccion,w ; 
    call leer
    
    banksel primerLetra
    movwf primerLetra
    banksel segundaLetra
    movwf segundaLetra
    
    
    movlw b'00001111'	  ; Realiza un AND entre W y primeraLetra, guarda el resultado en primeraLetra
    banksel primerLetra
    andwf primerLetra,f
    banksel segundaLetra  ; Cambia los nibbles de segundaLetra y realiza un AND con W, guarda el resultado en segundaLetra
    swapf segundaLetra,f
    andwf segundaLetra,f
    
    
    banksel primerLetra	  ; Mueve primeraLetra a W y llama a conversionNumero, guarda el resultado en W.
    movf primerLetra,w
    call conversionNumero
    movwf primerLetra

    banksel segundaLetra
    movf segundaLetra,w
    call conversionNumero
    movwf segundaLetra
   
    call mostrarLetras ; Una vez se tiene el dato deseado, se envian a la PC
    
    return
    
    
mostrarLetras    ; Envia las letras correspondientes, luego envia '\n'
    banksel segundaLetra
    movf segundaLetra,w
    call enviar ; Envia segundaLetra
    
    banksel primerLetra
    movf primerLetra,w
    call enviar ; Envia primeraLetra
    
    movlw 0x0A
    call enviar ; Envia \n
    return
    
enviar ; Envia lo guardado en w a la PC (lo coloca en TXREG)
    banksel PIR1
    btfss PIR1, TXIF
    goto $-1
    banksel TXREG
    movwf TXREG
    return
    
obtenerDireccion    ; Obtiene la direccion correspondiente para el buffer circular
    banksel PCL
    ADDWF PCL
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
    
conversionNumero ; Convierte un numero en hexa a su correspondiente en ASCII (0 a F)
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
    

    
configurarTMR1 ; Configura el Timer1 para interrumpir cada 0.1s (0x0BCD en los registros TMR1H y TMR1L)
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
    btfsc PIR2,EEIF	    ; Verifica si termino la escritura.
    goto bajarEscritura
    
    call actualizarTimer
    
    
    
terminar
    SWAPF  STATUS_TEMP,W    ;Swap STATUS_TEMP register into W ;(sets bank to original state)
    MOVWF  STATUS           ;Move W into STATUS register
    SWAPF  W_TEMP,F         ;Swap W_TEMP
    SWAPF  W_TEMP,W         ;Swap W_TEMP into W
    retfie
    
actualizarTimer ; Vuelve a "setear" los valores 0x0BDC en el Timer1 
    banksel TMR1H
    movlw 0x0B
    movwf TMR1H	
    
    banksel TMR1L
    movlw 0xDC
    movwf TMR1L
    
    banksel PIR1
    bcf PIR1,TMR1IF
    
    decfsz contador10segundos ; Decrementa: si f != 0: termina la interrupcion, sino llama a pasaron10s y termina la interrupcion.
    goto terminar
    goto pasaron10s

    
pasaron10s
    movlw d'10'		     ;Se coloca d'10' nuevamente.
    movwf contador10segundos    
    call obtenerCont
    call obtenerDireccion
    banksel direccion
    movwf direccion
    call leer
    banksel PORTD
    movwf PORTD
;    call mostrarConversion
    movlw d'1'		    ;Le suma uno a contDir y lo guarda en w
    banksel contDir
    addwf contDir
    movf contDir,w
    call guardarCont
    goto terminar
    
bajarEscritura	; Baja el flag de Interrupcion de Escritura
    bcf PIR2,EEIF
    goto terminar
    
    
escribir
    banksel EEADR	; Coloca la direccion de escritura en EEADR
    movwf EEADR
    banksel datoGuardar	; Coloco el dato a escribir (datoGuardar) en EEDAT
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
    banksel EEADR	; Coloca la direccion a leer en EEADR
    movwf EEADR
    banksel EECON1
    bcf EECON1,EEPGD
    bsf EECON1,RD
    banksel EEDAT	; Guarda el dato recien leido en W
    movf EEDAT,w
    return
    
    

    
actualizarDir ; Funcion que le resta d'10' a contDir
    banksel contDir
    movf contDir,w
    sublw d'10'
    btfsc STATUS,Z ; Verifica si la resta dio 0
    call resetearCont ; Si la resta dio 0, resetea el contador (lo vuelve 0)
    return	      ; Si la resta no dio 0, retorna a la tarea anterior sin cambios
    
    
obtenerCont1EraVez ; Ejecuta al inicio del programa
    banksel direccionDirMemoria	;
    movf direccionDirMemoria,w
    call leer
    movwf temp
    sublw d'10'
    btfss STATUS,C
    goto esMayorQue10
    movf temp,w
    return
    
obtenerCont ; Lee de la EEPROM la direccion dada por 'direccionDirMemoria'
    banksel direccionDirMemoria
    movf direccionDirMemoria,w
    call leer
    movwf contDir ; Guarda e en contDir al finalizar la lectura
    call actualizarDir
    return

guardarCont
    banksel contDir ; 
    movf contDir,w  ;	
    banksel datoGuardar; Guarda contDir en W y luego lo coloca en datoGuardar
    movwf datoGuardar;
    
    banksel direccionDirMemoria ; Guarda direccionDirMemoria en W y llama a escribir.
    movf direccionDirMemoria,w
    call escribir
    return
    
esMayorQue10 ; Funcion que de ser llamada, resetea el contDir, luego llama a guardar
    call resetearCont
    call guardarCont
    movf contDir,w
    return

resetearCont ; "Resetea" el contDir, dejandolo en 0 decimal.
    banksel contDir
    movlw d'0'
    movwf contDir
    return

end