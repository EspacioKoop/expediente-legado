; Caza Pixeles 98 - minijuego GBC para SIGA-98
; Codigo original del proyecto, licencia MIT (LICENSE en la raiz del repositorio).
;
; Partida arcade de 30 segundos: mueve el cursor con la cruceta y captura
; el objetivo movil. La puntuacion solo existe dentro de la ROM y desaparece
; al apagar o salir: no concede dinero, pistas ni progreso en SIGA-98.

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
DEF rSTAT  EQU $FF41
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
DEF TILE_JUGADOR  EQU 1
DEF TILE_OBJETIVO EQU 2
DEF TILE_LINEA    EQU 3
DEF TILE_DIGITO0  EQU 4
DEF TILE_C        EQU 14
DEF TILE_A        EQU 15
DEF TILE_Z        EQU 16
DEF TILE_P        EQU 17
DEF TILE_I        EQU 18
DEF TILE_X        EQU 19
DEF TILE_E        EQU 20
DEF TILE_L        EQU 21
DEF TILE_S        EQU 22
DEF TILE_T        EQU 23
DEF TILE_R        EQU 24
DEF TILE_O        EQU 25
DEF TILE_M        EQU 26
DEF TILE_EXCL     EQU 27

DEF SEGUNDOS_PARTIDA EQU 30
DEF FRAMES_SEGUNDO   EQU 60

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "CAZAPIXEL98"
    ds $0143 - @, 0
    db $80 ; ROM compatible con Game Boy Color.
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
    call DibujarTitulo

    xor a
    ld [wEstado], a
    ld [wTeclas], a
    ld [wTeclasPrevias], a
    ld [wTeclasNuevas], a

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
    call IniciarPartida
    jr Bucle

EstadoJuego:
    ; El HUD se actualiza al principio del VBlank, antes de la logica del frame.
    call ActualizarHUD
    call MoverJugador
    call MoverObjetivo
    call ComprobarCaptura
    call TickTiempo
    call ActualizarOAM

    ld a, [wTiempo]
    or a
    jr nz, Bucle
    call SonidoFin
    call MostrarFin
    jr Bucle

EstadoFin:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarPartida
    jr Bucle

; Lee cruceta y botones. Los cuatro bits bajos son direcciones y los cuatro
; altos son A/B/Select/Start. Tambien calcula pulsaciones nuevas.
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

IniciarPartida:
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo
    call DibujarHUD

    ld a, 80
    ld [wJugadorX], a
    ld a, 88
    ld [wJugadorY], a

    xor a
    ld [wObjetivoIndice], a
    ld [wPuntos], a
    ld [wFrames], a
    ld [wObjetivoTick], a
    ld [wDirX], a
    ld [wDirY], a

    ld a, SEGUNDOS_PARTIDA
    ld [wTiempo], a
    ld a, 5
    ld [wIntervaloObjetivo], a

    ld hl, PosicionesObjetivo
    ld a, [hli]
    ld [wObjetivoX], a
    ld a, [hl]
    ld [wObjetivoY], a
    call ActualizarOAM

    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ActivarLCD
    ret

MostrarFin:
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo

    ld hl, BG_MAP + (5 * 32) + 7
    ld de, TextoTiempoFin
    call EscribirTexto

    ld hl, BG_MAP + (8 * 32) + 5
    ld de, TextoScore
    call EscribirTexto
    ld a, [wPuntos]
    ld hl, BG_MAP + (8 * 32) + 11
    call EscribirNumero2

    ld hl, BG_MAP + (12 * 32) + 7
    ld de, TextoStart
    call EscribirTexto

    ld a, ESTADO_FIN
    ld [wEstado], a
    call ActivarLCD
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
    ld a, $93 ; LCD, fondo y sprites 8x8.
    ldh [rLCDC], a
    ei
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
    cp 33 ; reserva las dos primeras filas para el HUD.
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

