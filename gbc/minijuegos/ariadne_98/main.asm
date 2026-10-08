; ARIADNE 98 - vertical navegable (#2313/#2368/#2369).
; Laberinto cenital manual y determinista en 3 niveles con Minotauro telegráfico.
; Arte geométrico original del proyecto. Licencia MIT.

DEF rP1    EQU $FF00
DEF rLCDC  EQU $FF40
DEF rSCY   EQU $FF42
DEF rSCX   EQU $FF43
DEF rLY    EQU $FF44
DEF rBGP   EQU $FF47
DEF rIF    EQU $FF0F
DEF rBCPS  EQU $FF68
DEF rBCPD  EQU $FF69
DEF rIE    EQU $FFFF

DEF VRAM_TILES EQU $8000
DEF BG_MAP EQU $9800

DEF KEY_RIGHT EQU %00000001
DEF KEY_LEFT  EQU %00000010
DEF KEY_UP    EQU %00000100
DEF KEY_DOWN  EQU %00001000
DEF KEY_A     EQU %00010000
DEF KEY_START EQU %10000000

DEF ESTADO_TITULO EQU 0
DEF ESTADO_JUEGO  EQU 1
DEF ESTADO_SALIDA EQU 2

DEF NIVEL_ENTRADA  EQU 0
DEF NIVEL_GALERIAS EQU 1
DEF NIVEL_CENTRO   EQU 2

DEF TILE_SUELO          EQU 0
DEF TILE_MURO           EQU 1
DEF TILE_ARIADNE        EQU 2
DEF TILE_SALIDA         EQU 3
DEF TILE_A              EQU 4
DEF TILE_R              EQU 5
DEF TILE_I              EQU 6
DEF TILE_D              EQU 7
DEF TILE_N              EQU 8
DEF TILE_E              EQU 9
DEF TILE_9              EQU 10
DEF TILE_8              EQU 11
DEF TILE_1              EQU 12
DEF TILE_H              EQU 13
DEF TILE_L              EQU 14
DEF TILE_ALERTA         EQU 15
DEF TILE_HILO           EQU 16
DEF TILE_PUERTA         EQU 17
DEF TILE_CENTRO         EQU 18
DEF TILE_TRANSICION     EQU 19
DEF TILE_MINOTAURO      EQU 20
DEF TILE_2              EQU 21
DEF TILE_3              EQU 22

DEF HILO_MAX EQU 9

DEF LAB_ANCHO EQU 16
DEF LAB_ALTO  EQU 12
DEF LAB_X     EQU 2
DEF LAB_Y     EQU 4

INCLUDE "../comun/cartucho.asm"

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "ARIADNE98"
    ds $0143 - @, 0
    db $80
    ds $0150 - @, 0

SECTION "Juego", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF
    call IniciarCartucho

.espera_vblank:
    ldh a, [rLY]
    cp 144
    jr c, .espera_vblank

    xor a
    ldh [rLCDC], a
    ldh [rSCX], a
    ldh [rSCY], a
    ldh [rIF], a
    ld [wEstado], a
    ld [wTeclas], a
    ld [wTeclasPrevias], a
    ld [wTeclasNuevas], a
    ld [wCentroAlcanzado], a
    ld [wPuertaGaleriasAbierta], a

    call CargarTiles
    call ConfigurarPaletas
    call DibujarTitulo
    call ActivarLCD

Bucle:
    halt
    call LeerControles

    ld a, [wEstado]
    or a
    jr z, EstadoTitulo
    cp ESTADO_JUEGO
    jr z, EstadoJuego
    jr EstadoSalida

EstadoTitulo:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call IniciarJuego
    jr Bucle

EstadoJuego:
    ld a, [wTeclasNuevas]
    and KEY_START
    jr z, .no_reiniciar
    call IniciarJuego
    jr Bucle
.no_reiniciar:
    ld a, [wTeclasNuevas]
    and KEY_A
    jr z, .no_hilo
    call AlternarHilo
    jr Bucle
.no_hilo:
    ld a, [wTeclasNuevas]
    and KEY_LEFT
    jr nz, .izquierda
    ld a, [wTeclasNuevas]
    and KEY_RIGHT
    jr nz, .derecha
    ld a, [wTeclasNuevas]
    and KEY_UP
    jr nz, .arriba
    ld a, [wTeclasNuevas]
    and KEY_DOWN
    jr nz, .abajo
    jr Bucle
.izquierda:
    call MoverIzquierda
    jr Bucle
.derecha:
    call MoverDerecha
    jr Bucle
.arriba:
    call MoverArriba
    jr Bucle
.abajo:
    call MoverAbajo
    jr Bucle

EstadoSalida:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call MostrarTitulo
    jr Bucle

IniciarJuego:
    call DesactivarLCD
    call LimpiarFondo
    xor a
    ld [wNivelActual], a
    ld [wCentroAlcanzado], a
    ld [wPuertaGaleriasAbierta], a
    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ReiniciarHilo
    ld a, 1
    ld b, 1
    call CargarNivel
    call ActivarLCD
    ret

; Cargar nivel en A, con posicion inicial B=x, C=y.
CargarNivel:
    push bc
    ld [wNivelActual], a
    call ReiniciarMinotauro
    pop bc
    ld a, b
    ld [wJugadorX], a
    ld [wCruceSeguroX], a
    ld a, c
    ld [wJugadorY], a
    ld [wCruceSeguroY], a

    call DesactivarLCD
    call LimpiarFondo
    call DibujarHUD
    call DibujarLaberinto
    call DibujarJugador
    call DibujarMinotauro
    call ActivarLCD
    ret

MoverIzquierda:
    ld a, [wJugadorX]
    dec a
    ld b, a
    ld a, [wJugadorY]
    ld c, a
    jr IntentarMover

MoverDerecha:
    ld a, [wJugadorX]
    inc a
    ld b, a
    ld a, [wJugadorY]
    ld c, a
    jr IntentarMover

MoverArriba:
    ld a, [wJugadorX]
    ld b, a
    ld a, [wJugadorY]
    dec a
    ld c, a
    jr IntentarMover

MoverAbajo:
    ld a, [wJugadorX]
    ld b, a
    ld a, [wJugadorY]
    inc a
    ld c, a

IntentarMover:
    call TileMapaBC
    cp TILE_MURO
    ret z
    cp TILE_PUERTA
    jr nz, .no_puerta
    ; Si la puerta está cerrada, bloquea
    ld a, [wPuertaGaleriasAbierta]
    or a
    ret z
.no_puerta:
    push af
    call BorrarJugador
    call GestionarHilo
    ld a, b
    ld [wJugadorX], a
    ld a, c
    ld [wJugadorY], a

    ; El Minotauro avanza en su patrón determinista tras cada intento de paso
    call AvanzarMinotauro

    ; Comprobar contacto con Minotauro primero (tras el movimiento de ambos)
    call ComprobarContactoMinotauro

    ; Actualizar cruce seguro solo si Ariadne no sufrió colisión en esta casilla
    call ActualizarCruceSeguro

    call RedibujarHilo
    call DibujarJugador
    call DibujarMinotauro
    call ActualizarHUDHilo

    pop af

    ; Comprobar celdas especiales (Transiciones, Centro, Salida)
    cp TILE_TRANSICION
    jr z, .transicion
    cp TILE_CENTRO
    jr z, .centro
    cp TILE_SALIDA
    jr z, .salida
    ret

.transicion:
    call ProcesarTransicion
    ret

.centro:
    ld a, 1
    ld [wCentroAlcanzado], a
    ld [wPuertaGaleriasAbierta], a ; Al alcanzar el centro se abre el atajo en Galerias
    call RedibujarCasillaCentro
    call ActualizarHUDHilo
    ret

.salida:
    ; Victoria solo si ya se alcanzo el Centro y se regreso a Entrada
    ld a, [wCentroAlcanzado]
    or a
    ret z
    call MostrarSalida
    ret

ProcesarTransicion:
    ld a, [wNivelActual]
    cp NIVEL_ENTRADA
    jr z, .de_entrada_a_galerias
    cp NIVEL_GALERIAS
    jr z, .de_galerias
    cp NIVEL_CENTRO
    jr z, .de_centro_a_galerias
    ret

.de_entrada_a_galerias:
    ld a, NIVEL_GALERIAS
    ld b, 1
    ld c, 1
    call CargarNivel
    ret

.de_galerias:
    ; En Galerias, la transicion en (1,1) regresa a Entrada, en (14,10) va a Centro.
    ld a, [wJugadorX]
    cp 8
    jr c, .de_galerias_a_entrada
    ld a, NIVEL_CENTRO
    ld b, 1
    ld c, 1
    call CargarNivel
    ret
.de_galerias_a_entrada:
    ld a, NIVEL_ENTRADA
    ld b, 14
    ld c, 1
    call CargarNivel
    ret

.de_centro_a_galerias:
    ld a, NIVEL_GALERIAS
    ld b, 14
    ld c, 10
    call CargarNivel
    ret

ActualizarCruceSeguro:
    ; Un cruce seguro se actualiza solo si Ariadne no está en la misma celda que el Minotauro
    ld a, [wMinotauroActivo]
    or a
    jr z, .guardar
    ld a, [wJugadorX]
    ld b, a
    ld a, [wMinotauroX]
    cp b
    jr nz, .guardar
    ld a, [wJugadorY]
    ld b, a
    ld a, [wMinotauroY]
    cp b
    ret z
.guardar:
    ld a, [wJugadorX]
    ld [wCruceSeguroX], a
    ld a, [wJugadorY]
    ld [wCruceSeguroY], a
    ret

ComprobarContactoMinotauro:
    ld a, [wMinotauroActivo]
    or a
    ret z
    ld a, [wJugadorX]
    ld b, a
    ld a, [wMinotauroX]
    cp b
    ret nz
    ld a, [wJugadorY]
    ld b, a
    ld a, [wMinotauroY]
    cp b
    ret nz

    ; Contacto! Ariadne reaparece en el ultimo cruce seguro.
    ; NUNCA borra progreso externo (wCentroAlcanzado / wPuertaGaleriasAbierta).
    call BorrarJugador
    ld a, [wCruceSeguroX]
    ld [wJugadorX], a
    ld a, [wCruceSeguroY]
    ld [wJugadorY], a
    call DibujarJugador
    ret

ReiniciarMinotauro:
    xor a
    ld [wMinotauroPaso], a
    ld [wMinotauroAlerta], a
    ld a, [wNivelActual]
    cp NIVEL_GALERIAS
    jr z, .activo_galerias
    cp NIVEL_CENTRO
    jr z, .activo_centro
    xor a
    ld [wMinotauroActivo], a
    ret

.activo_galerias:
    ld a, 1
    ld [wMinotauroActivo], a
    ld a, 8
    ld [wMinotauroX], a
    ld a, 3
    ld [wMinotauroY], a
    ret

.activo_centro:
    ld a, 1
    ld [wMinotauroActivo], a
    ld a, 7
    ld [wMinotauroX], a
    ld a, 5
    ld [wMinotauroY], a
    ret

AvanzarMinotauro:
    ld a, [wMinotauroActivo]
    or a
    ret z

    call BorrarMinotauro

    ld a, [wNivelActual]
    cp NIVEL_GALERIAS
    jr z, .patron_galerias
    cp NIVEL_CENTRO
    jr z, .patron_centro
    ret

.patron_galerias:
    ld a, [wMinotauroPaso]
    inc a
    and $07 ; 8 pasos
    ld [wMinotauroPaso], a
    ld e, a
    ld d, 0
    ld hl, PatronMinotauroGalerias
    add hl, de
    ld a, [hl]
    ld b, a
    swap a
    and $0F
    ld [wMinotauroY], a
    ld a, b
    and $0F
    ld [wMinotauroX], a
    call EvaluarAlertaMinotauro
    ret

.patron_centro:
    ld a, [wMinotauroPaso]
    inc a
    and $07 ; 8 pasos
    ld [wMinotauroPaso], a
    ld e, a
    ld d, 0
    ld hl, PatronMinotauroCentro
    add hl, de
    ld a, [hl]
    ld b, a
    swap a
    and $0F
    ld [wMinotauroY], a
    ld a, b
    and $0F
    ld [wMinotauroX], a
    call EvaluarAlertaMinotauro
    ret

EvaluarAlertaMinotauro:
    ; Alerta telegráfica si el Minotauro está a distancia Manhattan <= 3 de Ariadne
    ld a, [wJugadorX]
    ld b, a
    ld a, [wMinotauroX]
    sub b
    jr nc, .dx_pos
    cpl
    inc a
.dx_pos:
    ld c, a

    ld a, [wJugadorY]
    ld b, a
    ld a, [wMinotauroY]
    sub b
    jr nc, .dy_pos
    cpl
    inc a
.dy_pos:
    add c
    cp 4
    jr c, .alerta_on
    xor a
    ld [wMinotauroAlerta], a
    ret
.alerta_on:
    ld a, 1
    ld [wMinotauroAlerta], a
    ret

MostrarTitulo:
    call DesactivarLCD
    call DibujarTitulo
    call ActivarLCD
    ret

DibujarTitulo:
    call LimpiarFondo

    ld a, TILE_A
    ld [BG_MAP + (6 * 32) + 5], a
    ld [BG_MAP + (6 * 32) + 8], a
    ld a, TILE_R
    ld [BG_MAP + (6 * 32) + 6], a
    ld a, TILE_I
    ld [BG_MAP + (6 * 32) + 7], a
    ld a, TILE_D
    ld [BG_MAP + (6 * 32) + 9], a
    ld a, TILE_N
    ld [BG_MAP + (6 * 32) + 10], a
    ld a, TILE_E
    ld [BG_MAP + (6 * 32) + 11], a
    ld a, TILE_9
    ld [BG_MAP + (6 * 32) + 13], a
    ld a, TILE_8
    ld [BG_MAP + (6 * 32) + 14], a

    ; Motivo de portada: Ariadne frente a una salida de laberinto.
    ld a, TILE_MURO
    ld [BG_MAP + (10 * 32) + 7], a
    ld [BG_MAP + (10 * 32) + 8], a
    ld [BG_MAP + (10 * 32) + 11], a
    ld [BG_MAP + (10 * 32) + 12], a
    ld [BG_MAP + (11 * 32) + 7], a
    ld [BG_MAP + (11 * 32) + 12], a
    ld [BG_MAP + (12 * 32) + 7], a
    ld [BG_MAP + (12 * 32) + 12], a
    ld a, TILE_ARIADNE
    ld [BG_MAP + (11 * 32) + 9], a
    ld a, TILE_SALIDA
    ld [BG_MAP + (11 * 32) + 11], a

    xor a
    ld [wEstado], a
    ret

MostrarSalida:
    call DesactivarLCD
    call LimpiarFondo

    ; Pantalla de victoria tras alcanzar el Centro y regresar
    ld a, TILE_SALIDA
    ld [BG_MAP + (7 * 32) + 9], a
    ld a, TILE_ARIADNE
    ld [BG_MAP + (10 * 32) + 9], a

    ld a, TILE_A
    ld [BG_MAP + (13 * 32) + 5], a
    ld a, TILE_R
    ld [BG_MAP + (13 * 32) + 6], a
    ld a, TILE_I
    ld [BG_MAP + (13 * 32) + 7], a
    ld a, TILE_A
    ld [BG_MAP + (13 * 32) + 8], a
    ld a, TILE_D
    ld [BG_MAP + (13 * 32) + 9], a
    ld a, TILE_N
    ld [BG_MAP + (13 * 32) + 10], a
    ld a, TILE_E
    ld [BG_MAP + (13 * 32) + 11], a

    ld a, ESTADO_SALIDA
    ld [wEstado], a
    call ActivarLCD
    ret

DibujarHUD:
    ; Nivel a la izquierda (L1, L2, L3); hilo en el centro; alerta a la derecha.
    ld a, TILE_L
    ld [BG_MAP], a
    ld a, [wNivelActual]
    or a
    jr z, .n1
    cp NIVEL_GALERIAS
    jr z, .n2
    ld a, TILE_3
    jr .set_num
.n2:
    ld a, TILE_2
    jr .set_num
.n1:
    ld a, TILE_1
.set_num:
    ld [BG_MAP + 1], a

    ld a, TILE_H
    ld [BG_MAP + 7], a

    call ActualizarHUDHilo
    ret

AlternarHilo:
    ld a, [wHiloActivo]
    xor 1
    and 1
    ld [wHiloActivo], a
    call ActualizarHUDHilo
    ret

ReiniciarHilo:
    ld a, HILO_MAX
    ld [wHiloRestante], a
    ld a, 1
    ld [wHiloActivo], a
    xor a
    ld [wHiloSegmentos], a
    ld hl, wHiloDesde
    ld b, HILO_MAX * 2
.limpiar:
    ld [hli], a
    dec b
    jr nz, .limpiar
    ret

ActualizarHUDHilo:
    ; Una marca junto a H indica que el tendido está activo.
    xor a
    ld [BG_MAP + 6], a
    ld a, [wHiloActivo]
    or a
    jr z, .marcas
    ld a, TILE_HILO
    ld [BG_MAP + 6], a
.marcas:
    ld hl, BG_MAP + 8
    ld a, [wHiloRestante]
    ld c, a
    ld b, HILO_MAX
.bucle:
    ld a, c
    or a
    jr z, .vacia
    ld a, TILE_HILO
    ld [hli], a
    dec c
    jr .siguiente
.vacia:
    xor a
    ld [hli], a
.siguiente:
    dec b
    jr nz, .bucle

.alerta:
    ; Icono de alerta telegráfica en HUD
    xor a
    ld [BG_MAP + 19], a
    ld a, [wMinotauroAlerta]
    or a
    ret z
    ld a, TILE_ALERTA
    ld [BG_MAP + 19], a
    ret

; B=x destino, C=y destino. Mantiene una pila de aristas tendidas.
GestionarHilo:
    push bc

    ; Empaquetar destino (yyyyxxxx).
    ld a, c
    swap a
    and $F0
    or b
    ld [wMovimientoHasta], a

    ; Empaquetar origen actual.
    ld a, [wJugadorY]
    swap a
    and $F0
    ld c, a
    ld a, [wJugadorX]
    or c
    ld [wMovimientoDesde], a

    ; ¿Es exactamente el último tramo en sentido inverso?
    ld a, [wHiloSegmentos]
    or a
    jr z, .tender
    dec a
    ld e, a
    ld d, 0
    ld hl, wHiloDesde
    add hl, de
    ld a, [wMovimientoHasta]
    cp [hl]
    jr nz, .buscar_existente
    ld hl, wHiloHasta
    add hl, de
    ld a, [wMovimientoDesde]
    cp [hl]
    jr nz, .buscar_existente

    ld a, [wHiloSegmentos]
    dec a
    ld [wHiloSegmentos], a
    ld a, [wHiloRestante]
    cp HILO_MAX
    jr nc, .actualizar_recogida
    inc a
    ld [wHiloRestante], a
.actualizar_recogida:
    call ActualizarHUDHilo
    jr .fin

.buscar_existente:
    ; Evita duplicar una arista ya tendida, en cualquiera de sus sentidos.
    ld a, [wHiloSegmentos]
    ld b, a
    xor a
    ld c, a
.buscar:
    ld a, b
    or a
    jr z, .tender
    ld e, c
    ld d, 0

    ld hl, wHiloDesde
    add hl, de
    ld a, [wMovimientoDesde]
    cp [hl]
    jr nz, .probar_inversa
    ld hl, wHiloHasta
    add hl, de
    ld a, [wMovimientoHasta]
    cp [hl]
    jr z, .fin

.probar_inversa:
    ld hl, wHiloDesde
    add hl, de
    ld a, [wMovimientoHasta]
    cp [hl]
    jr nz, .siguiente_existente
    ld hl, wHiloHasta
    add hl, de
    ld a, [wMovimientoDesde]
    cp [hl]
    jr z, .fin

.siguiente_existente:
    inc c
    dec b
    jr .buscar

.tender:
    ld a, [wHiloActivo]
    or a
    jr z, .fin
    ld a, [wHiloRestante]
    or a
    jr z, .fin
    ld a, [wHiloSegmentos]
    cp HILO_MAX
    jr nc, .fin

    ld c, a
    ld e, c
    ld d, 0
    ld hl, wHiloDesde
    add hl, de
    ld a, [wMovimientoDesde]
    ld [hl], a
    ld hl, wHiloHasta
    add hl, de
    ld a, [wMovimientoHasta]
    ld [hl], a

    ld a, [wHiloSegmentos]
    inc a
    ld [wHiloSegmentos], a
    ld a, [wHiloRestante]
    dec a
    ld [wHiloRestante], a
    call ActualizarHUDHilo
.fin:
    pop bc
    ret

RedibujarHilo:
    ld a, [wHiloSegmentos]
    or a
    ret z
    ld d, a
    ld hl, wHiloHasta
.bucle:
    ld a, [hli]
    push hl
    push de
    ld c, a
    and $0F
    ld b, a
    ld a, c
    swap a
    and $0F
    ld c, a
    call PosicionBGBC
    ld a, TILE_HILO
    ld [hl], a
    pop de
    pop hl
    dec d
    jr nz, .bucle
    ret

ObtenerPunteroLaberinto:
    ld a, [wNivelActual]
    or a
    jr z, .entrada
    cp NIVEL_GALERIAS
    jr z, .galerias
    ld de, LaberintoCentro
    ret
.entrada:
    ld de, LaberintoEntrada
    ret
.galerias:
    ld de, LaberintoGalerias
    ret

DibujarLaberinto:
    call ObtenerPunteroLaberinto
    ld hl, BG_MAP + (LAB_Y * 32) + LAB_X
    ld c, LAB_ALTO
.fila:
    ld b, LAB_ANCHO
.columna:
    ld a, [de]
    inc de
    ; Si es la puerta de Galerías y está abierta, dibujarla como suelo
    cp TILE_PUERTA
    jr nz, .comprobar_centro
    push af
    ld a, [wPuertaGaleriasAbierta]
    or a
    jr z, .puerta_cerrada
    pop af
    ld a, TILE_SUELO
    jr .dibujar
.puerta_cerrada:
    pop af
    jr .dibujar

.comprobar_centro:
    cp TILE_CENTRO
    jr nz, .dibujar
    push af
    ld a, [wCentroAlcanzado]
    or a
    jr z, .centro_no_alcanzado
    pop af
    ld a, TILE_SUELO
    jr .dibujar
.centro_no_alcanzado:
    pop af

.dibujar:
    ld [hli], a
    dec b
    jr nz, .columna

    ld a, l
    add 32 - LAB_ANCHO
    ld l, a
    jr nc, .sin_carry
    inc h
.sin_carry:
    dec c
    jr nz, .fila
    ret

RedibujarCasillaCentro:
    ld b, 14
    ld c, 10
    call PosicionBGBC
    ld a, TILE_SUELO
    ld [hl], a
    ret

DibujarJugador:
    ld a, [wJugadorX]
    ld b, a
    ld a, [wJugadorY]
    ld c, a
    call PosicionBGBC
    ld a, TILE_ARIADNE
    ld [hl], a
    ret

BorrarJugador:
    ld a, [wJugadorX]
    ld b, a
    ld a, [wJugadorY]
    ld c, a
    call TileMapaBC
    ; Si la celda era la puerta y está abierta, borrar a suelo
    cp TILE_PUERTA
    jr nz, .comprobar_centro
    ld a, [wPuertaGaleriasAbierta]
    or a
    jr z, .restaurar_tile
    ld a, TILE_SUELO
    jr .restaurar_tile

.comprobar_centro:
    cp TILE_CENTRO
    jr nz, .restaurar_tile
    ld a, [wCentroAlcanzado]
    or a
    jr z, .restaurar_tile
    ld a, TILE_SUELO

.restaurar_tile:
    ld d, a
    ld a, [wJugadorX]
    ld b, a
    ld a, [wJugadorY]
    ld c, a
    call PosicionBGBC
    ld a, d
    ld [hl], a
    ret

DibujarMinotauro:
    ld a, [wMinotauroActivo]
    or a
    ret z
    ld a, [wMinotauroX]
    ld b, a
    ld a, [wMinotauroY]
    ld c, a
    call PosicionBGBC
    ld a, TILE_MINOTAURO
    ld [hl], a
    ret

BorrarMinotauro:
    ld a, [wMinotauroActivo]
    or a
    ret z
    ld a, [wMinotauroX]
    ld b, a
    ld a, [wMinotauroY]
    ld c, a
    call TileMapaBC
    ; Si la celda era la puerta o centro alcanzado, borrar a suelo
    cp TILE_PUERTA
    jr nz, .comprobar_centro_mino
    ld a, [wPuertaGaleriasAbierta]
    or a
    jr z, .restaurar_tile_mino
    ld a, TILE_SUELO
    jr .restaurar_tile_mino

.comprobar_centro_mino:
    cp TILE_CENTRO
    jr nz, .restaurar_tile_mino
    ld a, [wCentroAlcanzado]
    or a
    jr z, .restaurar_tile_mino
    ld a, TILE_SUELO

.restaurar_tile_mino:
    ld d, a
    ld a, [wMinotauroX]
    ld b, a
    ld a, [wMinotauroY]
    ld c, a
    call PosicionBGBC
    ld a, d
    ld [hl], a
    ret

; B=x, C=y. Devuelve en A el tile lógico del mapa manual actual.
TileMapaBC:
    ld a, c
    swap a
    and $F0
    add b
    ld e, a
    ld d, 0
    call ObtenerPunteroLaberinto
    add hl, de
    ld a, [hl]
    ret

; B=x, C=y. Devuelve HL apuntando a la celda visible correspondiente.
PosicionBGBC:
    ld a, c
    add LAB_Y
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld de, BG_MAP + LAB_X
    add hl, de
    ld a, b
    ld e, a
    ld d, 0
    add hl, de
    ret

LeerControles:
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    ld b, a

    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    swap a
    or b
    ld b, a

    ld a, $30
    ldh [rP1], a

    ld a, [wTeclas]
    ld [wTeclasPrevias], a
    xor b
    and b
    ld [wTeclasNuevas], a
    ld a, b
    ld [wTeclas], a
    ret

DesactivarLCD:
    di
.espera:
    ldh a, [rLY]
    cp 144
    jr c, .espera
    xor a
    ldh [rLCDC], a
    ret

ActivarLCD:
    xor a
    ldh [rIF], a
    ld a, 1
    ldh [rIE], a
    ld a, $91
    ldh [rLCDC], a
    ei
    ret

LimpiarFondo:
    ld hl, BG_MAP
    ld bc, 32 * 32
.bucle:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .bucle
    ret

CargarTiles:
    ld de, Tiles
    ld hl, VRAM_TILES
    ld bc, TilesFin - Tiles
.bucle:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .bucle
    ret

ConfigurarPaletas:
    ld a, %11100100
    ldh [rBGP], a
    ld a, $80
    ldh [rBCPS], a
    ld hl, PaletaCGB
    ld b, 8
.cgb:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .cgb
    ret

SECTION "Datos", ROM0

; 16x12, borde cerrado.
; Tiles: 0=suelo, 1=muro, 3=salida, 17=puerta/atajo, 18=centro, 19=transicion

; Nivel 1: Entrada. Conecta con Salida (14,10) y Transición a Galerías (14,1).
LaberintoEntrada:
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,0,0,0,0,1,0,0,0,0,0,0,0,0,19,1
    db 1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,1
    db 1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,1
    db 1,0,1,1,1,1,1,1,1,1,1,1,0,1,0,1
    db 1,0,0,0,0,0,0,0,0,0,0,1,0,1,0,1
    db 1,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1
    db 1,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1
    db 1,0,1,1,1,1,1,1,0,1,0,1,1,1,1,1
    db 1,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1
    db 1,1,1,1,1,1,0,0,0,1,1,1,1,1,3,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Nivel 2: Galerías.
; Transición a Entrada en (1,1). Transición a Centro en (14,10).
; Bifurcación:
;  - Ruta larga segura: Pasillo superior/izquierdo bordeando las salas.
;  - Ruta corta expuesta: Pasillo central directo con compuerta (17) y patrulla del Minotauro.
LaberintoGalerias:
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,19,0,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1
    db 1,0,1,1,1,1,1,1,17,1,1,1,0,1,0,1
    db 1,0,1,0,0,0,0,0,0,0,0,1,0,1,0,1
    db 1,0,1,0,1,1,1,1,1,1,0,1,0,1,0,1
    db 1,0,0,0,1,0,0,0,0,1,0,0,0,0,0,1
    db 1,1,1,0,1,0,1,1,0,1,1,1,1,1,0,1
    db 1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1
    db 1,0,1,1,1,1,1,1,1,1,1,1,1,1,19,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Nivel 3: Centro.
; Transición de retorno a Galerías en (1,1). Centro/Altar en (14,10).
LaberintoCentro:
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,19,0,0,0,1,0,0,0,0,0,0,0,0,0,1
    db 1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,1
    db 1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1
    db 1,0,1,1,1,1,1,1,1,1,0,1,0,1,1,1
    db 1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1
    db 1,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1
    db 1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1
    db 1,0,1,1,0,1,0,1,1,1,1,1,0,1,0,1
    db 1,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1
    db 1,1,0,1,1,1,1,1,1,1,0,1,1,1,18,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Secuencia determinista de coordenadas (yyyyxxxx) para la patrulla del Minotauro en Galerías.
PatronMinotauroGalerias:
    db $38, $39, $3A, $3B, $3B, $3A, $39, $38

; Secuencia determinista de coordenadas (yyyyxxxx) para el Minotauro en Centro.
PatronMinotauroCentro:
    db $57, $58, $59, $69, $79, $69, $59, $58

PaletaCGB:
    dw $7FFF, $56B5, $2D6B, $1084

Tiles:
    ; 0 suelo
    db 0,0, 0,0, 0,0, %00010000,0
    db 0,0, 0,0, 0,0, 0,0
    ; 1 muro
    db $FF,$FF, $81,$FF, $BD,$C3, $A5,$DB
    db $A5,$DB, $BD,$C3, $81,$FF, $FF,$FF
    ; 2 Ariadne
    db %00011000,0, %00111100,0, %00011000,0, %01111110,0
    db %00011000,0, %00100100,0, %01000010,0, %10000001,0
    ; 3 salida
    db %00111100,%00111100, %01100110,%01100110, %11000011,%11000011, %10000001,%10000001
    db %10011001,%10011001, %11000011,%11000011, %01100110,%01100110, %00111100,%00111100
    ; 4 A
    db %00111100,0, %01100110,0, %11000011,0, %11000011,0
    db %11111111,0, %11000011,0, %11000011,0, %11000011,0
    ; 5 R
    db %11111100,0, %11000110,0, %11000110,0, %11111100,0
    db %11011000,0, %11001100,0, %11000110,0, %11000011,0
    ; 6 I
    db %11111111,0, %00011000,0, %00011000,0, %00011000,0
    db %00011000,0, %00011000,0, %00011000,0, %11111111,0
    ; 7 D
    db %11111000,0, %11001100,0, %11000110,0, %11000011,0
    db %11000011,0, %11000110,0, %11001100,0, %11111000,0
    ; 8 N
    db %11000011,0, %11100011,0, %11110011,0, %11011011,0
    db %11001111,0, %11000111,0, %11000011,0, %11000011,0
    ; 9 E
    db %11111111,0, %11000000,0, %11000000,0, %11111100,0
    db %11000000,0, %11000000,0, %11000000,0, %11111111,0
    ; 10 9
    db %00111100,0, %01100110,0, %11000011,0, %01111111,0
    db %00000011,0, %00000110,0, %01101100,0, %00111000,0
    ; 11 8
    db %00111100,0, %01100110,0, %01100110,0, %00111100,0
    db %01100110,0, %11000011,0, %01100110,0, %00111100,0
    ; 12 1
    db %00011000,0, %00111000,0, %00011000,0, %00011000,0
    db %00011000,0, %00011000,0, %00011000,0, %00111100,0
    ; 13 H
    db %11000011,0, %11000011,0, %11000011,0, %11111111,0
    db %11000011,0, %11000011,0, %11000011,0, %11000011,0
    ; 14 L
    db %11000000,0, %11000000,0, %11000000,0, %11000000,0
    db %11000000,0, %11000000,0, %11000000,0, %11111111,0
    ; 15 alerta
    db %00011000,0, %00011000,0, %00011000,0, %00011000,0
    db %00011000,0, 0,0, %00011000,0, 0,0
    ; 16 hilo / marca de recurso
    db 0,0, %00011000,0, %00111100,0, %01111110,0
    db %01111110,0, %00111100,0, %00011000,0, 0,0
    ; 17 puerta / compuerta atajo
    db %11111111,%11111111, %10000001,%10000001, %10111101,%10111101, %10100101,%10100101
    db %10100101,%10100101, %10111101,%10111101, %10000001,%10000001, %11111111,%11111111
    ; 18 centro del laberinto / altar
    db %00111100,0, %01111110,0, %11011011,0, %11111111,0
    db %11111111,0, %11011011,0, %01111110,0, %00111100,0
    ; 19 transicion de nivel
    db %00000000,0, %00111100,0, %01111110,0, %01100110,0
    db %01100110,0, %01111110,0, %00111100,0, %00000000,0
    ; 20 minotauro
    db %11000011,%11000011, %01100110,%01100110, %00111100,%00111100, %01111110,%01111110
    db %11111111,%11111111, %01100110,%01100110, %11000011,%11000011, %10000001,%10000001
    ; 21 2
    db %00111100,0, %01100110,0, %00000110,0, %00011100,0
    db %00110000,0, %01100000,0, %11111111,0, %11111111,0
    ; 22 3
    db %00111100,0, %01100110,0, %00000110,0, %00011100,0
    db %00000110,0, %01100110,0, %00111100,0, %00000000,0
TilesFin:

SECTION "Estado", WRAM0
wEstado: ds 1
wJugadorX: ds 1
wJugadorY: ds 1
wTeclas: ds 1
wTeclasPrevias: ds 1
wTeclasNuevas: ds 1
wHiloRestante: ds 1
wHiloActivo: ds 1
wHiloSegmentos: ds 1
wMovimientoDesde: ds 1
wMovimientoHasta: ds 1
wHiloDesde: ds HILO_MAX
wHiloHasta: ds HILO_MAX

wNivelActual: ds 1
wCentroAlcanzado: ds 1
wPuertaGaleriasAbierta: ds 1
wCruceSeguroX: ds 1
wCruceSeguroY: ds 1

wMinotauroActivo: ds 1
wMinotauroX: ds 1
wMinotauroY: ds 1
wMinotauroPaso: ds 1
wMinotauroAlerta: ds 1
