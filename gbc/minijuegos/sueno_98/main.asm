; SUENO 98 - micro-ROM literaria para #1179.
; Puzle abstracto de tres paneles. No contiene texto ni escenas de la obra.
; Solo completar las tres composiciones publica $A5 en WRAM $C100.

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

DEF ESTADO_TITULO EQU 0
DEF ESTADO_JUEGO EQU 1
DEF ESTADO_FIN EQU 2

DEF KEY_RIGHT EQU %00000001
DEF KEY_LEFT  EQU %00000010
DEF KEY_UP    EQU %00000100
DEF KEY_DOWN  EQU %00001000
DEF KEY_A     EQU %00010000
DEF KEY_START EQU %10000000

DEF TILE_VACIO EQU 0
DEF TILE_SOMBRA EQU 1
DEF TILE_LUZ EQU 2
DEF TILE_CURSOR EQU 3
DEF TILE_ERROR EQU 4
DEF TILE_OK EQU 5
DEF TILE_1 EQU 6
DEF TILE_2 EQU 7
DEF TILE_3 EQU 8
DEF TILE_MARCO EQU 9

DEF MARCA_COMPLETADO EQU $A5

INCLUDE "../comun/cartucho.asm"

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "SUENO98"
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
    ld [wSuenoCompletado], a
    ld [wEstado], a
    ld [wRonda], a
    ld [wCursor], a
    ld [wPatron], a
    ld [wError], a
    ld [wTeclas], a
    ld [wTeclasPrevias], a
    ld [wTeclasNuevas], a

    call CargarTiles
    call LimpiarFondo
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
    jr EstadoFin

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
    and KEY_A
    jr nz, .alternar
    ld a, [wTeclasNuevas]
    and KEY_START
    jr nz, .comprobar
    jr Bucle
.izquierda:
    call MoverIzquierda
    jr Bucle
.derecha:
    call MoverDerecha
    jr Bucle
.alternar:
    call AlternarPanel
    jr Bucle
.comprobar:
    call ComprobarObjetivo
    jr Bucle

EstadoFin:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call IniciarJuego
    jr Bucle

IniciarJuego:
    xor a
    ld [wSuenoCompletado], a
    ld [wRonda], a
    ld [wCursor], a
    ld [wPatron], a
    ld [wError], a
    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call DibujarJuego
    ret

MoverIzquierda:
    xor a
    ld [wError], a
    ld a, [wCursor]
    or a
    jr nz, .restar
    ld a, 2
    jr .guardar
.restar:
    dec a
.guardar:
    ld [wCursor], a
    call DibujarJuego
    ret

MoverDerecha:
    xor a
    ld [wError], a
    ld a, [wCursor]
    inc a
    cp 3
    jr c, .guardar
    xor a
.guardar:
    ld [wCursor], a
    call DibujarJuego
    ret

AlternarPanel:
    xor a
    ld [wError], a
    ld a, [wCursor]
    ld e, a
    ld d, 0
    ld hl, MascarasCursor
    add hl, de
    ld a, [hl]
    ld b, a
    ld a, [wPatron]
    xor b
    and %00000111
    ld [wPatron], a
    call DibujarJuego
    ret

ComprobarObjetivo:
    call ObjetivoActual
    ld b, a
    ld a, [wPatron]
    cp b
    jr nz, ObjetivoIncorrecto

    ld a, [wRonda]
    inc a
    cp 3
    jr z, CompletarObjetivoFinal
    ld [wRonda], a
    xor a
    ld [wCursor], a
    ld [wPatron], a
    ld [wError], a
    call DibujarJuego
    ret

ObjetivoIncorrecto:
    ld a, 1
    ld [wError], a
    call DibujarJuego
    ret

CompletarObjetivoFinal:
    ld a, MARCA_COMPLETADO
    ld [wSuenoCompletado], a
    ld a, ESTADO_FIN
    ld [wEstado], a
    call DibujarVictoria
    ret

ObjetivoActual:
    ld a, [wRonda]
    ld e, a
    ld d, 0
    ld hl, Objetivos
    add hl, de
    ld a, [hl]
    ret

DibujarTitulo:
    call DibujarMarco
    ld a, TILE_LUZ
    ld [BG_MAP + (7 * 32) + 6], a
    ld a, TILE_SOMBRA
    ld [BG_MAP + (7 * 32) + 9], a
    ld a, TILE_LUZ
    ld [BG_MAP + (7 * 32) + 12], a
    ld a, TILE_CURSOR
    ld [BG_MAP + (11 * 32) + 9], a
    ret

