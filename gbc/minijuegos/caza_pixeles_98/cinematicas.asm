; Cinematicas minimas de Pixel Exodus (#882).
; Se dibujan en BG: no consumen OAM y avanzan de forma no bloqueante junto al
; gameplay, sin introducir HALT ni alterar el temporizador de la partida.

DEF TILE_CIN_CHROMIA_VIVO EQU 54
DEF TILE_CIN_EXTRACTOR    EQU 55
DEF TILE_CIN_PIXEL        EQU 56
DEF TILE_CIN_FUGA         EQU 57
DEF TILE_CIN_APAGADO      EQU 58
DEF TILE_CIN_RETORNO      EQU 59
DEF TILE_CIN_FAUNA        EQU 60
DEF TILE_CIN_ALERTA       EQU 61
DEF TILE_CIN_RESIDUO      EQU 62
DEF TILE_CIN_BASE         EQU TILE_CIN_CHROMIA_VIVO

DEF CIN_TIPO_INTRO EQU 1
DEF CIN_TIPO_FASE2 EQU 2
DEF CIN_TIPO_FASE3 EQU 3
DEF CIN_TIPO_BOSS  EQU 4

DEF CIN_INTRO_FRAMES EQU 72
DEF CIN_BEAT_FRAMES  EQU 42
DEF CIN_BOSS_FRAMES  EQU 48

SECTION "CinematicasPixelExodus", ROM0

InicializarCinematicas:
    xor a
    ld [wCinematicaFrames], a
    ld [wCinematicaTipo], a
    call CargarTilesCinematicas
    ret

IniciarCinematicaIntro:
    ld a, CIN_TIPO_INTRO
    ld [wCinematicaTipo], a
    ld a, CIN_INTRO_FRAMES
    ld [wCinematicaFrames], a
    call DibujarCinematicaGameplay
    ret

IniciarCinematicaFase2:
    ld a, CIN_TIPO_FASE2
    ld [wCinematicaTipo], a
    ld a, CIN_BEAT_FRAMES
    ld [wCinematicaFrames], a
    call DibujarCinematicaGameplay
    ret

IniciarCinematicaFase3:
    ld a, CIN_TIPO_FASE3
    ld [wCinematicaTipo], a
    ld a, CIN_BEAT_FRAMES
    ld [wCinematicaFrames], a
    call DibujarCinematicaGameplay
    ret

IniciarCinematicaBoss:
    ld a, CIN_TIPO_BOSS
    ld [wCinematicaTipo], a
    ld a, CIN_BOSS_FRAMES
    ld [wCinematicaFrames], a
    call DibujarCinematicaGameplay
    ret

TickCinematica:
    ld a, [wCinematicaFrames]
    or a
    ret z
    dec a
    ld [wCinematicaFrames], a
    ret nz
    call LimpiarCinematicaGameplay
    ret

; Cinco viñetas sin texto largo: la lectura nace de la secuencia de iconos y del
; escenario que ya cambia por fase.
DibujarCinematicaGameplay:
    call LimpiarCinematicaGameplay
    ld hl, BG_MAP + (3 * 32) + 7
    ld a, [wCinematicaTipo]
    cp CIN_TIPO_INTRO
    jp z, .intro
    cp CIN_TIPO_FASE2
    jp z, .fase2
    cp CIN_TIPO_FASE3
    jp z, .fase3

.boss:
    ld c, TILE_CIN_RESIDUO
    call EscribirTileCine
    ld c, TILE_BEHEMOTH_A
    call EscribirTileCine
    ld c, TILE_NUCLEO
    call EscribirTileCine
    ld c, TILE_CIN_ALERTA
    call EscribirTileCine
    ld c, TILE_CIN_RESIDUO
    call EscribirTileCine
    ret

.intro:
    ld c, TILE_CIN_CHROMIA_VIVO
    call EscribirTileCine
    ld c, TILE_CIN_EXTRACTOR
    call EscribirTileCine
    ld c, TILE_CIN_PIXEL
    call EscribirTileCine
    ld c, TILE_CIN_PIXEL
    call EscribirTileCine
    ld c, TILE_CIN_FUGA
    call EscribirTileCine
    ret

.fase2:
    ld c, TILE_CIN_EXTRACTOR
    call EscribirTileCine
    ld c, TILE_FOCO
    call EscribirTileCine
    ld c, TILE_CIN_PIXEL
    call EscribirTileCine
    ld c, TILE_CIN_FUGA
    call EscribirTileCine
    ld c, TILE_CIN_RESIDUO
    call EscribirTileCine
    ret

.fase3:
    ld c, TILE_CIN_APAGADO
    call EscribirTileCine
    ld c, TILE_SEMILLA
    call EscribirTileCine
    ld c, TILE_CIN_RETORNO
    call EscribirTileCine
    ld c, TILE_CIN_CHROMIA_VIVO
    call EscribirTileCine
    ld c, TILE_CIN_FAUNA
    call EscribirTileCine
    ret

EscribirTileCine:
    call EsperarVRAM
    ld a, c
    ld [hli], a
    ret

LimpiarCinematicaGameplay:
    call EscenarioTileBaseFase
    ld c, a
    ld hl, BG_MAP + (3 * 32) + 7
    ld b, 5
.loop:
    call EscribirTileCine
    dec b
    jr nz, .loop
    ret

; Epilogo estatico en la pantalla de records. La victoria muestra el croma
; regresando con fauna; la derrota conserva el exodo y el residuo activo.
DibujarCinematicaFinal:
    call CargarTilesCinematicas
    ld hl, BG_MAP + (2 * 32) + 6
    ld a, [wBossDerrotado]
    or a
    jr z, .derrota
    ld c, TILE_CIN_RETORNO
    call EscribirTileCine
    ld c, TILE_CIN_CHROMIA_VIVO
    call EscribirTileCine
    ld c, TILE_CIN_FAUNA
    call EscribirTileCine
    ret
.derrota:
    ld c, TILE_CIN_FUGA
    call EscribirTileCine
    ld c, TILE_PLANETA_SECO
    call EscribirTileCine
    ld c, TILE_CIN_RESIDUO
    call EscribirTileCine
    ret

CargarTilesCinematicas:
    ld hl, TilesCinematicas
    ld de, VRAM_TILES + (TILE_CIN_BASE * 16)
    ld bc, TilesCinematicasFin - TilesCinematicas
.loop:
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

SECTION "CinematicasPixelExodusDatos", ROM0
TilesCinematicas:
    ; 54 Chromia vivo; 55 extractor; 56 croma; 57 fuga.
    db $3C,$3C,$7E,$42,$DB,$81,$FF,$81,$FF,$81,$7E,$42,$3C,$3C,$00,$00
    db $7E,$7E,$5A,$66,$7E,$42,$3C,$3C,$18,$18,$3C,$24,$66,$42,$00,$00
    db $00,$00,$18,$18,$3C,$3C,$7E,$66,$3C,$3C,$18,$18,$00,$00,$00,$00
    db $10,$10,$18,$18,$1C,$1C,$FE,$82,$1C,$1C,$18,$18,$10,$10,$00,$00
    ; 58 extractor apagado; 59 retorno; 60 fauna; 61 alerta; 62 residuo.
    db $7E,$7E,$42,$7E,$42,$42,$3C,$24,$18,$18,$18,$18,$00,$00,$18,$18
    db $08,$08,$18,$18,$38,$28,$7F,$41,$38,$28,$18,$18,$08,$08,$00,$00
    db $00,$00,$24,$24,$5A,$7E,$18,$3C,$24,$3C,$42,$42,$00,$00,$00,$00
    db $18,$18,$3C,$3C,$18,$18,$18,$18,$18,$18,$00,$00,$18,$18,$00,$00
    db $24,$24,$5A,$7E,$3C,$66,$7E,$5A,$18,$3C,$66,$7E,$3C,$5A,$24,$24
TilesCinematicasFin:

SECTION "CinematicasPixelExodusVars", WRAM0
wCinematicaFrames: ds 1
wCinematicaTipo:   ds 1
