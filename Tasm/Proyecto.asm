;____________________________________
; 			Proyecto 
;@autor: Castillo Montes Pamela 
;Last update on Sun Ago 15  2021
;____________________________________

;____________________________________
title "Proyecto: Not really Ponj ©" 
	.model small	;Small => 64KB
	.386			;Procesador
	.stack 64 		;Tamano del stack		
;____________________________________

;____________VARIABLES_______________
	.data			
;Caracteres ASCII marco del programa
marcoEsqInfIzq 		equ 	200d 	;'╚'
marcoEsqInfDer 		equ 	188d	;'╝'
marcoEsqSupDer 		equ 	187d	;'╗'
marcoEsqSupIzq 		equ 	201d 	;'╔'
marcoCruceVerSup	equ		203d	;'╦'
marcoCruceHorDer	equ 	185d 	;'╣'
marcoCruceVerInf	equ		202d	;'╩'
marcoCruceHorIzq	equ 	204d 	;'╠'
marcoCruce 			equ		206d	;'╬'
marcoHor 			equ 	205d 	;'═'
marcoVer 			equ 	186d 	;'║'

;Color para carácter							
cNegro 			equ		00h
cRojo 			equ 	04h
cRojoClaro		equ		0Ch
cCyanClaro		equ		0Bh
cAmarillo 		equ		0Eh
cBlanco 		equ		0Fh

;Color para fondo											
bgNegro 		equ		00h
bgAmarillo 		equ		0E0h

;Cadenas 		
titulo 				db 		"PONJ$"
tiempo_cadena		db 		"0:00$"
no_mouse			db 		'No se encuentra driver de mouse. Presione [enter] para salir$'
game_over 			db 		'GAME OVER$'
cadena_ganador 		db      'El ganador es: $'
cadena_continuar    db      'Presione [Enter] para continuar ...$'
empate 				db 		'Nadie ... Es un empate$'

;Player 1
player1 		db 		"Player 1$"		
p1_col			db 		6  		;Posición
p1_ren			db 		14  	;Posición
p1_score 		db 		0 		;Score

;Player 2
player2 		db 		"Player 2$"			
p2_col 			db 		73
p2_ren 			db 		14
p2_score		db 		0

;Posición inicial y rebote pelota
pelota_col		db 		40
pelota_ren 		db 		14	
rebote 			db 		0 			;0 = False, 1 = True

;Guardar una posición auxiliar
col_aux 		db 		0
ren_aux 		db 		0

;Variables auxiliar 8,10,60,1000
ocho			db 		8 		;Mouse
diez 			dw 		10
sesenta 		db 		60		;Cronometro
mil				dw		1000 	;Cronometro

;Contador para loops
conta 			db 		0

;Parametros para IMPRIME_BOTON
boton_caracter 	db 		0
boton_renglon 	db 		0
boton_columna 	db 		0
boton_color		db 		0
boton_bg_color	db 		0

;Cronometro
tick_ms			dw 		55 			;55 ms por cada tick del sistema
tiempo_inicial	dw 		0			;Número de ticks iniciales
milisegundos	dw		0		
segundos		db		0 		
minutos 		db		0	

;Velocidad
tiempo_velocidad 	db 		0
velocidad_col		db		01h
velocidad_ren 		db 		01h
;____________________________________

;__________MACROS____________________
inicializa_ds_es 	macro     
	mov ax,@data
	mov ds,ax
	mov es,ax 		;Imprimir cadenas utilizando int 10h  				
endm

clear macro 	
	mov ax,0003h 	;ah = Video 80x25 , al = Texto 16 colores
	int 10h			;Establece modo de video
endm

posiciona_cursor macro renglon,columna   ;Cambia la posición del cursor a 'renglon' 'columna'
	mov dh,renglon	
	mov dl,columna	
	mov bx,0         																		
	mov ax,0200h 	;Cambia posicion del cursor
	int 10h 		
endm 

muestra_cursor_mouse	macro       
	mov ax,1		 														
	int 33h			;int mouse
endm

oculta_cursor_teclado	macro      
	mov ah,01h 		
	mov cx,2607h 		;Parametro para ocultar cursor |
	int 10h 			;Cambia la visibilidad del cursor del teclado
endm

apaga_cursor_parpadeo	macro       
	mov ax,1003h 		
	xor bl,bl 			;BL = 0						
  	int 10h 			;Cambia la visibilidad del cursor del teclado