MoverObjetivo:
    ld a, [wObjetivoTick]
    inc a
    ld [wObjetivoTick], a
    ld b, a
    ld a, [wIntervaloObjetivo]
    cp b
    ret nc
    xor a
    ld [wObjetivoTick], a

    ld a, [wDirX]
    or a
    jr nz, .derecha

.izquierda:
    ld a, [wObjetivoX]
    cp 16
    jr z, .rebote_derecha
    dec a
    ld [wObjetivoX], a
    jr .vertical

.rebote_derecha:
    ld a, 1
    ld [wDirX], a
    ld a, [wObjetivoX]
    inc a
    ld [wObjetivoX], a
    jr .vertical

.derecha:
    ld a, [wObjetivoX]
    cp 152
    jr z, .rebote_izquierda
    inc a
    ld [wObjetivoX], a
    jr .vertical

.rebote_izquierda:
    xor a
    ld [wDirX], a
    ld a, [wObjetivoX]
    dec a
    ld [wObjetivoX], a

.vertical:
    ld a, [wDirY]
    or a
    jr nz, .abajo

.arriba:
    ld a, [wObjetivoY]
    cp 40
    jr z, .rebote_abajo
    dec a
    ld [wObjetivoY], a
    ret

.rebote_abajo:
    ld a, 1
    ld [wDirY], a
    ld a, [wObjetivoY]
    inc a
    ld [wObjetivoY], a
    ret

.abajo:
    ld a, [wObjetivoY]
    cp 152
    jr z, .rebote_arriba
    inc a
    ld [wObjetivoY], a
    ret

.rebote_arriba:
    xor a
    ld [wDirY], a
    ld a, [wObjetivoY]
    dec a
    ld [wObjetivoY], a
    ret

ComprobarCaptura:
    ; AABB de dos sprites de 8x8.
    ld a, [wJugadorX]
    add 8
    ld b, a
    ld a, [wObjetivoX]
    cp b
    jr nc, .no_captura

    ld a, [wObjetivoX]
    add 8
    ld b, a
    ld a, [wJugadorX]
    cp b
    jr nc, .no_captura

    ld a, [wJugadorY]
    add 8
    ld b, a
    ld a, [wObjetivoY]
    cp b
    jr nc, .no_captura

    ld a, [wObjetivoY]
    add 8
    ld b, a
    ld a, [wJugadorY]
    cp b
    jr nc, .no_captura

    ld a, [wPuntos]
    cp 99
    jr nc, .sin_incremento
    inc a
    ld [wPuntos], a

.sin_incremento:
    call AjustarDificultad
    call SiguienteObjetivo
    call SonidoCaptura

.no_captura:
    ret

AjustarDificultad:
    ld a, [wPuntos]
    cp 5
    jr nz, .nivel2
    ld a, 4
    ld [wIntervaloObjetivo], a
    ret
.nivel2:
    cp 10
    jr nz, .nivel3
    ld a, 3
    ld [wIntervaloObjetivo], a
    ret
.nivel3:
    cp 20
    ret nz
    ld a, 2
    ld [wIntervaloObjetivo], a
    ret

SiguienteObjetivo:
    ld a, [wObjetivoIndice]
    inc a
    and $0F
    ld [wObjetivoIndice], a
    ld b, a
    add a
    ld e, a
    ld d, 0
    ld hl, PosicionesObjetivo
    add hl, de
    ld a, [hli]
    ld [wObjetivoX], a
    ld a, [hl]
    ld [wObjetivoY], a

    ld a, b
    and 1
    ld [wDirX], a
    ld a, b
    and 2
    srl a
    ld [wDirY], a
    xor a
    ld [wObjetivoTick], a
    ret

TickTiempo:
    ld a, [wFrames]
    inc a
    cp FRAMES_SEGUNDO
    jr c, .guardar
    xor a
    ld [wFrames], a
    ld a, [wTiempo]
    or a
    ret z
    dec a
    ld [wTiempo], a
    ret
.guardar:
    ld [wFrames], a
    ret

