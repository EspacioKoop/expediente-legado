; Croc Riders 98 - minijuego GBC para SIGA-98
; Revision visual: OAM se escribe solo al comienzo de VBlank y el presupuesto
; de sprites queda por debajo del limite de 10 sprites por scanline.
; Codigo y pixel-art originales del proyecto, licencia MIT.

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

DEF KEY_A       EQU $01
DEF KEY_START   EQU $08
DEF KEY_RIGHT   EQU $10
DEF KEY_LEFT    EQU $20
DEF KEY_START_A EQU $09

DEF ESTADO_TITULO  EQU 0
DEF ESTADO_CARRERA EQU 1
DEF ESTADO_META    EQU 2
DEF ESTADO_WRECK   EQU 3

; Tiles de fondo/HUD.
DEF TILE_ROAD       EQU 1
DEF TILE_EDGE       EQU 2
DEF TILE_LANE       EQU 3
DEF TILE_PYR_L      EQU 4
DEF TILE_PYR_M      EQU 5
DEF TILE_PYR_R      EQU 6
DEF TILE_SPHINX_H   EQU 7
DEF TILE_SPHINX_B   EQU 8
DEF TILE_WAVE       EQU 9
DEF TILE_TOWER      EQU 10
DEF TILE_FINISH     EQU 11
DEF DIGIT_BASE      EQU 12
DEF TILE_C          EQU 22
DEF TILE_R          EQU 23
DEF TILE_O          EQU 24
DEF TILE_I          EQU 25
DEF TILE_D          EQU 26
DEF TILE_E          EQU 27
DEF TILE_S          EQU 28
DEF TILE_ARROW      EQU 29
DEF TILE_SCALE      EQU 30
DEF TILE_NITRO      EQU 31

; Sprites 8x16. Los indices deben ser pares: cada sprite usa N y N+1.
DEF TILE_CROC_L     EQU 32
DEF TILE_CROC_R     EQU 34
DEF TILE_TAXI_L     EQU 36
DEF TILE_TAXI_R     EQU 38
DEF TILE_BARRIER_L  EQU 40
DEF TILE_BARRIER_R  EQU 42
DEF TILE_BUS_L      EQU 44
DEF TILE_BUS_R      EQU 46
DEF TILE_FLAME      EQU 48

DEF TILE_TROPHY     EQU 50
DEF TILE_CRASH      EQU 51

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "CROCRIDERS98"
    ds $0143 - @, 0
    db $80
    ds $0150 - @, 0

SECTION "Juego", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF
    call ApagarLCDSeguro
    call BorrarOAMParcial
    call CargarTiles
    call ConfigurarPaletas
    call ConfigurarAudio
    call PrepararTitulo

    xor a
    ld [wKeys], a
    ld [wPrevKeys], a
    ld [wNewKeys], a
    ld [wFrame], a
    ld [wInv], a
    ld [wTurbo], a

    ld a, 1
    ldh [rIE], a
    xor a
    ldh [rIF], a
    ; Titulo sin sprites: modo 8x8/8x16 es irrelevante.
    ld a, $93
    ldh [rLCDC], a
    ei

BuclePrincipal:
    ; HALT despierta al entrar en VBlank. Todo acceso dinamico a OAM/VRAM
    ; se hace inmediatamente aqui para evitar escribir durante mode 2/3.
    halt
    ld a, [wEstado]
    cp ESTADO_CARRERA
    call z, RenderVBlank

    call LeerJoypad

    ld a, [wFrame]
    inc a
    ld [wFrame], a

    ld a, [wInv]
    or a
    jr z, .turbo
    dec a
    ld [wInv], a
.turbo:
    ld a, [wTurbo]
    or a
    jr z, .estado
    dec a
    ld [wTurbo], a

.estado:
    ld a, [wEstado]
    cp ESTADO_TITULO
    jp z, EstadoTitulo
    cp ESTADO_CARRERA
    jp z, EstadoCarrera
    jp EstadoFinal

