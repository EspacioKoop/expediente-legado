; Paper Planes 98 - minijuego GBC para SIGA-98
; Ruta 1: Nueva York, 1998.
; Codigo y pixel-art originales del proyecto, licencia MIT.
;
; Vuela un avion de papel por una ruta arcade inspirada en el skyline
; neoyorquino de finales de los 90: Liberty, WTC, Brooklyn Bridge y Empire.
; Toda la puntuacion vive en RAM; no hay guardado ni recompensa sistemica.

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

DEF KEY_A      EQU $01
DEF KEY_B      EQU $02
DEF KEY_SELECT EQU $04
DEF KEY_START  EQU $08
DEF KEY_RIGHT  EQU $10
DEF KEY_LEFT   EQU $20
DEF KEY_UP     EQU $40
DEF KEY_DOWN   EQU $80
DEF KEY_START_A EQU $09
DEF KEY_SUBIR   EQU $41

DEF ESTADO_TITULO EQU 0
DEF ESTADO_JUEGO  EQU 1
DEF ESTADO_CLEAR  EQU 2
DEF ESTADO_CRASH  EQU 3

DEF VIENTO_ARRIBA EQU 1
DEF VIENTO_ABAJO  EQU 2

DEF TILE_AVION_IZQ EQU 1
DEF TILE_AVION_DER EQU 2
DEF TILE_EDIFICIO  EQU 3
DEF TILE_TEJADO    EQU 4
DEF TILE_AGUJA     EQU 5
DEF TILE_ESTATUA   EQU 6
DEF TILE_ANTORCHA  EQU 7
DEF TILE_PUENTE    EQU 8
DEF TILE_CABLE     EQU 9
DEF TILE_SKYLINE   EQU 10
DEF TILE_AGUA      EQU 11
DEF TILE_NUBE      EQU 12
DEF FONT_BASE      EQU 13
DEF TILE_DOS_PUNTOS EQU FONT_BASE + 36
DEF TILE_GUION      EQU FONT_BASE + 37
DEF TILE_BARRA      EQU FONT_BASE + 38
DEF TILE_PUNTO      EQU FONT_BASE + 39
DEF TILE_MAYOR      EQU FONT_BASE + 40


INCLUDE "../comun/cartucho.asm"

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "PAPERPLANES98"
    ds $0143 - @, 0
    db $80
    ds $0150 - @, 0

SECTION "Juego", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF
    call IniciarCartucho
    call ApagarLCDSeguro
    call LimpiarOAM
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

    ld a, 1
    ldh [rIE], a
    xor a
    ldh [rIF], a
    ld a, $93
    ldh [rLCDC], a
    ei

BuclePrincipal:
    halt
    call LeerJoypad

    ld a, [wFrame]
    inc a
    ld [wFrame], a

    ld a, [wInv]
    or a
    jr z, .estado
    dec a
    ld [wInv], a

.estado:
    ld a, [wEstado]
    cp ESTADO_TITULO
    jr z, EstadoTitulo
    cp ESTADO_JUEGO
    jr z, EstadoJuego
    jr EstadoFinal

EstadoTitulo:
    ld a, [wNewKeys]
    and KEY_START_A
    jr z, BuclePrincipal
    call IniciarPartida
    jr BuclePrincipal

EstadoJuego:
    call MoverAvion
    call AplicarViento
    call MoverHito

    ld a, [wEstado]
    cp ESTADO_JUEGO
    jr nz, BuclePrincipal

    call ComprobarColision

    ld a, [wEstado]
    cp ESTADO_JUEGO
    jr nz, BuclePrincipal

    call ComprobarPaso
    call ActualizarOAM
    jr BuclePrincipal

EstadoFinal:
    ld a, [wNewKeys]
    and KEY_START_A
    jr z, BuclePrincipal
    call IniciarPartida
    jr BuclePrincipal

IniciarPartida:
    call ApagarLCDSeguro
    call LimpiarOAM
    call LimpiarBG
    call DibujarFondoJuego

    ld a, ESTADO_JUEGO
    ld [wEstado], a
    xor a
    ld [wTipoHito], a
    ld [wScore], a
    ld [wPerfectos], a
    ld [wGateChecked], a
    ld [wLandCrashed], a
    ld [wInv], a
    ld [wPasoFrame], a

    ld a, 3
    ld [wVidas], a
    ld a, 40
    ld [wAvionX], a
    ld a, 80
    ld [wAvionY], a
    ld a, 216
    ld [wHitoX], a

    call DibujarHUD
    call ActualizarOAM
    call SonidoSalida

    ld a, $93
    ldh [rLCDC], a
    ret

