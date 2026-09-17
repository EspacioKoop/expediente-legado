; Escenario visual de Pixel Exodus (#882).
; Mantiene fauna/parallax en BG para no consumir entradas OAM del Behemoth.

DEF TILE_ESC_ESTRELLA_LEJOS EQU 38
DEF TILE_ESC_ESTRELLA_CERCA EQU 39
DEF TILE_ESC_ATMOSFERA      EQU 40
DEF TILE_ESC_INDUSTRIA      EQU 41
DEF TILE_ESC_NEBULOSA       EQU 42
DEF TILE_ESC_AVE_A          EQU 43
DEF TILE_ESC_AVE_B          EQU 44
DEF TILE_ESC_PEZ_A          EQU 45
DEF TILE_ESC_PEZ_B          EQU 46
DEF TILE_ESC_BROTE          EQU 47
DEF TILE_ESC_TRANS_F1       EQU 48
DEF TILE_ESC_TRANS_F2       EQU 49
DEF TILE_ESC_TRANS_F3       EQU 50
DEF TILE_ESC_TRANS_BOSS     EQU 51
DEF TILE_ESC_FINAL_OK       EQU 52
DEF TILE_ESC_FINAL_RESIDUO  EQU 53
DEF TILE_ESCENARIO_BASE     EQU TILE_ESC_ESTRELLA_LEJOS

DEF PARALLAX_RAPIDO_FRAMES EQU 4
DEF PARALLAX_LENTO_FRAMES  EQU 8
DEF FAUNA_ANIM_FRAMES      EQU 16
DEF TRANSICION_FRAMES      EQU 36

SECTION "EscenarioVisual", ROM0

InicializarEscenarioVisual:
    xor a
    ld [wParallaxTickRapido], a
    ld [wParallaxTickLento], a
    ld [wFaunaTick], a
    ld [wFaunaFrame], a
    ld [wTransicionFrames], a
    ld [wTransicionTipo], a
    ld a, 2
    ld [wParallaxXRapido], a
    ld a, 15
    ld [wParallaxXLento], a
    call CargarTilesEscenario
    call DibujarFondoFaseVisual
    ld a, 1
    call IniciarTransicionVisual
    ret

; Se llama una vez por frame desde EstadoJuego. Las dos bandas usan cadencias
; distintas: no desplazan HUD/Chromia porque animan tiles BG, no rSCX global.
TickEscenarioVisual:
    call TickTransicionVisual
    call TickParallaxVisual
    call TickFaunaVisual
    ret

TickParallaxVisual:
    ld a, [wParallaxTickRapido]
    inc a
    cp PARALLAX_RAPIDO_FRAMES
    jr c, .guardar_rapido
    xor a
    ld [wParallaxTickRapido], a
    call MoverParallaxRapido
    jr .lento
.guardar_rapido:
    ld [wParallaxTickRapido], a
.lento:
    ld a, [wParallaxTickLento]
    inc a
    cp PARALLAX_LENTO_FRAMES
    jr c, .guardar_lento
    xor a
    ld [wParallaxTickLento], a
    call MoverParallaxLento
    ret
.guardar_lento:
    ld [wParallaxTickLento], a
    ret

MoverParallaxRapido:
    ld hl, BG_MAP + (4 * 32)
    ld a, [wParallaxXRapido]
    call EscenarioSumarXHL
    call EscenarioTileBaseFase
    ld c, a
    call EscenarioEscribirTileC

    ld a, [wParallaxXRapido]
    inc a
    cp 20
    jr c, .x_lista
    xor a
.x_lista:
    ld [wParallaxXRapido], a
    ld hl, BG_MAP + (4 * 32)
    call EscenarioSumarXHL
    ld c, TILE_ESC_ESTRELLA_CERCA
    call EscenarioEscribirTileC
    ret

MoverParallaxLento:
    ld hl, BG_MAP + (8 * 32)
    ld a, [wParallaxXLento]
    call EscenarioSumarXHL
    call EscenarioTileBaseFase
    ld c, a
    call EscenarioEscribirTileC

    ld a, [wParallaxXLento]
    inc a
    cp 20
    jr c, .x_lista
    xor a
.x_lista:
    ld [wParallaxXLento], a
    ld hl, BG_MAP + (8 * 32)
    call EscenarioSumarXHL
    ld c, TILE_ESC_ESTRELLA_LEJOS
    call EscenarioEscribirTileC
    ret

EscenarioSumarXHL:
    ld e, a
    ld d, 0
    add hl, de
    ret

; Redibujo completo al cambiar de fase. Se ejecuta con LCD apagado para evitar
; tearing al sustituir las nueve filas de gameplay y sus atributos CGB.
TransicionEscenarioFase:
    call DesactivarLCD
    call DibujarFondoFaseVisual
    ld a, [wFase]
    call IniciarTransicionVisual
    call ActivarLCD
    ret

TransicionBehemothVisual:
    ld a, 4
    call IniciarTransicionVisual
    ret

DibujarEscenarioFinal:
    call CargarTilesEscenario
    call DibujarFondoFaseVisual
    call DibujarFaunaVisual
    ld hl, BG_MAP + (2 * 32) + 9
    ld a, [wBossDerrotado]
    or a
    jr z, .residuo
    ld c, TILE_ESC_FINAL_OK
    call EscenarioEscribirTileC
    ret
.residuo:
    ld c, TILE_ESC_FINAL_RESIDUO
    call EscenarioEscribirTileC
    ret

DibujarFondoFaseVisual:
    call EscenarioTileBaseFase
    ld [wEscenarioTileBase], a
    call CargarPaletaEscenarioVisual

    ; Filas 2..10: fondo completo, preserva las dos filas del HUD y Chromia.
    ld hl, BG_MAP + (2 * 32)
    ld b, 9
.fila:
    ld c, 20
.columna:
    call EsperarVRAM
    ld a, [wEscenarioTileBase]
    ld [hli], a
    dec c
    jr nz, .columna
    ld de, 12
    add hl, de
    dec b
    jr nz, .fila

    call AplicarAtributosEscenarioVisual
    call DibujarDecoracionFaseVisual
    call DibujarParallaxInicialVisual
    call DibujarFaunaVisual
    ret

EscenarioTileBaseFase:
    ld a, [wFase]
    cp 1
    jr z, .fase1
    cp 2
    jr z, .fase2
    ld a, TILE_ESC_NEBULOSA
    ret
.fase1:
    ld a, TILE_ESC_ATMOSFERA
    ret
.fase2:
    ld a, TILE_ESC_INDUSTRIA
    ret

DibujarDecoracionFaseVisual:
    ld a, [wFase]
    cp 1
    jr z, .fase1
    cp 2
    jr z, .fase2

    ; Restauracion: nebulosa y croma disperso.
    ld hl, BG_MAP + (3 * 32) + 3
    ld c, TILE_ESC_ESTRELLA_LEJOS
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (6 * 32) + 12
    ld c, TILE_ESC_ESTRELLA_CERCA
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (9 * 32) + 18
    ld c, TILE_ESC_ESTRELLA_LEJOS
    call EscenarioEscribirTileC
    ret
.fase1:
    ; Atmosfera viva: estrellas espaciadas y horizonte limpio.
    ld hl, BG_MAP + (3 * 32) + 5
    ld c, TILE_ESC_ESTRELLA_LEJOS
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (6 * 32) + 14
    ld c, TILE_ESC_ESTRELLA_CERCA
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (9 * 32) + 2
    ld c, TILE_ESC_ESTRELLA_LEJOS
    call EscenarioEscribirTileC
    ret
.fase2:
    ; Zona muerta: tres focos de maquinaria recortan la banda industrial.
    ld hl, BG_MAP + (3 * 32) + 4
    ld c, TILE_FOCO
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (6 * 32) + 10
    ld c, TILE_RESIDUO
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (9 * 32) + 16
    ld c, TILE_FOCO
    call EscenarioEscribirTileC
    ret

DibujarParallaxInicialVisual:
    ld hl, BG_MAP + (4 * 32)
    ld a, [wParallaxXRapido]
    call EscenarioSumarXHL
    ld c, TILE_ESC_ESTRELLA_CERCA
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (8 * 32)
    ld a, [wParallaxXLento]
    call EscenarioSumarXHL
    ld c, TILE_ESC_ESTRELLA_LEJOS
    call EscenarioEscribirTileC
    ret

AplicarAtributosEscenarioVisual:
    call EsCGB
    ret nz
    ld a, 1
    ldh [rVBK], a
    ld hl, BG_MAP + (2 * 32)
    ld b, 9
.fila:
    ld c, 20
.columna:
    call EsperarVRAM
    ld a, 2 ; paleta BG 2 para el campo de juego.
    ld [hli], a
    dec c
    jr nz, .columna
    ld de, 12
    add hl, de
    dec b
    jr nz, .fila
    xor a
    ldh [rVBK], a
    ret

CargarPaletaEscenarioVisual:
    call EsCGB
    ret nz
    ld a, [wFase]
    cp 1
    jr z, .fase1
    cp 2
    jr z, .fase2
    ld hl, PaletaEscenarioF3
    jr .cargar
.fase1:
    ld hl, PaletaEscenarioF1
    jr .cargar
.fase2:
    ld hl, PaletaEscenarioF2
.cargar:
    ld a, $90 ; BG palette 2, auto incremento.
    ldh [rBCPS], a
    ld b, 8
.loop:
    call EsperarVRAM
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .loop
    ret

; ------------------------------ Fauna BG ------------------------------
; Nunca escribe OAM. La ausencia/presencia de fauna comunica degradacion y
; recuperacion sin robar sprites al boss ni al objetivo normal.
ActualizarFaunaVisual:
    call DibujarFaunaVisual
    ret

TickFaunaVisual:
    ld a, [wFaunaTick]
    inc a
    cp FAUNA_ANIM_FRAMES
    jr c, .guardar
    xor a
    ld [wFaunaTick], a
    ld a, [wFaunaFrame]
    xor 1
    ld [wFaunaFrame], a
    call DibujarFaunaVisual
    ret
.guardar:
    ld [wFaunaTick], a
    ret

DibujarFaunaVisual:
    call LimpiarFaunaVisual

    ld a, [wFase]
    cp 2
    jr nz, .por_restauracion
    ld a, [wEtapaChromia]
    cp 2
    ret c ; la zona muerta queda vacia hasta recuperar bosque.

.por_restauracion:
    ld a, [wEtapaChromia]
    or a
    jr z, .fase1_testigo

    ; Desde agua vuelve primero la fauna acuatica.
    ld hl, BG_MAP + (9 * 32) + 6
    ld a, [wFaunaFrame]
    or a
    jr z, .pez_a
    ld c, TILE_ESC_PEZ_B
    jr .pez_listo
.pez_a:
    ld c, TILE_ESC_PEZ_A
.pez_listo:
    call EscenarioEscribirTileC

    ld a, [wEtapaChromia]
    cp 2
    ret c

    ; Con bosque reaparecen aves.
    ld hl, BG_MAP + (6 * 32) + 16
    ld a, [wFaunaFrame]
    or a
    jr z, .ave_a
    ld c, TILE_ESC_AVE_B
    jr .ave_lista
.ave_a:
    ld c, TILE_ESC_AVE_A
.ave_lista:
    call EscenarioEscribirTileC

    ld a, [wEtapaChromia]
    cp 3
    ret c
    ld hl, BG_MAP + (10 * 32) + 3
    ld c, TILE_ESC_BROTE
    call EscenarioEscribirTileC
    ret

.fase1_testigo:
    ; Antes del colapso total se ve un ave solitaria; desaparece en fase 2.
    ld a, [wFase]
    cp 1
    ret nz
    ld hl, BG_MAP + (6 * 32) + 16
    ld a, [wFaunaFrame]
    or a
    jr z, .testigo_a
    ld c, TILE_ESC_AVE_B
    jr .testigo_lista
.testigo_a:
    ld c, TILE_ESC_AVE_A
.testigo_lista:
    call EscenarioEscribirTileC
    ret

LimpiarFaunaVisual:
    call EscenarioTileBaseFase
    ld c, a
    ld hl, BG_MAP + (9 * 32) + 6
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (6 * 32) + 16
    call EscenarioEscribirTileC
    ld hl, BG_MAP + (10 * 32) + 3
    call EscenarioEscribirTileC
    ret

; --------------------------- Transiciones BG --------------------------
IniciarTransicionVisual:
    ld [wTransicionTipo], a
    ld a, TRANSICION_FRAMES
    ld [wTransicionFrames], a
    call DibujarBannerTransicionVisual
    ret

TickTransicionVisual:
    ld a, [wTransicionFrames]
    or a
    ret z
    dec a
    ld [wTransicionFrames], a
    ret nz
    call LimpiarBannerTransicionVisual
    ret

DibujarBannerTransicionVisual:
    ld a, [wTransicionTipo]
    cp 1
    jr z, .fase1
    cp 2
    jr z, .fase2
    cp 3
    jr z, .fase3
    ld c, TILE_ESC_TRANS_BOSS
    jr .dibujar
.fase1:
    ld c, TILE_ESC_TRANS_F1
    jr .dibujar
.fase2:
    ld c, TILE_ESC_TRANS_F2
    jr .dibujar
.fase3:
    ld c, TILE_ESC_TRANS_F3
.dibujar:
    ld hl, BG_MAP + (2 * 32) + 8
    call EscenarioEscribirTileC
    inc hl
    call EscenarioEscribirTileC
    inc hl
    call EscenarioEscribirTileC
    ret

LimpiarBannerTransicionVisual:
    call EscenarioTileBaseFase
    ld c, a
    ld hl, BG_MAP + (2 * 32) + 8
    call EscenarioEscribirTileC
    inc hl
    call EscenarioEscribirTileC
    inc hl
    call EscenarioEscribirTileC
    ret

EscenarioEscribirTileC:
    call EsperarVRAM
    ld a, c
    ld [hl], a
    ret

CargarTilesEscenario:
    ld hl, TilesEscenario
    ld de, VRAM_TILES + (TILE_ESCENARIO_BASE * 16)
    ld bc, TilesEscenarioFin - TilesEscenario
.loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

SECTION "EscenarioDatos", ROM0
TilesEscenario:
    ; 38 estrella lejana, 39 estrella cercana.
    db $00,$00,$00,$00,$00,$00,$08,$08,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$08,$08,$1C,$1C,$08,$08,$00,$00,$00,$00,$00,$00,$00,$00
    ; 40 atmosfera, 41 industria, 42 nebulosa.
    db $00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00
    db $88,$88,$22,$22,$88,$88,$22,$22,$88,$88,$22,$22,$88,$88,$22,$22
    db $00,$00,$24,$24,$18,$18,$42,$42,$18,$18,$24,$24,$00,$00,$81,$81
    ; 43-44 ave; 45-46 pez; 47 brote/fauna recuperada.
    db $00,$00,$00,$00,$24,$24,$5A,$7E,$18,$3C,$00,$18,$00,$00,$00,$00
    db $00,$00,$00,$00,$18,$18,$3C,$7E,$24,$3C,$00,$18,$00,$00,$00,$00
    db $00,$00,$18,$18,$3C,$24,$7E,$42,$3C,$24,$18,$18,$00,$00,$00,$00
    db $00,$00,$18,$18,$3C,$24,$7E,$42,$18,$18,$3C,$24,$00,$00,$00,$00
    db $00,$00,$18,$18,$3C,$24,$18,$18,$7E,$42,$24,$24,$24,$24,$00,$00
    ; 48-51 iconos de transicion: exodo, zona muerta, restauracion, boss.
    db $18,$18,$3C,$3C,$7E,$66,$FF,$81,$7E,$66,$3C,$3C,$18,$18,$00,$00
    db $7E,$7E,$42,$7E,$5A,$66,$7E,$42,$5A,$66,$42,$7E,$7E,$7E,$00,$00
    db $00,$00,$18,$18,$3C,$24,$7E,$42,$FF,$81,$7E,$42,$24,$24,$18,$18
    db $FF,$A5,$DB,$FF,$7E,$DB,$FF,$66,$BD,$FF,$7E,$DB,$FF,$A5,$DB,$FF
    ; 52 final restaurado; 53 final con residuo.
    db $18,$18,$3C,$24,$7E,$42,$DB,$81,$FF,$81,$7E,$42,$3C,$24,$18,$18
    db $24,$24,$5A,$7E,$3C,$66,$7E,$5A,$18,$3C,$66,$7E,$3C,$5A,$24,$24
TilesEscenarioFin:

PaletaEscenarioF1:
    dw $63BE, $4631, $2D6B, $0000
PaletaEscenarioF2:
    dw $6739, $3D8C, $2529, $0000
PaletaEscenarioF3:
    dw $7FDE, $56D6, $2FED, $0000

SECTION "EscenarioVars", WRAM0
wEscenarioTileBase:    ds 1
wParallaxTickRapido:   ds 1
wParallaxTickLento:    ds 1
wParallaxXRapido:      ds 1
wParallaxXLento:       ds 1
wFaunaTick:            ds 1
wFaunaFrame:           ds 1
wTransicionFrames:     ds 1
wTransicionTipo:       ds 1
