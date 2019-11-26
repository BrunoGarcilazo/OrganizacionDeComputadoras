; PIC16F887 Configuration Bit Settings
; Assembly source line config statements

#include "p16f887.inc"

; CONFIG1
; __config 0xE0F2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFEFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

cblock 0x20	;Comienzo a escribir la memoria de datos en la direcciÃ³n 0x20
    d0
    d1
    flag
    sonar1S
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
    banksel TRISC
    bcf TRISC, 0
    movlw d'1'
    banksel flag
    movwf flag
    movlw d'10'
    banksel sonar1S
    movwf sonar1S
    movlw d'100'	    ; Movemos el decimal 100 a w
    banksel contador10segundos	; Movemos d'100' a contador10segundos
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
    call obtenerCont1EraVez
    call configurarTMR1
    
    
    
loop
    call obtenerAD	; Obtiene el dato AD
    banksel datoGuardar
    movwf datoGuardar	; Mueve el resultado de obtenerAD a datoGuardar
    banksel PIR1
    btfsc PIR1, RCIF	; Verifica el Receive Interrupt Flag bit
    goto verificoInput	; 
    goto loop

    
verificoInput	; Verifica el dato recibid
    bcf flag,1
    movlw 0x0A
    movlw d'10'
    banksel sonar1S
    movwf sonar1S
    call enviar ; Envia \n
    banksel RCREG
    movf RCREG,w	
    sublw 0x41 ; A
    btfsc STATUS,Z ; Si la resta dio 0 (bit en 1), se llamara a mostrarConversion
    call mostrarA
    ;Si la resta no dio 0 es porque RCREG no es 'A'
    movf RCREG,w
    sublw 0x48 ; H
    btfsc STATUS,Z ; Verifica si RCREG era H
    call mostrarH  ; Era H, llamo a mostrarH
    movf RCREG,w
    sublw 0x61 ; a
    btfsc STATUS,Z ; Verifica si RCREG era a
    call mostrarGrados  ; Era a, llamo a mostrarGrados
    movlw 0x0A
    call enviar ; Envia \n
    banksel flag
    btfsc flag,1    ; Se testea si el flag esta seteado (se recibio un dato valido)
    goto loop	    ; Si el test dio 1: es porque se recibio "A","H" o "a" y ya se mostraron datos en el PC, por lo tanto se vuelve a loop
    banksel flag
    bsf flag,0
    bcf flag,1	    ; Se realiza clear del bit 1 del flag
    call mal	    ; Como no se recibio ningun dato valido, se reproduce el sonido reprobatorio.
    goto loop	   ; Si no era A ni H ni a, vuelvo a loop
    
mostrarA	   ; Funcion que se encarga de mostrar el dato actual de temperatura en la PC
    banksel flag   ; Se setea el flag, para indicar que se ha recibido un dato valido ("A" en este caso) del PC
    bsf flag,0
    bsf flag,1
    call bien	   ; Se reproduce el sonido aprobatorio 
    banksel datoGuardar	; Se guarda datoGuardar en w
    movf datoGuardar,w
    call mostrarConversion  ; Se llama a mostrarConversion con datoGuardar en W, para enviar ese dato al PC
    return
    
mostrarH    ; Funcion utilizada para mostrar los datos cuando se envia "H" desde el PC.
    banksel flag
    bsf flag,0	; Se "setea" el flag utilizado para saber si el dato recibido desde la PC es uno de los caracteres admitidos ('A', 'H' o 'a')
    bsf flag,1
    call bien	; Llama a la funcion para reproducir el sonido de aprobacion
    movlw d'10'
    movwf contadorH ; Se guarda el decimal 10 en contadorH
    banksel contDir
    movf contDir,w ; Se guarda contDir en W
    movwf temp	   ; Se guarda W en temp
    sublw d'10'	   ; Se le resta 10 a W
    btfsc STATUS,Z 
    movwf temp	   ; Si la resta no dio 0, se guarda W en temp
    
seguirMostrando
    movf temp,w
    call obtenerDireccion ; Obtiene la direccion correspondiente
    call leer		  ; Lee de la direccion obtenida
    call mostrarConversion; Muestra la conversion de los datos obtenidos en la lectura
    movlw 0x0A
    call enviar ; Envia \n
    movlw d'1'
    addwf temp
    movf temp,w
    sublw d'10'
    btfsc STATUS,Z ; Utiliza el contador para mostrar todas las temperaturas registradas en la EEPROM
    movwf temp
    decfsz contadorH
    goto seguirMostrando ; Vuelve a obtener la direccion, leer y luego mostrar.
    goto loop		 ; Si ya termino de mostrar los 10 datos.
    
    
   
obtenerAD  ; Obtiene el dato devuelto por el conversor A/D
    banksel ADCON0
    bsf ADCON0, GO ; Empieza la conversion
    BTFSC ADCON0, GO ; Termino la conversion?
    goto $-1 ; No, chequear otra vez.
    banksel ADRESH 
    movf ADRESH, W
    return
    