PrepararTitulo:
    xor a
    ld [wEstado], a
    call LimpiarBG
    call DibujarFondoBase

    ld hl, TextoTitulo
    ld de, BG_MAP + (4 * 32) + 2
    call EscribirCadena
    ld hl, TextoNY1998
    ld de, BG_MAP + (7 * 32) + 3
    call EscribirCadena
    ld hl, TextoVolar
    ld de, BG_MAP + (10 * 32) + 2
    call EscribirCadena
    ld hl, TextoRuta1
    ld de, BG_MAP + (13 * 32) + 3
    call EscribirCadena
    ld hl, TextoRuta2
    ld de, BG_MAP + (14 * 32) + 2
    call EscribirCadena
    ret

PrepararFinal:
    call ApagarLCDSeguro
    call LimpiarOAM
    call LimpiarBG
    call DibujarFondoBase

    ld hl, TextoTitulo
    ld de, BG_MAP + (4 * 32) + 2
    call EscribirCadena

    ld a, [wEstado]
    cp ESTADO_CLEAR
    jr z, .clear
    ld hl, TextoCrumpled
    jr .mensaje
.clear:
    ld hl, TextoClear
.mensaje:
    ld de, BG_MAP + (7 * 32) + 3
    call EscribirCadena

    ld hl, TextoScore
    ld de, BG_MAP + (10 * 32) + 5
    call EscribirCadena
    ld a, [wScore]
    call EscribirDosDigitosFinal

    ld hl, TextoPerfect
    ld de, BG_MAP + (11 * 32) + 4
    call EscribirCadena
    ld a, [wPerfectos]
    call TileDigito
    ld [BG_MAP + (11 * 32) + 12], a

    ld hl, TextoAgain
    ld de, BG_MAP + (13 * 32) + 2
    call EscribirCadena

    ld a, $93
    ldh [rLCDC], a
    ret

MoverAvion:
    ; B pliega el avion: mantiene la altura actual y bloquea el viento.
    ; El mundo no se detiene, asi que hay que alinearse antes de estabilizar.
    ld a, [wKeys]
    and KEY_B
    ret nz

    ld a, [wKeys]
    and KEY_SUBIR
    jr z, .abajo
    ld a, [wAvionY]
    cp 42
    jr c, .abajo
    sub 2
    ld [wAvionY], a

.abajo:
    ld a, [wKeys]
    and KEY_DOWN
    jr z, .deriva
    ld a, [wAvionY]
    cp 126
    jr nc, .deriva
    add 2
    ld [wAvionY], a
    jr .horizontal

.deriva:
    ld a, [wKeys]
    and KEY_SUBIR
    jr nz, .horizontal
    ld a, [wFrame]
    and $03
    jr nz, .horizontal
    ld a, [wAvionY]
    cp 128
    jr nc, .horizontal
    inc a
    ld [wAvionY], a

.horizontal:
    ld a, [wKeys]
    and KEY_LEFT
    jr z, .derecha
    ld a, [wAvionX]
    cp 26
    jr c, .derecha
    dec a
    ld [wAvionX], a

.derecha:
    ld a, [wKeys]
    and KEY_RIGHT
    ret z
    ld a, [wAvionX]
    cp 64
    ret nc
    inc a
    ld [wAvionX], a
    ret

AplicarViento:
    ; B funciona como estabilizador: no corrige una mala trayectoria, solo
    ; conserva la posicion mientras se mantiene pulsado.
    ld a, [wKeys]
    and KEY_B
    ret nz

    ld a, [wTipoHito]
    ld e, a
    ld d, 0
    ld hl, MascaraViento
    add hl, de
    ld b, [hl]
    ld a, [wFrame]
    and b
    ret nz

    ld hl, DireccionViento
    add hl, de
    ld a, [hl]
    cp VIENTO_ARRIBA
    jr z, .arriba

.abajo:
    ld a, [wAvionY]
    cp 126
    ret nc
    inc a
    ld [wAvionY], a
    ret

.arriba:
    ld a, [wAvionY]
    cp 42
    ret c
    dec a
    ld [wAvionY], a
    ret