RenderVBlank:
    call ActualizarOAM

    ld a, [wHudDirty]
    or a
    jr z, .decor
    xor a
    ld [wHudDirty], a
    call DibujarHUD
.decor:
    ld a, [wDecorDirty]
    or a
    ret z
    xor a
    ld [wDecorDirty], a
    call DibujarDecorado
    ret

EstadoTitulo:
    ld a, [wNewKeys]
    and KEY_START_A
    jp z, BuclePrincipal
    call IniciarCarrera
    jp BuclePrincipal

EstadoCarrera:
    call ControlCarrera
    call AvanzarCarrera

    ld a, [wEstado]
    cp ESTADO_CARRERA
    jp nz, BuclePrincipal

    call ComprobarColisiones
    jp BuclePrincipal

EstadoFinal:
    ld a, [wNewKeys]
    and KEY_START_A
    jp z, BuclePrincipal
    call IniciarCarrera
    jp BuclePrincipal

PrepararTitulo:
    xor a
    ld [wEstado], a
    call LimpiarBG

    ; CROC
    ld a, TILE_C
    ld [BG_MAP + (3 * 32) + 7], a
    ld a, TILE_R
    ld [BG_MAP + (3 * 32) + 8], a
    ld a, TILE_O
    ld [BG_MAP + (3 * 32) + 9], a
    ld a, TILE_C
    ld [BG_MAP + (3 * 32) + 10], a

    ; RIDERS
    ld a, TILE_R
    ld [BG_MAP + (5 * 32) + 5], a
    ld a, TILE_I
    ld [BG_MAP + (5 * 32) + 6], a
    ld a, TILE_D
    ld [BG_MAP + (5 * 32) + 7], a
    ld a, TILE_E
    ld [BG_MAP + (5 * 32) + 8], a
    ld a, TILE_R
    ld [BG_MAP + (5 * 32) + 9], a
    ld a, TILE_S
    ld [BG_MAP + (5 * 32) + 10], a

    ld a, DIGIT_BASE + 9
    ld [BG_MAP + (7 * 32) + 8], a
    ld a, DIGIT_BASE + 8
    ld [BG_MAP + (7 * 32) + 9], a

    ; Piramides y flecha de inicio estaticas: sin parpadeo intencional.
    ld a, TILE_PYR_L
    ld [BG_MAP + (10 * 32) + 7], a
    ld a, TILE_PYR_M
    ld [BG_MAP + (10 * 32) + 8], a
    ld a, TILE_PYR_R
    ld [BG_MAP + (10 * 32) + 9], a
    ld a, TILE_ARROW
    ld [BG_MAP + (13 * 32) + 9], a
    ret

IniciarCarrera:
    call ApagarLCDSeguro
    call BorrarOAMParcial
    call LimpiarBG
    call DibujarCarretera

    ld a, ESTADO_CARRERA
    ld [wEstado], a
    xor a
    ld [wPlayerLane], a
    ld [wDistance], a
    ld [wDistanceTick], a
    ld [wScore], a
    ld [wStage], a
    ld [wInv], a
    ld [wTurbo], a
    ld [wHudDirty], a
    ld [wDecorDirty], a
    ld [wHazType], a

    ld a, 3
    ld [wLives], a
    ld [wNitro], a

    xor a
    ld [wR1Lane], a
    ld a, 48
    ld [wR1Y], a

    ld a, 2
    ld [wR2Lane], a
    ld a, 16
    ld [wR2Y], a

    ld a, 1
    ld [wHazLane], a
    ld a, 80
    ld [wHazY], a

    call DibujarHUD
    call DibujarDecorado
    call ActualizarOAM
    call SonidoSalida

    ; OBJ 8x16 activado para reducir a la mitad el numero de sprites.
    ld a, $97
    ldh [rLCDC], a
    ret

ControlCarrera:
    ld a, [wNewKeys]
    and KEY_LEFT
    jr z, .derecha
    ld a, [wPlayerLane]
    or a
    jr z, .derecha
    dec a
    ld [wPlayerLane], a