mostrarConversion        ; Tomar el dato del Conversor A/D y colocarlo en TXREG (lo envia a la PC)
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
    call conversionNumero ; Convierte primerLetra a su ASCII
    movwf primerLetra

    banksel segundaLetra
    movf segundaLetra,w
    call conversionNumero ; Convierte segundaLetra a su ASCII
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
    
mal ; Funcion para hacer sonar el buzzer con sonido "reprobatorio"
    call Delay3ms
    banksel flag
    btfss flag,0
    return
    banksel PORTC
    btfsc PORTC,0
    call ponerCero
    call ponerUno
    goto mal
    
bien ; Funcion para hacer sonar el buzzer con sonido "aprobatorio"
    call Delay1ms
    banksel flag
    btfss flag,0
    return
    banksel PORTC
    btfsc PORTC,0
    call ponerCero
    call ponerUno
    goto bien
    

Delay	; Delay
			;2493 cycles
	movlw	0xF2
	movwf	d0
	movlw	0x02
	movwf	d1
Delay_0
	decfsz	d0, f
	goto	$+2
	decfsz	d1, f
	goto	Delay_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return
	
Delay1ms ; Delay de 1ms
    call Delay
    return
Delay3ms ; Delay multiple, para obtener 3ms
    call Delay
    call Delay
    call Delay
    call Delay
    return
    
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
    call unSegundo
    banksel PIR2
    btfsc PIR2,EEIF	    ; Verifica si termino la escritura.
    goto bajarEscritura
    
    call actualizarTimer
    
    
unSegundo 
    banksel sonar1S
    decfsz sonar1S ; Decrementa sonar1S. Si se llega a 0, se vuelve a setear en 10 a sonar1S y hace clear de flag. Sino realiza un return y vuelve a la rutina anterior.
    return
    movlw d'10'
    movwf sonar1S
    banksel flag
    bcf flag,0
    return
    
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
    movlw d'100'		     ;Se coloca d'100' nuevamente.
    movwf contador10segundos    
    call obtenerCont
    call obtenerDireccion
    call escribir
    banksel datoGuardar
    movf datoGuardar,w
    banksel PORTD
    movwf PORTD
    
    movlw d'1'		    ;Le suma uno a contDir y lo guarda en w
    banksel contDir
    addwf contDir
    movf contDir,w
    call guardarCont
    goto terminar
    
bajarEscritura	; Baja el flag de Interrupcion de Escritura
    bcf PIR2,EEIF
    goto terminar
    
    
escribir ; Escribe un dato (datoGuardar) en la EEPROM (direccion guardada en w)
    banksel EEADR	; Coloca la direccion de escritura (previamente guardada en w) en EEADR 
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
    
ponerCero   ; Apaga el Buzzer
    banksel PORTC
    bcf PORTC, 0
    return
    
ponerUno    ; Enciende el Buzzer
    banksel PORTC
    bsf PORTC, 0
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
    btfss STATUS,C	; Verifica si direccionDirMemoria es mayor o menos a 10.
    goto esMayorQue10	; El bitTest resulto que no hay Carry, por lo tanto temp es > 10
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
    
mostrarGrados ; Funcion para convertir el dato recibido en un decimal
    banksel flag
    bsf flag,0
    bsf flag,1 ; Setea el flag en 1 para indicar que se recibio un dato correcto ("a" en este caso) por el puerto serial.
    call bien  ; Reproduce el sonido aprobatorio
    banksel datoGuardar
    movf datoGuardar,w	; Guarda datoGuardar en W
    
    banksel temp ; Mueve datoGuardar a temp
    movwf temp
    rrf temp,f	 ; Rota temp (datoGuardar)
    
    movlw b'01111111'
    andwf temp,f ; Realiza un and con temp para obtener la "primeraLetra"
    movf temp,w  ; Mueve el resultado (guardado en temp) en w
    
    
    banksel primerLetra ; Coloca W en primeraLetra
    movwf primerLetra				   ; Mismo W
    banksel segundaLetra ; Coloca W en segundaLetra
    movwf segundaLetra
    
    
    banksel primerLetra
    movlw b'00001111'
    andwf primerLetra,f ; Se obtiene el nibble menos significativo
    
    banksel segundaLetra
    movlw b'11110000'
    andwf segundaLetra,f ; Se obtiene el nibble mas significativo
    swapf segundaLetra
    
    
    movlw d'10'
    subwf primerLetra,w ; Le resta 10 a primeraLetra y verifica hay carry (primeraLetra < 10)
    btfsc STATUS,C
    call subirSegundaLetra ; Si da Carry, se incrementa la "SegundaLetra"
    
    swapf segundaLetra,f
    movf primerLetra,w
    iorwf segundaLetra,w  ; Une los nibbles en un dato unico y lo coloca en w
    
    call mostrarConversion ; Muestra el dato "transformado" en un decimal.
    movlw 0xb0
    call enviar ; Envia °
    movlw 0x43
    call enviar ; Envia C
    return
    
subirSegundaLetra   ; Incrementa segundaLetra y coloca d'0' en primeraLetra
    banksel segundaLetra
    incf segundaLetra
    movlw d'0'
    movwf primerLetra
    return
end