endm

imprime_caracter_color macro caracter,color,bg_color     ;Imprime un 'caracter' de cierto 'color' en un fondo 'bg_color'
	mov ah,09h				
	mov al,caracter 		
	mov bh,0				;BH = numero de pagina
	mov bl,color 			;BL = color del caracter 
	or bl,bg_color 			;= color del fondo 
	mov cx,1				
	int 10h 				;Imprime el caracter en AL
endm

imprime_cadena_color macro cadena,long_cadena,color,bg_color    ;Imprime una 'cadena' de cierto 'color' en un fondo 'bg_color'
	mov ah,13h				
	lea bp,cadena 			;Apuntador a la cadena a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			;BL = color de la cadena
	or bl,bg_color 			;= color del fondo 
	mov cx,long_cadena		;CX = longitud de la cadena 
	int 10h 				
endm

lee_mouse	macro  	;Revisa el estado del mouse
	mov ax,0003h 	
	int 33h			
endm

comprueba_mouse    macro   	;Revisa la existencia de mouse
	mov ax,0			
	int 33h					
endm
;____________________________________

;___________CÓDIGO___________________
	.code
inicio:					
	inicializa_ds_es    	;mov ax,@data ...

	;=== Comprobar Mouse ===
	comprueba_mouse			
	xor ax,0FFFFh			;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
	jz imprime_ui			;Existe -> salta a 'imprime_ui'
		lea dx,[no_mouse]   ;De lo contario ...
		mov ax,0900h	
		int 21h			
		jmp teclado			;Salta a 'teclado' para comprobar [Enter]

	;=== Imprimir Interfaz ===
imprime_ui:
	clear 						
	oculta_cursor_teclado		
	apaga_cursor_parpadeo 		

	;Inicializamos las posiciones y score de los jugadores + la pelota
	mov [p1_ren],14
	mov [p1_score],0

	mov [p2_ren],14
	mov [p2_score],0

	mov [pelota_col],40
	mov [pelota_ren],14

	call DIBUJA_UI 			;Dibuja la interfaz
	muestra_cursor_mouse 	

Waiting:
	lee_mouse 			;BX = Estado del mouse el estado
	test bx,0001h 		;0001h = Boton Izquierdo presionado
	jz Waiting 			;Si NO está presionado -> Loop mouse 

	;Conversión de resolución 640x200 a 80x25
	mov ax,dx 			
	div [ocho] 			
	xor ah,ah 			
	mov dx,ax 			

	mov ax,cx 			
	div [ocho] 			
	xor ah,ah 			
	mov cx,ax 			

	;=== Presiona botón [Play] ===
	cmp dx,1 				
	jge boton_play_R	;Renglon < 1 -> ¿[Play]?

	;=== Presiona botón [X] ===
	cmp dx,0 
	je x_wait          	;Renglon = 0 

	x_wait: 			;Revisa si el mouse está entre C = 76,78
		cmp cx,76 			
		jge x_wait1		;Columna >= 76
		jmp Waiting		;De lo contrario, no está en [X]      
	
	x_wait1:
		cmp cx,78			
		jbe salir		;Columna <= 78 -> [X]

	jmp Waiting 		;No inicia hasta que se presione play

	;=== Restringir el mouse en el área de los botones/ la parte de arriba ===
restringir_mouse:
	mov ax,08h			;Posición Vertical		
	mov cx,0			;Limite superior
	mov dx,32			;Limite inferior
	int 33h

empieza_cronometro:
	xor ax,ax 			;Borra el buffer del teclado anterior

	;=== Tiempo para cronometro ===
	mov ah,00h
	int 1Ah 					;DX = [tiempo_inicial]
	add dx,442h					;[tiempo_sistema]+60s  donde 442ticks = 60s
	mov [tiempo_inicial],dx

	;=== ¿Boton izquierdo está presionado? ===
mouse_no_clic:
	lee_mouse  				;BX = Estado del mouse
	test bx,0001h           ;0001h = Boton Izquierdo presionado
	jnz mouse_no_clic   	;Está presionado -> No continúa

principal:
	;=== Cronometro ===
    call CRONO
    
    ;=== Tiempo para Velocidad ===
    mov ah,2Ch 				;Lee reloj del sistema donde DL = 1/100 segundos
    int 21h
    mov [tiempo_velocidad],dl

	;=== Leer teclado  W/S -> Player 1 / Player 2 -> P/L ===
	xor ax,ax 				;Borra el buffer del teclado anterior
	mov ah,01h
	int 16h 				
	jnz desplazamiento		;Si detecta entrada de teclado -> desplazamiento
	jmp ruta_pelota 			

