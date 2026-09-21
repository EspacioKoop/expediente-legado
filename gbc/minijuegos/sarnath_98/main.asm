; SARNATH 98 - micro-ROM cultural para #932.
; Abstraccion de orientacion y memoria espacial entre zonas de un sitio
; arqueologico serial. No reconstruye un mapa historico real.
;
; Tres rondas: observar rumbos, ocultarlos con A y repetirlos con la cruceta.
; Solo completar las tres rutas publica $A5 en WRAM $C100.

DEF rP1    EQU $FF00
DEF rNR11  EQU $FF11
DEF rNR12  EQU $FF12
DEF rNR13  EQU $FF13
DEF rNR14  EQU $FF14
DEF rNR50  EQU $FF24
DEF rNR51  EQU $FF25
DEF rNR52  EQU $FF26
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

DEF ESTADO_TITULO EQU 0
DEF ESTADO_JUEGO EQU 1
DEF ESTADO_FIN EQU 2

DEF MODO_ESTUDIO EQU 0
DEF MODO_ENTRADA EQU 1

DEF KEY_RIGHT EQU %00000001
DEF KEY_LEFT  EQU %00000010
DEF KEY_UP    EQU %00000100
DEF KEY_DOWN  EQU %00001000
DEF KEY_A     EQU %00010000
DEF KEY_START EQU %10000000

DEF TILE_VACIO EQU 0
DEF TILE_NODO EQU 1
DEF TILE_CAMINO EQU 2
DEF TILE_UP EQU 3
DEF TILE_RIGHT EQU 4
DEF TILE_DOWN EQU 5
DEF TILE_LEFT EQU 6
DEF TILE_PASO EQU 7
DEF TILE_ERROR EQU 8
DEF TILE_META EQU 9
DEF TILE_1 EQU 10
DEF TILE_2 EQU 11
DEF TILE_3 EQU 12
DEF TILE_OJO EQU 13
DEF TILE_MARCO EQU 14
DEF TILE_OK EQU 15

DEF MARCA_COMPLETADO EQU $A5

INCLUDE "../comun/cartucho.asm"

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "SARNATH98"
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
    ld [wSarnathCompletado], a
    ld [wEstado], a
    ld [wTeclas], a
    ld [wTeclasPrevias], a
    ld [wTeclasNuevas], a

    call CargarTiles
    call LimpiarFondo
    call ConfigurarPaletas
    call ConfigurarAudio
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
    jr EstadoFin

EstadoTitulo:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarJuego
    jr Bucle

EstadoJuego:
    ld a, [wModo]
    cp MODO_ESTUDIO
    jr z, ModoEstudio
    jr ModoEntrada

ModoEstudio:
    ld a, [wTeclasNuevas]
    and KEY_A
    jr z, Bucle
    call ComenzarEntrada
    jr Bucle

ModoEntrada:
    ld a, [wTeclasNuevas]
    and $0F
    jr z, Bucle
    call ProcesarEntrada
    jr Bucle

EstadoFin:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarJuego
    jr Bucle

IniciarJuego:
    call DesactivarLCD
    call LimpiarFondo
    xor a
    ld [wSarnathCompletado], a
    ld [wRonda], a
    ld [wIndice], a
    ld [wModo], a
    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call DibujarEstudioInterno
    call ActivarLCD
    ret

ComenzarEntrada:
    call DesactivarLCD
    call LimpiarFondo
    xor a
    ld [wIndice], a
    ld a, MODO_ENTRADA
    ld [wModo], a
    call DibujarEntradaInterno
    call ActivarLCD
    call SonidoInicio
    ret

ProcesarEntrada:
    ld a, [wTeclasNuevas]
    and $0F
    ld b, a
    call TeclaEsperada
    cp b
    jr nz, EntradaErronea

    ld a, [wIndice]
    inc a
    ld [wIndice], a
    ld c, a
    call LongitudRuta
    cp c
    jr z, RondaCompleta

    call DibujarPaso
    call SonidoMover
    ret

EntradaErronea:
    call SonidoError
    call DesactivarLCD
    call LimpiarFondo
    xor a
    ld [wIndice], a
    ld [wModo], a
    call DibujarEstudioInterno
    ld a, TILE_ERROR
    ld [BG_MAP + (15 * 32) + 9], a
    call ActivarLCD
    ret

RondaCompleta:
    ld a, [wRonda]
    inc a
    cp 3
    jr z, CompletarRutaFinal
    ld [wRonda], a
    xor a
    ld [wIndice], a
    ld [wModo], a
    call SonidoRonda
    call DibujarEstudio
    ret

