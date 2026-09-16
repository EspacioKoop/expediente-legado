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
DEF rVBK   EQU $FF4F
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

; Tiles generados desde la maqueta A «Pantano de Lerna».
DEF TILE_AGUA           EQU 0
DEF TILE_ONDA           EQU 1
DEF TILE_CABEZA         EQU 3
DEF TILE_HUECO          EQU 9
DEF TILE_NODO           EQU 15
DEF TILE_SELLO          EQU 21
DEF TILE_CUELLO_LUZ     EQU 27
DEF TILE_ZARCILLO       EQU 29
DEF TILE_BARRO          EQU 31
DEF TILE_PLACA_AGUA     EQU 34
DEF TILE_PLACA_DUDA     EQU 35
DEF TILE_GLIFO          EQU 36
DEF TILE_DIGITO         EQU 39
DEF TILE_L              EQU 49
DEF TILE_ICONO          EQU 54
DEF TILE_RELOJ_ON       EQU 55
DEF TILE_CURSOR         EQU 57
DEF TILE_DESTELLO       EQU 58
DEF TILE_O              EQU 50
DEF TILE_P              EQU 51
DEF TILE_R              EQU 52
DEF TILE_T              EQU 53
DEF TILE_RELOJ_OFF      EQU 56

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
    ; La portada usa solo la paleta 0: se borran los atributos de la partida.
    ld a, 1
    ldh [rVBK], a
    call LimpiarBG
    xor a
    ldh [rVBK], a
    ld hl, HydraLoopTitleMap
    call CopiarMapa

    ld hl, HydraLoopTitlePalette
    ld b, 8
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
    ; Atributos CGB estaticos: agua, hidra, raiz y HUD. En DMG caen en el
    ; mapa normal y se sobrescriben justo despues con LimpiarBG y el fondo.
    ld a, 1
    ldh [rVBK], a
    ld hl, AtributosJuego
    call CopiarMapa
    xor a
    ldh [rVBK], a
    call LimpiarBG
    ld hl, FondoJuego
    call CopiarMapa
    ld hl, PaletaJuego
    ld b, PaletaJuegoFin - PaletaJuego
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
    jr nz, .reloj
    ld a, [wHuecoLeido]
    ld e, a
    ld d, 0
    ld hl, wPendientes
    add hl, de
    ld [hl], 1
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
    ld a, e
    ld [wHuecoLeido], a
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
    ; Agua de fondo y franja oscura (paleta HUD) en las filas 5-9.
    ld a, 1
    ldh [rVBK], a
    call LimpiarBG
    ld hl, BG_MAP + 5 * 32
    ld bc, 5 * 32
.franja:
    ld a, 4
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .franja
    xor a
    ldh [rVBK], a
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
    ; Placa: interrogacion hasta observar, despues la marca de su raiz.
    ld a, c
    or a
    ld a, TILE_PLACA_DUDA
    jr z, .placa
    ld a, b
    add TILE_GLIFO - 1
.placa:
    ld c, a
    ld b, TILE_CABEZA
    jr .direccion
.vacio:
    ld c, TILE_PLACA_AGUA
    ld b, TILE_HUECO
.direccion:
    push bc
    push de
    ld hl, DireccionesHuecos
    add hl, de
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    call Pintar2x3
    pop de
    pop bc
    ; Mientras dura la lectura, el cuello de la cabeza observada se ilumina.
    ld a, b
    cp TILE_CABEZA
    ret nz
    ld a, [wBloqueo]
    or a
    ret z
    ld a, [wHuecoLeido]
    cp e
    ret nz
    dec hl
    ld a, TILE_CUELLO_LUZ
    ld [hli], a
    inc a
    ld [hl], a
    ret

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

Pintar2x3:
    ; HL=celda superior izquierda, B=primer tile de 6, C=placa a la derecha
    ; de la fila central. Devuelve HL en la celda inferior derecha.
    ld de, 31
    ld a, b
    ld [hli], a
    inc a
    ld [hl], a
    add hl, de
    inc a
    ld [hli], a
    inc a
    ld [hli], a
    ld [hl], c
    dec hl
    add hl, de
    inc a
    ld [hli], a
    inc a
    ld [hl], a
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
    ; HL=colores, B=bytes.
    ld a, $80
    ldh [rBCPS], a
.bucle:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bucle
    ret

CopiarMapa:
    ; HL=mapa 20x18 -> BG_MAP (o atributos si VBK=1).
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

; Cabezas 2x3 en filas 2 y 7, columnas 1/5/9/13/17; placa en la fila central.
DireccionesHuecos:
FOR FILA, 2, 8, 5
    FOR COL, 1, 18, 4
        dw BG_MAP + FILA * 32 + COL
    ENDR
ENDR

DEF FILA_NODOS EQU 12
DireccionesNodos:
    dw BG_MAP + FILA_NODOS * 32 + 3
    dw BG_MAP + FILA_NODOS * 32 + 9
    dw BG_MAP + FILA_NODOS * 32 + 15