desplazamiento:
	mov ah,00h 			;Guarda el valor ASCII de la tecla presionada en AL
	int 16h

	;Player 1
	cmp al,'W'			
	je player1_arriba 	
	cmp al,'w'			
	je player1_arriba

	cmp al,'S' 		
	je player1_abajo
	cmp al,'s'  		
	je player1_abajo

	;Player 2
	cmp al,'P' 		
	je player2_arriba
	cmp al,'p'
	je player2_arriba 	

	cmp al,'L' 			
	je player2_abajo
	cmp al,'l' 			
	je player2_abajo

ruta_pelota:
	mov ah,2Ch 						;Leer reloj
    int 21h							
	cmp dl,[tiempo_velocidad]		;Comparamos NO ha pasado un 1/100 de segundo
	je 	mouse						;Entonces NO mueve la pelota
	mov [tiempo_velocidad],dl 		;De lo contario actualizamos el tiempo 

	;=== Borrar pelota posición anterior ===
	posiciona_cursor [pelota_ren],[pelota_col]
	cmp [rebote],0 					
	je borrar_pelota 			;Si no hay rebote, borra la pelota anterior

	imprime_caracter_color 219,cBlanco,bgNegro 
	mov [rebote],0 				;Reiniciamos la variable a 'No rebote'
	jmp mover_pelota

borrar_pelota:
	imprime_caracter_color 219d,cNegro,bgNegro 	 		

mover_pelota:
	;=== Mover la pelota ===
	mov al,velocidad_col
	add [pelota_col],al 		;Posición = Actual + Velocidad

		;=== ¿Choca en el limite izquierdo o derecho? ====
		cmp [pelota_col],1
		jbe score_player2

		cmp [pelota_col],78
		jge score_player1

		;=== ¿Choca con las barras? ===
		cmp [pelota_col],6
		je verificar_choque_player1

		cmp [pelota_col],73
		je verificar_choque_player2

verificar_choque_ren:
	mov al,velocidad_ren
	add [pelota_ren],al

		;=== ¿Choca a arriba o abajo? ===
		cmp [pelota_ren],5
		jbe negar_velocidad_ren

		cmp [pelota_ren],23
		jge	negar_velocidad_ren

continuar_pelota:
	mov al,[pelota_ren]
	mov [ren_aux],al 
	mov al,[pelota_col]
	mov [col_aux],al
	call IMPRIME_PELOTA

	;=== Comprueba el estado del mouse ===
mouse:
	lee_mouse 			;BX = Estado del mouse el estado
	test bx,0001h 		;0001h = Boton Izquierdo presionado
	jz principal 		;NO está presionado -> Loop mouse 

	;=== Conversión de resolución 640x200 a 80x25 ===
	mov ax,dx 			;Renglon [0,199]
	div [ocho] 			
	xor ah,ah 			;Descartar el residuo
	mov dx,ax 			;Renglon [0,24]

	mov ax,cx 			;Columnna [0,639]
	div [ocho] 			
	xor ah,ah 			;Descartar el residuo
	mov cx,ax 			;Columna [0,79]

	;=== Presiona botón [Stop] ===
	cmp dx,1 				;Renglon < 1 -> ¿[Stop]?
	jge boton_stop_R

	;=== Presiona botón [X] ===
	cmp dx,0 			
	je boton_x          	;Renglon = 0 
	jmp mouse_no_clic		;Repite hasta que se presione [X]

;________________Fin Main_______________

;________________Etiquetas______________
	;=== Revisa si está presionando [X] ===
boton_x: 					;Revisa si está entre C = 76,78
	cmp cx,76 			
	jge boton_x1			;Columna >= 76
	jmp mouse_no_clic		;De lo contrario, no está en [X]      
	
	boton_x1:
		cmp cx,78			
		jbe salir			;Columna <= 78
		jmp mouse_no_clic	

	;=== Revisa si está presionando [Play] ===