CompletarRutaFinal:
    call DesactivarLCD
    call LimpiarFondo
    call DibujarVictoria
    ld a, MARCA_COMPLETADO
    ld [wSarnathCompletado], a
    ld a, ESTADO_FIN
    ld [wEstado], a
    call SonidoVictoria
    call ActivarLCD
    ret

DibujarEstudio:
    call DesactivarLCD
    call LimpiarFondo
    call DibujarEstudioInterno
    call ActivarLCD
    ret

DibujarEstudioInterno:
    call DibujarMarco
    ld a, TILE_OJO
    ld [BG_MAP + (3 * 32) + 9], a
    call DibujarNumeroRonda
    call ObtenerRuta
    ld b, a
    ld c, 0
.estudio_loop:
    ld a, c
    cp b
    ret z
    push bc
    ld a, [hli]
    call TileParaDireccion
    pop bc
    push hl
    ld hl, BG_MAP + (8 * 32) + 7
    ld a, c
    ld e, a
    ld d, 0
    add hl, de
    ld [hl], b
    pop hl
    inc c
    jr .estudio_loop

DibujarEntradaInterno:
    call DibujarMarco
    call DibujarNumeroRonda
    ld a, TILE_NODO
    ld [BG_MAP + (8 * 32) + 5], a
    ld a, TILE_META
    ld [BG_MAP + (8 * 32) + 14], a
    ld a, TILE_CAMINO
    ld hl, BG_MAP + (8 * 32) + 7
    ld b, 5
.camino:
    ld [hli], a
    dec b
    jr nz, .camino
    ret

DibujarPaso:
    call DesactivarLCD
    ld hl, BG_MAP + (8 * 32) + 7
    ld a, [wIndice]
    dec a
    ld e, a
    ld d, 0
    add hl, de
    ld a, TILE_PASO
    ld [hl], a
    call ActivarLCD
    ret

DibujarTitulo:
    call DibujarMarco
    ld a, TILE_NODO
    ld [BG_MAP + (7 * 32) + 4], a
    ld a, TILE_CAMINO
    ld [BG_MAP + (7 * 32) + 6], a
    ld [BG_MAP + (7 * 32) + 8], a
    ld [BG_MAP + (7 * 32) + 10], a
    ld [BG_MAP + (7 * 32) + 12], a
    ld a, TILE_META
    ld [BG_MAP + (7 * 32) + 15], a
    ld a, TILE_OJO
    ld [BG_MAP + (11 * 32) + 9], a
    ret

DibujarVictoria:
    call DibujarMarco
    ld a, TILE_NODO
    ld [BG_MAP + (7 * 32) + 5], a
    ld a, TILE_PASO
    ld [BG_MAP + (7 * 32) + 7], a
    ld [BG_MAP + (7 * 32) + 9], a
    ld [BG_MAP + (7 * 32) + 11], a
    ld a, TILE_META
    ld [BG_MAP + (7 * 32) + 13], a
    ld a, TILE_OK
    ld [BG_MAP + (11 * 32) + 9], a
    ret

DibujarMarco:
    ld a, TILE_MARCO
    ld [BG_MAP + (2 * 32) + 3], a
    ld [BG_MAP + (2 * 32) + 16], a
    ld [BG_MAP + (15 * 32) + 3], a
    ld [BG_MAP + (15 * 32) + 16], a
    ret

DibujarNumeroRonda:
    ld a, [wRonda]
    or a
    jr z, .uno
    cp 1
    jr z, .dos
    ld a, TILE_3
    jr .poner
.uno:
    ld a, TILE_1
    jr .poner
.dos:
    ld a, TILE_2
.poner:
    ld [BG_MAP + (3 * 32) + 12], a
    ret

ObtenerRuta:
    ld a, [wRonda]
    or a
    jr z, .ruta0
    cp 1
    jr z, .ruta1
    ld hl, Ruta2
    ld a, 5
    ret
.ruta0:
    ld hl, Ruta0
    ld a, 3
    ret
.ruta1:
    ld hl, Ruta1
    ld a, 4
    ret

LongitudRuta:
    ld a, [wRonda]
    or a
    jr z, .tres
    cp 1
    jr z, .cuatro
    ld a, 5
    ret
.tres:
    ld a, 3
    ret
.cuatro:
    ld a, 4
    ret

TeclaEsperada:
    ld a, [wRonda]
    or a
    jr z, .r0
    cp 1
    jr z, .r1
    ld hl, Ruta2
    jr .indice
.r0:
    ld hl, Ruta0
    jr .indice
.r1:
    ld hl, Ruta1
.indice:
    ld a, [wIndice]
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    ret