.derecha:
    ld a, [wNewKeys]
    and KEY_RIGHT
    jr z, .nitro
    ld a, [wPlayerLane]
    cp 2
    jr nc, .nitro
    inc a
    ld [wPlayerLane], a

.nitro:
    ld a, [wNewKeys]
    and KEY_A
    ret z
    ld a, [wTurbo]
    or a
    ret nz
    ld a, [wNitro]
    or a
    ret z
    dec a
    ld [wNitro], a
    ld a, 90
    ld [wTurbo], a
    ld a, 1
    ld [wHudDirty], a
    call SonidoTurbo
    ret

AvanzarCarrera:
    ; Normal 30 Hz; nitro 60 Hz.
    ld a, [wTurbo]
    or a
    jr nz, .mover
    ld a, [wFrame]
    and 1
    ret nz

.mover:
    call MoverRival1
    call MoverRival2
    call MoverObstaculo

    ld a, [wDistanceTick]
    inc a
    cp 8
    jr c, .guarda_tick
    xor a
    ld [wDistanceTick], a

    ld a, [wDistance]
    inc a
    ld [wDistance], a
    ld a, 1
    ld [wHudDirty], a
    call ActualizarEtapa

    ld a, [wDistance]
    cp 90
    ret c

    ld a, ESTADO_META
    ld [wEstado], a
    call SonidoMeta
    call PrepararFinal
    ret

.guarda_tick:
    ld [wDistanceTick], a
    ret

MoverRival1:
    ld a, [wR1Y]
    inc a
    cp 160
    jr c, .guardar
    ld a, 24
    ld [wR1Y], a
    ld a, [wR1Lane]
    inc a
    cp 3
    jr c, .lane_ok
    xor a
.lane_ok:
    ld [wR1Lane], a
    call SumarPunto
    ret
.guardar:
    ld [wR1Y], a
    ret

MoverRival2:
    ld a, [wR2Y]
    inc a
    cp 160
    jr c, .guardar
    ld a, 8
    ld [wR2Y], a
    ld a, [wR2Lane]
    inc a
    cp 3
    jr c, .lane_ok
    xor a
.lane_ok:
    ld [wR2Lane], a
    call SumarPunto
    ret
.guardar:
    ld [wR2Y], a
    ret

MoverObstaculo:
    ld a, [wHazY]
    inc a
    cp 160
    jr c, .guardar
    ld a, 32
    ld [wHazY], a

    ld a, [wHazLane]
    inc a
    cp 3
    jr c, .lane_ok
    xor a
.lane_ok:
    ld [wHazLane], a

    ; Rota TAXI -> BARRERA -> BUS para que trafico y obstaculos sean distintos.
    ld a, [wHazType]
    inc a
    cp 3
    jr c, .tipo_ok
    xor a
.tipo_ok:
    ld [wHazType], a
    ret
.guardar:
    ld [wHazY], a
    ret

SumarPunto:
    ld a, [wScore]
    cp 99
    ret nc
    inc a
    ld [wScore], a
    ld a, 1
    ld [wHudDirty], a
    call SonidoPaso
    ret

ActualizarEtapa:
    ld a, [wDistance]
    cp 68
    jr nc, .etapa3
    cp 46
    jr nc, .etapa2
    cp 24
    jr nc, .etapa1
    xor a
    jr .decidida
.etapa1:
    ld a, 1
    jr .decidida
.etapa2:
    ld a, 2
    jr .decidida
.etapa3:
    ld a, 3
.decidida:
    ld b, a
    ld a, [wStage]
    cp b
    ret z
    ld a, b
    ld [wStage], a
    ld a, 1
    ld [wDecorDirty], a
    call SonidoCheckpoint
    ret

ComprobarColisiones:
    ld a, [wInv]
    or a
    ret nz
    call CheckR1
    ld a, [wInv]
    or a
    ret nz
    call CheckR2
    ld a, [wInv]
    or a
    ret nz
    call CheckHaz
    ret

