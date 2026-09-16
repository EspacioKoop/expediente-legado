; HYDRA LOOP 98 - prototipo GBC para SIGA-98 (#439)
; Cortar una cabeza hace brotar dos de la misma raiz. Observar revela la raiz.
; Un nodo solo se sella cuando ya se han leido al menos dos cabezas suyas;
; sellarlo a ciegas tapa el sintoma y la raiz dominante crece.
; Codigo y pixel-art de juego originales del proyecto, licencia MIT.
; La portada reutiliza los assets de gbc/minijuegos/hydra_loop (#556).

DEF rP1    EQU $FF00
DEF rIF    EQU $FF0F
DEF rNR10  EQU $FF10
DEF rNR50  EQU $FF24
DEF rNR51  EQU $FF25
DEF rNR52  EQU $FF26
DEF rLCDC  EQU $FF40
DEF rLY    EQU $FF44
DEF rBGP   EQU $FF47
DEF rOBP0  EQU $FF48
DEF rBCPS  EQU $FF68
DEF rBCPD  EQU $FF69
DEF rOCPS  EQU $FF6A
DEF rOCPD  EQU $FF6B
DEF rIE    EQU $FFFF

DEF VRAM_TILES EQU $8000
DEF BG_MAP     EQU $9800
DEF OAM_BASE   EQU $FE00

DEF PAD_A     EQU $01
DEF PAD_B     EQU $02
DEF PAD_START EQU $08

; LCD, tiles en $8000 y BG; el juego activa ademas sprites 8x8.
DEF LCDC_FONDO EQU $91
DEF LCDC_JUEGO EQU $93

DEF ESTADO_TITULO   EQU 0
DEF ESTADO_JUEGO    EQU 1
DEF ESTADO_FALLO    EQU 2
DEF ESTADO_VICTORIA EQU 3

DEF NUM_HUECOS            EQU 10
DEF NUM_NODOS             EQU 3
DEF NUM_NIVELES           EQU 3
DEF SEGMENTOS             EQU 6
DEF LECTURAS_PARA_SELLAR  EQU 2
DEF BLOQUEO_OBSERVAR      EQU 30
DEF CORTE_BROTES          EQU 2
; Elementos con redibujo pendiente: 10 huecos, 3 nodos, HUD y reloj.
DEF PENDIENTE_HUD         EQU 13
DEF PENDIENTE_RELOJ       EQU 14
DEF NUM_PENDIENTES        EQU 15
DEF MAX_DIBUJOS_VBLANK    EQU 3
DEF MARCA_COMPLETADO      EQU $A5

DEF TILE_CABEZA   EQU 1
DEF TILE_HUECO    EQU 5
DEF TILE_NODO     EQU 9
DEF TILE_SELLO    EQU 13
DEF TILE_GLIFO    EQU 17
DEF TILE_DIGITO   EQU 20
DEF TILE_L        EQU 30
DEF TILE_O        EQU 31
DEF TILE_P        EQU 32
DEF TILE_R        EQU 33
DEF TILE_T        EQU 34
DEF TILE_ICONO    EQU 35
DEF TILE_RELOJ_ON EQU 36
DEF TILE_RELOJ_OFF EQU 37
DEF TILE_CURSOR   EQU 38
DEF TILE_DESTELLO EQU 39

SECTION "VBlank", ROM0[$0040]
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "HYDRALOOP98"
    ds $0143 - @, 0
    db $80
    ds $0150 - @, 0

SECTION "Juego", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF
    ; El handshake nunca queda marcado por arrancar.
    xor a
    ld [wHydraCompletado], a
    ld [wTeclas], a
    ld [wNuevas], a
    ld [wFrame], a
    ld [wNivel], a
    call ApagarLCD
    call ConfigurarAudio
    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP0], a
    call PrepararTitulo

    ld a, 1
    ldh [rIE], a
    xor a
    ldh [rIF], a
    ei

BuclePrincipal:
    ; HALT despierta en VBlank: VRAM y OAM se tocan solo al principio.
    halt
    ld a, [wEstado]
    cp ESTADO_JUEGO
    call z, RenderVBlank

    call LeerPad
    ld hl, wFrame
    inc [hl]

    ld a, [wEstado]
    cp ESTADO_JUEGO
    jr z, .juego

    ld a, [wNuevas]
    and PAD_START | PAD_A
    jr z, BuclePrincipal
    ld a, [wEstado]
    cp ESTADO_TITULO
    jr z, .empezar
    cp ESTADO_FALLO
    jr z, .reintentar
    call PrepararTitulo
    jr BuclePrincipal
.empezar:
    xor a
    ld [wNivel], a
.reintentar:
    call IniciarNivel
    jr BuclePrincipal
.juego:
    call ActualizarJuego
    jr BuclePrincipal

PrepararTitulo:
    call ApagarLCD
    call BorrarOAM
    ld hl, HydraLoopTitleTiles
    ld de, VRAM_TILES
    ld bc, HydraLoopTitleTilesFin - HydraLoopTitleTiles
    call CopiarMemoria

    ld hl, HydraLoopTitleMap
    ld de, BG_MAP
    ld c, 18
.fila:
    ld b, 20
.columna:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .columna
    ld a, e
    add 12
    ld e, a
    jr nc, .sin_acarreo
    inc d
.sin_acarreo:
    dec c
    jr nz, .fila

    ld hl, HydraLoopTitlePalette
    call CargarPaletaBG
    ld a, ESTADO_TITULO
    ld [wEstado], a
    ld a, LCDC_FONDO
    ldh [rLCDC], a
    ret

IniciarNivel:
    call ApagarLCD
    call BorrarOAM
    ld hl, TilesJuego
    ld de, VRAM_TILES
    ld bc, TilesJuegoFin - TilesJuego
    call CopiarMemoria
    call LimpiarBG
    ld hl, PaletaJuego
    call CargarPaletaBG
    ld a, $80
    ldh [rOCPS], a
    ld hl, PaletaCursor
    ld b, 8
.paleta_obj:
    ld a, [hli]
    ldh [rOCPD], a
    dec b
    jr nz, .paleta_obj

    ld hl, wCabezas
    ld b, wFinNivel - wCabezas
    xor a
.cero:
    ld [hli], a
    dec b
    jr nz, .cero

    ; Niveles: 10 bytes por nivel con raiz+1 o 0 para hueco vacio.
    ld a, [wNivel]
    ld hl, Niveles
    ld de, NUM_HUECOS
    or a
    jr z, .copiar
    ld b, a
.saltar:
    add hl, de
    dec b
    jr nz, .saltar
.copiar:
    ld de, wCabezas
    ld b, NUM_HUECOS
.copiar_hueco:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copiar_hueco

    call ReiniciarReloj
    ; Con LCD apagada se dibuja todo de una vez.
    xor a
.dibujar:
    push af
    call DibujarElemento
    pop af
    inc a
    cp NUM_PENDIENTES
    jr c, .dibujar
    ld hl, wPendientes
    ld b, NUM_PENDIENTES
    xor a
.limpiar_pendientes:
    ld [hli], a
    dec b
    jr nz, .limpiar_pendientes

    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ActualizarOAM
    ld a, LCDC_JUEGO
    ldh [rLCDC], a
    ret

ActualizarJuego:
    ld a, [wBloqueo]
    or a
    jr z, .entrada
    ; Observar cuesta tiempo: la hidra sigue creciendo mientras tanto.
    dec a
    ld [wBloqueo], a
    jr .reloj
.entrada:
    call MoverCursor
    ld a, [wNuevas]
    and PAD_B
    jr z, .accion
    call Observar
    jr .reloj
.accion:
    ld a, [wNuevas]
    and PAD_A
    call nz, Actuar
    ld a, [wEstado]
    cp ESTADO_JUEGO
    ret nz
.reloj:
    jp AvanzarReloj

MoverCursor:
    ; Vecinos: izquierda, derecha, arriba, abajo; $FF sin salida.
    ld a, [wNuevas]
    and $F0
    ret z
    ld c, a
    ld a, [wCursor]
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    ld de, Vecinos
    add hl, de
    bit 5, c
    jr nz, .leer
    inc hl
    bit 4, c
    jr nz, .leer
    inc hl
    bit 6, c
    jr nz, .leer
    inc hl
.leer:
    ld a, [hl]
    cp $FF
    ret z
    ld [wCursor], a
    ret

Observar:
    ld a, [wCursor]
    cp NUM_HUECOS
    ret nc
    ld e, a
    ld d, 0
    ld hl, wCabezas
    add hl, de
    ld a, [hl]
    or a
    ret z
    dec a
    ld [wNodoLeido], a
    ld hl, wObservadas
    add hl, de
    ld [hl], 1
    ld hl, wPendientes
    add hl, de
    ld [hl], 1
    ld a, BLOQUEO_OBSERVAR
    ld [wBloqueo], a
    ld hl, SonidoObservar
    jp Sonar

Actuar:
    ld a, [wCursor]
    cp NUM_HUECOS
    jp nc, Sellar

Cortar:
    ; A=hueco. Atacar el sintoma lo multiplica en la misma raiz.
    ld e, a
    ld d, 0
    ld hl, wCabezas
    add hl, de
    ld a, [hl]
    or a
    ret z
    ld b, a
    ld [hl], 0
    ld hl, wObservadas
    add hl, de
    ld [hl], 0
    ld hl, wPendientes
    add hl, de
    ld [hl], 1
    push bc
    ld hl, SonidoCortar
    call Sonar
    pop bc
    ld a, b
    ld c, CORTE_BROTES
    jp Proliferar

Proliferar:
    ; A=raiz+1, C=cabezas nuevas. Sin hueco libre la hidra desborda.
    ld b, a
.otra:
    push bc
    call BuscarHueco
    pop bc
    cp $FF
    jp z, Desbordar
    ld e, a
    ld d, 0
    ld hl, wCabezas
    add hl, de
    ld [hl], b
    ld hl, wObservadas
    add hl, de
    ld [hl], 0
    ld hl, wPendientes
    add hl, de
    ld [hl], 1
    ; Los brotes se reparten saltando tres huecos desde el ultimo.
    ld a, e
    add 3
    cp NUM_HUECOS
    jr c, .siguiente_origen
    sub NUM_HUECOS
.siguiente_origen:
    ld [wOrigenBrote], a
    dec c
    jr nz, .otra
    ld a, 1
    ld [wPendientes + PENDIENTE_HUD], a
    ret

BuscarHueco:
    ; Devuelve A=primer hueco libre desde wOrigenBrote o $FF.
    ld a, [wOrigenBrote]
    ld c, NUM_HUECOS
.bucle:
    ld e, a
    ld d, 0
    ld hl, wCabezas
    add hl, de
    ld a, [hl]
    or a
    ld a, e
    ret z
    inc a
    cp NUM_HUECOS
    jr c, .siguiente
    xor a
.siguiente:
    dec c
    jr nz, .bucle
    ld a, $FF
    ret

Sellar:
    ; A=objetivo de nodo (10-12).
    sub NUM_HUECOS
    ld b, a
    ld e, a
    ld d, 0
    ld hl, wSellados
    add hl, de
    ld a, [hl]
    or a
    ret nz

    ld a, b
    inc a
    ld c, a
    xor a
    ld [wLecturas], a
    ld e, a
.contar:
    ld d, 0
    ld hl, wCabezas
    add hl, de
    ld a, [hl]
    cp c
    jr nz, .siguiente_lectura
    ld hl, wObservadas
    add hl, de
    ld a, [hl]
    or a
    jr z, .siguiente_lectura
    ld hl, wLecturas
    inc [hl]
.siguiente_lectura:
    inc e
    ld a, e
    cp NUM_HUECOS
    jr c, .contar

    ld a, [wLecturas]
    cp LECTURAS_PARA_SELLAR
    jr nc, .sellar
    ; Sellar sin haber leido el nodo solo tapa el sintoma.
    ld hl, SonidoError
    call Sonar
    call RaizDominante
    or a
    ret z
    ld c, 1
    jp Proliferar

.sellar:
    ld e, b
    ld d, 0
    ld hl, wSellados
    add hl, de
    ld [hl], 1
    ld hl, wPendientes + NUM_HUECOS
    add hl, de
    ld [hl], 1
    ld e, 0
.quitar:
    ld hl, wCabezas
    add hl, de
    ld a, [hl]
    cp c
    jr nz, .siguiente_cabeza
    ld [hl], 0
    ld hl, wObservadas
    add hl, de
    ld [hl], 0
    ld hl, wPendientes
    add hl, de
    ld [hl], 1
.siguiente_cabeza:
    inc e
    ld a, e
    cp NUM_HUECOS
    jr c, .quitar
    ld a, 1
    ld [wPendientes + PENDIENTE_HUD], a
    ld hl, SonidoSellar
    call Sonar
    call ReiniciarReloj
    call ContarCabezas
    or a
    ret nz
    jp NivelSuperado

RaizDominante:
    ; Devuelve A=raiz+1 no sellada con mas cabezas (empate: la menor) o 0.
    xor a
    ld [wMejorRaiz], a
    ld [wMejorCuenta], a
    ld b, 1
.raiz:
    ld e, b
    dec e
    ld d, 0
    ld hl, wSellados
    add hl, de
    ld a, [hl]
    or a
    jr nz, .siguiente_raiz
    ld c, 0
    ld e, 0
.contar:
    ld hl, wCabezas
    add hl, de
    ld a, [hl]
    cp b
    jr nz, .otra_cabeza
    inc c
.otra_cabeza:
    inc e
    ld a, e
    cp NUM_HUECOS
    jr c, .contar
    ld a, [wMejorCuenta]
    cp c
    jr nc, .siguiente_raiz
    ld a, c
    ld [wMejorCuenta], a
    ld a, b
    ld [wMejorRaiz], a
.siguiente_raiz:
    inc b
    ld a, b
    cp NUM_NODOS + 1
    jr c, .raiz
    ld a, [wMejorRaiz]
    ret

ContarCabezas:
    ld hl, wCabezas
    ld b, NUM_HUECOS
    ld c, 0
.bucle:
    ld a, [hli]
    or a
    jr z, .vacio
    inc c
.vacio:
    dec b
    jr nz, .bucle
    ld a, c
    ret

AvanzarReloj:
    ld hl, wTick
    dec [hl]
    ret nz
    call CargarTick
    ld a, 1
    ld [wPendientes + PENDIENTE_RELOJ], a
    ld hl, wSegmentos
    dec [hl]
    ret nz
    ld [hl], SEGMENTOS
    ld hl, SonidoCrecer
    call Sonar
    call RaizDominante
    or a
    ret z
    ld c, 1
    jp Proliferar

CargarTick:
    ld a, [wNivel]
    ld e, a
    ld d, 0
    ld hl, TicksPorSegmento
    add hl, de
    ld a, [hl]
    ld [wTick], a
    ret

ReiniciarReloj:
    call CargarTick
    ld a, SEGMENTOS
    ld [wSegmentos], a
    ld a, 1
    ld [wPendientes + PENDIENTE_RELOJ], a
    ret

NivelSuperado:
    ld hl, SonidoNivel
    call Sonar
    ld a, [wNivel]
    inc a
    cp NUM_NIVELES
    jr nc, .victoria
    ld [wNivel], a
    jp IniciarNivel
.victoria:
    ; Handshake estable para una futura integracion diegetica (#439).
    ld a, MARCA_COMPLETADO
    ld [wHydraCompletado], a
    ld a, ESTADO_VICTORIA
    ld [wEstado], a
    jp PantallaFinal

Desbordar:
    ld a, ESTADO_FALLO
    ld [wEstado], a
    ld hl, SonidoDesborde
    call Sonar
    jp PantallaFinal

PantallaFinal:
    call ApagarLCD
    call BorrarOAM
    call LimpiarBG
    ld hl, BG_MAP + (6 * 32) + 8
    call EscribirLoop
    ld a, [wEstado]
    cp ESTADO_VICTORIA
    jr nz, .fallo
    ld hl, BG_MAP + (8 * 32) + 8
    ld a, TILE_R
    ld [hli], a
    ld a, TILE_O
    ld [hli], a
    ld a, TILE_T
    ld [hli], a
    ld a, TILE_O
    ld [hl], a
    jr .encender
.fallo:
    ld hl, BG_MAP + (8 * 32) + 9
    ld a, TILE_L
    ld [hli], a
    ld a, [wNivel]
    add TILE_DIGITO + 1
    ld [hl], a
.encender:
    ld a, LCDC_FONDO
    ldh [rLCDC], a
    ret

EscribirLoop:
    ld a, TILE_L
    ld [hli], a
    ld a, TILE_O
    ld [hli], a
    ld [hli], a
    ld a, TILE_P
    ld [hl], a
    ret

RenderVBlank:
    call ActualizarOAM
    ; Como mucho tres elementos por frame: un sellado se reparte en varios.
    ld c, MAX_DIBUJOS_VBLANK
    ld e, 0
.buscar:
    ld d, 0
    ld hl, wPendientes
    add hl, de
    ld a, [hl]
    or a
    jr z, .siguiente
    ld [hl], 0
    push bc
    push de
    ld a, e
    call DibujarElemento
    pop de
    pop bc
    dec c
    ret z
.siguiente:
    inc e
    ld a, e
    cp NUM_PENDIENTES
    jr c, .buscar
    ret

DibujarElemento:
    cp NUM_HUECOS
    jr c, DibujarHueco
    cp PENDIENTE_HUD
    jr c, DibujarNodo
    jp z, DibujarHUD
    jp DibujarReloj

DibujarHueco:
    ld e, a
    ld d, 0
    ld hl, wCabezas
    add hl, de
    ld b, [hl]
    ld hl, wObservadas
    add hl, de
    ld c, [hl]
    ld a, b
    or a
    jr z, .vacio
    ; La marca de raiz solo aparece despues de observar la cabeza.
    ld a, c
    or a
    jr z, .sin_marca
    ld a, b
    add TILE_GLIFO - 1
.sin_marca:
    ld c, a
    ld b, TILE_CABEZA
    jr .direccion
.vacio:
    ld c, 0
    ld b, TILE_HUECO
.direccion:
    ld hl, DireccionesHuecos
    add hl, de
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    jp Pintar2x2

DibujarNodo:
    sub NUM_HUECOS
    ld e, a
    ld d, 0
    ld hl, wSellados
    add hl, de
    ld a, [hl]
    or a
    ld b, TILE_NODO
    jr z, .glifo
    ld b, TILE_SELLO
.glifo:
    ld a, e
    add TILE_GLIFO
    ld c, a
    ld hl, DireccionesNodos
    add hl, de
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a

Pintar2x2:
    ; HL=celda superior izquierda, B=primer tile, C=marca bajo el bloque.
    ld a, b
    ld [hli], a
    inc a
    ld [hl], a
    ld de, 31
    add hl, de
    inc a
    ld [hli], a
    inc a
    ld [hl], a
    add hl, de
    ld [hl], c
    ret

DibujarHUD:
    call ContarCabezas
    ld b, TILE_DIGITO
    cp 10
    jr c, .unidades
    sub 10
    inc b
.unidades:
    add TILE_DIGITO
    ld c, a
    ld hl, BG_MAP
    ld a, TILE_L
    ld [hli], a
    ld a, [wNivel]
    add TILE_DIGITO + 1
    ld [hl], a
    ld hl, BG_MAP + 4
    ld a, TILE_ICONO
    ld [hli], a
    ld a, b
    ld [hli], a
    ld [hl], c
    ret

DibujarReloj:
    ; Segmentos que quedan hasta el proximo brote espontaneo.
    ld a, [wSegmentos]
    ld b, a
    ld hl, BG_MAP + 13
    ld c, SEGMENTOS
.segmento:
    ld a, b
    or a
    ld a, TILE_RELOJ_OFF
    jr z, .poner
    dec b
    ld a, TILE_RELOJ_ON
.poner:
    ld [hli], a
    dec c
    jr nz, .segmento
    ret

ActualizarOAM:
    ld a, [wCursor]
    ld e, a
    ld d, 0
    ld hl, PosicionesCursor
    add hl, de
    add hl, de
    ld b, [hl]
    inc hl
    ld c, [hl]
    ld hl, OAM_BASE
    ld a, b
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, TILE_CURSOR
    ld [hli], a
    xor a
    ld [hli], a

    ; Al observar, el nodo raiz destella mientras dura la lectura.
    ld a, [wBloqueo]
    or a
    jr z, .sin_destello
    ld a, [wFrame]
    and 4
    jr z, .sin_destello
    ld a, [wNodoLeido]
    ld e, a
    push hl
    ld hl, PosicionesDestello
    add hl, de
    add hl, de
    ld b, [hl]
    inc hl
    ld c, [hl]
    pop hl
    ld a, b
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, TILE_DESTELLO
    ld [hli], a
    xor a
    ld [hl], a
    ret
.sin_destello:
    xor a
    ld [hl], a
    ret

LeerPad:
    ld a, [wTeclas]
    ld b, a
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    swap a
    ld c, a
    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    or c
    ld c, a
    ld a, $30
    ldh [rP1], a
    ld a, c
    ld [wTeclas], a
    ld a, b
    cpl
    and c
    ld [wNuevas], a
    ret

ApagarLCD:
    ldh a, [rLCDC]
    add a
    ret nc
.espera:
    ldh a, [rLY]
    cp 144
    jr c, .espera
    xor a
    ldh [rLCDC], a
    ret

BorrarOAM:
    ld hl, OAM_BASE
    ld b, 40
    xor a
.bucle:
    ld [hli], a
    dec b
    jr nz, .bucle
    ret

LimpiarBG:
    ld hl, BG_MAP
    ld bc, 32 * 32
.bucle:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .bucle
    ret

CopiarMemoria:
    ; HL=origen, DE=destino, BC=bytes.
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, CopiarMemoria
    ret

CargarPaletaBG:
    ld a, $80
    ldh [rBCPS], a
    ld b, 8
.bucle:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bucle
    ret

ConfigurarAudio:
    ld a, $80
    ldh [rNR52], a
    ld a, $77
    ldh [rNR50], a
    ld a, $11
    ldh [rNR51], a
    ret

Sonar:
    ; HL=cinco bytes para NR10-NR14 del canal 1.
    ld c, LOW(rNR10)
    ld b, 5
.bucle:
    ld a, [hli]
    ldh [c], a
    inc c
    dec b
    jr nz, .bucle
    ret
FinCodigo:

SonidoObservar: db $00, $80, $A1, $C0, $87
SonidoCortar:   db $1A, $C0, $F2, $40, $86
SonidoError:    db $00, $C0, $C2, $10, $84
SonidoSellar:   db $00, $80, $F3, $A0, $87
SonidoCrecer:   db $2B, $40, $B2, $80, $85
SonidoNivel:    db $00, $40, $F4, $E0, $87
SonidoDesborde: db $0F, $C0, $F4, $30, $84

Vecinos:
    db $FF, 1, $FF, 5
    db 0, 2, $FF, 6
    db 1, 3, $FF, 7
    db 2, 4, $FF, 8
    db 3, $FF, $FF, 9
    db $FF, 6, 0, 10
    db 5, 7, 1, 10
    db 6, 8, 2, 11
    db 7, 9, 3, 12
    db 8, $FF, 4, 12
    db $FF, 11, 5, $FF
    db 10, 12, 7, $FF
    db 11, $FF, 9, $FF

; Cabezas 2x2 en filas 3 y 8, columnas 1/5/9/13/17; marca de raiz debajo.
DireccionesHuecos:
FOR FILA, 3, 9, 5
    FOR COL, 1, 18, 4
        dw BG_MAP + FILA * 32 + COL
    ENDR
ENDR

DEF FILA_NODOS EQU 13
DireccionesNodos:
    dw BG_MAP + FILA_NODOS * 32 + 3
    dw BG_MAP + FILA_NODOS * 32 + 9
    dw BG_MAP + FILA_NODOS * 32 + 15

; OAM Y/X: flecha a la izquierda de cada objetivo.
PosicionesCursor:
FOR FILA, 3, 9, 5
    FOR COL, 1, 18, 4
        db FILA * 8 + 20, COL * 8
    ENDR
ENDR
    db FILA_NODOS * 8 + 20, 3 * 8
    db FILA_NODOS * 8 + 20, 9 * 8
    db FILA_NODOS * 8 + 20, 15 * 8

PosicionesDestello:
    db (FILA_NODOS - 1) * 8 + 16, 3 * 8 + 12
    db (FILA_NODOS - 1) * 8 + 16, 9 * 8 + 12
    db (FILA_NODOS - 1) * 8 + 16, 15 * 8 + 12

; Raiz+1 por hueco. N1 comun; tres raices con una cabeza suelta; tres raices
; con mas presion. Cada nivel es resoluble sin cortar salvo la cabeza suelta.
Niveles:
    db 2, 0, 2, 0, 0,  0, 2, 0, 2, 0
    db 1, 3, 0, 1, 0,  3, 0, 1, 0, 2
    db 0, 2, 1, 0, 3,  2, 3, 0, 1, 2

TicksPorSegmento:
    db 60, 45, 40

PaletaJuego:
    dw $5B9A, $2A46, $18D8, $1042

PaletaCursor:
    dw $0000, $139F, $7FFF, $0000

    INCLUDE "assets/title_palette.inc"

TilesJuego:
    ; 0 vacio
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    ; 1-4 cabeza de hidra
    dw `00000011, `00001111, `00011111, `00111311
    dw `00111111, `00111111, `00011222, `00001122
    dw `11000000, `11110000, `11111000, `11311100
    dw `11111100, `11111100, `22211000, `22110000
    dw `00000111, `00000111, `00001111, `00001111
    dw `00011111, `00011111, `00111111, `00111111
    dw `11100000, `11100000, `11110000, `11110000
    dw `11111000, `11111000, `11111100, `11111100
    ; 5-8 hueco: muñon cortado
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000333, `00003333
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `33300000, `33330000
    ; 9-12 nodo raiz
    dw `00033333, `00311111, `03111111, `31112111
    dw `31121111, `31111111, `31111112, `31111111
    dw `33333000, `11111300, `11111130, `11211113
    dw `11112113, `11111113, `21111113, `11111113
    dw `31111111, `31211111, `31111111, `31111121
    dw `03111111, `00311111, `00033333, `00000000
    dw `11111113, `11111213, `11111113, `12111113
    dw `11111130, `11111300, `33333000, `00000000
    ; 13-16 nodo sellado
    dw `00033333, `00333333, `03322333, `33332233
    dw `33333322, `33333332, `33333333, `33333333
    dw `33333000, `33333300, `33322330, `33223333
    dw `22333333, `23333333, `33333333, `33333333
    dw `33333333, `33333333, `33333332, `33333322
    dw `03332233, `00322333, `00033333, `00000000
    dw `33333333, `33333333, `23333333, `22333333
    dw `33223330, `33322300, `33333000, `00000000
    ; 17-19 marcas de raiz: circulo, cuadrado, triangulo
    dw `00000000, `00333300, `03300330, `03000030
    dw `03000030, `03300330, `00333300, `00000000
    dw `00000000, `03333330, `03000030, `03000030
    dw `03000030, `03000030, `03333330, `00000000
    dw `00000000, `00033000, `00300300, `00300300
    dw `03000030, `03000030, `33333333, `00000000
    ; 20-29 digitos 0-9
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
    ; 30-34 L O P R T
    dw `03000000, `03000000, `03000000, `03000000
    dw `03000000, `03000000, `03333300, `00000000
    dw `00333000, `03000300, `03000300, `03000300
    dw `03000300, `03000300, `00333000, `00000000
    dw `03333000, `03000300, `03000300, `03333000
    dw `03000000, `03000000, `03000000, `00000000
    dw `03333000, `03000300, `03000300, `03333000
    dw `03030000, `03003000, `03000300, `00000000
    dw `03333300, `00030000, `00030000, `00030000
    dw `00030000, `00030000, `00030000, `00000000
    ; 35 icono de cabeza
    dw `00111100, `01311310, `01111110, `00122100
    dw `00011000, `00011000, `00111100, `00000000
    ; 36-37 reloj de brote lleno / vacio
    dw `00000000, `03333330, `03222230, `03222230
    dw `03222230, `03222230, `03333330, `00000000
    dw `00000000, `03333330, `03000030, `03000030
    dw `03000030, `03000030, `03333330, `00000000
    ; 38 cursor (sprite)
    dw `00000000, `03300000, `03130000, `03113000
    dw `03111300, `03113000, `03130000, `03300000
    ; 39 destello de raiz (sprite)
    dw `00030000, `00313000, `03111300, `31121130
    dw `03111300, `00313000, `00030000, `00000000
TilesJuegoFin:

    INCLUDE "assets/title_tiles.asm"
    INCLUDE "assets/title_tilemap.asm"

SECTION "Estado", WRAM0
wEstado:        ds 1
wNivel:         ds 1
wTeclas:        ds 1
wNuevas:        ds 1
wFrame:         ds 1
wCabezas:       ds NUM_HUECOS
wObservadas:    ds NUM_HUECOS
wSellados:      ds NUM_NODOS
wPendientes:    ds NUM_PENDIENTES
wCursor:        ds 1
wTick:          ds 1
wSegmentos:     ds 1
wOrigenBrote:   ds 1
wBloqueo:       ds 1
wNodoLeido:     ds 1
wLecturas:      ds 1
wMejorRaiz:     ds 1
wMejorCuenta:   ds 1
wFinNivel:

SECTION "Handshake", WRAM0[$C100]
wHydraCompletado: ds 1