MoverHito:
    ld a, [wPasoFrame]
    xor 1
    ld [wPasoFrame], a
    ret nz

    ld a, [wHitoX]
    cp 8
    jr z, SiguienteHito
    dec a
    ld [wHitoX], a
    ret

SiguienteHito:
    ld a, [wTipoHito]
    cp 3
    jr z, .fin
    inc a
    ld [wTipoHito], a
    ld a, 216
    ld [wHitoX], a
    xor a
    ld [wGateChecked], a
    ld [wLandCrashed], a
    call DibujarHUD
    ret

.fin:
    ld a, ESTADO_CLEAR
    ld [wEstado], a
    call SonidoClear
    call PrepararFinal
    ret

ComprobarColision:
    ld a, [wInv]
    or a
    ret nz

    ld a, [wHitoX]
    ld b, a
    ld a, [wAvionX]
    cp b
    ret nc

    call ObtenerBaseX
    ld b, a
    ld a, [wAvionX]
    add 16
    cp b
    ret c

    ld a, [wTipoHito]
    ld e, a
    ld d, 0
    ld hl, CorredorTop
    add hl, de
    ld b, [hl]
    ld a, [wAvionY]
    cp b
    jr c, Choque

    ld hl, CorredorBottom
    add hl, de
    ld b, [hl]
    ld a, [wAvionY]
    cp b
    jr z, .ok
    jr c, .ok
    jr Choque
.ok:
    ret

Choque:
    ld a, 1
    ld [wLandCrashed], a
    ld a, 48
    ld [wInv], a
    ld a, 80
    ld [wAvionY], a

    ld a, [wVidas]
    dec a
    ld [wVidas], a
    call SonidoChoque
    call DibujarHUD
    ld a, [wVidas]
    or a
    ret nz

    ld a, ESTADO_CRASH
    ld [wEstado], a
    call PrepararFinal
    ret

ComprobarPaso:
    ld a, [wGateChecked]
    or a
    ret nz

    ld a, [wHitoX]
    ld b, a
    ld a, [wAvionX]
    cp b
    ret c

    ld a, 1
    ld [wGateChecked], a
    ld a, [wLandCrashed]
    or a
    ret nz

    call EsPasoPreciso
    jr nc, .normal

    ld a, [wScore]
    add 2
    ld [wScore], a
    ld a, [wPerfectos]
    inc a
    ld [wPerfectos], a
    call SonidoPrecision
    call DibujarHUD
    ret

.normal:
    ld a, [wScore]
    inc a
    ld [wScore], a
    call SonidoPaso
    call DibujarHUD
    ret

EsPasoPreciso:
    ld a, [wTipoHito]
    ld e, a
    ld d, 0
    ld hl, PrecisionTop
    add hl, de
    ld b, [hl]
    ld a, [wAvionY]
    cp b
    jr c, .no

    ld hl, PrecisionBottom
    add hl, de
    ld b, [hl]
    ld a, [wAvionY]
    cp b
    jr c, .si
    jr z, .si
.no:
    and a
    ret
.si:
    scf
    ret

ObtenerBaseX:
    ld a, [wTipoHito]
    ld e, a
    ld d, 0
    ld hl, AnchurasHito
    add hl, de
    ld b, [hl]
    ld a, [wHitoX]
    sub b
    ret

ActualizarOAM:
    call LimpiarOAM
    ld hl, OAM_BASE
    call DibujarAvion
    call DibujarHito
    ret

DibujarAvion:
    ld a, [wInv]
    or a
    jr z, .visible
    ld a, [wFrame]
    and $04
    ret nz

.visible:
    ld a, [wAvionY]
    ld b, a
    ld a, [wAvionX]
    ld e, a

    ld a, b
    ld b, e
    ld c, TILE_AVION_IZQ
    ld d, 0
    call PonerSprite

    ld a, e
    add 8
    ld b, a
    ld a, [wAvionY]
    ld c, TILE_AVION_DER
    ld d, 0
    call PonerSprite
    ret

DibujarHito:
    ; ObtenerBaseX consulta una tabla con HL; conservar el destino en OAM.
    push hl
    call ObtenerBaseX
    pop hl
    ld e, a
    ld a, [wTipoHito]
    or a
    jp z, DibujarLiberty
    cp 1
    jp z, DibujarWTC
    cp 2
    jp z, DibujarBridge
    jp DibujarEmpire