; OAM Y/X: flecha a la izquierda de la fila central de cada bloque.
PosicionesCursor:
FOR FILA, 2, 8, 5
    FOR COL, 1, 18, 4
        db FILA * 8 + 24, COL * 8
    ENDR
ENDR
    db FILA_NODOS * 8 + 24, 3 * 8
    db FILA_NODOS * 8 + 24, 9 * 8
    db FILA_NODOS * 8 + 24, 15 * 8

; Destello sobre las raices que suben de cada nodo.
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

; 0 agua, 1 hidra, 2 raiz y barro, 3 placas, 4 HUD. Las cuatro primeras
; comparten el azul profundo del agua como color 0: los bordes de bloque no
; se notan y, en DMG, ese indice es el blanco del fondo.
PaletaJuego:
    dw $2D44, $3DE7, $52AD, $1881
    dw $2D44, $1E66, $2373, $0CA1
    dw $2D44, $2CED, $253C, $1044
    dw $2D44, $1462, $1B1D, $6FDC
    dw $1462, $2D44, $1B1D, $6FDC
PaletaJuegoFin:

PaletaCursor:
    dw $0000, $139F, $7FFF, $0000

    INCLUDE "assets/title_palette.inc"

TilesJuego:
    ; 0 agua lisa
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    ; 1-2 ondas de agua (2 variantes)
    dw `00000000, `00000000, `00022200, `02200022
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00111000, `01000110, `00000000, `00000000
    ; 3-8 cabeza de hidra con cuello, 2x3
    dw `03000000, `31300000, `31130333, `03113111
    dw `00311111, `03112111, `03123211, `03112111
    dw `00000030, `00000313, `33303113, `11131130
    dw `11111300, `11121130, `11232130, `11121130
    dw `03111111, `00311111, `00031333, `00313333
    dw `03132323, `03133333, `00313233, `00031111
    dw `11111130, `11111300, `33313000, `33331300
    dw `32323130, `33333130, `33231300, `11113000
    dw `00003111, `00003121, `00003111, `00003212
    dw `00003111, `00031121, `00311111, `03333333
    dw `11130000, `21130000, `11130000, `12130000
    dw `11130000, `21113000, `11111300, `33333330
    ; 9-14 munon cortado sobre el agua, 2x3
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000333, `00003222
    dw `00003121, `00003111, `00031111, `03333333
    dw `00000000, `00000000, `33300000, `22230000
    dw `21130000, `11130000, `11113000, `33333330
    ; 15-20 nudo de raiz con nucleo vivo, 2x3
    dw `00000000, `00000333, `00033111, `00311111
    dw `03111133, `03111322, `31113222, `31113222
    dw `00000000, `33300000, `11133000, `11111300
    dw `33111130, `22311130, `22231113, `22231113
    dw `31111322, `03111133, `03111111, `00311111
    dw `00033111, `00311311, `03110131, `31100311
    dw `22311113, `33111130, `11111130, `11111300
    dw `11133000, `11311300, `13101130, `11300113
    dw `31003110, `10031100, `10311000, `03110000
    dw `31100000, `11000000, `10000000, `11111111
    dw `01130013, `00113001, `00011301, `00001130
    dw `00000113, `00000011, `00000001, `11111111
    ; 21-26 nudo sellado: nucleo apagado con aspa, 2x3
    dw `00000000, `00000333, `00033111, `00311111
    dw `03111233, `03111323, `31113332, `31113332
    dw `00000000, `33300000, `11133000, `11111300
    dw `33211130, `32311130, `23331113, `23331113
    dw `31111323, `03111233, `03111111, `00311111
    dw `00033111, `00333333, `03330333, `33300333
    dw `32311113, `33211130, `11111130, `11111300
    dw `11133000, `33333300, `33303330, `33300333
    dw `33003330, `30033300, `30333000, `03330000
    dw `33300000, `33000000, `30000000, `33333333
    dw `03330033, `00333003, `00033303, `00003330
    dw `00000333, `00000033, `00000003, `33333333
    ; 27-28 tramo de cuello iluminado al observar, 2x1
    dw `00003222, `00003222, `00003222, `00003222
    dw `00003222, `00032222, `00311111, `03333333
    dw `22230000, `22230000, `22230000, `22230000
    dw `22230000, `22223000, `11111300, `33333330
    ; 29-30 raices que suben del nodo, 2x1
    dw `00001000, `00001000, `00010000, `00010000
    dw `00001000, `00001000, `00000100, `00000100
    dw `00001000, `00010000, `00010000, `00100000
    dw `00100000, `01000000, `01000000, `01000000
    ; 31-33 orilla y barro (borde, A, B)
    dw `10011001, `11111111, `11131111, `11111111
    dw `31111113, `11111111, `11113111, `11111111
    dw `11111111, `11131111, `11111111, `31111113
    dw `11111111, `11113111, `11111111, `13111111
    dw `11111111, `11111311, `13111111, `11111111
    dw `11311111, `11111111, `11111131, `11111111
    ; 34 placa sin cabeza: solo agua
    dw `00000000, `00000000, `00000000, `00000000
    dw `00000000, `00000000, `00000000, `00000000
    ; 35 placa de cabeza sin leer
    dw `01111110, `11122111, `11211211, `11111211
    dw `11112111, `11121111, `11111111, `01121110
    ; 36-38 marcas de raiz: circulo, cuadrado, triangulo
    dw `01111110, `11333311, `13111131, `13111131
    dw `13111131, `13111131, `11333311, `01111110
    dw `01111110, `13333331, `13111131, `13111131
    dw `13111131, `13111131, `13333331, `01111110
    dw `01111110, `11133111, `11311311, `11311311
    dw `13111131, `13111131, `13333331, `01111110
    ; 39-48 digitos 0-9
    dw `00033300, `00300030, `00300330, `00303030
    dw `00330030, `00300030, `00033300, `00000000
    dw `00003000, `00033000, `00003000, `00003000
    dw `00003000, `00003000, `00033300, `00000000
    dw `00033300, `00300030, `00000030, `00000300
    dw `00003000, `00030000, `00333330, `00000000
    dw `00333300, `00000030, `00000030, `00033300
    dw `00000030, `00000030, `00333300, `00000000
    dw `00000300, `00003300, `00030300, `00300300
    dw `00333330, `00000300, `00000300, `00000000
    dw `00333330, `00300000, `00300000, `00333300
    dw `00000030, `00000030, `00333300, `00000000
    dw `00033300, `00300000, `00300000, `00333300
    dw `00300030, `00300030, `00033300, `00000000
    dw `00333330, `00000030, `00000300, `00003000
    dw `00030000, `00030000, `00030000, `00000000
    dw `00033300, `00300030, `00300030, `00033300
    dw `00300030, `00300030, `00033300, `00000000
    dw `00033300, `00300030, `00300030, `00033330
    dw `00000030, `00000030, `00033300, `00000000
    ; 49-53 L O P R T
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
    ; 54 icono de hidra del HUD
    dw `22022022, `32032032, `22022022, `02022020
    dw `00222200, `00022000, `00022000, `00222200
    ; 55-56 reloj de brote lleno / vacio
    dw `00000000, `03333330, `03222230, `03222230
    dw `03222230, `03222230, `03333330, `00000000
    dw `00000000, `03333330, `03000030, `03000030
    dw `03000030, `03000030, `03333330, `00000000
    ; 57 cursor (sprite)
    dw `33000000, `32300000, `31230000, `31123000
    dw `31112300, `31123000, `31230000, `33300000
    ; 58 destello de raiz (sprite)
    dw `00030000, `00323000, `03222300, `32212230
    dw `03222300, `00323000, `00030000, `00000000