boton_play_R:  				;Revisa si está entre R = 1,3 
	cmp dx,3
	jbe boton_play_C   		;Renglon >= 3?
	jmp Waiting				;De lo contrario, no está en [Play]	

	boton_play_C:			;Revisar si el mouse está entre C = 43,45
		cmp cx,45
		jbe boton_play		;Columna <= 45
		jmp Waiting			

	boton_play:
	cmp cx,43 				;Columna >= 43
	jge restringir_mouse 	;Inicia el juego
	jmp Waiting   			
 

	;=== Revisa si está presionando [Stop] ===
boton_stop_R: 				;Revisa si el mouse está entre R = 1,3
	cmp dx,3
	jbe boton_stop_C   		;Renglon >= 3?
	jmp mouse_no_clic		

	boton_stop_C: 			;Revisar si el mouse está entre C = 34,36
		cmp cx,36
		jbe boton_stop		;Columna <= 36
		jmp mouse_no_clic	

	boton_stop:
		cmp cx,34
		jge imprime_ui			;Reinicia el juego 
		jmp mouse_no_clic		

	;=== Comprueba si se puede mover y realiza el desplazamiento ===
player1_arriba:
	mov dl,[p1_ren]		;p1_ren = Mitad de la barra
	sub dl,3d 			;= -La otra mitad -1 desplazamiento
	cmp dl,5d			
	jge p1_arriba 		;Player1 >= 5 Entonces puede subir
	jmp ruta_pelota

	p1_arriba:
		dec [p1_ren] 									;Realiza el desplazamiento en la variable
		mov [ren_aux],dl 								;Guarda sus valores en var aux
		posiciona_cursor [ren_aux],[p1_col]
		imprime_caracter_color 219d,cBlanco,bgNegro 	;Imprime el desplazamiento 

		add [ren_aux],5d
		posiciona_cursor [ren_aux],[p1_col]
		imprime_caracter_color 219d,cNegro,bgNegro		;Borra lo restante de la barra

		jmp ruta_pelota 					

player1_abajo:
	mov dl,[p1_ren]		
	add dl,3d 			
	cmp dl,23d			;Player2 <= 23 Entonces puede bajar 
	jbe p1_abajo
	jmp ruta_pelota

	p1_abajo:
		inc [p1_ren]
		mov [ren_aux],dl
		posiciona_cursor [ren_aux],[p1_col]
		imprime_caracter_color 219d,cBlanco,bgNegro 	 

		sub [ren_aux],5d
		posiciona_cursor [ren_aux],[p1_col]
		imprime_caracter_color 219d,cNegro,bgNegro	
		jmp ruta_pelota

player2_arriba:
	mov dl,[p2_ren]
	sub dl,3d 
	cmp dl,5d
	jge p2_arriba
	jmp ruta_pelota

	p2_arriba:
		dec [p2_ren]
		mov [ren_aux],dl
		posiciona_cursor [ren_aux],[p2_col]
		imprime_caracter_color 219d,cBlanco,bgNegro 

		add [ren_aux],5d
		posiciona_cursor [ren_aux],[p2_col]
		imprime_caracter_color 219d,cNegro,bgNegro
		jmp ruta_pelota 

player2_abajo:
	mov dl,[p2_ren]		
	add dl,3d 			
	cmp dl,23d			
	jbe p2_abajo
	jmp ruta_pelota

	p2_abajo:
		inc [p2_ren]
		mov [ren_aux],dl
		posiciona_cursor [ren_aux],[p2_col]
		imprime_caracter_color 219d,cBlanco,bgNegro 	 

		sub [ren_aux],5d
		posiciona_cursor [ren_aux],[p2_col]
		imprime_caracter_color 219d,cNegro,bgNegro	
		jmp ruta_pelota

	;=== Cambiar sentido de pelota ===
negar_velocidad_col:
	NEG [velocidad_col]
	mov [rebote],1 			 ;Rebote = True
	jmp verificar_choque_ren

negar_velocidad_ren:
	NEG [velocidad_ren]
	jmp continuar_pelota	

	;=== Aumenta el score ===
score_player1:
	inc p1_score
	mov [col_aux],4
	mov bl,[p1_score]
	call IMPRIME_SCORE_BL
	call RESET_PELOTA
	jmp ruta_pelota

score_player2:
	inc p2_score
	mov [col_aux],76
	mov bl,[p2_score]
	call IMPRIME_SCORE_BL
	call RESET_PELOTA
	jmp ruta_pelota

	;=== Verifica si choco con p1 o p2 ===