DibujarLiberty:
    ld d, 1
    ld c, TILE_EDIFICIO
    ld a, e
    ld b, a
    ld a, 128
    call PonerSprite
    ld a, e
    add 8
    ld b, a
    ld a, 128
    call PonerSprite
    ld a, e
    ld b, a
    ld a, 136
    call PonerSprite
    ld a, e
    add 8
    ld b, a
    ld a, 136
    call PonerSprite

    ld d, 2
    ld c, TILE_ESTATUA
    ld a, e
    add 4
    ld b, a
    ld a, 120
    call PonerSprite
    ld a, e
    add 4
    ld b, a
    ld a, 112
    call PonerSprite
    ld a, e
    add 4
    ld b, a
    ld a, 104
    call PonerSprite
    ld c, TILE_ANTORCHA
    ld a, e
    add 8
    ld b, a
    ld a, 96
    call PonerSprite
    ret

DibujarWTC:
    ld d, 1
    ld c, TILE_EDIFICIO

    ld a, e
    ld b, a
    ld a, 72
.wtc1:
    push af
    call PonerSprite
    pop af
    add 8
    cp 144
    jr c, .wtc1

    ld a, e
    add 16
    ld b, a
    ld a, 64
.wtc2:
    push af
    call PonerSprite
    pop af
    add 8
    cp 144
    jr c, .wtc2

    ld c, TILE_TEJADO
    ld a, e
    ld b, a
    ld a, 64
    call PonerSprite
    ld a, e
    add 16
    ld b, a
    ld a, 56
    call PonerSprite

    ld c, TILE_AGUJA
    ld a, e
    add 16
    ld b, a
    ld a, 48
    call PonerSprite
    ret

DibujarBridge:
    ld d, 3
    ld c, TILE_PUENTE
    ld a, e
    ld b, a
    ld a, 112
    call PonerSprite
    ld a, e
    add 8
    ld b, a
    ld a, 112
    call PonerSprite
    ld a, e
    add 16
    ld b, a
    ld a, 112
    call PonerSprite
    ld a, e
    add 24
    ld b, a
    ld a, 112
    call PonerSprite
    ld a, e
    add 32
    ld b, a
    ld a, 112
    call PonerSprite
    ld a, e
    add 40
    ld b, a
    ld a, 112
    call PonerSprite

    ld c, TILE_EDIFICIO
    ld a, e
    add 8
    ld b, a
    ld a, 80
    call PonerSprite
    ld a, 88
    call PonerSprite
    ld a, 96
    call PonerSprite
    ld a, 104
    call PonerSprite
    ld a, e
    add 32
    ld b, a
    ld a, 80
    call PonerSprite
    ld a, 88
    call PonerSprite
    ld a, 96
    call PonerSprite
    ld a, 104
    call PonerSprite

    ld c, TILE_CABLE
    ld a, e
    ld b, a
    ld a, 88
    call PonerSprite
    ld a, e
    add 16
    ld b, a
    ld a, 72
    call PonerSprite
    ld a, e
    add 24
    ld b, a
    ld a, 72
    call PonerSprite
    ld a, e
    add 40
    ld b, a
    ld a, 88
    call PonerSprite
    ret

DibujarEmpire:
    ld d, 1
    ld c, TILE_EDIFICIO

    ld a, 96
.empire_base:
    push af
    ld a, e
    ld b, a
    pop af
    push af
    call PonerSprite
    pop af
    push af
    ld a, e
    add 8
    ld b, a
    pop af
    push af
    call PonerSprite
    pop af
    add 8
    cp 144
    jr c, .empire_base

    ld c, TILE_TEJADO
    ld a, e
    add 4
    ld b, a
    ld a, 88
    call PonerSprite
    ld c, TILE_EDIFICIO
    ld a, e
    add 4
    ld b, a
    ld a, 80
    call PonerSprite
    ld a, 72
    call PonerSprite
    ld c, TILE_AGUJA
    ld a, e
    add 4
    ld b, a
    ld a, 64
    call PonerSprite
    ld a, 56
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

DibujarHUD:
    ; Una sola fila mantiene estado y deja el cielo libre para leer la ruta.
    ld a, [wTipoHito]
    and 1
    jr nz, .viento_abajo
    ld hl, TextoHUDUp
    jr .hud0
.viento_abajo:
    ld hl, TextoHUDDown