TilesJuegoFin:

FondoJuego:
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  1,  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  1,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  1,  0,  0,  0,  2,  0,  0,  0,  0
    db  0,  0,  0, 34,  1,  0,  0, 34,  2,  0,  0, 34,  0,  0,  0, 34,  0,  0,  0, 34
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  1,  0,  0,  1,  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  0,  0,  1
    db  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  1,  0,  0,  0,  2
    db  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0, 34,  0,  0,  0, 34,  0,  0,  0, 34,  0,  0,  0, 34,  0,  0,  0, 34
    db  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  1,  0,  0,  1,  0,  0,  0,  2,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  0,  1
    db  0,  0,  0, 29, 30,  0,  0,  0,  0, 29, 30,  0,  0,  0,  0, 29, 30,  0,  0,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
    db 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32
    db 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33, 32, 33

AtributosJuego:
    db  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0
    db  0,  1,  1,  3,  0,  1,  1,  3,  0,  1,  1,  3,  0,  1,  1,  3,  0,  1,  1,  3
    db  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0
    db  0,  1,  1,  3,  0,  1,  1,  3,  0,  1,  1,  3,  0,  1,  1,  3,  0,  1,  1,  3
    db  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0,  0,  1,  1,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  2,  2,  0,  0,  0,  0,  2,  2,  0,  0,  0,  0,  2,  2,  0,  0,  0
    db  0,  0,  0,  2,  2,  0,  0,  0,  0,  2,  2,  0,  0,  0,  0,  2,  2,  0,  0,  0
    db  0,  0,  0,  2,  2,  3,  0,  0,  0,  2,  2,  3,  0,  0,  0,  2,  2,  3,  0,  0
    db  0,  0,  0,  2,  2,  0,  0,  0,  0,  2,  2,  0,  0,  0,  0,  2,  2,  0,  0,  0
    db  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2
    db  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2
    db  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2

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
wHuecoLeido:    ds 1
wLecturas:      ds 1
wMejorRaiz:     ds 1
wMejorCuenta:   ds 1
wFinNivel:

SECTION "Handshake", WRAM0[$C100]
wHydraCompletado: ds 1