CheckR1:
    ld a, [wPlayerLane]
    ld b, a
    ld a, [wR1Lane]
    cp b
    ret nz
    ld a, [wR1Y]
    cp 112
    ret c
    cp 145
    ret nc
    ld a, 24
    ld [wR1Y], a
    call Golpe
    ret

CheckR2:
    ld a, [wPlayerLane]
    ld b, a
    ld a, [wR2Lane]
    cp b
    ret nz
    ld a, [wR2Y]
    cp 112
    ret c
    cp 145
    ret nc
    ld a, 8
    ld [wR2Y], a
    call Golpe
    ret

CheckHaz:
    ld a, [wPlayerLane]
    ld b, a
    ld a, [wHazLane]
    cp b
    ret nz
    ld a, [wHazY]
    cp 112
    ret c
    cp 145
    ret nc
    ld a, 32
    ld [wHazY], a
    call Golpe
    ret

Golpe:
    ; La invulnerabilidad ya no se representa ocultando al jugador.
    ; Asi no existe un parpadeo voluntario confundible con fallo grafico.
    ld a, 54
    ld [wInv], a
    ld a, [wLives]
    dec a
    ld [wLives], a
    ld a, 1
    ld [wHudDirty], a
    call SonidoChoque
    ld a, [wLives]
    or a
    ret nz

    ld a, ESTADO_WRECK
    ld [wEstado], a
    call PrepararFinal
    ret

PrepararFinal:
    call ApagarLCDSeguro
    call BorrarOAMParcial
    call LimpiarBG

    ld a, [wEstado]
    cp ESTADO_META
    jr z, .trofeo
    ld a, TILE_CRASH
    jr .icono
.trofeo:
    ld a, TILE_TROPHY
.icono:
    ld [BG_MAP + (6 * 32) + 9], a

    ld a, TILE_S
    ld [BG_MAP + (9 * 32) + 6], a
    ld a, [wScore]
    ld de, BG_MAP + (9 * 32) + 8
    call EscribirDosDigitos

    ld a, TILE_D
    ld [BG_MAP + (11 * 32) + 6], a
    ld a, [wDistance]
    ld de, BG_MAP + (11 * 32) + 8
    call EscribirDosDigitos

    ld a, TILE_ARROW
    ld [BG_MAP + (14 * 32) + 9], a
    ld a, $93
    ldh [rLCDC], a
    ret

DibujarHUD:
    ld a, TILE_D
    ld [BG_MAP], a
    ld a, [wDistance]
    ld de, BG_MAP + 1
    call EscribirDosDigitos

    ld a, TILE_S
    ld [BG_MAP + 5], a
    ld a, [wScore]
    ld de, BG_MAP + 6
    call EscribirDosDigitos

    ld a, TILE_SCALE
    ld [BG_MAP + 10], a
    ld a, [wLives]
    add DIGIT_BASE
    ld [BG_MAP + 11], a

    ld a, TILE_NITRO
    ld [BG_MAP + 14], a
    ld a, [wNitro]
    add DIGIT_BASE
    ld [BG_MAP + 15], a
    ret

EscribirDosDigitos:
    ld b, 0
.decenas:
    cp 10
    jr c, .unidad
    sub 10
    inc b
    jr .decenas
.unidad:
    ld c, a
    ld a, b
    add DIGIT_BASE
    ld [de], a
    inc de
    ld a, c
    add DIGIT_BASE
    ld [de], a
    ret

DibujarCarretera:
    ; 3 carriles con dos separadores de fondo. Ya no consumen sprites.
    ld hl, BG_MAP + (4 * 32) + 4
    ld de, 20
    ld c, 14
.fila:
    ld a, TILE_EDGE
    ld [hli], a

    ld b, 3
    ld a, TILE_ROAD
.road_a:
    ld [hli], a
    dec b
    jr nz, .road_a
    ld a, TILE_LANE
    ld [hli], a

    ld b, 2
    ld a, TILE_ROAD
.road_b:
    ld [hli], a
    dec b
    jr nz, .road_b
    ld a, TILE_LANE
    ld [hli], a

    ld b, 3
    ld a, TILE_ROAD