.hud0:
    ld de, BG_MAP
    call EscribirCadena

    ld a, [wVidas]
    call TileDigito
    ld [BG_MAP + 1], a

    ld a, [wTipoHito]
    inc a
    call TileDigito
    ld [BG_MAP + 8], a

    ld a, [wScore]
    ld b, 0
    cp 10
    jr c, .score_unidades
    sub 10
    inc b
.score_unidades:
    ld c, a
    ld a, b
    call TileDigito
    ld [BG_MAP + 13], a
    ld a, c
    call TileDigito
    ld [BG_MAP + 14], a

    ld a, [wPerfectos]
    call TileDigito
    ld [BG_MAP + 17], a
    ret

EscribirDosDigitosFinal:
    ld b, 0
    cp 10
    jr c, .unidad
    sub 10
    inc b
.unidad:
    ld c, a
    ld a, b
    call TileDigito
    ld [BG_MAP + (10 * 32) + 11], a
    ld a, c
    call TileDigito
    ld [BG_MAP + (10 * 32) + 12], a
    ret

TileDigito:
    add FONT_BASE
    ret

EscribirCadena:
.siguiente:
    ld a, [hli]
    or a
    ret z
    call CaracterATile
    ld [de], a
    inc de
    jr .siguiente

CaracterATile:
    cp $20
    jr z, .espacio
    cp $30
    jr c, .simbolos
    cp $3A
    jr nc, .letras
    sub $30
    add FONT_BASE
    ret
.letras:
    cp $41
    jr c, .simbolos
    cp $5B
    jr nc, .simbolos
    sub $41
    add FONT_BASE + 10
    ret
.simbolos:
    cp $3A
    jr z, .dos_puntos
    cp $2D
    jr z, .guion
    cp $2F
    jr z, .barra
    cp $2E
    jr z, .punto
    cp $3E
    jr z, .mayor
.espacio:
    xor a
    ret
.dos_puntos:
    ld a, TILE_DOS_PUNTOS
    ret
.guion:
    ld a, TILE_GUION
    ret
.barra:
    ld a, TILE_BARRA
    ret
.punto:
    ld a, TILE_PUNTO
    ret
.mayor:
    ld a, TILE_MAYOR
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

LimpiarOAM:
    ld hl, OAM_BASE
    ld b, 160
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

LimpiarBG:
    ld hl, BG_MAP
    ld bc, 32 * 32
.loop:
    ; La comprobacion de BC modifica A en cada vuelta.
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

DibujarFondoBase:
    ; Rompe el cielo plano con tres nubes, sin competir con los hitos.
    ld a, TILE_NUBE
    ld [BG_MAP + (5 * 32) + 2], a
    ld [BG_MAP + (8 * 32) + 15], a
    ld [BG_MAP + (11 * 32) + 7], a

    ld hl, BG_MAP + (15 * 32)
    ld b, 20
    ld a, TILE_SKYLINE
.skyline:
    ld [hli], a
    dec b
    jr nz, .skyline

    ; El tilemap mide 32 celdas por fila aunque solo 20 sean visibles.
    ; Dibujar 40 celdas seguidas producía una barra de agua de 32+8.
    ld hl, BG_MAP + (16 * 32)
    ld b, 20
    ld a, TILE_AGUA
.agua_superior:
    ld [hli], a
    dec b
    jr nz, .agua_superior

    ld hl, BG_MAP + (17 * 32)
    ld b, 20
    ld a, TILE_AGUA
.agua_inferior:
    ld [hli], a
    dec b
    jr nz, .agua_inferior
    ret

DibujarFondoJuego:
    call DibujarFondoBase

    ; Una segunda capa baja da masa al skyline sin tapar título/final.
    ld hl, BG_MAP + (14 * 32)
    ld b, 20
    ld a, TILE_EDIFICIO
.edificios:
    ld [hli], a
    dec b
    jr nz, .edificios
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
    ld a, $B2
    ldh [rNR12], a
    ld a, $C0
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoPaso:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $D1
    ldh [rNR12], a
    ld a, $70
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoPrecision:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $F1
    ldh [rNR12], a
    ld a, $D0
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoChoque:
    xor a
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $A2
    ldh [rNR12], a
    ld a, $30
    ldh [rNR13], a
    ld a, $84
    ldh [rNR14], a
    ret

SonidoClear:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $F2
    ldh [rNR12], a
    ld a, $E0
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SECTION "Datos", ROM0
AnchurasHito:
    db 16, 24, 48, 24