ActualizarOAM:
    ld hl, OAM_BASE
    ld a, [wJugadorY]
    ld [hli], a
    ld a, [wJugadorX]
    ld [hli], a
    ld a, TILE_JUGADOR
    ld [hli], a
    xor a
    ld [hli], a

    ld a, [wObjetivoY]
    ld [hli], a
    ld a, [wObjetivoX]
    ld [hli], a
    ld a, TILE_OBJETIVO
    ld [hli], a
    ld a, 1 ; paleta OBJ 1 para el objetivo.
    ld [hl], a
    ret

ActualizarHUD:
    ld a, [wPuntos]
    ld hl, BG_MAP + 7
    call EscribirNumero2
    ld a, [wTiempo]
    ld hl, BG_MAP + 15
    call EscribirNumero2
    ret

DibujarTitulo:
    ld hl, BG_MAP + (2 * 32) + 2
    call DibujarLinea16

    ld hl, BG_MAP + (4 * 32) + 3
    ld de, TextoTitulo
    call EscribirTexto

    ld hl, BG_MAP + (6 * 32) + 2
    call DibujarLinea16

    ld hl, BG_MAP + (9 * 32) + 7
    ld de, TextoStart
    call EscribirTexto
    ret

DibujarHUD:
    ld hl, BG_MAP + 1
    ld de, TextoScore
    call EscribirTexto
    xor a
    ld hl, BG_MAP + 7
    call EscribirNumero2

    ld hl, BG_MAP + 10
    ld de, TextoTime
    call EscribirTexto
    ld a, SEGUNDOS_PARTIDA
    ld hl, BG_MAP + 15
    call EscribirNumero2

    ld hl, BG_MAP + 32 + 2
    call DibujarLinea16
    ret

DibujarLinea16:
    ld b, 16
    ld a, TILE_LINEA
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

EscribirTexto:
.loop:
    ld a, [de]
    cp $FF
    ret z
    ld [hli], a
    inc de
    jr .loop

; A = 0..99, HL = posicion del primer digito.
EscribirNumero2:
    ld b, 0
.decenas:
    cp 10
    jr c, .escribir
    sub 10
    inc b
    jr .decenas
.escribir:
    ld c, a
    call EsperarVRAM
    ld a, b
    add TILE_DIGITO0
    ld [hli], a
    call EsperarVRAM
    ld a, c
    add TILE_DIGITO0
    ld [hl], a
    ret

EsperarVRAM:
.espera:
    ldh a, [rSTAT]
    and 3
    cp 3
    jr z, .espera
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

    ; Fondo GBC 0: crema, verde grisaceo, verde oscuro, negro.
    ld a, $80
    ldh [rBCPS], a
    ld hl, PaletaFondo
    ld b, PaletaFondoFin - PaletaFondo
.bg:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bg

    ; OBJ 0 = cursor verde/cian; OBJ 1 = objetivo rojo/naranja.
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

SonidoInicio:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $C2
    ldh [rNR12], a
    ld a, $80
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoCaptura:
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

SonidoFin:
    xor a
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $E3
    ldh [rNR12], a
    ld a, $20
    ldh [rNR13], a
    ld a, $83
    ldh [rNR14], a
    ret

SECTION "Datos", ROM0
TextoTitulo:
    db TILE_C, TILE_A, TILE_Z, TILE_A, TILE_VACIO
    db TILE_P, TILE_I, TILE_X, TILE_E, TILE_L, TILE_VACIO
    db TILE_DIGITO0 + 9, TILE_DIGITO0 + 8, $FF
TextoStart:
    db TILE_S, TILE_T, TILE_A, TILE_R, TILE_T, $FF
TextoScore:
    db TILE_S, TILE_C, TILE_O, TILE_R, TILE_E, $FF
TextoTime:
    db TILE_T, TILE_I, TILE_M, TILE_E, $FF
TextoTiempoFin:
    db TILE_T, TILE_I, TILE_M, TILE_E, TILE_EXCL, $FF

