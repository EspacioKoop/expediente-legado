; WEBKEEPER 98 - portero arcade GBC para SIGA-98 (#748)
; Kwaku, una arana suplente, defiende Web United durante tres partidos cortos.
; El juego prima lectura y contraengano: los amagos siempre revelan el destino
; real con margen suficiente y tras dos derrotas se activa ayuda adicional.
; Codigo, texto y pixel-art originales del proyecto. Licencia MIT.

DEF rP1    EQU $FF00
DEF rIF    EQU $FF0F
DEF rLCDC  EQU $FF40
DEF rSCY   EQU $FF42
DEF rSCX   EQU $FF43
DEF rLY    EQU $FF44
DEF rBGP   EQU $FF47
DEF rOBP0  EQU $FF48
DEF rBCPS  EQU $FF68
DEF rBCPD  EQU $FF69
DEF rOCPS  EQU $FF6A
DEF rOCPD  EQU $FF6B
DEF rIE    EQU $FFFF

DEF BG_MAP     EQU $9800
DEF VRAM_TILES EQU $8000
DEF OAM_BASE   EQU $FE00

DEF KEY_RIGHT EQU %00000001
DEF KEY_LEFT  EQU %00000010
DEF KEY_UP    EQU %00000100
DEF KEY_DOWN  EQU %00001000
DEF KEY_A     EQU %00010000
DEF KEY_B     EQU %00100000
DEF KEY_START EQU %10000000

DEF ESTADO_TITULO   EQU 0
DEF ESTADO_HISTORIA EQU 1
DEF ESTADO_PARTIDO  EQU 2
DEF ESTADO_DERROTA  EQU 3
DEF ESTADO_VICTORIA EQU 4

DEF CARRIL_IZQ    EQU 0
DEF CARRIL_CENTRO EQU 1
DEF CARRIL_DER    EQU 2
DEF ALTURA_RASO   EQU 0
DEF ALTURA_ALTO   EQU 1

DEF FRAMES_TELEGRAFO EQU 90
DEF FRAMES_REVELADO  EQU 40
DEF VENTANA_PARADA   EQU 45
DEF VENTANA_RED      EQU 60
DEF RECARGA_RED      EQU 180
DEF MARCA_COMPLETADO EQU $A5

DEF TILE_VACIO   EQU 0
DEF TILE_ARANA   EQU 1
DEF TILE_BALON   EQU 2
DEF TILE_POSTE   EQU 3
DEF TILE_RED     EQU 4
DEF TILE_LINEA   EQU 5
DEF TILE_DIGITO0 EQU 6
DEF TILE_A       EQU 16
DEF TILE_EXCL    EQU 42
DEF TILE_PUNTO   EQU 43
DEF TILE_DOSPT   EQU 44
DEF TILE_GUION   EQU 45


INCLUDE "../comun/pantalla_cgb.asm"

SECTION "VBlank", ROM0[$0040]
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "WEBKEEPER98"
    ds $0143 - @, 0
    db $80
    ds $0150 - @, 0

SECTION "Juego", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF
    xor a
    ld [wTituloCGB], a
    ld [wWebkeeperCompletado], a
    ld [wEstado], a
    ld [wPartido], a
    ld [wDerrotasPartido], a
    ld [wAyuda], a
    ld [wTeclas], a
    ld [wTeclasPrevias], a
    ld [wTeclasNuevas], a
    ldh [rSCX], a
    ldh [rSCY], a

.espera_vblank:
    ldh a, [rLY]
    cp 144
    jr c, .espera_vblank

    xor a
    ldh [rLCDC], a
    ldh [rIF], a
    call LimpiarOAM
    call CargarTiles
    call ConfigurarPaletas
    call MostrarTitulo

    ld a, 1
    ldh [rIE], a
    xor a
    ldh [rIF], a
    ei

BuclePrincipal:
    halt
    call LeerControles

    ld a, [wEstado]
    cp ESTADO_TITULO
    jr z, EstadoTitulo
    cp ESTADO_HISTORIA
    jr z, EstadoHistoria
    cp ESTADO_PARTIDO
    jr z, EstadoPartido
    cp ESTADO_DERROTA
    jr z, EstadoDerrota
    jr EstadoVictoria

EstadoTitulo:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, BuclePrincipal
    xor a
    ld [wPartido], a
    ld [wDerrotasPartido], a
    ld [wAyuda], a
    call MostrarHistoria
    jr BuclePrincipal

EstadoHistoria:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, BuclePrincipal
    call IniciarPartido
    jr BuclePrincipal

EstadoPartido:
    call ActualizarPartido
    jr BuclePrincipal

EstadoDerrota:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, BuclePrincipal
    call IniciarPartido
    jr BuclePrincipal

EstadoVictoria:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, BuclePrincipal
    call MostrarTitulo
    jr BuclePrincipal

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

MostrarTitulo:
    call DesactivarLCD
    call LimpiarFondo
    call LimpiarOAM

    call EsCGB
    jr nz, .texto
    ld hl, TituloCGB
    call CargarPantallaCGB
    ld a, 1
    ld [wTituloCGB], a
    jr .estado
.texto:
    ld hl, BG_MAP + 4 * 32 + 4
    ld de, TextoTitulo
    call EscribirTexto
    ld hl, BG_MAP + 7 * 32 + 3
    ld de, TextoSubtitulo
    call EscribirTexto
    ld hl, BG_MAP + 12 * 32 + 5
    ld de, TextoPulsaA
    call EscribirTexto

.estado:
    ld a, ESTADO_TITULO
    ld [wEstado], a
    call ActivarLCD
    ret

MostrarHistoria:
    call DesactivarLCD
    call LimpiarFondo
    call LimpiarOAM

    ld a, [wPartido]
    or a
    jr z, .debut
    cp 1
    jr z, .tramposos

.final:
    ld hl, BG_MAP + 4 * 32 + 6
    ld de, TextoFinal
    call EscribirTexto
    ld hl, BG_MAP + 7 * 32 + 2
    ld de, TextoMiraAntes
    call EscribirTexto
    ld hl, BG_MAP + 10 * 32 + 2
    ld de, TextoNoSaltes
    call EscribirTexto
    jr .fin

.debut:
    ld hl, BG_MAP + 4 * 32 + 3
    ld de, TextoKwakuArco
    call EscribirTexto
    ld hl, BG_MAP + 7 * 32 + 2
    ld de, TextoOchoPatas
    call EscribirTexto
    ld hl, BG_MAP + 10 * 32 + 3
    ld de, TextoTresDeSeis
    call EscribirTexto
    jr .fin

.tramposos:
    ld hl, BG_MAP + 4 * 32 + 4
    ld de, TextoNoSuerte
    call EscribirTexto
    ld hl, BG_MAP + 7 * 32 + 2
    ld de, TextoVienenAmagos
    call EscribirTexto
    ld hl, BG_MAP + 10 * 32 + 3
    ld de, TextoCuatroDeOcho
    call EscribirTexto

.fin:
    ld hl, BG_MAP + 14 * 32 + 5
    ld de, TextoPulsaA
    call EscribirTexto
    ld a, ESTADO_HISTORIA
    ld [wEstado], a
    call ActivarLCD
    ret

MostrarDerrota:
    call DesactivarLCD
    call LimpiarFondo
    call LimpiarOAM

    ld hl, BG_MAP + 4 * 32 + 5
    ld de, TextoOtraVez
    call EscribirTexto
    ld hl, BG_MAP + 7 * 32 + 1
    ld de, TextoMismoPartido
    call EscribirTexto

    ld a, [wAyuda]
    or a
    jr z, .sin_ayuda
    ld hl, BG_MAP + 10 * 32 + 2
    ld de, TextoPista
    call EscribirTexto
.sin_ayuda:
    ld hl, BG_MAP + 14 * 32 + 5
    ld de, TextoReintenta
    call EscribirTexto

    ld a, ESTADO_DERROTA
    ld [wEstado], a
    call ActivarLCD
    ret

MostrarVictoria:
    call DesactivarLCD
    call LimpiarFondo
    call LimpiarOAM

    ld hl, BG_MAP + 4 * 32 + 5
    ld de, TextoCampeones
    call EscribirTexto
    ld hl, BG_MAP + 8 * 32 + 1
    ld de, TextoMejorRed
    call EscribirTexto
    ld hl, BG_MAP + 11 * 32 + 3
    ld de, TextoNoSeVe
    call EscribirTexto
    ld hl, BG_MAP + 15 * 32 + 5
    ld de, TextoPulsaA
    call EscribirTexto

    ld a, ESTADO_VICTORIA
    ld [wEstado], a
    call ActivarLCD
    ret

IniciarPartido:
    call DesactivarLCD
    call LimpiarFondo
    call LimpiarOAM
    call DibujarPorteria

    ld a, CARRIL_CENTRO
    ld [wPorteroCarril], a
    xor a
    ld [wPorteroAltura], a
    ld [wTiro], a
    ld [wParadas], a
    ld [wVentanaParada], a
    ld [wVentanaRed], a
    ld [wRecargaRed], a

    ld a, [wDerrotasPartido]
    cp 2
    jr c, .sin_ayuda
    ld a, 1
    jr .guardar_ayuda
.sin_ayuda:
    xor a
.guardar_ayuda:
    ld [wAyuda], a

    call DibujarHUD
    call PrepararTiro
    call ActualizarOAM
    ld a, ESTADO_PARTIDO
    ld [wEstado], a
    call ActivarLCD
    ret

ActualizarPartido:
    call TickVentanas
    call MoverPortero
    call AccionesPortero

    ld a, [wTimerTiro]
    or a
    jr z, .resolver
    dec a
    ld [wTimerTiro], a
    call ActualizarOAM
    ret

.resolver:
    call ResolverTiro
    ret

TickVentanas:
    ld a, [wVentanaParada]
    or a
    jr z, .red
    dec a
    ld [wVentanaParada], a
.red:
    ld a, [wVentanaRed]
    or a
    jr z, .recarga
    dec a
    ld [wVentanaRed], a
.recarga:
    ld a, [wRecargaRed]
    or a
    ret z
    dec a
    ld [wRecargaRed], a
    ret

MoverPortero:
    ld a, [wTeclasNuevas]
    bit 1, a
    jr z, .derecha
    ld a, [wPorteroCarril]
    or a
    jr z, .derecha
    dec a
    ld [wPorteroCarril], a
.derecha:
    ld a, [wTeclasNuevas]
    bit 0, a
    jr z, .arriba
    ld a, [wPorteroCarril]
    cp CARRIL_DER
    jr z, .arriba
    inc a
    ld [wPorteroCarril], a
.arriba:
    ld a, [wTeclasNuevas]
    bit 2, a
    jr z, .abajo
    ld a, ALTURA_ALTO
    ld [wPorteroAltura], a
.abajo:
    ld a, [wTeclasNuevas]
    bit 3, a
    ret z
    xor a
    ld [wPorteroAltura], a
    ret

AccionesPortero:
    ld a, [wTeclasNuevas]
    and KEY_A
    jr z, .red
    ld a, VENTANA_PARADA
    ld [wVentanaParada], a
.red:
    ld a, [wTeclasNuevas]
    and KEY_B
    ret z
    ld a, [wRecargaRed]
    or a
    ret nz
    ld a, VENTANA_RED
    ld [wVentanaRed], a
    ld a, RECARGA_RED
    ld [wRecargaRed], a
    ret

PrepararTiro:
    call CargarDatosTiro
    ld a, FRAMES_TELEGRAFO
    ld [wTimerTiro], a
    ret

CargarDatosTiro:
    ld a, [wPartido]
    or a
    jr z, .m1
    cp 1
    jr z, .m2
    ld hl, TirosFinal
    jr .indice
.m1:
    ld hl, TirosDebut
    jr .indice
.m2:
    ld hl, TirosTramposos
.indice:
    ld a, [wTiro]
    ld c, a
    ld b, 0
    add hl, bc
    add hl, bc
    add hl, bc

    ld a, [hli]
    ld [wObjetivoCarril], a
    ld a, [hli]
    ld [wObjetivoAltura], a
    ld a, [hl]
    ld [wTiroAmago], a

    ld a, [wObjetivoCarril]
    cp CARRIL_IZQ
    jr z, .falso_der
    cp CARRIL_DER
    jr z, .falso_izq
    ld a, CARRIL_CENTRO
    jr .guardar_falso
.falso_der:
    ld a, CARRIL_DER
    jr .guardar_falso
.falso_izq:
    xor a
.guardar_falso:
    ld [wFalsoCarril], a
    ld a, [wObjetivoAltura]
    xor 1
    ld [wFalsoAltura], a
    ret

ResolverTiro:
    xor a
    ld [wUltimoFueParada], a

    ld a, [wVentanaRed]
    or a
    jr z, .probar_estirada
    ld a, [wPorteroCarril]
    ld b, a
    ld a, [wObjetivoCarril]
    cp b
    jr z, .parada

.probar_estirada:
    ld a, [wVentanaParada]
    or a
    jr z, .fallo
    ld a, [wPorteroCarril]
    ld b, a
    ld a, [wObjetivoCarril]
    cp b
    jr nz, .fallo
    ld a, [wPorteroAltura]
    ld b, a
    ld a, [wObjetivoAltura]
    cp b
    jr nz, .fallo

.parada:
    ld hl, wParadas
    inc [hl]
    ld a, 1
    ld [wUltimoFueParada], a
.fallo:
    ld hl, wTiro
    inc [hl]
    xor a
    ld [wVentanaParada], a
    ld [wVentanaRed], a
    call DibujarHUD

    call TotalTirosActual
    ld b, a
    ld a, [wTiro]
    cp b
    jr nc, FinalizarPartido

    call PrepararTiro
    call ActualizarOAM
    ret

FinalizarPartido:
    call ParadasNecesariasActual
    ld b, a
    ld a, [wParadas]
    cp b
    jr c, .derrota

    ld a, [wPartido]
    cp 2
    jr z, .campeon
    inc a
    ld [wPartido], a
    xor a
    ld [wDerrotasPartido], a
    ld [wAyuda], a
    call MostrarHistoria
    ret

.derrota:
    ld hl, wDerrotasPartido
    inc [hl]
    ld a, [hl]
    cp 2
    jr c, .mostrar_derrota
    ld a, 1
    ld [wAyuda], a
.mostrar_derrota:
    call MostrarDerrota
    ret

.campeon:
    ld a, MARCA_COMPLETADO
    ld [wWebkeeperCompletado], a
    call MostrarVictoria
    ret

TotalTirosActual:
    ld a, [wPartido]
    or a
    jr z, .seis
    cp 1
    jr z, .ocho
    ld a, 9
    ret
.seis:
    ld a, 6
    ret
.ocho:
    ld a, 8
    ret

ParadasNecesariasActual:
    ld a, [wPartido]
    or a
    jr z, .tres
    cp 1
    jr z, .cuatro
    ld a, 5
    ret
.tres:
    ld a, 3
    ret
.cuatro:
    ld a, 4
    ret

DibujarPorteria:
    ld hl, BG_MAP + 5 * 32 + 4
    ld b, 12
    ld a, TILE_LINEA
.top:
    ld [hli], a
    dec b
    jr nz, .top

    ld c, 6
    ld hl, BG_MAP + 6 * 32 + 4
.izq:
    ld a, TILE_POSTE
    ld [hl], a
    ld de, 32
    add hl, de
    dec c
    jr nz, .izq

    ld c, 6
    ld hl, BG_MAP + 6 * 32 + 15
.der:
    ld a, TILE_POSTE
    ld [hl], a
    ld de, 32
    add hl, de
    dec c
    jr nz, .der

    ld c, 5
    ld hl, BG_MAP + 6 * 32 + 5
.fila_red:
    push hl
    ld b, 10
.col_red:
    ld a, TILE_RED
    ld [hli], a
    dec b
    jr nz, .col_red
    pop hl
    ld de, 32
    add hl, de
    dec c
    jr nz, .fila_red
    ret

DibujarHUD:
    ld hl, BG_MAP
    ld de, TextoMarcador
    call EscribirTexto

    ld a, [wPartido]
    inc a
    add TILE_DIGITO0
    ld [BG_MAP + 1], a

    ld a, [wTiro]
    add TILE_DIGITO0
    ld [BG_MAP + 4], a
    call TotalTirosActual
    add TILE_DIGITO0
    ld [BG_MAP + 6], a

    ld a, [wParadas]
    add TILE_DIGITO0
    ld [BG_MAP + 9], a
    call ParadasNecesariasActual
    add TILE_DIGITO0
    ld [BG_MAP + 11], a

    ld a, [wAyuda]
    or a
    jr z, .sin_ayuda
    ld a, TILE_A
    ld [BG_MAP + 19], a
    ret
.sin_ayuda:
    xor a
    ld [BG_MAP + 19], a
    ret

ActualizarOAM:
    ld a, [wPorteroAltura]
    or a
    jr z, .arana_rasa
    ld a, 80
    jr .arana_y
.arana_rasa:
    ld a, 112
.arana_y:
    ld [OAM_BASE], a

    ld a, [wPorteroCarril]
    call XDeCarril
    ld [OAM_BASE + 1], a
    ld a, TILE_ARANA
    ld [OAM_BASE + 2], a
    xor a
    ld [OAM_BASE + 3], a

    ld a, [wObjetivoCarril]
    ld b, a
    ld a, [wObjetivoAltura]
    ld c, a

    ld a, [wTiroAmago]
    or a
    jr z, .destino_listo
    ld a, [wAyuda]
    or a
    jr nz, .destino_listo
    ld a, [wTimerTiro]
    cp FRAMES_REVELADO + 1
    jr c, .destino_listo
    ld a, [wFalsoCarril]
    ld b, a
    ld a, [wFalsoAltura]
    ld c, a

.destino_listo:
    ld a, c
    or a
    jr z, .balon_raso
    ld a, 64
    jr .balon_y
.balon_raso:
    ld a, 96
.balon_y:
    ld [OAM_BASE + 4], a
    ld a, b
    call XDeCarril
    ld [OAM_BASE + 5], a
    ld a, TILE_BALON
    ld [OAM_BASE + 6], a
    xor a
    ld [OAM_BASE + 7], a

    ld a, [wVentanaRed]
    or a
    jr z, .ocultar_red
    ld a, [OAM_BASE]
    ld [OAM_BASE + 8], a
    ld a, [OAM_BASE + 1]
    add 8
    ld [OAM_BASE + 9], a
    ld a, TILE_RED
    ld [OAM_BASE + 10], a
    xor a
    ld [OAM_BASE + 11], a
    ret
.ocultar_red:
    xor a
    ld [OAM_BASE + 8], a
    ld [OAM_BASE + 9], a
    ret

XDeCarril:
    or a
    jr z, .izq
    cp 1
    jr z, .centro
    ld a, 120
    ret
.izq:
    ld a, 48
    ret
.centro:
    ld a, 84
    ret

DesactivarLCD:
    ldh a, [rLCDC]
    bit 7, a
    ret z
.espera:
    ldh a, [rLY]
    cp 144
    jr c, .espera
    xor a
    ldh [rLCDC], a
    ret

ActivarLCD:
    ld a, $93
    ldh [rLCDC], a
    ret

LimpiarFondo:
    ; Al salir del título a pantalla completa se recuperan tiles, paleta y
    ; atributos del juego antes de dibujar nada (#808).
    ld a, [wTituloCGB]
    or a
    jr z, .limpiar
    xor a
    ld [wTituloCGB], a
    call DescargarPantallaCGB
    call CargarTiles
    call ConfigurarPaletas
.limpiar:
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

ConfigurarPaletas:
    ; DMG: el índice 1 del fondo (tinta) pasa a negro para que se lea (#805).
    ld a, %11101100
    ldh [rBGP], a
    ld a, %11100100
    ldh [rOBP0], a

    ld a, $80
    ldh [rBCPS], a
    ld hl, PaletaBG
    ld b, 8
.bg:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .bg

    ld a, $80
    ldh [rOCPS], a
    ld hl, PaletaOBJ
    ld b, 8
.obj:
    ld a, [hli]
    ldh [rOCPD], a
    dec b
    jr nz, .obj
    ret

EscribirTexto:
.loop:
    ld a, [de]
    inc de
    or a
    ret z
    cp $20
    jr z, .espacio
    cp $30
    jr c, .simbolo
    cp $3A
    jr nc, .letra
    sub $30
    add TILE_DIGITO0
    jr .poner
.letra:
    cp $41
    jr c, .simbolo
    cp $5B
    jr nc, .simbolo
    sub $41
    add TILE_A
    jr .poner
.simbolo:
    cp $21
    jr z, .excl
    cp $2E
    jr z, .punto
    cp $3A
    jr z, .dospt
    cp $2D
    jr z, .guion
.espacio:
    xor a
    jr .poner
.excl:
    ld a, TILE_EXCL
    jr .poner
.punto:
    ld a, TILE_PUNTO
    jr .poner
.dospt:
    ld a, TILE_DOSPT
    jr .poner
.guion:
    ld a, TILE_GUION
.poner:
    ld [hli], a
    jr .loop

TirosDebut:
    db 1, 0, 0
    db 0, 1, 0
    db 2, 0, 0
    db 1, 1, 0
    db 0, 0, 0
    db 2, 1, 0

TirosTramposos:
    db 0, 0, 1
    db 2, 1, 0
    db 1, 0, 1
    db 0, 1, 0
    db 2, 0, 1
    db 1, 1, 0
    db 2, 1, 1
    db 0, 0, 0

TirosFinal:
    db 1, 0, 1
    db 0, 1, 0
    db 2, 0, 1
    db 1, 1, 0
    db 0, 0, 1
    db 2, 1, 0
    db 1, 0, 1
    db 2, 0, 0
    db 0, 1, 1

TextoTitulo:        db "WEBKEEPER 98", 0
TextoSubtitulo:     db "OCHO PATAS. UN ARCO.", 0
TextoPulsaA:        db "A PARA SEGUIR", 0
TextoKwakuArco:     db "KWAKU, AL ARCO!", 0
TextoOchoPatas:     db "TIENES OCHO PATAS.", 0
TextoTresDeSeis:    db "PARA 3 DE 6", 0
TextoNoSuerte:      db "NO FUE SUERTE.", 0
TextoVienenAmagos:  db "AHORA VIENEN AMAGOS.", 0
TextoCuatroDeOcho:  db "PARA 4 DE 8", 0
TextoFinal:         db "LA FINAL", 0
TextoMiraAntes:     db "MIRA ANTES DE SALTAR.", 0
TextoNoSaltes:      db "5 DE 9. SIN PRISA.", 0
TextoOtraVez:       db "OTRA VEZ.", 0
TextoMismoPartido:  db "REPITES ESTE PARTIDO.", 0
TextoPista:         db "PISTA: MIRA EL BALON.", 0
TextoReintenta:     db "A PARA REINTENTAR", 0
TextoCampeones:     db "CAMPEONES!", 0
TextoMejorRed:      db "LA MEJOR RED", 0
TextoNoSeVe:        db "NO SIEMPRE SE VE.", 0
TextoMarcador:      db "P0 T0-0 S0-0", 0

Tiles:
    ds 16, 0
    db $00,$00,$24,$24,$18,$18,$7E,$7E,$DB,$DB,$7E,$7E,$18,$18,$42,$42
    db $00,$00,$18,$18,$3C,$3C,$7E,$7E,$66,$66,$7E,$7E,$3C,$3C,$18,$18
    db $18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18
    db $81,$81,$42,$42,$24,$24,$18,$18,$18,$18,$24,$24,$42,$42,$81,$81
    db $00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00

    db $3C,0,$66,0,$6E,0,$76,0,$66,0,$66,0,$3C,0,$00,0
    db $18,0,$38,0,$18,0,$18,0,$18,0,$18,0,$7E,0,$00,0
    db $3C,0,$66,0,$06,0,$0C,0,$30,0,$60,0,$7E,0,$00,0
    db $3C,0,$66,0,$06,0,$1C,0,$06,0,$66,0,$3C,0,$00,0
    db $0C,0,$1C,0,$3C,0,$6C,0,$7E,0,$0C,0,$0C,0,$00,0
    db $7E,0,$60,0,$7C,0,$06,0,$06,0,$66,0,$3C,0,$00,0
    db $1C,0,$30,0,$60,0,$7C,0,$66,0,$66,0,$3C,0,$00,0
    db $7E,0,$06,0,$0C,0,$18,0,$30,0,$30,0,$30,0,$00,0
    db $3C,0,$66,0,$66,0,$3C,0,$66,0,$66,0,$3C,0,$00,0
    db $3C,0,$66,0,$66,0,$3E,0,$06,0,$0C,0,$38,0,$00,0

    db $18,0,$3C,0,$66,0,$66,0,$7E,0,$66,0,$66,0,$00,0
    db $7C,0,$66,0,$66,0,$7C,0,$66,0,$66,0,$7C,0,$00,0
    db $3C,0,$66,0,$60,0,$60,0,$60,0,$66,0,$3C,0,$00,0
    db $78,0,$6C,0,$66,0,$66,0,$66,0,$6C,0,$78,0,$00,0
    db $7E,0,$60,0,$60,0,$7C,0,$60,0,$60,0,$7E,0,$00,0
    db $7E,0,$60,0,$60,0,$7C,0,$60,0,$60,0,$60,0,$00,0
    db $3C,0,$66,0,$60,0,$6E,0,$66,0,$66,0,$3C,0,$00,0
    db $66,0,$66,0,$66,0,$7E,0,$66,0,$66,0,$66,0,$00,0
    db $3C,0,$18,0,$18,0,$18,0,$18,0,$18,0,$3C,0,$00,0
    db $1E,0,$0C,0,$0C,0,$0C,0,$0C,0,$6C,0,$38,0,$00,0
    db $66,0,$6C,0,$78,0,$70,0,$78,0,$6C,0,$66,0,$00,0
    db $60,0,$60,0,$60,0,$60,0,$60,0,$60,0,$7E,0,$00,0
    db $63,0,$77,0,$7F,0,$6B,0,$63,0,$63,0,$63,0,$00,0
    db $66,0,$76,0,$7E,0,$7E,0,$6E,0,$66,0,$66,0,$00,0
    db $3C,0,$66,0,$66,0,$66,0,$66,0,$66,0,$3C,0,$00,0
    db $7C,0,$66,0,$66,0,$7C,0,$60,0,$60,0,$60,0,$00,0
    db $3C,0,$66,0,$66,0,$66,0,$6E,0,$6C,0,$36,0,$00,0
    db $7C,0,$66,0,$66,0,$7C,0,$78,0,$6C,0,$66,0,$00,0
    db $3C,0,$66,0,$60,0,$3C,0,$06,0,$66,0,$3C,0,$00,0
    db $7E,0,$18,0,$18,0,$18,0,$18,0,$18,0,$18,0,$00,0
    db $66,0,$66,0,$66,0,$66,0,$66,0,$66,0,$3C,0,$00,0
    db $66,0,$66,0,$66,0,$66,0,$66,0,$3C,0,$18,0,$00,0
    db $63,0,$63,0,$63,0,$6B,0,$7F,0,$77,0,$63,0,$00,0
    db $66,0,$66,0,$3C,0,$18,0,$3C,0,$66,0,$66,0,$00,0
    db $66,0,$66,0,$66,0,$3C,0,$18,0,$18,0,$18,0,$00,0
    db $7E,0,$06,0,$0C,0,$18,0,$30,0,$60,0,$7E,0,$00,0

    db $18,0,$18,0,$18,0,$18,0,$18,0,$00,0,$18,0,$00,0
    db $00,0,$00,0,$00,0,$00,0,$00,0,$00,0,$18,0,$00,0
    db $00,0,$18,0,$18,0,$00,0,$00,0,$18,0,$18,0,$00,0
    db $00,0,$00,0,$00,0,$7E,0,$00,0,$00,0,$00,0,$00,0
TilesFin:

PaletaBG:
    ; El color 1 es la tinta del texto y la portería (#805): en gris claro no se
    ; leía. Blanco, azul noche, gris oscuro, negro.
    dw $7FFF, $3084, $294A, $0000
PaletaOBJ:
    dw $7FFF, $03FF, $001F, $0000

SECTION "Handshake", WRAM0[$C100]
wWebkeeperCompletado: ds 1
wEstado:               ds 1
wPartido:              ds 1
wDerrotasPartido:      ds 1
wAyuda:                ds 1
wTeclas:               ds 1
wTeclasPrevias:        ds 1
wTeclasNuevas:         ds 1
wPorteroCarril:        ds 1
wPorteroAltura:        ds 1
wTiro:                 ds 1
wParadas:              ds 1
wTimerTiro:            ds 1
wObjetivoCarril:       ds 1
wObjetivoAltura:       ds 1
wTiroAmago:            ds 1
wFalsoCarril:          ds 1
wFalsoAltura:          ds 1
wVentanaParada:        ds 1
wVentanaRed:           ds 1
wRecargaRed:           ds 1
wUltimoFueParada:      ds 1
FinWRAM:

; Título a pantalla completa (#808): si el fondo la tiene cargada, para
; devolverle sus tiles al juego al salir.
SECTION "TituloCGBVars", WRAM0
wTituloCGB:  ds 1

SECTION "TituloCGB", ROMX
    PANTALLA_CGB TituloCGB, "assets/titulo"
