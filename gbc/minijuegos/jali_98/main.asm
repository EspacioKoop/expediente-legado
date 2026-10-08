; JALI 98 - micro-ROM cultural para la Portatil Color 98 (#932).
; Codigo, pixel-art y audio originales del proyecto.
;
; Referencia historica de diseno: jali mogol de arenisca roja, probablemente
; Agra, segunda mitad del siglo XVI, Met 1993.67.1. La ROM NO reconstruye esa
; pieza ni usa texto sagrado, caligrafia o simbolos rituales: abstrae la relacion
; documentada entre calado geometrico, luz y sombra en tres bandas jugables.
;
; Objetivo: rotar las tres bandas hasta que cada una proyecte su patron de luz.
; Solo la solucion completa y tras manipular las tres bandas publica $A5 en
; WRAM $C100. Arrancar, comprar, insertar o jugar parcialmente no cuenta.

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
DEF BG_MAP     EQU $9800

DEF ESTADO_TITULO EQU 0
DEF ESTADO_JUEGO  EQU 1
DEF ESTADO_FIN    EQU 2

DEF KEY_RIGHT EQU %00000001
DEF KEY_LEFT  EQU %00000010
DEF KEY_UP    EQU %00000100
DEF KEY_DOWN  EQU %00001000
DEF KEY_A     EQU %00010000
DEF KEY_START EQU %10000000

DEF TILE_VACIO    EQU 0
DEF TILE_PIEDRA   EQU 1
DEF TILE_HUECO    EQU 2
DEF TILE_ESTRELLA EQU 3
DEF TILE_ROMBO    EQU 4
DEF TILE_CURSOR   EQU 5
DEF TILE_LUZ      EQU 6
DEF TILE_SOMBRA   EQU 7
DEF TILE_J        EQU 8
DEF TILE_A        EQU 9
DEF TILE_L        EQU 10
DEF TILE_I        EQU 11
DEF TILE_9        EQU 12
DEF TILE_8        EQU 13
DEF TILE_SOL      EQU 14
DEF TILE_RAYO     EQU 15
DEF FONT_BASE     EQU 16

DEF TODAS_TOCADAS    EQU %00000111
DEF MARCA_COMPLETADO EQU $A5

INCLUDE "../comun/cartucho.asm"

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "JALI98"
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
    ld [wJaliCompletado], a
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
    ld a, [wTeclasNuevas]
    and KEY_UP
    call nz, SeleccionarAnterior

    ld a, [wTeclasNuevas]
    and KEY_DOWN
    call nz, SeleccionarSiguiente

    ld a, [wTeclasNuevas]
    and KEY_LEFT
    call nz, RotarIzquierda

    ld a, [wTeclasNuevas]
    and KEY_RIGHT
    call nz, RotarDerecha

    ld a, [wTeclasNuevas]
    and KEY_A
    call nz, ComprobarSolucion

    call ActualizarJuego
    call ComprobarSolucion
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
    ld [wJaliCompletado], a
    ld [wSeleccion], a
    ld [wFases], a
    ld [wFases + 1], a
    ld [wFases + 2], a
    ld [wTocadas], a
    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call DibujarJuego
    call ActivarLCD
    ret

SeleccionarAnterior:
    ld a, [wSeleccion]
    or a
    jr nz, .decrementar
    ld a, 3
.decrementar:
    dec a
    ld [wSeleccion], a
    call SonidoMover
    ret

SeleccionarSiguiente:
    ld a, [wSeleccion]
    inc a
    cp 3
    jr c, .guardar
    xor a
.guardar:
    ld [wSeleccion], a
    call SonidoMover
    ret

RotarIzquierda:
    call FaseSeleccionada
    ld a, [hl]
    dec a
    and 3
    ld [hl], a
    call MarcarTocada
    call SonidoMover
    ret

RotarDerecha:
    call FaseSeleccionada
    ld a, [hl]
    inc a
    and 3
    ld [hl], a
    call MarcarTocada
    call SonidoMover
    ret

FaseSeleccionada:
    ld hl, wFases
    ld a, [wSeleccion]
    ld e, a
    ld d, 0
    add hl, de
    ret

MarcarTocada:
    ld a, [wSeleccion]
    ld e, a
    ld d, 0
    ld hl, BitsSeleccion
    add hl, de
    ld a, [hl]
    ld b, a
    ld a, [wTocadas]
    or b
    ld [wTocadas], a
    ret

ComprobarSolucion:
    ld a, [wTocadas]
    cp TODAS_TOCADAS
    ret nz

    ld a, [wFases]
    cp 1
    ret nz
    ld a, [wFases + 1]
    cp 3
    ret nz
    ld a, [wFases + 2]
    cp 2
    ret nz

    call CompletarJali
    ret

CompletarJali:
    call DesactivarLCD
    call LimpiarFondo
    call DibujarVictoria
    ld a, MARCA_COMPLETADO
    ld [wJaliCompletado], a
    ld a, ESTADO_FIN
    ld [wEstado], a
    call SonidoVictoria
    call ActivarLCD
    ret

ActualizarJuego:
    call DesactivarLCD
    call DibujarBandas
    call DibujarMarcas
    call DibujarCursor
    call ActivarLCD
    ret

DibujarTitulo:
    ld hl, TextoTitulo
    ld de, BG_MAP + (1 * 32) + 6
    call EscribirCadena

    ld a, TILE_SOL
    ld [BG_MAP + (2 * 32) + 4], a
    ld a, TILE_RAYO
    ld [BG_MAP + (2 * 32) + 7], a
    ld [BG_MAP + (2 * 32) + 10], a
    ld [BG_MAP + (2 * 32) + 13], a
    ld a, TILE_ESTRELLA
    ld [BG_MAP + (2 * 32) + 16], a

    ld hl, TextoObjetivo
    ld de, BG_MAP + (4 * 32) + 1
    call EscribirCadena

    ld hl, TextoAlinear
    ld de, BG_MAP + (5 * 32) + 0
    call EscribirCadena

    ld hl, TextoLuzSombra
    ld de, BG_MAP + (6 * 32) + 2
    call EscribirCadena

    ld hl, TextoControles
    ld de, BG_MAP + (8 * 32) + 1
    call EscribirCadena

    ld hl, TextoArribaAbajo
    ld de, BG_MAP + (10 * 32) + 0
    call EscribirCadena

    ld hl, TextoIzqDer
    ld de, BG_MAP + (11 * 32) + 0
    call EscribirCadena

    ld hl, TextoStart
    ld de, BG_MAP + (12 * 32) + 2
    call EscribirCadena
    ret

EscribirCadena:
.siguiente:
    ld a, [hli]
    or a
    ret z
    call CaracterATile
    ld [de], a
    inc de
    jr .siguiente

CaracterATile:
    cp $20
    jr z, .espacio
    cp $30
    jr c, .simbolos
    cp $3A
    jr nc, .letras
    sub $30
    add FONT_BASE
    ret
.letras:
    cp $41
    jr c, .simbolos
    cp $5B
    jr nc, .simbolos
    sub $41
    add FONT_BASE + 10
    ret
.simbolos:
    cp $3A
    jr z, .dos_puntos
    cp $2F
    jr z, .barra
.espacio:
    xor a
    ret
.dos_puntos:
    ld a, FONT_BASE + 36
    ret
.barra:
    ld a, FONT_BASE + 38
    ret

DibujarJuego:
    ld a, TILE_SOL
    ld [BG_MAP + (2 * 32) + 2], a
    ld a, TILE_RAYO
    ld [BG_MAP + (2 * 32) + 4], a
    ld [BG_MAP + (2 * 32) + 5], a
    ld [BG_MAP + (2 * 32) + 6], a
    call DibujarBandas
    call DibujarMarcas
    call DibujarCursor
    ret

DibujarBandas:
    ld hl, BG_MAP + (6 * 32) + 6
    ld a, [wFases]
    call DibujarPatron
    ld hl, BG_MAP + (9 * 32) + 6
    ld a, [wFases + 1]
    call DibujarPatron
    ld hl, BG_MAP + (12 * 32) + 6
    ld a, [wFases + 2]
    call DibujarPatron
    ret

DibujarPatron:
    and 3
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    push hl
    ld hl, Patrones
    add hl, de
    ld d, h
    ld e, l
    pop hl
    ld b, 8
.copiar:
    ld a, [de]
    ld [hli], a
    inc de
    dec b
    jr nz, .copiar
    ret

DibujarMarcas:
    ld a, [wFases]
    cp 1
    ld a, TILE_SOMBRA
    jr nz, .marca0
    ld a, TILE_LUZ
.marca0:
    ld [BG_MAP + (6 * 32) + 16], a

    ld a, [wFases + 1]
    cp 3
    ld a, TILE_SOMBRA
    jr nz, .marca1
    ld a, TILE_LUZ
.marca1:
    ld [BG_MAP + (9 * 32) + 16], a

    ld a, [wFases + 2]
    cp 2
    ld a, TILE_SOMBRA
    jr nz, .marca2
    ld a, TILE_LUZ
.marca2:
    ld [BG_MAP + (12 * 32) + 16], a
    ret

DibujarCursor:
    xor a
    ld [BG_MAP + (6 * 32) + 4], a
    ld [BG_MAP + (9 * 32) + 4], a
    ld [BG_MAP + (12 * 32) + 4], a

    ld a, [wSeleccion]
    or a
    jr z, .fila0
    cp 1
    jr z, .fila1
    ld a, TILE_CURSOR
    ld [BG_MAP + (12 * 32) + 4], a
    ret
.fila0:
    ld a, TILE_CURSOR
    ld [BG_MAP + (6 * 32) + 4], a
    ret
.fila1:
    ld a, TILE_CURSOR
    ld [BG_MAP + (9 * 32) + 4], a
    ret

DibujarVictoria:
    ld a, TILE_SOL
    ld [BG_MAP + (2 * 32) + 9], a
    ld a, TILE_RAYO
    ld [BG_MAP + (3 * 32) + 7], a
    ld [BG_MAP + (3 * 32) + 9], a
    ld [BG_MAP + (3 * 32) + 11], a

    ld hl, BG_MAP + (6 * 32) + 6
    ld a, 1
    call DibujarPatron

    ld hl, BG_MAP + (9 * 32) + 6
    ld a, 3
    call DibujarPatron

    ld hl, BG_MAP + (12 * 32) + 6
    ld a, 2
    call DibujarPatron

    ld a, TILE_LUZ
    ld [BG_MAP + (6 * 32) + 16], a
    ld [BG_MAP + (9 * 32) + 16], a
    ld [BG_MAP + (12 * 32) + 16], a
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
.bucle:
    ld a, d
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
    ld a, $70
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoMover:
    ld a, $40
    ldh [rNR11], a
    ld a, $55
    ldh [rNR12], a
    ld a, $B0
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

SECTION "Datos", ROM0
TextoTitulo:        db "JALI 98", 0
TextoObjetivo:      db "OBJETIVO:", 0
TextoAlinear:       db "ALINEAR TRES BANDAS", 0
TextoLuzSombra:     db "DE LUZ Y SOMBRA", 0
TextoControles:     db "CONTROLES:", 0
TextoArribaAbajo:   db "ARRIBA/ABAJO ELEGIR", 0
TextoIzqDer:        db "IZQ/DER ROTAR BANDA", 0
TextoStart:         db "A/START EMPEZAR", 0

BitsSeleccion:
    db %00000001, %00000010, %00000100

Patrones:
    db TILE_PIEDRA, TILE_HUECO, TILE_PIEDRA, TILE_HUECO, TILE_PIEDRA, TILE_HUECO, TILE_PIEDRA, TILE_HUECO
    db TILE_ESTRELLA, TILE_HUECO, TILE_ROMBO, TILE_HUECO, TILE_ESTRELLA, TILE_HUECO, TILE_ROMBO, TILE_HUECO
    db TILE_ROMBO, TILE_PIEDRA, TILE_HUECO, TILE_ESTRELLA, TILE_HUECO, TILE_PIEDRA, TILE_ROMBO, TILE_HUECO
    db TILE_HUECO, TILE_ROMBO, TILE_ESTRELLA, TILE_PIEDRA, TILE_HUECO, TILE_ESTRELLA, TILE_ROMBO, TILE_PIEDRA

PaletaCGB:
    dw $0000, $1DD9, $4B9F, $630C

Tiles:
    REPT 8
        db %00000000, %00000000
    ENDR
    REPT 8
        db %11111111, %00000000
    ENDR
    db %11111111,0, %10000001,0, %10000001,0, %10000001,0
    db %10000001,0, %10000001,0, %10000001,0, %11111111,0
    db %00011000,0, %10011001,0, %01011010,0, %00111100,0
    db %00111100,0, %01011010,0, %10011001,0, %00011000,0
    db %00011000,0, %00111100,0, %01100110,0, %11000011,0
    db %11000011,0, %01100110,0, %00111100,0, %00011000,0
    db %10000000,0, %11000000,0, %11100000,0, %11110000,0
    db %11100000,0, %11000000,0, %10000000,0, %00000000,0
    db %10101010,%01010101, %01010101,%10101010, %10101010,%01010101, %01010101,%10101010
    db %10101010,%01010101, %01010101,%10101010, %10101010,%01010101, %01010101,%10101010
    db %11111111,%11111111, %11000011,%11000011, %10100101,%10100101, %10011001,%10011001
    db %10011001,%10011001, %10100101,%10100101, %11000011,%11000011, %11111111,%11111111
    db %00111100,0, %00011000,0, %00011000,0, %00011000,0
    db %00011000,0, %10011000,0, %10011000,0, %01110000,0
    db %00111100,0, %01100110,0, %11000011,0, %11000011,0
    db %11111111,0, %11000011,0, %11000011,0, %11000011,0
    db %11000000,0, %11000000,0, %11000000,0, %11000000,0
    db %11000000,0, %11000000,0, %11000000,0, %11111111,0
    db %11111111,0, %00011000,0, %00011000,0, %00011000,0
    db %00011000,0, %00011000,0, %00011000,0, %11111111,0
    db %00111100,0, %01100110,0, %11000011,0, %11000011,0
    db %01111111,0, %00000011,0, %00000110,0, %00111100,0
    db %00111100,0, %01100110,0, %01100110,0, %00111100,0
    db %01100110,0, %11000011,0, %11000011,0, %01111110,0
    db %10011001,0, %01011010,0, %00111100,0, %11111111,0
    db %11111111,0, %00111100,0, %01011010,0, %10011001,0
    db %00011000,0, %00110000,0, %01100000,0, %11000000,0
    db %00000011,0, %00000110,0, %00001100,0, %00011000,0
    ; Fuente mayusculas y digitos ('0'-'9', 'A'-'Z', ':', '-')
    db $00, $00, $38, $38, $44, $44, $4C, $4C, $54, $54, $64, $64, $44, $44, $38, $38 ; '0'
    db $00, $00, $10, $10, $30, $30, $10, $10, $10, $10, $10, $10, $10, $10, $38, $38 ; '1'
    db $00, $00, $38, $38, $44, $44, $04, $04, $08, $08, $10, $10, $20, $20, $7C, $7C ; '2'
    db $00, $00, $78, $78, $04, $04, $04, $04, $38, $38, $04, $04, $04, $04, $78, $78 ; '3'
    db $00, $00, $08, $08, $18, $18, $28, $28, $48, $48, $7C, $7C, $08, $08, $08, $08 ; '4'
    db $00, $00, $7C, $7C, $40, $40, $40, $40, $78, $78, $04, $04, $04, $04, $78, $78 ; '5'
    db $00, $00, $38, $38, $40, $40, $40, $40, $78, $78, $44, $44, $44, $44, $38, $38 ; '6'
    db $00, $00, $7C, $7C, $04, $04, $08, $08, $10, $10, $20, $20, $20, $20, $20, $20 ; '7'
    db $00, $00, $38, $38, $44, $44, $44, $44, $38, $38, $44, $44, $44, $44, $38, $38 ; '8'
    db $00, $00, $38, $38, $44, $44, $44, $44, $3C, $3C, $04, $04, $04, $04, $38, $38 ; '9'
    db $00, $00, $38, $38, $44, $44, $44, $44, $7C, $7C, $44, $44, $44, $44, $44, $44 ; 'A'
    db $00, $00, $78, $78, $44, $44, $44, $44, $78, $78, $44, $44, $44, $44, $78, $78 ; 'B'
    db $00, $00, $3C, $3C, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3C, $3C ; 'C'
    db $00, $00, $78, $78, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $78, $78 ; 'D'
    db $00, $00, $7C, $7C, $40, $40, $40, $40, $78, $78, $40, $40, $40, $40, $7C, $7C ; 'E'
    db $00, $00, $7C, $7C, $40, $40, $40, $40, $78, $78, $40, $40, $40, $40, $40, $40 ; 'F'
    db $00, $00, $3C, $3C, $40, $40, $40, $40, $5C, $5C, $44, $44, $44, $44, $3C, $3C ; 'G'
    db $00, $00, $44, $44, $44, $44, $44, $44, $7C, $7C, $44, $44, $44, $44, $44, $44 ; 'H'
    db $00, $00, $38, $38, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $38, $38 ; 'I'
    db $00, $00, $04, $04, $04, $04, $04, $04, $04, $04, $44, $44, $44, $44, $38, $38 ; 'J'
    db $00, $00, $44, $44, $48, $48, $50, $50, $60, $60, $50, $50, $48, $48, $44, $44 ; 'K'
    db $00, $00, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $7C, $7C ; 'L'
    db $00, $00, $44, $44, $6C, $6C, $54, $54, $54, $54, $44, $44, $44, $44, $44, $44 ; 'M'
    db $00, $00, $44, $44, $64, $64, $54, $54, $4C, $4C, $44, $44, $44, $44, $44, $44 ; 'N'
    db $00, $00, $38, $38, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $38, $38 ; 'O'
    db $00, $00, $78, $78, $44, $44, $44, $44, $78, $78, $40, $40, $40, $40, $40, $40 ; 'P'
    db $00, $00, $38, $38, $44, $44, $44, $44, $44, $44, $54, $54, $48, $48, $34, $34 ; 'Q'
    db $00, $00, $78, $78, $44, $44, $44, $44, $78, $78, $50, $50, $48, $48, $44, $44 ; 'R'
    db $00, $00, $3C, $3C, $40, $40, $40, $40, $38, $38, $04, $04, $04, $04, $78, $78 ; 'S'
    db $00, $00, $7C, $7C, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ; 'T'
    db $00, $00, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $38, $38 ; 'U'
    db $00, $00, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $28, $28, $10, $10 ; 'V'
    db $00, $00, $44, $44, $44, $44, $54, $54, $54, $54, $6C, $6C, $44, $44, $44, $44 ; 'W'
    db $00, $00, $44, $44, $44, $44, $28, $28, $10, $10, $28, $28, $44, $44, $44, $44 ; 'X'
    db $00, $00, $44, $44, $44, $44, $28, $28, $10, $10, $10, $10, $10, $10, $10, $10 ; 'Y'
    db $00, $00, $7C, $7C, $04, $04, $08, $08, $10, $10, $20, $20, $40, $40, $7C, $7C ; 'Z'
    db $00, $00, $00, $00, $10, $10, $10, $10, $00, $00, $10, $10, $10, $10, $00, $00 ; ':'
    db $00, $00, $00, $00, $00, $00, $00, $00, $7C, $7C, $00, $00, $00, $00, $00, $00 ; '-'
    db $00, $00, $04, $04, $08, $08, $08, $08, $10, $10, $20, $20, $20, $20, $40, $40 ; '/'
TilesFin:

SECTION "Handshake", WRAM0[$C100]
wJaliCompletado: ds 1
wEstado:         ds 1
wSeleccion:      ds 1
wFases:          ds 3
wTocadas:        ds 1
wTeclas:         ds 1
wTeclasPrevias:  ds 1
wTeclasNuevas:   ds 1
