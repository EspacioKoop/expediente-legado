; RYU_FLOW - micro-ROM GBC para SIGA-98 (#440)
; Codigo y graficos originales del proyecto; licencia segun LICENSE en la raiz.
;
; El jugador debe reorientar tres compuertas. Cada nivel arranca con las tres
; incorrectas y solo se supera cuando las tres han sido manipuladas y el cauce
; coincide con su solucion declarativa. En Game Boy Color hay tres niveles
; (dia, amanecer y noche, #808); en Game Boy clasica, solo el primero. La
; finalizacion se marca al superar el ultimo. Arrancar y salir no cuenta.

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
; Los sprites se escriben en una OAM en sombra y el bucle principal la vuelca
; nada más despertar en VBlank: así se pueden mover en cualquier momento del
; fotograma. (Con DMA desde la interrupción el núcleo de la portátil dejaba de
; leer los controles.)
DEF OAM_BASE   EQU $C200
DEF OAM_REAL   EQU $FE00
DEF SPRITES_VOLCADOS EQU 8

DEF ESTADO_TITULO EQU 0
DEF ESTADO_JUEGO  EQU 1
DEF ESTADO_FIN    EQU 2
DEF ESTADO_DIALOGO EQU 3

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

; Estado de cada compuerta. En Game Boy clasica abierta es la curva arriba y
; cerrada la curva abajo.
DEF ABIERTA EQU 0
DEF MEDIA   EQU 1
DEF CERRADA EQU 2
DEF TODAS_TOCADAS        EQU %00000111
DEF NUM_NIVELES          EQU 3
DEF NIVEL_TAM            EQU 10
DEF NIVEL_ACOPLADO       EQU 3
DEF NIVEL_INICIAL        EQU 4
DEF NIVEL_SOLUCION       EQU 7
DEF ESPERA_NIVEL         EQU 45
DEF MARCA_COMPLETADO     EQU $A5

; Arte de la lámina en Game Boy Color (#808).
DEF PRIMER_TILE_SPRITE EQU 240 ; banco 1 de VRAM, tras los tiles de la pantalla
DEF TILE_SPRITE_CURSOR EQU PRIMER_TILE_SPRITE + 10
DEF ATRIB_CIFRA        EQU %00001000 ; banco 1, paleta 0
DEF ATRIB_CURSOR       EQU %00001001 ; banco 1, paleta 1
DEF CURSOR_Y           EQU 34 + 16
DEF CIFRAS_Y           EQU 130 + 16
DEF DRAGONES_X         EQU 108 + 8
DEF NIVEL_X            EQU 19 + 8
DEF NIVEL_Y            EQU 132 + 16
DEF MOVIMIENTOS_X      EQU 140 + 8


INCLUDE "../comun/pantalla_cgb.asm"

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
    xor a
    ld [wPantallaCGB], a

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
    call VolcarOAM
    call LeerControles

    ld a, [wEstado]
    or a
    jr z, EstadoTitulo
    cp ESTADO_JUEGO
    jr z, EstadoJuego
    cp ESTADO_DIALOGO
    jr z, EstadoDialogo
    jr EstadoFin

EstadoTitulo:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jp z, Bucle
    call SonidoInicio
    call IniciarJuego
    jp Bucle

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
    call PulsarCompuerta
    call SumarMovimiento
    call SonidoCompuerta
    call ActualizarCompuertas
    call ComprobarSolucion

.cursor:
    call ActualizarCursor
    jp Bucle

; El anciano habla al empezar cada nivel; A o Start cierra el cuadro.
EstadoDialogo:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jp z, Bucle
    call CerrarDialogo
    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ActualizarCursor
    jp Bucle

EstadoFin:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jp z, Bucle
    call SonidoInicio
    call IniciarJuego
    jp Bucle

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
    xor a
    ld [wNivel], a
    ld [wRyuFlowCompletado], a
    ; sigue en IniciarNivel

IniciarNivel:
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo

    xor a
    ld [wSeleccion], a
    ld [wTocados], a
    ld [wModoCGB], a
    ld [wMovimientos], a
    ld [wMovimientos + 1], a
    ld [wMovimientos + 2], a

    call PunteroNivel
    ld de, NIVEL_INICIAL
    add hl, de
    ld de, wEstados
    ld b, 3
.estados:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .estados

    call EsCGB
    jr nz, .texto
    call DibujarJuegoCGB
    call CargarPaletasNivelCGB
    call ActualizarCompuertas
    call AbrirDialogo
    jr .listo
.texto:
    call DibujarJuego
    call ActualizarCompuertas
    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ActualizarCursor
.listo:
    call ActivarLCD
    ret

; HL = datos del nivel actual. Estropea A y DE.
PunteroNivel:
    ld a, [wNivel]
    ld h, 0
    ld l, a
    add hl, hl
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de
    ld de, Niveles
    add hl, de
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

; Avanza la compuerta elegida; en los niveles acoplados, también la de su derecha.
PulsarCompuerta:
    ld a, [wSeleccion]
    ld c, a
    call AvanzarCompuerta

    ld b, 1
    ld a, c
    or a
    jr z, .marcar
.desplazar:
    sla b
    dec a
    jr nz, .desplazar
.marcar:
    ld a, [wTocados]
    or b
    ld [wTocados], a

    call PunteroNivel
    ld de, NIVEL_ACOPLADO
    add hl, de
    ld a, [hl]
    or a
    ret z

    ld a, c
    cp 2
    ret z
    inc c
    call AvanzarCompuerta
    ret

; C = compuerta. Pasa al siguiente estado según la tabla del nivel.
AvanzarCompuerta:
    ld hl, wEstados
    ld b, 0
    add hl, bc
    ld a, [hl]
    push hl
    push af
    call PunteroNivel
    pop af
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    pop hl
    ld [hl], a
    ret

ComprobarSolucion:
    ld a, [wTocados]
    cp TODAS_TOCADAS
    ret nz
    call PunteroNivel
    ld de, NIVEL_SOLUCION
    add hl, de
    ld de, wEstados
    ld b, 3
.comparar:
    ld a, [de]
    cp [hl]
    ret nz
    inc de
    inc hl
    dec b
    jr nz, .comparar

    ; Nivel superado. En Game Boy Color se pasa al siguiente mientras quede.
    ld a, [wModoCGB]
    or a
    jr z, .final
    ld a, [wNivel]
    cp NUM_NIVELES - 1
    jr nc, .final
    call SonidoExito
    ld c, ESPERA_NIVEL
.espera:
    halt
    call VolcarOAM
    dec c
    jr nz, .espera
    ld a, [wNivel]
    inc a
    ld [wNivel], a
    jp IniciarNivel
.final:
    call CompletarFlujo
    ret

CompletarFlujo:
    ld a, MARCA_COMPLETADO
    ld [wRyuFlowCompletado], a
    call SonidoExito

    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo
    ld a, [wModoCGB]
    or a
    jr z, .texto
    ld hl, VictoriaCGB
    call CargarPantallaCGB
    ld a, 1
    ld [wPantallaCGB], a
    jr .dibujado
.texto:
    call DibujarFinal
.dibujado:

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
    ; Tras resolver el puzle no queda nada que señalar.
    ld a, [wEstado]
    cp ESTADO_JUEGO
    ret nz
    ld a, [wModoCGB]
    or a
    jp nz, ActualizarSpritesCGB
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
    ld a, [wModoCGB]
    or a
    jp nz, ActualizarCompuertasCGB

    ; Game Boy clasica: curva arriba (abierta) o abajo; en su sitio, remarcada.
    call PunteroNivel
    ld de, NIVEL_SOLUCION
    add hl, de
    ld c, 0
.compuerta:
    push hl
    ld b, 0
    ld hl, wEstados
    add hl, bc
    ld d, [hl]
    pop hl
    push hl
    add hl, bc
    ld e, [hl]

    ld a, d
    cp ABIERTA
    ld a, TILE_COMPUERTA_UP
    jr z, .forma
    ld a, TILE_COMPUERTA_DN
.forma:
    ld b, a
    ld a, d
    cp e
    ld a, b
    jr nz, .escribir
    add TILE_UP_OK - TILE_COMPUERTA_UP
.escribir:
    ld b, a
    ld hl, ColumnasCompuertaDMG
    ld e, c
    ld d, 0
    add hl, de
    ld e, [hl]
    ld hl, BG_MAP + (9 * 32)
    add hl, de
    call EsperarVRAM
    ld [hl], b
    pop hl
    inc c
    ld a, c
    cp 3
    jr nz, .compuerta
    ret

DibujarTitulo:
    call EsCGB
    jr nz, .texto
    ld hl, TituloCGB
    call CargarPantallaCGB
    ld a, 1
    ld [wPantallaCGB], a
    ret
.texto:
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

; Pantalla de juego de la lámina: escena, HUD, sprites y sus paletas. LCD apagada.
DibujarJuegoCGB:
    ld hl, JuegoCGB
    call CargarPantallaCGB
    ld a, 1
    ld [wPantallaCGB], a
    ld [wModoCGB], a

    ld a, 1
    ldh [rVBK], a
    ld hl, VRAM_TILES + PRIMER_TILE_SPRITE * 16
    ld de, SpritesCGB
    ld bc, SpritesCGBFin - SpritesCGB
    call CopiarCGB
    xor a
    ldh [rVBK], a

    ld a, $80
    ldh [rOCPS], a
    ld hl, PaletasSpritesCGB
    ld b, PaletasSpritesCGBFin - PaletasSpritesCGB
.obj:
    ld a, [hli]
    ldh [rOCPD], a
    dec b
    jr nz, .obj
    ret

; Cada compuerta abierta (bit a 0) muestra agua entre las columnas del torii y
; cada compuerta en su posición final enciende su icono del HUD.
ActualizarCompuertasCGB:
    call PunteroNivel
    ld de, NIVEL_SOLUCION
    add hl, de
    ld a, l
    ld [wPunteroSolucion], a
    ld a, h
    ld [wPunteroSolucion + 1], a
    xor a
    ld [wCorrectas], a
    ld hl, ParchesCompuertasCGB
    ld c, 0
.compuerta:
    push bc
    push hl
    ld b, 0
    ld hl, wEstados
    add hl, bc
    ld a, [hl]
    ld [wEstadoActual], a
    ld a, [wPunteroSolucion]
    ld l, a
    ld a, [wPunteroSolucion + 1]
    ld h, a
    add hl, bc
    ld a, [hl]
    ld [wSolucionActual], a
    pop hl

    ; Dos parches por estado: primero se deshace el otro hueco y luego se pone el propio.
    ld a, [wEstadoActual]
    add a
    call AplicarIndiceCGB
    ld a, [wEstadoActual]
    add a
    inc a
    call AplicarIndiceCGB

    ld a, [wSolucionActual]
    ld b, a
    ld a, [wEstadoActual]
    cp b
    ld a, 7
    jr nz, .icono
    ld a, [wCorrectas]
    inc a
    ld [wCorrectas], a
    ld a, 6
.icono:
    call AplicarIndiceCGB

    ld de, 8 * 2
    add hl, de
    pop bc
    inc c
    ld a, c
    cp 3
    jr nz, .compuerta
    ret

; HL = tabla de punteros a parche, A = índice. Conserva HL.
AplicarIndiceCGB:
    push hl
    add a
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    call AplicarParcheCGB
    pop hl
    ret

; LCD apagada: paletas del nivel (día, amanecer o noche) sobre las de la pantalla.
CargarPaletasNivelCGB:
    ld a, [wNivel]
    add a
    ld e, a
    ld d, 0
    ld hl, PaletasNivelCGB
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, $80
    ldh [rBCPS], a
    ld b, 8 * 4 * 2
.paleta:
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .paleta
    ret

AbrirDialogo:
    ld hl, DialogosCGB
    call ParcheDialogo
    ld a, ESTADO_DIALOGO
    ld [wEstado], a
    ret

CerrarDialogo:
    ld hl, DialogosCGBBase
    ; sigue en ParcheDialogo

; HL = tabla de parches de diálogo; aplica el del nivel actual.
ParcheDialogo:
    ld a, [wNivel]
    jp AplicarIndiceCGB

; Cursor que flota sobre la compuerta elegida, dragones despiertos y movimientos.
ActualizarSpritesCGB:
    ld a, [wFrames]
    inc a
    ld [wFrames], a
    swap a
    and 1
    ld b, a

    ld a, [wSeleccion]
    ld e, a
    ld d, 0
    ld hl, CursorXCGB
    add hl, de
    ld c, [hl]

    ld hl, OAM_BASE
    ld a, CURSOR_Y
    add b
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, TILE_SPRITE_CURSOR
    ld [hli], a
    ld a, ATRIB_CURSOR
    ld [hli], a

    ld a, NIVEL_Y
    ld [hli], a
    ld a, NIVEL_X
    ld [hli], a
    ld a, [wNivel]
    add PRIMER_TILE_SPRITE + 1
    ld [hli], a
    ld a, ATRIB_CIFRA
    ld [hli], a

    ld a, CIFRAS_Y
    ld [hli], a
    ld a, DRAGONES_X
    ld [hli], a
    ld a, [wCorrectas]
    add PRIMER_TILE_SPRITE
    ld [hli], a
    ld a, ATRIB_CIFRA
    ld [hli], a

    ld de, wMovimientos
    ld c, MOVIMIENTOS_X
    ld b, 3
.cifra:
    ld a, CIFRAS_Y
    ld [hli], a
    ld a, c
    ld [hli], a
    add 6
    ld c, a
    ld a, [de]
    inc de
    add PRIMER_TILE_SPRITE
    ld [hli], a
    ld a, ATRIB_CIFRA
    ld [hli], a
    dec b
    jr nz, .cifra
    ret

; Movimientos en tres cifras decimales; se quedan en 999.
SumarMovimiento:
    ld hl, wMovimientos + 2
    ld b, 3
.cifra:
    ld a, [hl]
    inc a
    cp 10
    jr c, .guardar
    xor a
    ld [hld], a
    dec b
    jr nz, .cifra
    ld a, 9
    ld [wMovimientos], a
    ld [wMovimientos + 1], a
    ld [wMovimientos + 2], a
    ret
.guardar:
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

; LCD apagada: limpia la OAM en sombra y la real.
LimpiarOAM:
    ld hl, OAM_BASE
    call .limpiar
    ld hl, OAM_REAL
.limpiar:
    ld b, 160
    xor a
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

; Justo tras el halt, en VBlank: copia a la OAM los sprites que usa la ROM.
VolcarOAM:
    ld hl, OAM_BASE
    ld de, OAM_REAL
    ld b, SPRITES_VOLCADOS * 4
.loop:
    ld a, [hli]
    ld [de], a
    inc de
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
    ; Al salir del título a pantalla completa se recuperan tiles, paleta y
    ; atributos del juego antes de dibujar nada (#808).
    ld a, [wPantallaCGB]
    or a
    jr z, .limpiar
    xor a
    ld [wPantallaCGB], a
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

; Por nivel: siguiente estado desde abierta, media y cerrada; si pulsar arrastra
; a la compuerta de la derecha; estados iniciales y solución.
Niveles:
    ; 1-1, día: abrir o cerrar.
    db CERRADA, CERRADA, ABIERTA, 0
    db CERRADA, ABIERTA, CERRADA
    db ABIERTA, CERRADA, ABIERTA
    ; 1-2, amanecer: abierta, a medias, cerrada.
    db MEDIA, CERRADA, ABIERTA, 0
    db CERRADA, ABIERTA, MEDIA
    db MEDIA, CERRADA, ABIERTA
    ; 1-3, noche: cada compuerta arrastra a la de su derecha (solución única:
    ; dos pulsaciones en cada una).
    db MEDIA, CERRADA, ABIERTA, 1
    db CERRADA, CERRADA, CERRADA
    db MEDIA, ABIERTA, ABIERTA

; Columnas del mapa de las tres compuertas en Game Boy clásica.
ColumnasCompuertaDMG:
    db 4, 9, 14

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

; Posición X (OAM) del cursor sobre cada torii.
CursorXCGB:
    db 23 + 8, 23 + 45 + 8, 23 + 90 + 8

; Por compuerta, dos parches por estado (abierta, media, cerrada) y el icono
; encendido o apagado.
ParchesCompuertasCGB:
    FOR N, 1, 4
    dw JuegoCGB_Media{d:N}_Base, JuegoCGB_Abierta{d:N}
    dw JuegoCGB_Abierta{d:N}_Base, JuegoCGB_Media{d:N}
    dw JuegoCGB_Media{d:N}_Base, JuegoCGB_Abierta{d:N}_Base
    dw JuegoCGB_Correcta{d:N}, JuegoCGB_Correcta{d:N}_Base
    ENDR

DialogosCGB:
    dw JuegoCGB_Dialogo1, JuegoCGB_Dialogo2, JuegoCGB_Dialogo3
DialogosCGBBase:
    dw JuegoCGB_Dialogo1_Base, JuegoCGB_Dialogo2_Base, JuegoCGB_Dialogo3_Base

PaletasNivelCGB:
    dw JuegoCGB_Paletas, PaletasAmanecerCGB, PaletasNocheCGB

SpritesCGB:
    INCLUDE "assets/sprites_tiles.inc"
SpritesCGBFin:

PaletasSpritesCGB:
    INCLUDE "assets/sprites_paletas.inc"
PaletasSpritesCGBFin:

SECTION "Variables", WRAM0
wEstado:        ds 1
wSeleccion:     ds 1
wNivel:         ds 1
wEstados:       ds 3
wTocados:       ds 1
wTeclas:        ds 1
wTeclasPrevias: ds 1
wTeclasNuevas:  ds 1

; Contrato estable para futura integracion con #442. La ROM lo escribe solo al
; completar la interaccion; este corte no conecta aun ese byte con Godot.
SECTION "Handshake", WRAM0[$C100]
wRyuFlowCompletado: ds 1

; Pantalla completa CGB (#808): si el fondo la tiene cargada, para devolverle
; sus tiles al juego al salir.
SECTION "TituloCGBVars", WRAM0
wPantallaCGB:  ds 1

; Pantalla de juego y victoria con el arte de la lámina (#808).
SECTION "JuegoCGBVars", WRAM0
wModoCGB:        ds 1
wCorrectas:      ds 1
wFrames:         ds 1
wMovimientos:    ds 3
wPunteroSolucion: ds 2
wEstadoActual:   ds 1
wSolucionActual: ds 1

SECTION "OAMSombra", WRAM0[OAM_BASE]
wOAMSombra:      ds 160

SECTION "TituloCGB", ROMX
    PANTALLA_CGB TituloCGB, "assets/titulo"

SECTION "JuegoCGB", ROM0
    PANTALLA_CGB JuegoCGB, "assets/juego"
    INCLUDE "assets/juego_variantes.inc"
PaletasAmanecerCGB:
    INCLUDE "assets/juego_paletas_amanecer.inc"
PaletasNocheCGB:
    INCLUDE "assets/juego_paletas_noche.inc"

SECTION "VictoriaCGB", ROMX
    PANTALLA_CGB VictoriaCGB, "assets/victoria"
