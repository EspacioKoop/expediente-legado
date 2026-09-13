; Caza Pixeles 98 - minijuego GBC para SIGA-98
; Codigo original del proyecto, licencia MIT (LICENSE en la raiz del repositorio).
;
; Mueve el bloque verde con la cruceta y toca el rombo rojo.
; Cada captura recoloca el objetivo y emite un bip. No guarda estado.

DEF rP1    EQU $FF00
DEF rNR10  EQU $FF10
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
DEF rOBP0  EQU $FF48
DEF rIF    EQU $FF0F
DEF rBCPS  EQU $FF68
DEF rBCPD  EQU $FF69
DEF rOCPS  EQU $FF6A
DEF rOCPD  EQU $FF6B
DEF rIE    EQU $FFFF

DEF VRAM_TILES EQU $8000
DEF BG_MAP     EQU $9800
DEF OAM_BASE   EQU $FE00

DEF KEY_RIGHT EQU %00000001
DEF KEY_LEFT  EQU %00000010
DEF KEY_UP    EQU %00000100
DEF KEY_DOWN  EQU %00001000

DEF PLAYER_TILE EQU 1
DEF TARGET_TILE EQU 2

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "CAZAPIXEL98"
    ds $0143 - @, 0
    db $80 ; Compatible con Game Boy Color; activa el modo CGB en hardware GBC.
    ds $0150 - @, 0

SECTION "Juego", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF

.espera_vblank:
    ldh a, [rLY]
    cp 144
    jr c, .espera_vblank

    xor a
    ldh [rLCDC], a
    ldh [rSCX], a
    ldh [rSCY], a
    ldh [rIF], a

    call LimpiarOAM
    call CargarTiles
    call LimpiarFondo
    call ConfigurarPaletas
    call ConfigurarAudio

    ld a, 80
    ld [wJugadorX], a
    ld a, 80
    ld [wJugadorY], a
    xor a
    ld [wObjetivoIndice], a
    ld [wPuntos], a

    ld hl, PosicionesObjetivo
    ld a, [hli]
    ld [wObjetivoX], a
    ld a, [hl]
    ld [wObjetivoY], a
    call ActualizarOAM

    ld a, 1
    ldh [rIE], a
    ld a, $93 ; LCD encendida, tiles $8000, sprites 8x8 y fondo activo.
    ldh [rLCDC], a
    ei

Bucle:
    halt
    call LeerCruceta
    call MoverJugador
    call ComprobarCaptura
    call ActualizarOAM
    jr Bucle

LeerCruceta:
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    ld [wTeclas], a
    ld a, $30
    ldh [rP1], a
    ret

MoverJugador:
    ld a, [wTeclas]
    and KEY_RIGHT
    jr z, .izquierda
    ld a, [wJugadorX]
    cp 160
    jr nc, .izquierda
    inc a
    ld [wJugadorX], a

.izquierda:
    ld a, [wTeclas]
    and KEY_LEFT
    jr z, .arriba
    ld a, [wJugadorX]
    cp 9
    jr c, .arriba
    dec a
    ld [wJugadorX], a

.arriba:
    ld a, [wTeclas]
    and KEY_UP
    jr z, .abajo
    ld a, [wJugadorY]
    cp 17
    jr c, .abajo
    dec a
    ld [wJugadorY], a

.abajo:
    ld a, [wTeclas]
    and KEY_DOWN
    ret z
    ld a, [wJugadorY]
    cp 152
    ret nc
    inc a
    ld [wJugadorY], a
    ret

ComprobarCaptura:
    ; Separacion horizontal: jugador_derecha < objetivo_izquierda.
    ld a, [wJugadorX]
    add 7
    ld b, a
    ld a, [wObjetivoX]
    cp b
    jr nc, .no_captura

    ; Separacion horizontal: objetivo_derecha < jugador_izquierda.
    ld a, [wObjetivoX]
    add 7
    ld b, a
    ld a, [wJugadorX]
    cp b
    jr nc, .no_captura

    ; Separacion vertical: jugador_abajo < objetivo_arriba.
    ld a, [wJugadorY]
    add 7
    ld b, a
    ld a, [wObjetivoY]
    cp b
    jr nc, .no_captura

    ; Separacion vertical: objetivo_abajo < jugador_arriba.
    ld a, [wObjetivoY]
    add 7
    ld b, a
    ld a, [wJugadorY]
    cp b
    jr nc, .no_captura

    ld a, [wPuntos]
    inc a
    ld [wPuntos], a
    call SiguienteObjetivo
    call Bip