PosicionesObjetivo:
    db 24, 40
    db 136, 48
    db 72, 64
    db 120, 112
    db 40, 128
    db 152, 136
    db 88, 88
    db 32, 104
    db 144, 72
    db 56, 144
    db 104, 40
    db 16, 64
    db 128, 128
    db 48, 48
    db 112, 80
    db 64, 120

; Tile 0: vacio.
; Tile 1: cursor/jugador.
; Tile 2: objetivo en forma de rombo.
; Tile 3: separador horizontal.
Tiles:
    rept 8
        db $00, $00
    endr

    db $18, $00, $3C, $00, $7E, $00, $DB, $00
    db $FF, $00, $7E, $00, $24, $00, $42, $00

    db $18, $18, $3C, $3C, $7E, $7E, $FF, $FF
    db $FF, $FF, $7E, $7E, $3C, $3C, $18, $18

    db $00, $00, $00, $00, $00, $00, $FF, $00
    db $FF, $00, $00, $00, $00, $00, $00, $00

; Digitos 0-9, color de fondo 1.
    db $3C,$00,$66,$00,$6E,$00,$76,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $18,$00,$38,$00,$18,$00,$18,$00,$18,$00,$18,$00,$7E,$00,$00,$00
    db $3C,$00,$66,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$7E,$00,$00,$00
    db $3C,$00,$66,$00,$06,$00,$1C,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    db $0C,$00,$1C,$00,$3C,$00,$6C,$00,$7E,$00,$0C,$00,$0C,$00,$00,$00
    db $7E,$00,$60,$00,$7C,$00,$06,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    db $1C,$00,$30,$00,$60,$00,$7C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $7E,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$30,$00,$30,$00,$00,$00
    db $3C,$00,$66,$00,$66,$00,$3C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $3C,$00,$66,$00,$66,$00,$3E,$00,$06,$00,$0C,$00,$38,$00,$00,$00

; C A Z P I X E L S T R O M !
    db $3C,$00,$66,$00,$60,$00,$60,$00,$60,$00,$66,$00,$3C,$00,$00,$00
    db $18,$00,$3C,$00,$66,$00,$66,$00,$7E,$00,$66,$00,$66,$00,$00,$00
    db $7E,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$60,$00,$7E,$00,$00,$00
    db $7C,$00,$66,$00,$66,$00,$7C,$00,$60,$00,$60,$00,$60,$00,$00,$00
    db $3C,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$3C,$00,$00,$00
    db $66,$00,$66,$00,$3C,$00,$18,$00,$3C,$00,$66,$00,$66,$00,$00,$00
    db $7E,$00,$60,$00,$60,$00,$7C,$00,$60,$00,$60,$00,$7E,$00,$00,$00
    db $60,$00,$60,$00,$60,$00,$60,$00,$60,$00,$60,$00,$7E,$00,$00,$00
    db $3C,$00,$66,$00,$60,$00,$3C,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    db $7E,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
    db $7C,$00,$66,$00,$66,$00,$7C,$00,$78,$00,$6C,$00,$66,$00,$00,$00
    db $3C,$00,$66,$00,$66,$00,$66,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $63,$00,$77,$00,$7F,$00,$6B,$00,$63,$00,$63,$00,$63,$00,$00,$00
    db $18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00,$18,$00,$00,$00
TilesFin:

PaletaFondo:
    dw $7FFF, $5AD6, $318C, $0000
PaletaFondoFin:

PaletasObjetos:
    dw $7FFF, $7FE0, $03E0, $0000
    dw $7FFF, $421F, $001F, $0000
PaletasObjetosFin:

SECTION "Variables", WRAM0
wEstado:            ds 1
wJugadorX:          ds 1
wJugadorY:          ds 1
wObjetivoX:         ds 1
wObjetivoY:         ds 1
wObjetivoIndice:    ds 1
wDirX:              ds 1
wDirY:              ds 1
wObjetivoTick:      ds 1
wIntervaloObjetivo: ds 1
wPuntos:            ds 1
wTiempo:            ds 1
wFrames:            ds 1
wTeclas:            ds 1
wTeclasPrevias:     ds 1
wTeclasNuevas:      ds 1
