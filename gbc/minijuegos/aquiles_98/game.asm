; MYRMIDON 98 - ROM GBC propia para la familia Aquiles (#438).
; Codigo y pixel-art originales del proyecto, licencia MIT.
;
; La regla central es deliberada: el rival parece invulnerable. Mantener B
; permite leer un ciclo completo de guardia; solo despues se revela durante
; un instante el punto vulnerable. Hay que colocar la mira abajo y pulsar A
; en esa ventana. Atacar antes de leer o fuera de tiempo reinicia la lectura.
;
; La ROM es autonoma: no guarda dinero, pistas ni progreso de SIGA-98.

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
DEF rOBP1  EQU $FF49
DEF rIF    EQU $FF0F
DEF rBCPS  EQU $FF68
DEF rBCPD  EQU $FF69
DEF rOCPS  EQU $FF6A
DEF rOCPD  EQU $FF6B
DEF rIE    EQU $FFFF

DEF VRAM_TILES EQU $8000
DEF BG_MAP     EQU $9800
DEF OAM_BASE   EQU $FE00

DEF ESTADO_TITULO   EQU 0
DEF ESTADO_DUELO    EQU 1
DEF ESTADO_VICTORIA EQU 2

DEF KEY_RIGHT  EQU %00000001
DEF KEY_LEFT   EQU %00000010
DEF KEY_UP     EQU %00000100
DEF KEY_DOWN   EQU %00001000
DEF KEY_A      EQU %00010000
DEF KEY_B      EQU %00100000
DEF KEY_SELECT EQU %01000000
DEF KEY_START  EQU %10000000

DEF TILE_VACIO   EQU 0
DEF TILE_CABEZA  EQU 1
DEF TILE_TORSO   EQU 2
DEF TILE_PIERNAS EQU 3
DEF TILE_ESCUDO  EQU 4
DEF TILE_MIRA    EQU 5
DEF TILE_DEBIL   EQU 6
DEF TILE_OJO     EQU 7
DEF TILE_FALLO   EQU 8
DEF TILE_PIP     EQU 9
DEF TILE_TROFEO  EQU 10
DEF TILE_FLECHA  EQU 11
DEF TILE_M       EQU 12
DEF TILE_Y       EQU 13
DEF TILE_R       EQU 14
DEF TILE_I       EQU 15
DEF TILE_D       EQU 16
DEF TILE_O       EQU 17
DEF TILE_N       EQU 18
DEF TILE_9       EQU 19
DEF TILE_8       EQU 20
DEF TILE_A       EQU 21
DEF TILE_SUELO   EQU 22

DEF LECTURA_COMPLETA EQU $0F
DEF IMPACTOS_META    EQU 3
DEF FALLO_FRAMES     EQU 12


INCLUDE "../comun/cartucho.asm"

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "MYRMIDON98"
    ds $0143 - @, 0
    db $80 ; dual: Game Boy + mejoras de paleta en Game Boy Color.
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
    ld [wFalloTimer], a

    call ActivarLCD

Bucle:
    halt
    ; OAM se toca al principio de VBlank y nunca desde la logica tardia.
    call RenderOAM
    call LeerControles

    ld a, [wEstado]
    or a
    jr z, EstadoTitulo
    cp ESTADO_DUELO
    jr z, EstadoDuelo
    jr EstadoVictoria

EstadoTitulo:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarDuelo
    jr Bucle

EstadoDuelo:
    call MoverMira
    call TickFase
    call ActualizarLectura
    call IntentarGolpe
    call TickFallo
    jr Bucle

EstadoVictoria:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarDuelo
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

IniciarDuelo:
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo
    call DibujarArena

    xor a
    ld [wMira], a
    ld [wFase], a
    ld [wMascaraLectura], a
    ld [wLeido], a
    ld [wImpactos], a
    ld [wFalloTimer], a
    call DuracionFase
    ld [wFaseTimer], a

    ld a, ESTADO_DUELO
    ld [wEstado], a
    call ActivarLCD
    ret

MoverMira:
    ld a, [wTeclasNuevas]
    and KEY_UP
    jr z, .abajo
    ld a, [wMira]
    or a
    jr z, .abajo
    dec a
    ld [wMira], a

.abajo:
    ld a, [wTeclasNuevas]
    and KEY_DOWN
    ret z
    ld a, [wMira]
    cp 2
    ret nc
    inc a
    ld [wMira], a
    ret

TickFase:
    ld a, [wFaseTimer]
    dec a
    ld [wFaseTimer], a
    ret nz

    ld a, [wFase]
    inc a
    and 3
    ld [wFase], a
    call DuracionFase
    ld [wFaseTimer], a
    ret

; La lectura exige mantener B durante el ciclo entero. Soltar B antes de
; completarlo borra el progreso de observacion, evitando activar la pista por
; presencia o por una pulsacion casual.
ActualizarLectura:
    ld a, [wLeido]
    or a
    ret nz

    ld a, [wTeclas]
    and KEY_B
    jr nz, .observando

    xor a
    ld [wMascaraLectura], a
    ret

.observando:
    ld a, [wFase]
    ld e, a
    ld d, 0
    ld hl, BitsFase
    add hl, de
    ld a, [hl]
    ld b, a
    ld a, [wMascaraLectura]
    or b
    ld [wMascaraLectura], a
    cp LECTURA_COMPLETA
    ret nz

    ld a, 1
    ld [wLeido], a
    call SonidoLectura
    ret

IntentarGolpe:
    ld a, [wTeclasNuevas]
    and KEY_A
    ret z

    ; Sin lectura completa, cualquier ataque rebota.
    ld a, [wLeido]
    or a
    jr z, FallarGolpe

    ; La mira debe estar en la zona baja.
    ld a, [wMira]
    cp 2
    jr nz, FallarGolpe

    ; Fase 3 = guardia abierta. Es la unica ventana vulnerable.
    ld a, [wFase]
    cp 3
    jr nz, FallarGolpe

    call GolpeValido
    ret

FallarGolpe:
    xor a
    ld [wLeido], a
    ld [wMascaraLectura], a
    ld a, FALLO_FRAMES
    ld [wFalloTimer], a
    call SonidoFallo
    ret

GolpeValido:
    call SonidoImpacto
    ld a, [wImpactos]
    inc a
    ld [wImpactos], a
    cp IMPACTOS_META
    jr nc, MostrarVictoria

    ; Cada impacto obliga a volver a leer el patron y acelera el siguiente.
    xor a
    ld [wLeido], a
    ld [wMascaraLectura], a
    ld [wFase], a
    call DuracionFase
    ld [wFaseTimer], a
    ret

TickFallo:
    ld a, [wFalloTimer]
    or a
    ret z
    dec a
    ld [wFalloTimer], a
    ret

; Primer ciclo pausado, segundo mas tenso, tercero claramente rapido.
DuracionFase:
    ld a, [wImpactos]
    or a
    jr z, .lenta
    cp 1
    jr z, .media
    ld a, 28
    ret
.media:
    ld a, 36
    ret
.lenta:
    ld a, 45
    ret

MostrarVictoria:
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo
    call DibujarVictoria
    ld a, ESTADO_VICTORIA
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

; OAM fijo: mira, guardia, punto debil, ojo, tres impactos y fallo.
; Solo se ejecuta justo despues de VBlank.
RenderOAM:
    ld hl, OAM_BASE
    ld b, 32
    xor a
.limpiar:
    ld [hli], a
    dec b
    jr nz, .limpiar

    ld a, [wEstado]
    cp ESTADO_DUELO
    ret nz

    ; Slot 0: mira, con tres alturas discretas.
    ld a, [wMira]
    ld e, a
    ld d, 0
    ld hl, MiraY
    add hl, de
    ld a, [hl]
    ld [OAM_BASE], a
    ld a, 112
    ld [OAM_BASE + 1], a
    ld a, TILE_MIRA
    ld [OAM_BASE + 2], a
    xor a
    ld [OAM_BASE + 3], a

    ; Slot 1: escudo que recorre cabeza, torso y pierna. En fase 3 desaparece.
    ld a, [wFase]
    cp 3
    jr nc, .punto_debil
    ld e, a
    ld d, 0
    ld hl, GuardiaY
    add hl, de
    ld a, [hl]
    ld [OAM_BASE + 4], a
    ld a, 144
    ld [OAM_BASE + 5], a
    ld a, TILE_ESCUDO
    ld [OAM_BASE + 6], a
    ld a, 1
    ld [OAM_BASE + 7], a

.punto_debil:
    ; Slot 2: el talon solo se hace visible tras leer y durante la apertura.
    ld a, [wLeido]
    or a
    jr z, .ojo
    ld a, [wFase]
    cp 3
    jr nz, .ojo
    ld a, 120
    ld [OAM_BASE + 8], a
    ld a, 144
    ld [OAM_BASE + 9], a
    ld a, TILE_DEBIL
    ld [OAM_BASE + 10], a
    ld a, 2
    ld [OAM_BASE + 11], a

.ojo:
    ; Slot 3: confirma que el patron ya fue comprendido, sin texto obligatorio.
    ld a, [wLeido]
    or a
    jr z, .impactos
    ld a, 32
    ld [OAM_BASE + 12], a
    ld a, 24
    ld [OAM_BASE + 13], a
    ld a, TILE_OJO
    ld [OAM_BASE + 14], a
    ld a, 3
    ld [OAM_BASE + 15], a

.impactos:
    ; Slots 4..6: tres marcas de progreso estrictamente internas a la ROM.
    ld a, [wImpactos]
    or a
    jr z, .fallo
    ld a, 32
    ld [OAM_BASE + 16], a
    ld a, 16
    ld [OAM_BASE + 17], a
    ld a, TILE_PIP
    ld [OAM_BASE + 18], a
    ld a, 2
    ld [OAM_BASE + 19], a

    ld a, [wImpactos]
    cp 2
    jr c, .fallo
    ld a, 32
    ld [OAM_BASE + 20], a
    ld a, 28
    ld [OAM_BASE + 21], a
    ld a, TILE_PIP
    ld [OAM_BASE + 22], a
    ld a, 2
    ld [OAM_BASE + 23], a

    ld a, [wImpactos]
    cp 3
    jr c, .fallo
    ld a, 32
    ld [OAM_BASE + 24], a
    ld a, 40
    ld [OAM_BASE + 25], a
    ld a, TILE_PIP
    ld [OAM_BASE + 26], a
    ld a, 2
    ld [OAM_BASE + 27], a

.fallo:
    ; Slot 7: rebote visual corto; no hay flash de pantalla ni sacudida.
    ld a, [wFalloTimer]
    or a
    ret z
    ld a, 88
    ld [OAM_BASE + 28], a
    ld a, 136
    ld [OAM_BASE + 29], a
    ld a, TILE_FALLO
    ld [OAM_BASE + 30], a
    ld a, 1
    ld [OAM_BASE + 31], a
    ret

DibujarTitulo:
    ; MYRMIDON
    ld a, TILE_M
    ld [BG_MAP + (5 * 32) + 6], a
    ld a, TILE_Y
    ld [BG_MAP + (5 * 32) + 7], a
    ld a, TILE_R
    ld [BG_MAP + (5 * 32) + 8], a
    ld a, TILE_M
    ld [BG_MAP + (5 * 32) + 9], a
    ld a, TILE_I
    ld [BG_MAP + (5 * 32) + 10], a
    ld a, TILE_D
    ld [BG_MAP + (5 * 32) + 11], a
    ld a, TILE_O
    ld [BG_MAP + (5 * 32) + 12], a
    ld a, TILE_N
    ld [BG_MAP + (5 * 32) + 13], a

    ld a, TILE_9
    ld [BG_MAP + (7 * 32) + 9], a
    ld a, TILE_8
    ld [BG_MAP + (7 * 32) + 10], a

    ; Gramática visual: observar -> guardia -> punto vulnerable.
    ld a, TILE_OJO
    ld [BG_MAP + (11 * 32) + 5], a
    ld a, TILE_FLECHA
    ld [BG_MAP + (11 * 32) + 7], a
    ld a, TILE_ESCUDO
    ld [BG_MAP + (11 * 32) + 9], a
    ld a, TILE_FLECHA
    ld [BG_MAP + (11 * 32) + 11], a
    ld a, TILE_DEBIL
    ld [BG_MAP + (11 * 32) + 13], a

    ld a, TILE_A
    ld [BG_MAP + (14 * 32) + 9], a
    ret

DibujarArena:
    ; Rival monumental simplificado a tres tiles verticales.
    ld a, TILE_CABEZA
    ld [BG_MAP + (5 * 32) + 16], a
    ld a, TILE_TORSO
    ld [BG_MAP + (8 * 32) + 16], a
    ld a, TILE_PIERNAS
    ld [BG_MAP + (11 * 32) + 16], a

    ; El ojo en la esquina sugiere observacion sin un tutorial textual.
    ld a, TILE_OJO
    ld [BG_MAP + (4 * 32) + 2], a

    ; Suelo de arena.
    ld hl, BG_MAP + (15 * 32) + 2
    ld b, 17
    ld a, TILE_SUELO
.suelo:
    ld [hli], a
    dec b
    jr nz, .suelo
    ret

DibujarVictoria:
    call DibujarTitulo
    ld a, TILE_TROFEO
    ld [BG_MAP + (10 * 32) + 9], a
    ld a, TILE_PIP
    ld [BG_MAP + (12 * 32) + 8], a
    ld [BG_MAP + (12 * 32) + 9], a
    ld [BG_MAP + (12 * 32) + 10], a
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
    ; Fallback DMG legible.
    ; DMG: el índice 1 del fondo (tinta) pasa a negro para que se lea (#805).
    ld a, %11101100
    ldh [rBGP], a
    ld a, %11100100
    ldh [rOBP0], a
    ldh [rOBP1], a

    ; Fondo CGB 0: crema, azul grisaceo, azul oscuro, negro.
    ld a, $80
    ldh [rBCPS], a
    ld hl, PaletaFondo
    ld b, PaletaFondoFin - PaletaFondo
.bg:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bg

    ; OBJ 0 mira verde, 1 guardia roja, 2 punto amarillo, 3 lectura cian.
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
    ld a, $90
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoLectura:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $D2
    ldh [rNR12], a
    ld a, $D0
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoFallo:
    xor a
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $91
    ldh [rNR12], a
    ld a, $30
    ldh [rNR13], a
    ld a, $82
    ldh [rNR14], a
    ret

SonidoImpacto:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $F2
    ldh [rNR12], a
    ld a, $40
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

; Y de OAM: coordenada visible + 16.
MiraY:
    db 64, 88, 120
GuardiaY:
    db 64, 88, 112
BitsFase:
    db 1, 2, 4, 8

; BGR555 little-endian.
PaletaFondo:
    ; El color 1 es el de las figuras y el suelo (#805): en gris claro casi no
    ; se veían. Blanco, bronce oscuro, gris oscuro, negro.
    dw $7FFF, $150A, $294A, $0000
PaletaFondoFin:

PaletasObjetos:
    ; paleta 0: verde
    dw $7FFF, $03E0, $01A0, $0000
    ; paleta 1: rojo
    dw $7FFF, $001F, $000F, $0000
    ; paleta 2: amarillo
    dw $7FFF, $03FF, $021F, $0000
    ; paleta 3: cian
    dw $7FFF, $7FE0, $3DE0, $0000
PaletasObjetosFin:

; Cada fila usa el plano bajo para mantener las siluetas simples y legibles.
Tiles:
; 0 vacio
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; 1 cabeza/helmet
    db $3C,$00,$7E,$00,$5A,$00,$7E,$00,$3C,$00,$18,$00,$18,$00,$00,$00
; 2 torso
    db $18,$00,$7E,$00,$FF,$00,$DB,$00,$5A,$00,$5A,$00,$42,$00,$00,$00
; 3 piernas
    db $42,$00,$42,$00,$66,$00,$24,$00,$24,$00,$24,$00,$66,$00,$00,$00
; 4 escudo
    db $7E,$00,$FF,$00,$FF,$00,$FF,$00,$7E,$00,$3C,$00,$18,$00,$00,$00
; 5 mira
    db $18,$00,$18,$00,$18,$00,$FF,$00,$18,$00,$18,$00,$18,$00,$00,$00
; 6 punto debil
    db $00,$00,$24,$00,$18,$00,$7E,$00,$18,$00,$24,$00,$00,$00,$00,$00
; 7 ojo
    db $00,$00,$3C,$00,$7E,$00,$DB,$00,$7E,$00,$3C,$00,$00,$00,$00,$00
; 8 fallo/rebote
    db $01,$00,$02,$00,$04,$00,$18,$00,$20,$00,$40,$00,$80,$00,$00,$00
; 9 pip/corazon
    db $00,$00,$66,$00,$FF,$00,$FF,$00,$7E,$00,$3C,$00,$18,$00,$00,$00
; 10 trofeo
    db $7E,$00,$5A,$00,$7E,$00,$3C,$00,$18,$00,$18,$00,$3C,$00,$00,$00
; 11 flecha
    db $10,$00,$18,$00,$1C,$00,$FE,$00,$1C,$00,$18,$00,$10,$00,$00,$00
; 12 M
    db $81,$00,$C3,$00,$A5,$00,$99,$00,$81,$00,$81,$00,$81,$00,$00,$00
; 13 Y
    db $81,$00,$42,$00,$24,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
; 14 R
    db $FC,$00,$82,$00,$82,$00,$FC,$00,$A0,$00,$90,$00,$88,$00,$00,$00
; 15 I
    db $7E,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$7E,$00,$00,$00
; 16 D
    db $F8,$00,$84,$00,$82,$00,$82,$00,$82,$00,$84,$00,$F8,$00,$00,$00
; 17 O
    db $7C,$00,$82,$00,$82,$00,$82,$00,$82,$00,$82,$00,$7C,$00,$00,$00
; 18 N
    db $82,$00,$C2,$00,$A2,$00,$92,$00,$8A,$00,$86,$00,$82,$00,$00,$00
; 19 9
    db $7C,$00,$82,$00,$82,$00,$7E,$00,$02,$00,$04,$00,$78,$00,$00,$00
; 20 8
    db $7C,$00,$82,$00,$82,$00,$7C,$00,$82,$00,$82,$00,$7C,$00,$00,$00
; 21 A
    db $38,$00,$44,$00,$82,$00,$FE,$00,$82,$00,$82,$00,$82,$00,$00,$00
; 22 suelo
    db $00,$00,$00,$00,$00,$00,$FF,$00,$55,$00,$AA,$00,$00,$00,$00,$00
TilesFin:

SECTION "Estado", WRAM0
wEstado:         ds 1
wTeclas:         ds 1
wTeclasPrevias:  ds 1
wTeclasNuevas:   ds 1
wMira:           ds 1
wFase:           ds 1
wFaseTimer:      ds 1
wMascaraLectura: ds 1
wLeido:          ds 1
wImpactos:       ds 1
wFalloTimer:     ds 1