.no_captura:
    ret

SiguienteObjetivo:
    ld a, [wObjetivoIndice]
    inc a
    and $0F
    ld [wObjetivoIndice], a
    add a
    ld e, a
    ld d, 0
    ld hl, PosicionesObjetivo
    add hl, de
    ld a, [hli]
    ld [wObjetivoX], a
    ld a, [hl]
    ld [wObjetivoY], a
    ret

ActualizarOAM:
    ld hl, OAM_BASE
    ld a, [wJugadorY]
    ld [hli], a
    ld a, [wJugadorX]
    ld [hli], a
    ld a, PLAYER_TILE
    ld [hli], a
    xor a
    ld [hli], a

    ld a, [wObjetivoY]
    ld [hli], a
    ld a, [wObjetivoX]
    ld [hli], a
    ld a, TARGET_TILE
    ld [hli], a
    ld a, 1 ; Paleta OBJ 1: rojo.
    ld [hl], a
    ret

LimpiarOAM:
    ld hl, OAM_BASE
    ld b, 160
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

CargarTiles:
    ld hl, Tiles
    ld de, VRAM_TILES
    ld bc, TilesFin - Tiles
.loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

LimpiarFondo:
    ld hl, BG_MAP
    ld bc, 32 * 32
    xor a
.loop:
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

ConfigurarPaletas:
    ; Fallback DMG y emuladores que expongan paletas clasicas.
    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP0], a

    ; Paleta de fondo CGB 0: marfil -> gris verdoso -> oscuro -> negro.
    ld a, $80
    ldh [rBCPS], a
    ld hl, PaletaFondo
    ld b, PaletaFondoFin - PaletaFondo
.bg:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bg

    ; Paletas OBJ CGB 0 (jugador verde) y 1 (objetivo rojo).
    ld a, $80
    ldh [rOCPS], a
    ld hl, PaletasObjetos
    ld b, PaletasObjetosFin - PaletasObjetos
.obj:
    ld a, [hli]
    ldh [rOCPD], a
    dec b
    jr nz, .obj
    ret

ConfigurarAudio:
    ld a, $80
    ldh [rNR52], a
    ld a, $77
    ldh [rNR50], a
    ld a, $11
    ldh [rNR51], a
    ret

Bip:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F1
    ldh [rNR12], a
    ld a, $40
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SECTION "Datos", ROM0
PosicionesObjetivo:
    db 24, 32
    db 136, 40
    db 72, 56
    db 120, 112
    db 40, 128
    db 152, 136
    db 88, 88
    db 32, 104
    db 144, 72
    db 56, 144
    db 104, 32
    db 16, 64
    db 128, 128
    db 48, 48
    db 112, 80
    db 64, 120

; Tile 0: fondo transparente/blanco.
; Tile 1: jugador, cuadrado macizo (indice de color 1).
; Tile 2: objetivo, rombo macizo (indice de color 3).
Tiles:
    rept 8
        db $00, $00
    endr
    rept 8
        db $FF, $00
    endr
    db $18, $18
    db $3C, $3C
    db $7E, $7E
    db $FF, $FF
    db $FF, $FF
    db $7E, $7E
    db $3C, $3C
    db $18, $18
TilesFin:

PaletaFondo:
    dw $7FFF, $5AD6, $318C, $0000
PaletaFondoFin:

PaletasObjetos:
    ; Paleta 0: transparente, verde vivo, verde oscuro, negro.
    dw $7FFF, $03E0, $01A0, $0000
    ; Paleta 1: transparente, rojo claro, rojo vivo, negro.
    dw $7FFF, $421F, $001F, $0000
PaletasObjetosFin:

SECTION "Variables", WRAM0
wJugadorX:       ds 1
wJugadorY:       ds 1
wObjetivoX:      ds 1
wObjetivoY:      ds 1
wObjetivoIndice: ds 1
wPuntos:         ds 1
wTeclas:         ds 1
