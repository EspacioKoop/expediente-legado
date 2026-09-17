; Cinematicas minimas de Pixel Exodus (#882).
; Se dibujan en BG: no consumen OAM. Las transiciones avanzan junto al gameplay;
; la intro funciona tambien como instrucciones y congela brevemente movimiento,
; objetivo y cuenta atras antes de entregar el control.

DEF TILE_CIN_CHROMIA_VIVO EQU 54
DEF TILE_CIN_EXTRACTOR    EQU 55
DEF TILE_CIN_PIXEL        EQU 56
DEF TILE_CIN_FUGA         EQU 57
DEF TILE_CIN_APAGADO      EQU 58
DEF TILE_CIN_RETORNO      EQU 59
DEF TILE_CIN_FAUNA        EQU 60
DEF TILE_CIN_ALERTA       EQU 61
DEF TILE_CIN_RESIDUO      EQU 62
DEF TILE_CIN_CRUCETA      EQU 63
DEF TILE_CIN_FLECHA       EQU 64
DEF TILE_CIN_BASE         EQU TILE_CIN_CHROMIA_VIVO

DEF CIN_TIPO_INTRO EQU 1
DEF CIN_TIPO_FASE2 EQU 2
DEF CIN_TIPO_FASE3 EQU 3
DEF CIN_TIPO_BOSS  EQU 4

; 72 frames conserva el contrato del beat narrativo introducido en #906. El
; onboarding necesita algo mas de lectura y usa su propia duración total.
DEF CIN_INTRO_FRAMES         EQU 72
DEF CIN_INSTRUCCIONES_FRAMES EQU 150
DEF CIN_BEAT_FRAMES          EQU 42
DEF CIN_BOSS_FRAMES          EQU 48

; Barreras de residuo dibujadas como BG. Las coordenadas estan expresadas en el
; mismo espacio OAM que jugador/objetivos para reutilizar AABB sin sprites extra.
DEF OBSTACULO_ANCHO EQU 16
DEF OBSTACULO_ALTO  EQU 8
DEF OBSTACULO_1_X   EQU 40
DEF OBSTACULO_1_Y   EQU 56
DEF OBSTACULO_2_X   EQU 96
DEF OBSTACULO_2_Y   EQU 72
DEF OBSTACULO_3_X   EQU 64
DEF OBSTACULO_3_Y   EQU 96

SECTION "CinematicasPixelExodus", ROM0

InicializarCinematicas:
    xor a
    ld [wCinematicaFrames], a
    ld [wCinematicaTipo], a
    ld a, [wJugadorX]
    ld [wJugadorSeguroX], a
    ld a, [wJugadorY]
    ld [wJugadorSeguroY], a
    call CargarTilesCinematicas
    ret

IniciarCinematicaIntro:
    ld a, CIN_TIPO_INTRO
    ld [wCinematicaTipo], a
    ld a, CIN_INSTRUCCIONES_FRAMES
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
    ; La intro debe rechazar el movimiento antes de que el resolver actualice la
    ; ultima posicion segura del jugador.
    ld a, [wCinematicaFrames]
    or a
    jr z, .obstaculos
    ld a, [wCinematicaTipo]
    cp CIN_TIPO_INTRO
    jr nz, .obstaculos
    call BloquearGameplayInstrucciones

.obstaculos:
    ; Obstaculos y colision pertenecen al mismo pase BG: cero OAM adicional.
    call ResolverObstaculosGameplay
    call DibujarObstaculosGameplay

    ld a, [wCinematicaFrames]
    or a
    ret z
    dec a
    ld [wCinematicaFrames], a
    ret nz
    call LimpiarCinematicaGameplay
    ld a, [wCinematicaTipo]
    cp CIN_TIPO_INTRO
    ret nz
    call LimpiarInstruccionesIntro
    ret

; El onboarding sucede tras Start/A pero antes del primer segundo efectivo.
; MoverJugador ya se ejecuto en este frame, por eso se restaura la posicion
; segura. MoverObjetivo y TickTiempo ocurren despues: reiniciar sus contadores
; evita que el mundo avance mientras el jugador lee los iconos.
BloquearGameplayInstrucciones:
    ld a, [wJugadorSeguroX]
    ld [wJugadorX], a
    ld a, [wJugadorSeguroY]
    ld [wJugadorY], a
    xor a
    ld [wObjetivoTick], a
    ld [wFrames], a
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
    call DibujarInstruccionesIntro
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

; Instrucciones iconicas integradas en la intro:
;   cruceta -> nave -> croma
;   semilla -> restauracion; foco -> restauracion a costa del combo x1.
DibujarInstruccionesIntro:
    ld hl, BG_MAP + (5 * 32) + 5
    ld c, TILE_CIN_CRUCETA
    call EscribirTileCine
    ld c, TILE_CIN_FLECHA
    call EscribirTileCine
    ld c, TILE_JUGADOR
    call EscribirTileCine
    ld c, TILE_CIN_FLECHA
    call EscribirTileCine
    ld c, TILE_OBJETIVO
    call EscribirTileCine

    ld hl, BG_MAP + (7 * 32) + 5
    ld c, TILE_SEMILLA
    call EscribirTileCine
    ld c, TILE_CIN_FLECHA
    call EscribirTileCine
    ld c, TILE_R
    call EscribirTileCine
    ld c, TILE_FOCO
    call EscribirTileCine
    ld c, TILE_CIN_FLECHA
    call EscribirTileCine
    ld c, TILE_R
    call EscribirTileCine
    ld c, TILE_X
    call EscribirTileCine
    ld c, TILE_DIGITO0 + 1
    call EscribirTileCine
    ret

LimpiarInstruccionesIntro:
    call EscenarioTileBaseFase
    ld c, a
    ld hl, BG_MAP + (5 * 32) + 5
    ld b, 5
.fila_movimiento:
    call EscribirTileCine
    dec b
    jr nz, .fila_movimiento
    ld hl, BG_MAP + (7 * 32) + 5
    ld b, 8
.fila_reglas:
    call EscribirTileCine
    dec b
    jr nz, .fila_reglas
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

; ------------------------- Obstaculos jugables -------------------------
; Dos barreras aparecen en la zona muerta; restauracion suma una tercera. Al
; entrar el Behemoth se retiran para conservar legibilidad y la arena del boss.
DibujarObstaculosGameplay:
    ld a, [wBossActivo]
    or a
    jp nz, LimpiarObstaculosGameplay
    ld a, [wFase]
    cp 2
    ret c

    ld hl, BG_MAP + (5 * 32) + 4
    call DibujarBarreraResiduo
    ld hl, BG_MAP + (7 * 32) + 11
    call DibujarBarreraResiduo

    ld a, [wFase]
    cp 3
    ret c
    ld hl, BG_MAP + (10 * 32) + 7
    call DibujarBarreraResiduo
    ret

DibujarBarreraResiduo:
    ld c, TILE_CIN_RESIDUO
    call EscribirTileCine
    ld c, TILE_CIN_EXTRACTOR
    call EscribirTileCine
    ret

LimpiarObstaculosGameplay:
    call EscenarioTileBaseFase
    ld c, a
    ld hl, BG_MAP + (5 * 32) + 4
    call EscribirTileCine
    call EscribirTileCine
    ld hl, BG_MAP + (7 * 32) + 11
    call EscribirTileCine
    call EscribirTileCine
    ld hl, BG_MAP + (10 * 32) + 7
    call EscribirTileCine
    call EscribirTileCine
    ret

ResolverObstaculosGameplay:
    ld a, [wBossActivo]
    or a
    jr nz, .guardar_seguro
    ld a, [wFase]
    cp 2
    jr c, .guardar_seguro

    call JugadorChocaObstaculosActivos
    jr nc, .guardar_seguro

    ; Rechaza el movimiento del frame restaurando la ultima posicion valida.
    ld a, [wJugadorSeguroX]
    ld [wJugadorX], a
    ld a, [wJugadorSeguroY]
    ld [wJugadorY], a
    call JugadorChocaObstaculosActivos
    ret nc

    ; Si una transicion hizo nacer una barrera justo bajo el jugador, usa un
    ; punto de rescate conocido para evitar dejarlo atrapado.
    ld a, 80
    ld [wJugadorX], a
    ld [wJugadorSeguroX], a
    ld a, 88
    ld [wJugadorY], a
    ld [wJugadorSeguroY], a
    ret

.guardar_seguro:
    ld a, [wJugadorX]
    ld [wJugadorSeguroX], a
    ld a, [wJugadorY]
    ld [wJugadorSeguroY], a
    ret

JugadorChocaObstaculosActivos:
    ld b, OBSTACULO_1_X
    ld c, OBSTACULO_1_Y
    call ColisionObstaculoBC
    ret c
    ld b, OBSTACULO_2_X
    ld c, OBSTACULO_2_Y
    call ColisionObstaculoBC
    ret c
    ld a, [wFase]
    cp 3
    jr c, .sin_colision
    ld b, OBSTACULO_3_X
    ld c, OBSTACULO_3_Y
    call ColisionObstaculoBC
    ret c
.sin_colision:
    and a
    ret

; B/C = X/Y superior izquierda en coordenadas OAM. Jugador y barrera usan AABB.
ColisionObstaculoBC:
    ld a, [wJugadorX]
    add 8
    cp b
    jr c, .sin
    jr z, .sin
    ld a, b
    add OBSTACULO_ANCHO
    ld d, a
    ld a, [wJugadorX]
    cp d
    jr nc, .sin

    ld a, [wJugadorY]
    add 8
    cp c
    jr c, .sin
    jr z, .sin
    ld a, c
    add OBSTACULO_ALTO
    ld d, a
    ld a, [wJugadorY]
    cp d
    jr nc, .sin
    scf
    ret
.sin:
    and a
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
    ; 63 cruceta; 64 flecha de flujo/instruccion.
    db $18,$18,$18,$18,$7E,$66,$7E,$66,$7E,$66,$18,$18,$18,$18,$00,$00
    db $00,$00,$10,$10,$18,$18,$FC,$84,$18,$18,$10,$10,$00,$00,$00,$00
TilesCinematicasFin:

SECTION "CinematicasPixelExodusVars", WRAM0
wCinematicaFrames: ds 1
wCinematicaTipo:   ds 1
wJugadorSeguroX:   ds 1
wJugadorSeguroY:   ds 1