.road_c:
    ld [hli], a
    dec b
    jr nz, .road_c

    ld a, TILE_EDGE
    ld [hli], a
    add hl, de
    dec c
    jr nz, .fila
    ret

BorrarDecorado:
    ld hl, BG_MAP + 32
    ld de, 12
    ld c, 3
.fila:
    ld b, 20
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    add hl, de
    dec c
    jr nz, .fila
    ret

DibujarDecorado:
    call BorrarDecorado
    ld a, [wStage]
    or a
    jp z, DecoradoPiramides
    cp 1
    jp z, DecoradoEsfinge
    cp 2
    jp z, DecoradoNilo
    jp DecoradoCairo

DecoradoPiramides:
    ld a, TILE_PYR_L
    ld [BG_MAP + (2 * 32) + 2], a
    ld a, TILE_PYR_M
    ld [BG_MAP + (2 * 32) + 3], a
    ld a, TILE_PYR_R
    ld [BG_MAP + (2 * 32) + 4], a

    ld a, TILE_PYR_L
    ld [BG_MAP + (2 * 32) + 13], a
    ld a, TILE_PYR_M
    ld [BG_MAP + (2 * 32) + 14], a
    ld a, TILE_PYR_R
    ld [BG_MAP + (2 * 32) + 15], a
    ret

DecoradoEsfinge:
    call DecoradoPiramides
    ld a, TILE_SPHINX_H
    ld [BG_MAP + (2 * 32) + 8], a
    ld a, TILE_SPHINX_B
    ld [BG_MAP + (2 * 32) + 9], a
    ld [BG_MAP + (2 * 32) + 10], a
    ret

DecoradoNilo:
    ld hl, BG_MAP + (3 * 32)
    ld b, 20
    ld a, TILE_WAVE
.olas:
    ld [hli], a
    dec b
    jr nz, .olas
    ld a, TILE_TOWER
    ld [BG_MAP + (1 * 32) + 4], a
    ld [BG_MAP + (2 * 32) + 4], a
    ret

DecoradoCairo:
    ld a, TILE_TOWER
    ld [BG_MAP + (1 * 32) + 4], a
    ld [BG_MAP + (2 * 32) + 4], a
    ld [BG_MAP + (3 * 32) + 4], a
    ld a, TILE_FINISH
    ld [BG_MAP + (2 * 32) + 15], a
    ret

ActualizarOAM:
    ; Maximo: jugador 2 + llama 1 + dos rivales 4 + obstaculo 2 = 9.
    ; Se limpian solo 10 entradas OAM (40 bytes), por lo que cabe holgadamente
    ; dentro de VBlank incluso en hardware real.
    call BorrarOAMParcial
    ld hl, OAM_BASE
    call DibujarJugador
    call DibujarRival1
    call DibujarRival2
    call DibujarObstaculo
    ret

DibujarJugador:
    ld a, [wPlayerLane]
    call LaneToX
    ld b, a
    ld a, 128
    ld d, 0
    call PonerCroc16

    ld a, [wTurbo]
    or a
    ret z
    ld a, [wPlayerLane]
    call LaneToX
    add 4
    ld b, a
    ld a, 140
    ld c, TILE_FLAME
    ld d, 3
    call PonerSprite
    ret

DibujarRival1:
    ld a, [wR1Lane]
    call LaneToX
    ld b, a
    ld a, [wR1Y]
    ld d, 1
    call PonerCroc16
    ret

DibujarRival2:
    ld a, [wR2Lane]
    call LaneToX
    ld b, a
    ld a, [wR2Y]
    ld d, 1
    call PonerCroc16
    ret

DibujarObstaculo:
    ld a, [wHazLane]
    call LaneToX
    ld b, a
    ld a, [wHazY]

    ld e, a
    ld a, [wHazType]
    or a
    jr z, .taxi
    cp 1
    jr z, .barrera
    ld c, TILE_BUS_L
    ld d, 2
    jr .pinta
.taxi:
    ld c, TILE_TAXI_L
    ld d, 2
    jr .pinta