verificar_choque_player1:
	call GET_PLAYER1			;Al = Limite Superior y Bl = Limite Inferior
	cmp [pelota_ren],al
	jge comprobar_box_inferior  		
	cmp [pelota_ren],bl
	jbe comprobar_box_superior
	jmp verificar_choque_ren

verificar_choque_player2:
	call GET_PLAYER2			;Al = Limite Superior y Bl = Limite Inferior
	cmp [pelota_ren],al
	jge comprobar_box_inferior  		
	cmp [pelota_ren],bl
	jbe comprobar_box_superior
	jmp verificar_choque_ren

comprobar_box_inferior:
		cmp [pelota_ren],bl
		jbe negar_velocidad_col
		jmp verificar_choque_ren
comprobar_box_superior:
		cmp [pelota_ren],al
		jge negar_velocidad_col
		jmp verificar_choque_ren

screen_ganador:
	call IMPRIME_GANADOR
	esperar_enter:
		xor ax,ax 				;Borra el buffer del teclado anterior
		mov ah,08h
		int 21h
		cmp al,0Dh				
		jnz esperar_enter		;Espera hasta que se presione [Enter]
		jmp imprime_ui			;Se presiono, entonces reinicia el juego

	;=== Sale al presionar [Enter] ===
teclado:     		
	mov ah,08h
	int 21h
	cmp al,0Dh		;0Dh = [Enter]
	jnz teclado 	

salir:	
	clear 			
	mov ax,4C00h	
	int 21h			
;____________________________________

;_______PROCEDIMIENTOS_______________
DIBUJA_UI proc
	;Esquinas superiores
	posiciona_cursor 0,0
	imprime_caracter_color marcoEsqSupIzq,cAmarillo,bgNegro
		
	posiciona_cursor 0,79
	imprime_caracter_color marcoEsqSupDer,cAmarillo,bgNegro
		
	;Esquina inferiores
	posiciona_cursor 24,0
	imprime_caracter_color marcoEsqInfIzq,cAmarillo,bgNegro
		
	posiciona_cursor 24,79
	imprime_caracter_color marcoEsqInfDer,cAmarillo,bgNegro
		
	;Marcos horizontales
	mov cx,78 			   ;Ancho
	marcos_horizontales:
		mov [col_aux],cl
		;Superior
			posiciona_cursor 0,[col_aux]
			imprime_caracter_color marcoHor,cAmarillo,bgNegro
		;Inferior
			posiciona_cursor 24,[col_aux]
			imprime_caracter_color marcoHor,cAmarillo,bgNegro
		;Limite mouse
			posiciona_cursor 4,[col_aux]
			imprime_caracter_color marcoHor,cAmarillo,bgNegro
		mov cl,[col_aux]
		loop marcos_horizontales

	;Marcos verticales
	mov cx,23 			   ;Altura
	marcos_verticales:
		mov [ren_aux],cl
		;Izquierdo
			posiciona_cursor [ren_aux],0
			imprime_caracter_color marcoVer,cAmarillo,bgNegro
		;Derecho
			posiciona_cursor [ren_aux],79
			imprime_caracter_color marcoVer,cAmarillo,bgNegro
		mov cl,[ren_aux]
		loop marcos_verticales

	;Marcos verticales internos
	mov cx,3 					;Altura 
	marcos_verticales_internos:
		mov [ren_aux],cl
		;Interno izquierdo (marcador player 1)
			posiciona_cursor [ren_aux],7
			imprime_caracter_color marcoVer,cAmarillo,bgNegro
		;Interno derecho (marcador player 2)
			posiciona_cursor [ren_aux],72
			imprime_caracter_color marcoVer,cAmarillo,bgNegro
		jmp marcos_verticales_internos_aux1

	marcos_verticales_internos_aux2:
		jmp marcos_verticales_internos

	marcos_verticales_internos_aux1:
		;Interno central izquierdo (Timer)
			posiciona_cursor [ren_aux],32
			imprime_caracter_color marcoVer,cAmarillo,bgNegro
		;Interno central derecho (Timer)
			posiciona_cursor [ren_aux],47
			imprime_caracter_color marcoVer,cAmarillo,bgNegro
		mov cl,[ren_aux]
		loop marcos_verticales_internos_aux2

	;Intersecciones internas	
	posiciona_cursor 0,7
	imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
	posiciona_cursor 4,7
	imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

	posiciona_cursor 0,32
	imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
	posiciona_cursor 4,32
	imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

	posiciona_cursor 0,47
	imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
	posiciona_cursor 4,47
	imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

	posiciona_cursor 0,72
	imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
	posiciona_cursor 4,72
	imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

	posiciona_cursor 4,0
	imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
	posiciona_cursor 4,79
	imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

	;Botón [X]
	posiciona_cursor 0,76
	imprime_caracter_color '[',cAmarillo,bgNegro
	posiciona_cursor 0,77
	imprime_caracter_color 'X',cRojoClaro,bgNegro
	posiciona_cursor 0,78
	imprime_caracter_color ']',cAmarillo,bgNegro

	;Título
	posiciona_cursor 0,38
	imprime_cadena_color [titulo],4,cBlanco,bgNegro

	call IMPRIME_DATOS_INICIALES
	ret