CorredorTop:
    db 40, 40, 72, 40
CorredorBottom:
    db 88, 64, 104, 68

; Ventana central que concede dos puntos y cuenta un paso perfecto.
PrecisionTop:
    db 58, 46, 82, 48
PrecisionBottom:
    db 70, 58, 94, 60

; Liberty/Bridge empujan hacia arriba cada 8 frames. WTC/Empire tienen
; rachas hacia abajo cada 4 frames, obligando a anticipar los corredores
; estrechos. B permite mantener altura, pero mientras se pulsa no se maniobra.
DireccionViento:
    db VIENTO_ARRIBA, VIENTO_ABAJO, VIENTO_ARRIBA, VIENTO_ABAJO
MascaraViento:
    db $07, $03, $07, $03

TextoTitulo:    db "PAPER PLANES 98", 0
TextoNY1998:   db "NEW YORK 1998", 0
TextoVolar:    db "A/UP FLY  B HOLD", 0
TextoRuta1:    db "LIBERTY > WTC", 0
TextoRuta2:    db "BRIDGE > EMPIRE", 0
TextoHUDUp:    db "F3 WUP G1/4 S00 P0", 0
TextoHUDDown:  db "F3 WDN G1/4 S00 P0", 0
TextoClear:    db "NYC CLEAR", 0
TextoCrumpled: db "PLANE CRUMPLED", 0
TextoScore:    db "SCORE 00", 0
TextoPerfect:  db "PERFECT 0/4", 0
TextoAgain:    db "A/START AGAIN", 0