.barrera:
    ld c, TILE_BARRIER_L
    ld d, 3
.pinta:
    ld a, e
    call PonerVehiculo16
    ret

PonerCroc16:
    ; A=Y, B=X, D=paleta. Dos sprites 8x16: izquierda y derecha.
    push af
    ld c, TILE_CROC_L
    call PonerSprite
    pop af
    ld e, a
    ld a, b
    add 8
    ld b, a
    ld a, e
    ld c, TILE_CROC_R
    call PonerSprite
    ret

PonerVehiculo16:
    ; C contiene el tile izquierdo par; el derecho esta a +2.
    push af
    push bc
    call PonerSprite
    pop bc
    pop af
    ld e, a
    inc c
    inc c
    ld a, b
    add 8
    ld b, a
    ld a, e
    call PonerSprite
    ret

PonerSprite:
    ld [hli], a
    ld a, b
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, d
    ld [hli], a
    ret

LaneToX:
    or a
    jr z, .lane0
    cp 1
    jr z, .lane1
    ld a, 112
    ret
.lane1:
    ld a, 80
    ret
.lane0:
    ld a, 48
    ret

LeerJoypad:
    ld a, [wKeys]
    ld [wPrevKeys], a

    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    swap a
    ld b, a

    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    or b
    ld b, a

    ld a, $30
    ldh [rP1], a

    ld a, b
    ld [wKeys], a
    ld c, a
    ld a, [wPrevKeys]
    cpl
    and c
    ld [wNewKeys], a
    ret

ApagarLCDSeguro:
.espera:
    ldh a, [rLY]
    cp 144
    jr c, .espera
    xor a
    ldh [rLCDC], a
    ret

BorrarOAMParcial:
    ld hl, OAM_BASE
    ld b, 40
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

LimpiarBG:
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

ConfigurarPaletas:
    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a

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

SonidoSalida:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $C2
    ldh [rNR12], a
    ld a, $60
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoTurbo:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $F2
    ldh [rNR12], a
    ld a, $D0
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoPaso:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $A1
    ldh [rNR12], a
    ld a, $80
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoChoque:
    xor a
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $B2
    ldh [rNR12], a
    ld a, $20
    ldh [rNR13], a
    ld a, $84
    ldh [rNR14], a
    ret