endp

IMPRIME_DATOS_INICIALES proc
	mov [tiempo_cadena],"1"
	mov [tiempo_cadena+2],"0"
	mov [tiempo_cadena+3],"0"

	;Imprime el score del player 1, en (col_aux,ren_aux)
	mov [col_aux],4
	mov bl,[p1_score]
	call IMPRIME_SCORE_BL

	;Imprime el score del player 2, en (col_aux,ren_aux)
	mov [col_aux],76
	mov bl,[p2_score]
	call IMPRIME_SCORE_BL

	;'Player 1'
	posiciona_cursor 2,9
	imprime_cadena_color player1,8,cBlanco,bgNegro
		
	;'Player 2'
	posiciona_cursor 2,63
	imprime_cadena_color player2,8,cBlanco,bgNegro

	;Cadena Timer
	posiciona_cursor 2,38
	imprime_cadena_color tiempo_cadena,4,cBlanco,bgNegro

	;Imprime barras -> Player 1
	mov al,[p1_col]			;AL = Columna
	mov ah,[p1_ren]			;AH = Renglon
	mov [col_aux],al
	mov [ren_aux],ah
	call IMPRIME_PLAYER

	;Imprime barras -> Player 2
	mov al,[p2_col]			
	mov ah,[p2_ren]			
	mov [col_aux],al
	mov [ren_aux],ah
	call IMPRIME_PLAYER

	;Imprime Pelota
	mov [col_aux],40
	mov [ren_aux],14
	call IMPRIME_PELOTA

	;Botón Stop
	mov [boton_caracter],254d
	mov [boton_color],bgAmarillo
	mov [boton_renglon],1
	mov [boton_columna],34
	call IMPRIME_BOTON

	;Botón Start
	mov [boton_caracter],16d
	mov [boton_color],bgAmarillo
	mov [boton_renglon],1
	mov [boton_columna],43d
	call IMPRIME_BOTON
	ret
endp
       
IMPRIME_SCORE_BL proc  	
	xor ah,ah
	mov al,bl
	mov [conta],0

	div10:
		xor dx,dx				
		div [diez]			;Dividir entre 10 para guardar cada caracter de la cifra
		push dx
		inc [conta]
		cmp ax,0
		ja div10

	imprime_digito:
		posiciona_cursor 2,[col_aux]
		pop dx
		or dl,30h
		imprime_caracter_color dl,cBlanco,bgNegro
		inc [col_aux]
		dec [conta]
		cmp [conta],0
		ja imprime_digito
	ret
endp

IMPRIME_PLAYER proc  		;Imprime la Barra con el carácter █ 5 veces
	posiciona_cursor [ren_aux],[col_aux]
	imprime_caracter_color 219d,cBlanco,bgNegro
	dec [ren_aux]
	posiciona_cursor [ren_aux],[col_aux]
	imprime_caracter_color 219d,cBlanco,bgNegro
	dec [ren_aux]
	posiciona_cursor [ren_aux],[col_aux]
	imprime_caracter_color 219d,cBlanco,bgNegro
	add [ren_aux],3
	posiciona_cursor [ren_aux],[col_aux]
	imprime_caracter_color 219d,cBlanco,bgNegro
	inc [ren_aux]
	posiciona_cursor [ren_aux],[col_aux]
	imprime_caracter_color 219d,cBlanco,bgNegro
	ret
endp

IMPRIME_PELOTA proc  			
	posiciona_cursor [ren_aux],[col_aux]
	imprime_caracter_color 2d,cCyanClaro,bgNegro  
	ret
endp