Tiles:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    ; Silueta 16x8 más compacta: ambos bitplanes marcan contorno oscuro.
    db $01, $01, $03, $03, $0F, $0F, $FF, $FF, $0F, $0F, $03, $03, $00, $00, $00, $00
    db $00, $00, $80, $80, $C0, $C0, $FF, $FF, $FE, $FE, $FC, $FC, $F8, $F8, $38, $38
    db $FF, $FF, $DB, $99, $DB, $99, $FF, $FF, $B7, $B7, $B7, $B7, $FF, $FF, $B7, $B7
    db $18, $18, $3C, $3C, $7E, $7E, $FF, $FF, $FF, $FF, $B7, $B7, $B7, $B7, $FF, $FF
    db $18, $18, $18, $18, $18, $18, $3C, $3C, $3C, $3C, $7E, $7E, $FF, $FF, $FF, $FF
    db $18, $00, $38, $00, $38, $00, $18, $00, $3C, $00, $7E, $00, $38, $00, $38, $00
    db $08, $00, $1C, $00, $08, $00, $08, $00, $18, $00, $38, $00, $18, $00, $18, $00
    db $00, $00, $FF, $FF, $FF, $FF, $AA, $AA, $FF, $FF, $FF, $FF, $00, $00, $00, $00
    db $81, $81, $42, $42, $24, $24, $18, $18, $18, $18, $24, $24, $42, $42, $81, $81
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44, $00, $6E, $00, $FF, $00
    db $FF, $00, $00, $00, $00, $FF, $00, $00, $FF, $00, $00, $00, $00, $FF, $00, $00
    db $00, $00, $18, $00, $3C, $00, $7E, $00, $FF, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $38, $38, $44, $44, $4C, $4C, $54, $54, $64, $64, $44, $44, $38, $38
    db $00, $00, $10, $10, $30, $30, $10, $10, $10, $10, $10, $10, $10, $10, $38, $38
    db $00, $00, $38, $38, $44, $44, $04, $04, $08, $08, $10, $10, $20, $20, $7C, $7C
    db $00, $00, $78, $78, $04, $04, $04, $04, $38, $38, $04, $04, $04, $04, $78, $78
    db $00, $00, $08, $08, $18, $18, $28, $28, $48, $48, $7C, $7C, $08, $08, $08, $08
    db $00, $00, $7C, $7C, $40, $40, $40, $40, $78, $78, $04, $04, $04, $04, $78, $78
    db $00, $00, $38, $38, $40, $40, $40, $40, $78, $78, $44, $44, $44, $44, $38, $38
    db $00, $00, $7C, $7C, $04, $04, $08, $08, $10, $10, $20, $20, $20, $20, $20, $20
    db $00, $00, $38, $38, $44, $44, $44, $44, $38, $38, $44, $44, $44, $44, $38, $38
    db $00, $00, $38, $38, $44, $44, $44, $44, $3C, $3C, $04, $04, $04, $04, $38, $38
    db $00, $00, $38, $38, $44, $44, $44, $44, $7C, $7C, $44, $44, $44, $44, $44, $44
    db $00, $00, $78, $78, $44, $44, $44, $44, $78, $78, $44, $44, $44, $44, $78, $78
    db $00, $00, $3C, $3C, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3C, $3C
    db $00, $00, $78, $78, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $78, $78
    db $00, $00, $7C, $7C, $40, $40, $40, $40, $78, $78, $40, $40, $40, $40, $7C, $7C
    db $00, $00, $7C, $7C, $40, $40, $40, $40, $78, $78, $40, $40, $40, $40, $40, $40
    db $00, $00, $3C, $3C, $40, $40, $40, $40, $5C, $5C, $44, $44, $44, $44, $3C, $3C
    db $00, $00, $44, $44, $44, $44, $44, $44, $7C, $7C, $44, $44, $44, $44, $44, $44
    db $00, $00, $38, $38, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $38, $38
    db $00, $00, $04, $04, $04, $04, $04, $04, $04, $04, $44, $44, $44, $44, $38, $38
    db $00, $00, $44, $44, $48, $48, $50, $50, $60, $60, $50, $50, $48, $48, $44, $44
    db $00, $00, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $7C, $7C
    db $00, $00, $44, $44, $6C, $6C, $54, $54, $54, $54, $44, $44, $44, $44, $44, $44
    db $00, $00, $44, $44, $64, $64, $54, $54, $4C, $4C, $44, $44, $44, $44, $44, $44
    db $00, $00, $38, $38, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $38, $38
    db $00, $00, $78, $78, $44, $44, $44, $44, $78, $78, $40, $40, $40, $40, $40, $40
    db $00, $00, $38, $38, $44, $44, $44, $44, $44, $44, $54, $54, $48, $48, $34, $34
    db $00, $00, $78, $78, $44, $44, $44, $44, $78, $78, $50, $50, $48, $48, $44, $44
    db $00, $00, $3C, $3C, $40, $40, $40, $40, $38, $38, $04, $04, $04, $04, $78, $78
    db $00, $00, $7C, $7C, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    db $00, $00, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $38, $38
    db $00, $00, $44, $44, $44, $44, $44, $44, $44, $44, $44, $44, $28, $28, $10, $10
    db $00, $00, $44, $44, $44, $44, $54, $54, $54, $54, $6C, $6C, $44, $44, $44, $44
    db $00, $00, $44, $44, $44, $44, $28, $28, $10, $10, $28, $28, $44, $44, $44, $44
    db $00, $00, $44, $44, $44, $44, $28, $28, $10, $10, $10, $10, $10, $10, $10, $10
    db $00, $00, $7C, $7C, $04, $04, $08, $08, $10, $10, $20, $20, $40, $40, $7C, $7C
    db $00, $00, $00, $00, $10, $10, $10, $10, $00, $00, $10, $10, $10, $10, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $7C, $7C, $00, $00, $00, $00, $00, $00
    db $00, $00, $04, $04, $08, $08, $08, $08, $10, $10, $20, $20, $20, $20, $40, $40
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $10, $10, $10
    db $00, $00, $40, $40, $20, $20, $10, $10, $08, $08, $10, $10, $20, $20, $40, $40
TilesFin:

PaletaFondo:
    ; Azul cielo pálido en el color 0: conserva contraste sin fondo blanco lavado.
    dw $7F56, $7E40, $58A0, $0000
PaletaFondoFin:

PaletasObjetos:
    dw $7FFF, $7BDE, $02DF, $0000
    dw $7FFF, $56B5, $294A, $0000
    dw $7FFF, $4F5A, $22D2, $0000
    dw $7FFF, $2D5F, $14B5, $0000
PaletasObjetosFin:

SECTION "Variables", WRAM0
wEstado:       ds 1
wKeys:         ds 1
wPrevKeys:     ds 1
wNewKeys:      ds 1
wFrame:        ds 1
wPasoFrame:    ds 1
wAvionX:       ds 1
wAvionY:       ds 1
wHitoX:        ds 1
wTipoHito:     ds 1
wGateChecked:  ds 1
wLandCrashed:  ds 1
wScore:        ds 1
wPerfectos:    ds 1
wVidas:        ds 1
wInv:          ds 1