SonidoCheckpoint:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $D1
    ldh [rNR12], a
    ld a, $A0
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoMeta:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $F3
    ldh [rNR12], a
    ld a, $F0
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SECTION "Datos", ROM0
Tiles:
    ; 0 vacio
    rept 8
        db $00,$00
    endr

    ; 1 asfalto (indice 1)
    rept 8
        db $FF,$00
    endr

    ; 2 borde
    db $FF,$FF,$81,$81,$FF,$FF,$81,$81,$FF,$FF,$81,$81,$FF,$FF,$81,$81

    ; 3 separador de carril: asfalto + raya clara discontinua
    db $E7,$18,$E7,$18,$E7,$18,$E7,$18,$FF,$00,$FF,$00,$E7,$18,$E7,$18

    ; 4-6 piramide izquierda/centro/derecha
    db $01,$01,$03,$03,$07,$07,$0F,$0F,$1F,$1F,$3F,$3F,$7F,$7F,$FF,$FF
    db $18,$18,$3C,$3C,$7E,$7E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $80,$80,$C0,$C0,$E0,$E0,$F0,$F0,$F8,$F8,$FC,$FC,$FE,$FE,$FF,$FF

    ; 7-8 esfinge
    db $3C,$3C,$7E,$7E,$DB,$DB,$FF,$FF,$7E,$7E,$3C,$3C,$18,$18,$18,$18
    db $FF,$FF,$FF,$FF,$7E,$7E,$7E,$7E,$FF,$FF,$FF,$FF,$DB,$DB,$81,$81

    ; 9 Nilo
    db $00,$00,$66,$66,$99,$99,$00,$00,$66,$66,$99,$99,$00,$00,$66,$66

    ; 10 Cairo Tower estilizada
    db $18,$18,$3C,$3C,$18,$18,$18,$18,$3C,$3C,$3C,$3C,$7E,$7E,$FF,$FF

    ; 11 bandera meta
    db $80,$80,$F8,$F8,$A8,$A8,$F8,$F8,$80,$80,$80,$80,$80,$80,$80,$80

    ; 12-21 digitos 0-9
    db $1C,$1C,$22,$22,$26,$26,$2A,$2A,$32,$32,$22,$22,$1C,$1C,$00,$00
    db $08,$08,$18,$18,$08,$08,$08,$08,$08,$08,$08,$08,$1C,$1C,$00,$00
    db $1C,$1C,$22,$22,$02,$02,$04,$04,$08,$08,$10,$10,$3E,$3E,$00,$00
    db $3C,$3C,$02,$02,$02,$02,$1C,$1C,$02,$02,$02,$02,$3C,$3C,$00,$00
    db $04,$04,$0C,$0C,$14,$14,$24,$24,$3E,$3E,$04,$04,$04,$04,$00,$00
    db $3E,$3E,$20,$20,$20,$20,$3C,$3C,$02,$02,$02,$02,$3C,$3C,$00,$00
    db $1C,$1C,$20,$20,$20,$20,$3C,$3C,$22,$22,$22,$22,$1C,$1C,$00,$00
    db $3E,$3E,$02,$02,$04,$04,$08,$08,$10,$10,$10,$10,$10,$10,$00,$00
    db $1C,$1C,$22,$22,$22,$22,$1C,$1C,$22,$22,$22,$22,$1C,$1C,$00,$00
    db $1C,$1C,$22,$22,$22,$22,$1E,$1E,$02,$02,$02,$02,$1C,$1C,$00,$00

    ; 22 C
    db $1C,$1C,$22,$22,$20,$20,$20,$20,$20,$20,$22,$22,$1C,$1C,$00,$00
    ; 23 R
    db $3C,$3C,$22,$22,$22,$22,$3C,$3C,$28,$28,$24,$24,$22,$22,$00,$00
    ; 24 O
    db $1C,$1C,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$1C,$1C,$00,$00
    ; 25 I
    db $3E,$3E,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$3E,$3E,$00,$00
    ; 26 D
    db $3C,$3C,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$3C,$3C,$00,$00
    ; 27 E
    db $3E,$3E,$20,$20,$20,$20,$3C,$3C,$20,$20,$20,$20,$3E,$3E,$00,$00
    ; 28 S
    db $1E,$1E,$20,$20,$20,$20,$1C,$1C,$02,$02,$02,$02,$3C,$3C,$00,$00

    ; 29 flecha
    db $08,$08,$0C,$0C,$3E,$3E,$7F,$7F,$3E,$3E,$0C,$0C,$08,$08,$00,$00
    ; 30 escama/vida
    db $18,$18,$3C,$3C,$7E,$7E,$FF,$FF,$7E,$7E,$3C,$3C,$18,$18,$00,$00
    ; 31 nitro
    db $18,$00,$3C,$00,$7E,$00,$3C,$00,$18,$00,$3C,$00,$18,$00,$00,$00

    ; 32-35 cocodrilo motero 16x16: perfil lateral deliberadamente exagerado.
    ; Cola a la izquierda, hocico largo/ojos a la derecha y moto roja con dos ruedas.
    db $00,$00,$00,$00,$01,$00,$07,$00,$1F,$00,$7F,$00,$CF,$00,$03,$0C
    db $00,$1F,$00,$38,$30,$30,$78,$78,$78,$78,$30,$30,$00,$00,$00,$00
    db $00,$00,$78,$00,$FF,$40,$FF,$00,$FE,$00,$F8,$00,$E0,$00,$00,$C0
    db $00,$F0,$00,$78,$30,$30,$78,$78,$78,$78,$30,$30,$00,$00,$00,$00

    ; 36-39 taxi 16x16: carroceria amarilla, cristales azules, ruedas negras.
    db $07,$00,$0F,$07,$18,$07,$18,$07,$3F,$20,$3F,$20,$3F,$23,$3F,$20
    db $3F,$20,$3F,$23,$3F,$20,$3F,$20,$18,$07,$18,$07,$0F,$07,$07,$00
    db $E0,$00,$F0,$E0,$18,$E0,$18,$E0,$FC,$04,$FC,$04,$FC,$04,$FC,$04
    db $FC,$04,$FC,$04,$FC,$04,$FC,$04,$18,$E0,$18,$E0,$F0,$E0,$E0,$00

    ; 40-43 barrera 16x16: franjas rojas/blancas y patas.
    db $00,$00,$00,$00,$3F,$3F,$3F,$00,$03,$3C,$3C,$03,$03,$3C,$3C,$03
    db $03,$3C,$3C,$03,$3F,$3F,$0C,$0C,$1E,$1E,$1E,$00,$3F,$00,$00,$00
    db $00,$00,$00,$00,$FC,$FC,$FC,$00,$C0,$3C,$3C,$C0,$C0,$3C,$3C,$C0
    db $C0,$3C,$3C,$C0,$FC,$FC,$30,$30,$78,$78,$78,$00,$3C,$00,$00,$00

    ; 44-47 autobus/trafico 16x16: gran parabrisas y carroceria azul.
    db $00,$0F,$0F,$1F,$0F,$30,$0F,$30,$0F,$30,$00,$3F,$0F,$30,$0F,$30
    db $0F,$30,$0F,$30,$00,$3F,$20,$3F,$20,$3F,$07,$1F,$00,$18,$00,$0F
    db $00,$F0,$F0,$F8,$F0,$0C,$F0,$0C,$F0,$0C,$00,$FC,$F0,$0C,$F0,$0C
    db $F0,$0C,$F0,$0C,$00,$FC,$04,$FC,$04,$FC,$E0,$F8,$00,$18,$00,$F0

    ; 48-49 llama nitro (sprite 8x16)
    db $08,$00,$1C,$00,$3E,$00,$1C,$00,$3E,$00,$7F,$00,$3E,$00,$1C,$00
    db $00,$00,$08,$00,$1C,$00,$08,$00,$1C,$00,$3E,$00,$1C,$00,$08,$00

    ; 50 trofeo / 51 choque (fondo)
    db $7E,$7E,$5A,$5A,$7E,$7E,$3C,$3C,$18,$18,$18,$18,$3C,$3C,$7E,$7E
    db $81,$81,$42,$42,$24,$24,$18,$18,$18,$18,$24,$24,$42,$42,$81,$81
