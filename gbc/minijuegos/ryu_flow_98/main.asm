; RYU_FLOW - micro-ROM GBC para SIGA-98 (#440)
; Codigo y graficos originales del proyecto; licencia segun LICENSE en la raiz.
;
; El jugador debe reorientar tres compuertas. La ROM arranca con las tres
; incorrectas y solo marca finalizacion cuando las tres han sido manipuladas
; y el cauce coincide con la solucion declarativa. Arrancar y salir no cuenta.

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
DEF KEY_A     EQU %00010000
DEF KEY_START EQU %10000000

DEF TILE_VACIO       EQU 0
DEF TILE_AGUA        EQU 1
DEF TILE_COMPUERTA_UP EQU 2
DEF TILE_COMPUERTA_DN EQU 3
DEF TILE_UP_OK       EQU 4
DEF TILE_DN_OK       EQU 5
DEF TILE_FUENTE      EQU 6
DEF TILE_META        EQU 7
DEF TILE_CURSOR      EQU 8
DEF TILE_DRAGON_HEAD EQU 9
DEF TILE_DRAGON_BODY EQU 10
DEF TILE_MARCA_UP    EQU 11
DEF TILE_MARCA_DN    EQU 12
DEF TILE_R           EQU 13
DEF TILE_Y           EQU 14
DEF TILE_U           EQU 15
DEF TILE_F           EQU 16
DEF TILE_L           EQU 17
DEF TILE_O           EQU 18
DEF TILE_W           EQU 19
DEF TILE_S           EQU 20
DEF TILE_T           EQU 21
DEF TILE_A           EQU 22
DEF TILE_G           EQU 23
DEF TILE_I           EQU 24
DEF TILE_K           EQU 25
DEF TILE_J           EQU 26

; bit 0 = compuerta 1, bit 1 = compuerta 2, bit 2 = compuerta 3.
; 0 = curva arriba, 1 = curva abajo.
DEF COMPUERTAS_INICIALES EQU %00000101
DEF SOLUCION_COMPUERTAS  EQU %00000010
DEF TODAS_TOCADAS        EQU %00000111
DEF MARCA_COMPLETADO     EQU $A5

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "RYUFLOW98"
    ds $0143 - @, 0
    db $80 ; dual-mode CGB: sigue funcionando en fallback DMG.
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
    ld [wRyuFlowCompletado], a

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
    call IniciarJuego
    jr Bucle

EstadoJuego:
    ld a, [wTeclasNuevas]
    and KEY_LEFT
    call nz, SeleccionarAnterior

    ld a, [wTeclasNuevas]
    and KEY_RIGHT
    call nz, SeleccionarSiguiente

    ld a, [wTeclasNuevas]
    and KEY_A
    jr z, .cursor
    call ToggleCompuerta
    call SonidoCompuerta
    call ActualizarCompuertas
    call ComprobarSolucion

.cursor:
    call ActualizarCursor
    jr Bucle

EstadoFin:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarJuego
    jr Bucle

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

IniciarJuego:
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo

    xor a
    ld [wSeleccion], a
    ld [wTocados], a
    ld [wRyuFlowCompletado], a
    ld a, COMPUERTAS_INICIALES
    ld [wCompuertas], a

    call DibujarJuego
    call ActualizarCompuertas
    call ActualizarCursor

    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ActivarLCD
    ret

SeleccionarAnterior:
    ld a, [wSeleccion]
    or a
    jr nz, .decrementar
    ld a, 2
    ld [wSeleccion], a
    ret
.decrementar:
    dec a
    ld [wSeleccion], a
    ret

SeleccionarSiguiente:
    ld a, [wSeleccion]
    cp 2
    jr c, .incrementar
    xor a
    ld [wSeleccion], a
    ret
.incrementar:
    inc a
    ld [wSeleccion], a
    ret

ToggleCompuerta:
    ld a, [wSeleccion]
    or a
    jr z, .primera
    cp 1
    jr z, .segunda

.tercera:
    ld a, [wCompuertas]
    xor %00000100
    ld [wCompuertas], a
    ld a, [wTocados]
    or %00000100
    ld [wTocados], a
    ret

.segunda:
    ld a, [wCompuertas]
    xor %00000010
    ld [wCompuertas], a
    ld a, [wTocados]
    or %00000010
    ld [wTocados], a
    ret

.primera:
    ld a, [wCompuertas]
    xor %00000001
    ld [wCompuertas], a
    ld a, [wTocados]
    or %00000001
    ld [wTocados], a
    ret

ComprobarSolucion:
    ld a, [wTocados]
    cp TODAS_TOCADAS
    ret nz
    ld a, [wCompuertas]
    cp SOLUCION_COMPUERTAS
    ret nz
    call CompletarFlujo
    ret

CompletarFlujo:
    ld a, MARCA_COMPLETADO
    ld [wRyuFlowCompletado], a
    call SonidoExito

    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo
    call DibujarFinal

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

ActualizarCursor:
    ld hl, OAM_BASE
    ld a, 80
    ld [hli], a

    ld a, [wSeleccion]
    add a
    ld e, a
    ld d, 0
    ld hl, PosicionesCursor
    add hl, de
    ld a, [hl]

    ld hl, OAM_BASE + 1
    ld [hli], a
    ld a, TILE_CURSOR
    ld [hli], a
    xor a
    ld [hl], a
    ret

ActualizarCompuertas:
    ; Compuerta 1: objetivo arriba (bit 0 = 0).
    ld hl, BG_MAP + (9 * 32) + 4
    call EsperarVRAM
    ld a, [wCompuertas]
    and %00000001
    jr nz, .g1_abajo
    ld a, TILE_UP_OK
    jr .g1_escribir
.g1_abajo:
    ld a, TILE_COMPUERTA_DN
.g1_escribir:
    ld [hl], a

    ; Compuerta 2: objetivo abajo (bit 1 = 1).
    ld hl, BG_MAP + (9 * 32) + 9
    call EsperarVRAM
    ld a, [wCompuertas]
    and %00000010
    jr z, .g2_arriba
    ld a, TILE_DN_OK
    jr .g2_escribir
.g2_arriba:
    ld a, TILE_COMPUERTA_UP
.g2_escribir:
    ld [hl], a

    ; Compuerta 3: objetivo arriba (bit 2 = 0).
    ld hl, BG_MAP + (9 * 32) + 14
    call EsperarVRAM
    ld a, [wCompuertas]
    and %00000100
    jr nz, .g3_abajo
    ld a, TILE_UP_OK
    jr .g3_escribir
.g3_abajo:
    ld a, TILE_COMPUERTA_DN
.g3_escribir:
    ld [hl], a
    ret

DibujarTitulo:
    ld hl, BG_MAP + (3 * 32) + 6
    ld de, TextoTitulo
    call EscribirTexto

    ; Serpiente/agua estilizada, propia y muy simple.
    ld hl, BG_MAP + (7 * 32) + 4
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_HEAD
    ld [hl], a

    ld hl, BG_MAP + (12 * 32) + 7
    ld de, TextoStart
    call EscribirTexto
    ret

DibujarJuego:
    ld hl, BG_MAP + (1 * 32) + 6
    ld de, TextoTitulo
    call EscribirTexto

    ld hl, BG_MAP + (4 * 32) + 7
    ld de, TextoGira
    call EscribirTexto

    ; Cauce principal. Las compuertas sustituyen tres tramos.
    ld hl, BG_MAP + (9 * 32) + 1
    ld b, 18
    ld a, TILE_AGUA
.rio:
    ld [hli], a
    dec b
    jr nz, .rio

    ld hl, BG_MAP + (9 * 32) + 1
    ld a, TILE_FUENTE
    ld [hl], a
    ld hl, BG_MAP + (9 * 32) + 18
    ld a, TILE_META
    ld [hl], a

    ; Guia del cauce esperado: arriba, abajo, arriba.
    ld hl, BG_MAP + (11 * 32) + 4
    ld a, TILE_MARCA_UP
    ld [hl], a
    ld hl, BG_MAP + (11 * 32) + 9
    ld a, TILE_MARCA_DN
    ld [hl], a
    ld hl, BG_MAP + (11 * 32) + 14
    ld a, TILE_MARCA_UP
    ld [hl], a
    ret

DibujarFinal:
    ld hl, BG_MAP + (2 * 32) + 6
    ld de, TextoTitulo
    call EscribirTexto

    ld hl, BG_MAP + (5 * 32) + 7
    ld de, TextoFlowOk
    call EscribirTexto

    ; El ryū sigue el cauce resuelto. No hay premio sistemico en la ROM.
    ld hl, BG_MAP + (9 * 32) + 2
    ld a, TILE_FUENTE
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_BODY
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_DRAGON_HEAD
    ld [hli], a
    ld a, TILE_AGUA
    ld [hli], a
    ld a, TILE_META
    ld [hl], a
    ret

EscribirTexto:
.loop:
    ld a, [de]
    cp $FF
    ret z
    ld [hli], a
    inc de
    jr .loop

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
.loop:
    ; El OR del contador modifica A: sin repetir el xor, cada celda recibía el
    ; contador y el mapa se llenaba de tiles de letras (#805).
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

ConfigurarPaletas:
    ; DMG: el índice 1 del fondo (tinta) pasa a negro para que se lea (#805).
    ld a, %11101100
    ldh [rBGP], a
    ld a, %11100100
    ldh [rOBP0], a

    ; Paleta fria: espuma, cian, azul y tinta oscura.
    ld a, $80
    ldh [rBCPS], a
    ld hl, PaletaFondo
    ld b, PaletaFondoFin - PaletaFondo
.bg:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bg

    ld a, $80
    ldh [rOCPS], a
    ld hl, PaletaObjeto
    ld b, PaletaObjetoFin - PaletaObjeto
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
    ld a, $A2
    ldh [rNR12], a
    ld a, $70
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoCompuerta:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $B1
    ldh [rNR12], a
    ld a, $30
    ldh [rNR13], a
    ld a, $84
    ldh [rNR14], a
    ret

SonidoExito:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F2
    ldh [rNR12], a
    ld a, $B0
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SECTION "Datos", ROM0
TextoTitulo:
    db TILE_R, TILE_Y, TILE_U, TILE_VACIO, TILE_F, TILE_L, TILE_O, TILE_W, $FF
TextoStart:
    db TILE_S, TILE_T, TILE_A, TILE_R, TILE_T, $FF
TextoGira:
    db TILE_A, TILE_VACIO, TILE_G, TILE_I, TILE_R, TILE_A, $FF
TextoFlowOk:
    db TILE_F, TILE_L, TILE_O, TILE_W, TILE_VACIO, TILE_O, TILE_K, $FF

; Valores OAM X para las columnas 4, 9 y 14.
PosicionesCursor:
    db 40, 0
    db 80, 0
    db 120, 0

Tiles:
    ; 0 vacio
    rept 8
        db $00, $00
    endr

    ; 1 agua horizontal
    db $00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00
    ; 2 compuerta curva arriba
    db $00,$00,$03,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$60,$00,$C0,$00
    ; 3 compuerta curva abajo
    db $C0,$00,$60,$00,$30,$00,$18,$00,$0C,$00,$06,$00,$03,$00,$00,$00
    ; 4 curva arriba correcta (segundo plano)
    db $00,$00,$00,$03,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$60,$00,$C0
    ; 5 curva abajo correcta
    db $00,$C0,$00,$60,$00,$30,$00,$18,$00,$0C,$00,$06,$00,$03,$00,$00
    ; 6 fuente
    db $18,$18,$3C,$3C,$7E,$7E,$FF,$FF,$7E,$7E,$3C,$3C,$18,$18,$00,$00
    ; 7 meta/remolino
    db $3C,$00,$42,$00,$99,$00,$A5,$00,$A5,$00,$99,$00,$42,$00,$3C,$00
    ; 8 cursor
    db $18,$18,$3C,$3C,$7E,$7E,$FF,$FF,$18,$18,$18,$18,$18,$18,$18,$18
    ; 9 cabeza de dragon propia
    db $3C,$00,$7E,$00,$DB,$00,$FF,$00,$7E,$00,$3C,$00,$24,$00,$42,$00
    ; 10 cuerpo serpentino
    db $00,$00,$18,$00,$3C,$00,$66,$00,$C3,$00,$66,$00,$3C,$00,$18,$00
    ; 11 marca arriba
    db $18,$00,$3C,$00,$7E,$00,$DB,$00,$18,$00,$18,$00,$18,$00,$00,$00
    ; 12 marca abajo
    db $00,$00,$18,$00,$18,$00,$18,$00,$DB,$00,$7E,$00,$3C,$00,$18,$00

    ; 13..26: R Y U F L O W S T A G I K J
    db $7C,$00,$66,$00,$66,$00,$7C,$00,$78,$00,$6C,$00,$66,$00,$00,$00
    db $66,$00,$66,$00,$3C,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
    db $66,$00,$66,$00,$66,$00,$66,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $7E,$00,$60,$00,$60,$00,$7C,$00,$60,$00,$60,$00,$60,$00,$00,$00
    db $60,$00,$60,$00,$60,$00,$60,$00,$60,$00,$60,$00,$7E,$00,$00,$00
    db $3C,$00,$66,$00,$66,$00,$66,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $63,$00,$63,$00,$63,$00,$6B,$00,$7F,$00,$77,$00,$63,$00,$00,$00
    db $3C,$00,$66,$00,$60,$00,$3C,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    db $7E,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
    db $18,$00,$3C,$00,$66,$00,$66,$00,$7E,$00,$66,$00,$66,$00,$00,$00
    db $3C,$00,$66,$00,$60,$00,$6E,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $3C,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$3C,$00,$00,$00
    db $66,$00,$6C,$00,$78,$00,$70,$00,$78,$00,$6C,$00,$66,$00,$00,$00
    db $1E,$00,$0C,$00,$0C,$00,$0C,$00,$0C,$00,$6C,$00,$38,$00,$00,$00
TilesFin:

PaletaFondo:
    ; El color 1 es la tinta del texto, el cauce y las guías (#805): en gris
    ; casi blanco no se leía. Espuma, azul tinta, azul, tinta oscura.
    dw $7BDE, $5142, $7C00, $2108
PaletaFondoFin:

PaletaObjeto:
    dw $7FFF, $7FE0, $03E0, $0000
PaletaObjetoFin:

SECTION "Variables", WRAM0
wEstado:        ds 1
wSeleccion:     ds 1
wCompuertas:    ds 1
wTocados:       ds 1
wTeclas:        ds 1
wTeclasPrevias: ds 1
wTeclasNuevas:  ds 1

; Contrato estable para futura integracion con #442. La ROM lo escribe solo al
; completar la interaccion; este corte no conecta aun ese byte con Godot.
SECTION "Handshake", WRAM0[$C100]
wRyuFlowCompletado: ds 1