TileParaDireccion:
    cp KEY_UP
    jr z, .up
    cp KEY_RIGHT
    jr z, .right
    cp KEY_DOWN
    jr z, .down
    ld b, TILE_LEFT
    ret
.up:
    ld b, TILE_UP
    ret
.right:
    ld b, TILE_RIGHT
    ret
.down:
    ld b, TILE_DOWN
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
    ld d, 0
.loop:
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

CargarTiles:
    ld de, Tiles
    ld hl, VRAM_TILES
    ld bc, TilesFin - Tiles
.loop:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
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

ConfigurarAudio:
    ld a, $80
    ldh [rNR52], a
    ld a, $77
    ldh [rNR50], a
    ld a, $11
    ldh [rNR51], a
    ret

SonidoInicio:
    ld a, $80
    ldh [rNR11], a
    ld a, $70
    ldh [rNR12], a
    ld a, $60
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoMover:
    ld a, $40
    ldh [rNR11], a
    ld a, $50
    ldh [rNR12], a
    ld a, $A0
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoError:
    ld a, $40
    ldh [rNR11], a
    ld a, $42
    ldh [rNR12], a
    ld a, $30
    ldh [rNR13], a
    ld a, $84
    ldh [rNR14], a
    ret

SonidoRonda:
    ld a, $80
    ldh [rNR11], a
    ld a, $68
    ldh [rNR12], a
    ld a, $C0
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoVictoria:
    ld a, $80
    ldh [rNR11], a
    ld a, $78
    ldh [rNR12], a
    ld a, $20
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SECTION "Rutas", ROM0
Ruta0:
    db KEY_UP, KEY_RIGHT, KEY_UP
Ruta1:
    db KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN
Ruta2:
    db KEY_UP, KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT

PaletaCGB:
    dw $0000, $12A5, $2E4B, $63D2

Tiles:
    REPT 8
        db %00000000, %00000000
    ENDR
    ; nodo
    db %00111100,0, %01111110,0, %11111111,0, %11111111,0
    db %11111111,0, %11111111,0, %01111110,0, %00111100,0
    ; camino
    db 0,0, 0,0, 0,0, %11111111,0
    db %11111111,0, 0,0, 0,0, 0,0
    ; arriba
    db %00011000,0, %00111100,0, %01111110,0, %11011011,0
    db %00011000,0, %00011000,0, %00011000,0, %00011000,0
    ; derecha
    db %00010000,0, %00011000,0, %11111100,0, %11111110,0
    db %11111100,0, %00011000,0, %00010000,0, 0,0
    ; abajo
    db %00011000,0, %00011000,0, %00011000,0, %00011000,0
    db %11011011,0, %01111110,0, %00111100,0, %00011000,0
    ; izquierda
    db %00001000,0, %00011000,0, %00111111,0, %01111111,0
    db %00111111,0, %00011000,0, %00001000,0, 0,0
    ; paso
    db %00000000,0, %00011000,0, %00111100,0, %01111110,0
    db %01111110,0, %00111100,0, %00011000,0, %00000000,0
    ; error
    db %11000011,0, %01100110,0, %00111100,0, %00011000,0
    db %00011000,0, %00111100,0, %01100110,0, %11000011,0
    ; meta
    db %11111111,0, %10000001,0, %10111101,0, %10100101,0
    db %10100101,0, %10111101,0, %10000001,0, %11111111,0
    ; 1
    db %00011000,0, %00111000,0, %00011000,0, %00011000,0
    db %00011000,0, %00011000,0, %00111100,0, %00111100,0
    ; 2
    db %00111100,0, %01100110,0, %00000110,0, %00001100,0
    db %00011000,0, %00110000,0, %01111110,0, %01111110,0
    ; 3
    db %00111100,0, %01100110,0, %00000110,0, %00011100,0
    db %00000110,0, %01100110,0, %00111100,0, %00000000,0
    ; ojo abstracto
    db %00000000,0, %00111100,0, %01100110,0, %11011011,0
    db %11011011,0, %01100110,0, %00111100,0, %00000000,0
    ; marco
    db %11111111,0, %10000001,0, %10000001,0, %10000001,0
    db %10000001,0, %10000001,0, %10000001,0, %11111111,0
    ; ok
    db %00000000,0, %00000001,0, %00000011,0, %10000110,0
    db %11001100,0, %01111000,0, %00110000,0, %00000000,0
TilesFin:

SECTION "Handshake", WRAM0[$C100]
wSarnathCompletado: ds 1
wEstado: ds 1
wModo: ds 1
wRonda: ds 1
wIndice: ds 1
wTeclas: ds 1
wTeclasPrevias: ds 1
wTeclasNuevas: ds 1