DibujarJuego:
    call DesactivarLCD
    call LimpiarFondo
    call DibujarMarco
    call DibujarRonda
    call DibujarPaneles
    call DibujarCursor
    ld a, [wError]
    or a
    jr z, .sin_error
    ld a, TILE_ERROR
    ld [BG_MAP + (12 * 32) + 9], a
.sin_error:
    call ActivarLCD
    ret

DibujarRonda:
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
    ld [BG_MAP + (3 * 32) + 9], a
    ret

DibujarPaneles:
    ld a, [wPatron]
    and %00000001
    ld a, TILE_SOMBRA
    jr z, .panel0
    ld a, TILE_LUZ
.panel0:
    ld [BG_MAP + (8 * 32) + 6], a

    ld a, [wPatron]
    and %00000010
    ld a, TILE_SOMBRA
    jr z, .panel1
    ld a, TILE_LUZ
.panel1:
    ld [BG_MAP + (8 * 32) + 9], a

    ld a, [wPatron]
    and %00000100
    ld a, TILE_SOMBRA
    jr z, .panel2
    ld a, TILE_LUZ
.panel2:
    ld [BG_MAP + (8 * 32) + 12], a
    ret

DibujarCursor:
    xor a
    ld [BG_MAP + (10 * 32) + 6], a
    ld [BG_MAP + (10 * 32) + 9], a
    ld [BG_MAP + (10 * 32) + 12], a
    ld a, [wCursor]
    or a
    jr z, .cero
    cp 1
    jr z, .uno
    ld a, TILE_CURSOR
    ld [BG_MAP + (10 * 32) + 12], a
    ret
.cero:
    ld a, TILE_CURSOR
    ld [BG_MAP + (10 * 32) + 6], a
    ret
.uno:
    ld a, TILE_CURSOR
    ld [BG_MAP + (10 * 32) + 9], a
    ret

DibujarVictoria:
    call DesactivarLCD
    call LimpiarFondo
    call DibujarMarco
    ld a, TILE_LUZ
    ld [BG_MAP + (7 * 32) + 6], a
    ld [BG_MAP + (7 * 32) + 9], a
    ld a, TILE_SOMBRA
    ld [BG_MAP + (7 * 32) + 12], a
    ld a, TILE_OK
    ld [BG_MAP + (11 * 32) + 9], a
    call ActivarLCD
    ret

DibujarMarco:
    ld a, TILE_MARCO
    ld [BG_MAP + (2 * 32) + 3], a
    ld [BG_MAP + (2 * 32) + 16], a
    ld [BG_MAP + (15 * 32) + 3], a
    ld [BG_MAP + (15 * 32) + 16], a
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

SECTION "Datos", ROM0
MascarasCursor:
    db %00000001, %00000010, %00000100

Objetivos:
    db %00000101, %00000110, %00000011

PaletaCGB:
    dw $0000, $18C6, $3DEF, $7FFF

Tiles:
    REPT 8
        db %00000000, %00000000
    ENDR
    ; sombra
    db %11111111,0, %10000001,0, %10000001,0, %10000001,0
    db %10000001,0, %10000001,0, %10000001,0, %11111111,0
    ; luz
    db %11111111,0, %11111111,0, %11111111,0, %11111111,0
    db %11111111,0, %11111111,0, %11111111,0, %11111111,0
    ; cursor
    db 0,0, %00011000,0, %00111100,0, %01111110,0
    db %00011000,0, %00011000,0, %00011000,0, 0,0
    ; error
    db %11000011,0, %01100110,0, %00111100,0, %00011000,0
    db %00011000,0, %00111100,0, %01100110,0, %11000011,0
    ; ok
    db 0,0, %00000001,0, %00000011,0, %10000110,0
    db %11001100,0, %01111000,0, %00110000,0, 0,0
    ; 1
    db %00011000,0, %00111000,0, %00011000,0, %00011000,0
    db %00011000,0, %00011000,0, %00111100,0, %00111100,0
    ; 2
    db %00111100,0, %01100110,0, %00000110,0, %00001100,0
    db %00011000,0, %00110000,0, %01111110,0, %01111110,0
    ; 3
    db %00111100,0, %01100110,0, %00000110,0, %00011100,0
    db %00000110,0, %01100110,0, %00111100,0, 0,0
    ; marco
    db %11111111,0, %10000001,0, %10000001,0, %10000001,0
    db %10000001,0, %10000001,0, %10000001,0, %11111111,0
TilesFin:

SECTION "Handshake", WRAM0[$C100]
wSuenoCompletado: ds 1
wEstado: ds 1
wRonda: ds 1
wCursor: ds 1
wPatron: ds 1
wError: ds 1
wTeclas: ds 1
wTeclasPrevias: ds 1
wTeclasNuevas: ds 1