TilesFin:

PaletaFondo:
    ; arena clara, asfalto gris, amarillo/blanco, negro
    dw $7FFF, $4210, $03FF, $0000
PaletaFondoFin:

PaletasObjetos:
    ; 0 jugador: verde cocodrilo / rojo moto / negro
    dw $7FFF, $03E0, $001F, $0000
    ; 1 rivales: verde oscuro / naranja / negro
    dw $7FFF, $02A0, $021F, $0000
    ; 2 trafico: amarillo / azul / negro
    dw $7FFF, $03FF, $7C00, $0000
    ; 3 barrera y nitro: rojo / blanco / negro
    dw $7FFF, $001F, $7BDE, $0000
PaletasObjetosFin:

SECTION "Variables", WRAM0
wEstado:       ds 1
wKeys:         ds 1
wPrevKeys:     ds 1
wNewKeys:      ds 1
wFrame:        ds 1
wPlayerLane:   ds 1
wDistance:     ds 1
wDistanceTick: ds 1
wScore:        ds 1
wStage:        ds 1
wLives:        ds 1
wNitro:        ds 1
wTurbo:        ds 1
wInv:          ds 1
wHudDirty:     ds 1
wDecorDirty:   ds 1
wR1Lane:       ds 1
wR1Y:          ds 1
wR2Lane:       ds 1
wR2Y:          ds 1
wHazLane:      ds 1
wHazY:         ds 1
wHazType:      ds 1
