; ARIADNE 98 - primer vertical navegable (#2313/#2368/#2389).
; Laberinto cenital manual y determinista. Este corte NO implementa hilo,
; Minotauro, SRAM ni handshake SIGA; solo portada -> laberinto -> salida.
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

DEF TILE_SUELO   EQU 0
DEF TILE_MURO    EQU 1
DEF TILE_ARIADNE EQU 2
DEF TILE_SALIDA  EQU 3
DEF TILE_A       EQU 4
DEF TILE_R       EQU 5
DEF TILE_I       EQU 6
DEF TILE_D       EQU 7
DEF TILE_N       EQU 8
DEF TILE_E       EQU 9
DEF TILE_9       EQU 10
DEF TILE_8       EQU 11
DEF TILE_1       EQU 12
DEF TILE_H       EQU 13
DEF TILE_L       EQU 14
DEF TILE_ALERTA  EQU 15

DEF LAB_ANCHO EQU 16
DEF LAB_ALTO  EQU 12
DEF LAB_X     EQU 2
DEF LAB_Y     EQU 4
DEF INICIO_X  EQU 1
DEF INICIO_Y  EQU 1

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
    ld a, INICIO_X
    ld [wJugadorX], a
    ld a, INICIO_Y
    ld [wJugadorY], a
    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call DibujarHUD
    call DibujarLaberinto
    call DibujarJugador
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
    push af
    call BorrarJugador
    ld a, b
    ld [wJugadorX], a
    ld a, c
    ld [wJugadorY], a
    call DibujarJugador
    pop af
    cp TILE_SALIDA
    ret nz
    call MostrarSalida
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

    ; La primera salida solo confirma navegación; aún no publica progreso.
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
    ; Reserva estable para nivel, hilo y alerta. Este corte solo fija el layout.
    ld a, TILE_L
    ld [BG_MAP], a
    ld a, TILE_1
    ld [BG_MAP + 1], a
    ld a, TILE_H
    ld [BG_MAP + 7], a
    ld a, TILE_ALERTA
    ld [BG_MAP + 14], a
    ret

DibujarLaberinto:
    ld de, Laberinto
    ld hl, BG_MAP + (LAB_Y * 32) + LAB_X
    ld c, LAB_ALTO
.fila:
    ld b, LAB_ANCHO
.columna:
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .columna

    ; El tilemap tiene 32 columnas; el laberinto ocupa solo 16.
    ld a, l
    add 32 - LAB_ANCHO
    ld l, a
    jr nc, .sin_carry
    inc h
.sin_carry:
    dec c
    jr nz, .fila
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
    call PosicionBGBC
    ld a, TILE_SUELO
    ld [hl], a
    ret

; B=x, C=y. Devuelve en A el tile lógico del mapa manual.
TileMapaBC:
    ld a, c
    swap a
    and $F0
    add b
    ld e, a
    ld d, 0
    ld hl, Laberinto
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

; 16x12, borde cerrado. 0=suelo, 1=muro, 3=salida.
; La ruta desde (1,1) hasta (14,10) es única en varios tramos, pero siempre
; reversible: no hay RNG ni puertas de un solo sentido.
Laberinto:
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1
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
TilesFin:

SECTION "Estado", WRAM0
wEstado: ds 1
wJugadorX: ds 1
wJugadorY: ds 1
wTeclas: ds 1
wTeclasPrevias: ds 1
wTeclasNuevas: ds 1