IMPRIME_BOTON proc   	;Imprime botón de 3x3,con parametros: 'boton_carácter', 'boton_color'
					 	; y posición: 'boton_renglon','boton_columna'

	mov ax,0600h 			;AH = 06h -> scroll up window
							;AL = 00h -> borrar
	mov bh,cRojo	 		;Color de caracter
	xor bh,[boton_color] 	;Color de fondo
	mov ch,[boton_renglon] 	;Renglón del Inicio del botón
	mov cl,[boton_columna] 	;Columna del Inicia el boton
	mov dh,ch 				;DH = Renglón del Inicio del botón botón
	add dh,2 				;DH = +2 [Obtener el renglón final]
	mov dl,cl 				;DL = Columna del Inicia el boton
	add dl,2 				;DL = +2 [Obtener la columna final]
	int 10h

	mov [col_aux],dl  		
	mov [ren_aux],dh      	
	dec [col_aux]			;Col -1 = Centro del botón
	dec [ren_aux] 			;Ren -1 = Centro del botón

	posiciona_cursor [ren_aux],[col_aux]
	imprime_caracter_color [boton_caracter],cRojo,[boton_color]
	ret 			
endp	 		

CRONO proc 					
	;=== Obtiene los ticks actuales ===
	mov ah,00h
	int 1Ah						;dx = [tiempo_actual]
	mov ax,[tiempo_inicial]		;ax = [tiempo_inicial]

	sub ax,dx					;Ticks transcurridos
	
	;=== Convertir de Ticks a Segundos y Minutos ===
	mul [tick_ms]
	div [mil]
	div [sesenta]				;AH = Segundos , AL = Minutos
	
	;=== Guardar ===
	mov [segundos],ah
	mov [minutos],al
	
	;=== ¿Se termino el timer? ===
	cmp [minutos],0
	je comprobar_segundos
	jmp continuar_tiempo

	comprobar_segundos:
		cmp [segundos],0
		je screen_ganador

	continuar_tiempo:
		;==== Imprimir ====
		mov dl,[minutos]
		or dl,30h				
		mov [tiempo_cadena],dl

		xor ah,ah
		mov al,[segundos]
		aam 						;Ascii Adjust for Multiplication
		or ax,3030h
		mov [tiempo_cadena+2],ah 	;Decenas
		mov [tiempo_cadena+3],al    ;Unidades
	
		posiciona_cursor 2,38
		imprime_cadena_color tiempo_cadena,4,cBlanco,bgNegro
	ret
endp

RESET_PELOTA proc
	;=== Borra la actual pelota ===
	posiciona_cursor [pelota_ren],[pelota_col]
	imprime_caracter_color 219d,cNegro,bgNegro

	;=== Cambia los valores a los iniciales ===
	mov [pelota_col],40
	mov [pelota_ren],14

	;=== Imprime ===
	mov [col_aux],40
	mov [ren_aux],14
	call IMPRIME_PELOTA
	ret 
endp

GET_PLAYER1 proc		
	mov al,[p1_ren]
	sub al,2d 				;Al = Limite Superior
	mov bl,[p1_ren]
	add bl,2d 				;Bl = Limite Inferior
	ret
endp

GET_PLAYER2 proc
	mov al,[p2_ren]
	sub al,2d 				;Al = Limite Superior
	mov bl,[p2_ren]
	add bl,2d 				;Bl = Limite Inferior
	ret
endp

IMPRIME_GANADOR proc
	clear
	posiciona_cursor 8,33
	imprime_cadena_color game_over,9,cBlanco,bgNegro

	posiciona_cursor 9,31
	imprime_cadena_color cadena_ganador,15,cBlanco,bgNegro

	posiciona_cursor 13,23
	imprime_cadena_color cadena_continuar,35,cBlanco,bgNegro
	
	mov al,[p1_score]
	cmp al,[p2_score]
	je es_empate 			;Si son iguales, empate
	cmp al,[p2_score]
	ja ganador_p1			;Si p1 > p2
	jmp ganador_p2 			;De lo contario p1 < p2

	es_empate:
		posiciona_cursor 11,26
		imprime_cadena_color empate,22,cBlanco,bgNegro
		ret

	ganador_p1:
		posiciona_cursor 11,34
		imprime_cadena_color player1,8,cBlanco,bgNegro
		ret

	ganador_p2:
		posiciona_cursor 11,34
		imprime_cadena_color player2,8,cBlanco,bgNegro
		ret
endp
;____________________________________

;___________FIN______________________
	end inicio			
