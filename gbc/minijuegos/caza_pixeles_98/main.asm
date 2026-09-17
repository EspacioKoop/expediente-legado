; Pixel Exodus (id estable: caza_pixeles_98) - minijuego GBC para SIGA-98
; Codigo original del proyecto, licencia MIT (LICENSE en la raiz del repositorio).
;
; Campana arcade ecologista en tres fases. La puntuacion, restauracion y records
; viven exclusivamente dentro de la ROM; no conceden dinero, pistas ni progreso
; en SIGA-98.

DEF rP1    EQU $FF00
DEF rDIV   EQU $FF04
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
DEF rVBK   EQU $FF4F
DEF rBCPS  EQU $FF68
DEF rBCPD  EQU $FF69
DEF rOCPS  EQU $FF6A
DEF rOCPD  EQU $FF6B
DEF rIE    EQU $FFFF

DEF VRAM_TILES EQU $8000
DEF BG_MAP     EQU $9800
DEF OAM_BASE   EQU $FE00

DEF ESTADO_TITULO EQU 0
DEF ESTADO_JUEGO  EQU 1
DEF ESTADO_FIN    EQU 2

DEF KEY_RIGHT EQU %00000001
DEF KEY_LEFT  EQU %00000010
DEF KEY_UP    EQU %00000100
DEF KEY_DOWN  EQU %00001000
DEF KEY_A     EQU %00010000
DEF KEY_START EQU %10000000

DEF TILE_VACIO          EQU 0
DEF TILE_JUGADOR        EQU 1
DEF TILE_OBJETIVO       EQU 2
DEF TILE_LINEA          EQU 3
DEF TILE_DIGITO0        EQU 4
DEF TILE_C              EQU 14
DEF TILE_A              EQU 15
DEF TILE_Z              EQU 16
DEF TILE_P              EQU 17
DEF TILE_I              EQU 18
DEF TILE_X              EQU 19
DEF TILE_E              EQU 20
DEF TILE_L              EQU 21
DEF TILE_S              EQU 22
DEF TILE_T              EQU 23
DEF TILE_R              EQU 24
DEF TILE_O              EQU 25
DEF TILE_M              EQU 26
DEF TILE_EXCL           EQU 27
DEF TILE_SEMILLA        EQU 28
DEF TILE_FOCO           EQU 29
DEF TILE_PLANETA_SECO   EQU 30
DEF TILE_PLANETA_AGUA   EQU 31
DEF TILE_PLANETA_BOSQUE EQU 32
DEF TILE_PLANETA_VIVO   EQU 33
DEF TILE_BEHEMOTH_A     EQU 34
DEF TILE_BEHEMOTH_B     EQU 35
DEF TILE_NUCLEO         EQU 36
DEF TILE_RESIDUO        EQU 37

DEF TIPO_CROMA   EQU 0
DEF TIPO_SEMILLA EQU 1
DEF TIPO_FOCO    EQU 2

DEF SEGUNDOS_PARTIDA EQU 45
DEF FASE2_TIEMPO     EQU 30
DEF FASE3_TIEMPO     EQU 15
DEF BEHEMOTH_TIEMPO  EQU 8
DEF FASE_FINAL       EQU 4
DEF FRAMES_SEGUNDO   EQU 60
DEF COMBO_DURACION   EQU 90
DEF COMBO_X2         EQU 3
DEF COMBO_X3         EQU 6
DEF RESTAURA_SEMILLA EQU 4
DEF RESTAURA_FOCO    EQU 12
DEF RESTAURA_NUCLEO  EQU 6
DEF RESTAURA_BOSS    EQU 18

; Glitch Behemoth: metasprite 32x32, cuatro puntos vulnerables. Cada scanline
; atraviesa como maximo 4 sprites de cuerpo + nucleo + jugador = 6 (<10 GBC).
DEF BEHEMOTH_X                    EQU 112
DEF BEHEMOTH_Y                    EQU 72
DEF BEHEMOTH_PUNTOS               EQU 4
DEF BEHEMOTH_INVULN_FRAMES        EQU 24
DEF BOSS_SPRITES_CUERPO           EQU 16
DEF BOSS_SPRITES_LINEA            EQU 4
DEF MAX_SPRITES_LINEA_BEHEMOTH    EQU 6

; Formato SRAM privado de la ROM. La RAM con bateria la aporta el cartucho
; comun MBC5 de #819 y la Portatil Color 98 la persiste por cartucho.
DEF SRAM_MAGIC0              EQU $A000
DEF SRAM_MAGIC1              EQU $A001
DEF SRAM_MAGIC2              EQU $A002
DEF SRAM_MAGIC3              EQU $A003
DEF SRAM_VERSION             EQU $A004
DEF SRAM_MEJOR_PUNTOS        EQU $A005
DEF SRAM_MEJOR_COMBO         EQU $A006
DEF SRAM_MEJOR_FASE          EQU $A007
DEF SRAM_MEJOR_RESTAURACION  EQU $A008
DEF SRAM_CHECKSUM            EQU $A009
DEF SRAM_VERSION_ACTUAL      EQU 1

INCLUDE "../comun/cartucho.asm"
INCLUDE "../comun/pantalla_cgb.asm"

SECTION "VBlank", ROM0[$0040]
VBlank:
    reti

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "CAZAPIXEL98"
    ds $0143 - @, 0
    db $80 ; ROM compatible con Game Boy Color.
    ds $0150 - @, 0

SECTION "Juego", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF
    call IniciarCartucho
    call CargarRecords
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
    call LeerControles

    ld a, [wEstado]
    or a
    jr z, EstadoTitulo
    cp ESTADO_JUEGO
    jr z, EstadoJuego
    jr EstadoFin

EstadoTitulo:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarPartida
    jr Bucle

EstadoJuego:
    call ActualizarHUD
    call MoverJugador
    call TickBehemoth
    call TickEscenarioVisual
    call MoverObjetivo
    call TickCombo
    call ComprobarCaptura
    call TickTiempo
    call ActualizarOAM

    ld a, [wTiempo]
    or a
    jr nz, Bucle
    ld a, [wBossDerrotado]
    or a
    jr nz, .mostrar_fin
    call SonidoFin
.mostrar_fin:
    call MostrarFin
    jr Bucle

EstadoFin:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarPartida
    jr Bucle

; Lee cruceta y botones y calcula pulsaciones nuevas.
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

IniciarPartida:
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo

    ld a, 80
    ld [wJugadorX], a
    ld a, 88
    ld [wJugadorY], a

    xor a
    ld [wObjetivoIndice], a
    ld [wPuntos], a
    ld [wFrames], a
    ld [wObjetivoTick], a
    ld [wDirX], a
    ld [wDirY], a
    ld [wCombo], a
    ld [wComboFrames], a
    ld [wMejorComboPartida], a
    ld [wRestauracion], a
    ld [wFocosCerrados], a
    ld [wEtapaChromia], a
    ld [wBossActivo], a
    ld [wBossDerrotado], a
    ld [wBossGolpes], a
    ld [wBossPunto], a
    ld [wBossInvuln], a

    ld a, 1
    ld [wMultiplicador], a
    ld [wFase], a

    ldh a, [rDIV]
    or a
    jr nz, .semilla_lista
    ld a, $A5
.semilla_lista:
    ld [wRng], a

    ld a, SEGUNDOS_PARTIDA
    ld [wTiempo], a
    ld a, 5
    ld [wIntervaloObjetivo], a

    call AplicarPaletaFase
    call DibujarHUD
    call InicializarEscenarioVisual
    call DibujarChromia
    call SiguienteObjetivo
    call ActualizarOAM

    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ActivarLCD
    ret

MostrarFin:
    call GuardarRecords
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo
    call DibujarEscenarioFinal
    call DibujarChromia
    call DibujarResultadoBoss

    ld hl, BG_MAP + (3 * 32) + 7
    ld de, TextoTiempoFin
    call EscribirTexto

    ld hl, BG_MAP + (5 * 32) + 5
    ld de, TextoScore
    call EscribirTexto
    ld a, [wPuntos]
    ld hl, BG_MAP + (5 * 32) + 11
    call EscribirNumero2

    ld hl, BG_MAP + (7 * 32) + 3
    ld de, TextoMejorScore
    call EscribirTexto
    ld a, [wMejorPuntos]
    ld hl, BG_MAP + (7 * 32) + 11
    call EscribirNumero2

    ; R = mejor restauracion. X = mejor combo. P4 = final completado.
    ld hl, BG_MAP + (9 * 32) + 4
    ld a, TILE_R
    ld [hli], a
    inc hl
    ld a, [wMejorRestauracion]
    call EscribirNumero2
    ld hl, BG_MAP + (9 * 32) + 10
    ld a, TILE_X
    ld [hli], a
    ld a, [wMejorCombo]
    cp 10
    jr c, .combo_final_listo
    ld a, 9
.combo_final_listo:
    add TILE_DIGITO0
    ld [hl], a

    ld hl, BG_MAP + (11 * 32) + 8
    ld a, TILE_P
    ld [hli], a
    ld a, [wMejorFase]
    add TILE_DIGITO0
    ld [hl], a

    ld hl, BG_MAP + (14 * 32) + 7
    ld de, TextoStart
    call EscribirTexto

    ld a, ESTADO_FIN
    ld [wEstado], a
    call ActivarLCD
    ret

DibujarResultadoBoss:
    ld hl, BG_MAP + (11 * 32) + 16
    ld a, [wBossDerrotado]
    or a
    jr z, .residuo
    ld a, TILE_SEMILLA
    ld [hl], a
    ret
.residuo:
    ld a, TILE_NUCLEO
    ld [hl], a
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

MoverJugador:
    ld a, [wTeclas]
    and KEY_RIGHT
    jr z, .izquierda
    ld a, [wJugadorX]
    cp 160
    jr nc, .izquierda
    inc a
    ld [wJugadorX], a

.izquierda:
    ld a, [wTeclas]
    and KEY_LEFT
    jr z, .arriba
    ld a, [wJugadorX]
    cp 9
    jr c, .arriba
    dec a
    ld [wJugadorX], a

.arriba:
    ld a, [wTeclas]
    and KEY_UP
    jr z, .abajo
    ld a, [wJugadorY]
    cp 33
    jr c, .abajo
    dec a
    ld [wJugadorY], a

.abajo:
    ld a, [wTeclas]
    and KEY_DOWN
    ret z
    ld a, [wJugadorY]
    cp 152
    ret nc
    inc a
    ld [wJugadorY], a
    ret

MoverObjetivo:
    ld a, [wBossActivo]
    or a
    ret nz

    ; Los focos contaminantes son instalaciones: permanecen fijos.
    ld a, [wTipoObjetivo]
    cp TIPO_FOCO
    ret z

    ld a, [wObjetivoTick]
    inc a
    ld [wObjetivoTick], a
    ld b, a

    ld a, [wIntervaloObjetivo]
    ld c, a
    ld a, [wTipoObjetivo]
    cp TIPO_SEMILLA
    jr nz, .intervalo_listo
    inc c
    inc c
.intervalo_listo:
    ld a, c
    cp b
    ret nc
    xor a
    ld [wObjetivoTick], a

    ld a, [wDirX]
    or a
    jr nz, .derecha

.izquierda:
    ld a, [wObjetivoX]
    cp 16
    jr z, .rebote_derecha
    dec a
    ld [wObjetivoX], a
    jr .vertical
.rebote_derecha:
    ld a, 1
    ld [wDirX], a
    ld a, [wObjetivoX]
    inc a
    ld [wObjetivoX], a
    jr .vertical

.derecha:
    ld a, [wObjetivoX]
    cp 152
    jr z, .rebote_izquierda
    inc a
    ld [wObjetivoX], a
    jr .vertical
.rebote_izquierda:
    xor a
    ld [wDirX], a
    ld a, [wObjetivoX]
    dec a
    ld [wObjetivoX], a

.vertical:
    ld a, [wDirY]
    or a
    jr nz, .abajo
.arriba:
    ld a, [wObjetivoY]
    cp 40
    jr z, .rebote_abajo
    dec a
    ld [wObjetivoY], a
    ret
.rebote_abajo:
    ld a, 1
    ld [wDirY], a
    ld a, [wObjetivoY]
    inc a
    ld [wObjetivoY], a
    ret
.abajo:
    ld a, [wObjetivoY]
    cp 152
    jr z, .rebote_arriba
    inc a
    ld [wObjetivoY], a
    ret
.rebote_arriba:
    xor a
    ld [wDirY], a
    ld a, [wObjetivoY]
    dec a
    ld [wObjetivoY], a
    ret

ComprobarCaptura:
    ld a, [wBossActivo]
    or a
    jp nz, ComprobarPuntoBehemoth

    ; AABB de dos sprites de 8x8.
    ld a, [wJugadorX]
    add 8
    ld b, a
    ld a, [wObjetivoX]
    cp b
    jp nc, .no_captura
    ld a, [wObjetivoX]
    add 8
    ld b, a
    ld a, [wJugadorX]
    cp b
    jp nc, .no_captura
    ld a, [wJugadorY]
    add 8
    ld b, a
    ld a, [wObjetivoY]
    cp b
    jp nc, .no_captura
    ld a, [wObjetivoY]
    add 8
    ld b, a
    ld a, [wJugadorY]
    cp b
    jp nc, .no_captura

    ld a, [wTipoObjetivo]
    cp TIPO_FOCO
    jr z, .foco
    cp TIPO_SEMILLA
    jr z, .semilla
.croma:
    call RegistrarCaptura
    call AjustarDificultad
    call SiguienteObjetivo
    call SonidoCaptura
    ret
.semilla:
    call RegistrarCaptura
    ld a, RESTAURA_SEMILLA
    call SumarRestauracion
    call AjustarDificultad
    call SiguienteObjetivo
    call SonidoRestauracion
    ret
.foco:
    call CerrarFocoContaminante
    call AjustarDificultad
    call SiguienteObjetivo
    call SonidoFoco
.no_captura:
    ret

RegistrarCaptura:
    ld a, [wCombo]
    cp 9
    jr nc, .combo_listo
    inc a
    ld [wCombo], a
.combo_listo:
    ld b, a
    ld a, [wMejorComboPartida]
    cp b
    jr nc, .record_combo_listo
    ld a, b
    ld [wMejorComboPartida], a
.record_combo_listo:
    ld a, COMBO_DURACION
    ld [wComboFrames], a

    ld a, [wCombo]
    cp COMBO_X3
    jr nc, .x3
    cp COMBO_X2
    jr nc, .x2
    ld a, 1
    jr .guardar_multiplicador
.x2:
    ld a, 2
    jr .guardar_multiplicador
.x3:
    ld a, 3
.guardar_multiplicador:
    ld [wMultiplicador], a
    ld b, a

    ld a, [wPuntos]
    cp 99
    ret nc
    add b
    cp 100
    jr c, .guardar_puntos
    ld a, 99
.guardar_puntos:
    ld [wPuntos], a
    ret

CerrarFocoContaminante:
    ; Restaurar compite con mantener la cadena de puntuacion.
    xor a
    ld [wCombo], a
    ld [wComboFrames], a
    ld a, 1
    ld [wMultiplicador], a

    ld a, [wFocosCerrados]
    cp 99
    jr nc, .focos_listos
    inc a
    ld [wFocosCerrados], a
.focos_listos:
    ld a, RESTAURA_FOCO
    call SumarRestauracion

    ld a, [wPuntos]
    cp 99
    ret nc
    inc a
    ld [wPuntos], a
    ret

; A = incremento de restauracion. Satura a 99 y actualiza Chromia solo cuando
; se cruza uno de sus cuatro estados visuales.
SumarRestauracion:
    ld b, a
    ld a, [wRestauracion]
    add b
    cp 100
    jr c, .guardar
    ld a, 99
.guardar:
    ld [wRestauracion], a
    call ActualizarChromia
    ret

TickCombo:
    ld a, [wComboFrames]
    or a
    ret z
    dec a
    ld [wComboFrames], a
    ret nz
    xor a
    ld [wCombo], a
    inc a
    ld [wMultiplicador], a
    ret

AjustarDificultad:
    ld a, [wFase]
    cp 3
    jr z, .nivel3
    cp 2
    jr z, .nivel2

    ld a, [wPuntos]
    cp 20
    jr nc, .nivel3
    cp 10
    jr nc, .nivel2
    cp 5
    ret c
    ld a, 4
    ld [wIntervaloObjetivo], a
    ret
.nivel2:
    ld a, 3
    ld [wIntervaloObjetivo], a
    ret
.nivel3:
    ld a, 2
    ld [wIntervaloObjetivo], a
    ret

AvanzarRng:
    ld a, [wRng]
    srl a
    jr nc, .no_feedback
    xor $B8
.no_feedback:
    or a
    jr nz, .guardar
    ld a, $A5
.guardar:
    ld [wRng], a
    ret

SiguienteObjetivo:
    call AvanzarRng
    and $0F
    ld b, a
    ld a, [wObjetivoIndice]
    cp b
    jr nz, .indice_listo
    inc b
    ld a, b
    and $0F
    ld b, a
.indice_listo:
    ld a, b
    ld [wObjetivoIndice], a
    add a
    ld e, a
    ld d, 0
    ld hl, PosicionesObjetivo
    add hl, de
    ld a, [hli]
    ld [wObjetivoX], a
    ld a, [hl]
    ld [wObjetivoY], a

    ld a, [wFase]
    cp 1
    jr nz, .tipos_avanzados
    ld a, [wRng]
    and 1
    ld [wTipoObjetivo], a
    jr .direccion
.tipos_avanzados:
    ld a, [wRng]
    and 3
    cp 3
    jr nz, .tipo_listo
    ld a, TIPO_FOCO
.tipo_listo:
    ld [wTipoObjetivo], a
.direccion:
    ld a, [wObjetivoIndice]
    and 1
    ld [wDirX], a
    ld a, [wObjetivoIndice]
    and 2
    srl a
    ld [wDirY], a
    xor a
    ld [wObjetivoTick], a
    ret

TickTiempo:
    ld a, [wFrames]
    inc a
    cp FRAMES_SEGUNDO
    jr c, .guardar_frame
    xor a
    ld [wFrames], a
    ld a, [wTiempo]
    or a
    ret z
    dec a
    ld [wTiempo], a

    cp FASE2_TIEMPO
    jr z, .fase2
    cp FASE3_TIEMPO
    jr z, .fase3
    cp BEHEMOTH_TIEMPO
    jr z, .behemoth
    ret
.fase2:
    ld a, 2
    ld [wFase], a
    ld a, 3
    ld [wIntervaloObjetivo], a
    call AplicarPaletaFase
    call TransicionEscenarioFase
    call SonidoFase
    ret
.fase3:
    ld a, 3
    ld [wFase], a
    ld a, 2
    ld [wIntervaloObjetivo], a
    call AplicarPaletaFase
    call TransicionEscenarioFase
    call SonidoFase
    ret
.behemoth:
    ld a, [wFase]
    cp 3
    ret nz
    call IniciarBehemoth
    ret
.guardar_frame:
    ld [wFrames], a
    ret

; -------------------------- Glitch Behemoth ---------------------------
IniciarBehemoth:
    ld a, [wBossActivo]
    or a
    ret nz
    ld a, 1
    ld [wBossActivo], a
    xor a
    ld [wBossDerrotado], a
    ld [wBossGolpes], a
    ld [wBossPunto], a
    ld [wBossInvuln], a
    ld [wCombo], a
    ld [wComboFrames], a
    inc a
    ld [wMultiplicador], a
    call ActualizarPuntoBehemoth
    call TransicionBehemothVisual
    call SonidoBehemoth
    ret

TickBehemoth:
    ld a, [wBossActivo]
    or a
    ret z
    ld a, [wBossInvuln]
    or a
    ret z
    dec a
    ld [wBossInvuln], a
    ret

ActualizarPuntoBehemoth:
    ld a, [wBossPunto]
    add a
    ld e, a
    ld d, 0
    ld hl, PuntosBehemoth
    add hl, de
    ld a, [hli]
    ld [wBossPuntoX], a
    ld a, [hl]
    ld [wBossPuntoY], a
    ret

ComprobarPuntoBehemoth:
    ld a, [wBossDerrotado]
    or a
    ret nz
    ld a, [wBossInvuln]
    or a
    ret nz

    ld a, [wJugadorX]
    add 8
    ld b, a
    ld a, [wBossPuntoX]
    cp b
    ret nc
    ld a, [wBossPuntoX]
    add 8
    ld b, a
    ld a, [wJugadorX]
    cp b
    ret nc
    ld a, [wJugadorY]
    add 8
    ld b, a
    ld a, [wBossPuntoY]
    cp b
    ret nc
    ld a, [wBossPuntoY]
    add 8
    ld b, a
    ld a, [wJugadorY]
    cp b
    ret nc
    call GolpearBehemoth
    ret

GolpearBehemoth:
    ld a, [wBossGolpes]
    inc a
    ld [wBossGolpes], a
    cp BEHEMOTH_PUNTOS
    jr nc, .derrotado

    ld [wBossPunto], a
    ld a, BEHEMOTH_INVULN_FRAMES
    ld [wBossInvuln], a
    call ActualizarPuntoBehemoth
    ld a, RESTAURA_NUCLEO
    call SumarRestauracion
    call SonidoGolpeBehemoth
    ret

.derrotado:
    ld a, RESTAURA_BOSS
    call SumarRestauracion
    ld a, 1
    ld [wBossDerrotado], a
    ld a, FASE_FINAL
    ld [wFase], a
    xor a
    ld [wTiempo], a
    call SonidoVictoria
    ret

ActualizarOAM:
    ld hl, OAM_BASE
    ; Nave: un sprite.
    ld a, [wJugadorY]
    ld [hli], a
    ld a, [wJugadorX]
    ld [hli], a
    ld a, TILE_JUGADOR
    ld [hli], a
    xor a
    ld [hli], a

    ld a, [wBossActivo]
    or a
    jp nz, DibujarBehemothOAM

    ; Objetivo normal: un sprite.
    ld a, [wObjetivoY]
    ld [hli], a
    ld a, [wObjetivoX]
    ld [hli], a
    ld a, [wTipoObjetivo]
    or a
    jr z, .croma
    cp TIPO_SEMILLA
    jr z, .semilla
    ld a, TILE_FOCO
    ld c, 3
    jr .tipo_listo
.croma:
    ld a, TILE_OBJETIVO
    ld c, 1
    jr .tipo_listo
.semilla:
    ld a, TILE_SEMILLA
    ld c, 2
.tipo_listo:
    ld [hli], a
    ld a, c
    ld [hl], a
    ret

; HL llega al segundo sprite OAM. Dibuja 4x4 = 16 sprites de cuerpo y un unico
; nucleo superpuesto. Con el jugador son 18 objetos OAM; por scanline, maximo 6.
DibujarBehemothOAM:
    ld b, BEHEMOTH_Y
    xor a
    ld c, a
.fila:
    ld d, BEHEMOTH_X
    ld e, 4
.columna:
    ld a, b
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, e
    xor c
    and 1
    jr z, .tile_a
    ld a, TILE_BEHEMOTH_B
    jr .tile_listo
.tile_a:
    ld a, TILE_BEHEMOTH_A
.tile_listo:
    ld [hli], a
    ld a, 3
    ld [hli], a
    ld a, d
    add 8
    ld d, a
    dec e
    jr nz, .columna
    ld a, b
    add 8
    ld b, a
    inc c
    ld a, c
    cp 4
    jr c, .fila

    ; Punto vulnerable actual: paleta luminosa de croma.
    ld a, [wBossPuntoY]
    ld [hli], a
    ld a, [wBossPuntoX]
    ld [hli], a
    ld a, TILE_NUCLEO
    ld [hli], a
    ld a, 1
    ld [hl], a
    ret

; ---------------------------- HUD / Chromia ---------------------------
ActualizarHUD:
    ld a, [wPuntos]
    ld hl, BG_MAP + 6
    call EscribirNumero2

    ld hl, BG_MAP + 10
    call EsperarVRAM
    ld a, [wMultiplicador]
    add TILE_DIGITO0
    ld [hl], a

    ld a, [wTiempo]
    ld hl, BG_MAP + 17
    call EscribirNumero2

    ld hl, BG_MAP + 32 + 3
    call EsperarVRAM
    ld a, [wFase]
    cp FASE_FINAL
    jr c, .fase_hud_lista
    ld a, 3
.fase_hud_lista:
    add TILE_DIGITO0
    ld [hl], a

    ld a, [wRestauracion]
    ld hl, BG_MAP + 32 + 7
    call EscribirNumero2
    ret

ActualizarChromia:
    ld a, [wRestauracion]
    cp 75
    jr nc, .vivo
    cp 50
    jr nc, .bosque
    cp 25
    jr nc, .agua
    xor a
    jr .comparar
.agua:
    ld a, 1
    jr .comparar
.bosque:
    ld a, 2
    jr .comparar
.vivo:
    ld a, 3
.comparar:
    ld b, a
    ld a, [wEtapaChromia]
    cp b
    ret z
    ld a, b
    ld [wEtapaChromia], a
    call DibujarChromia
    call ActualizarFaunaVisual
    ld a, [wFase]
    cp 3
    ret nz
    call AplicarPaletaFase
    ret

DibujarChromia:
    ld a, [wEtapaChromia]
    cp 3
    jr z, .vivo
    cp 2
    jr z, .bosque
    cp 1
    jr z, .agua
    ld d, TILE_PLANETA_SECO
    jr .tile_listo
.agua:
    ld d, TILE_PLANETA_AGUA
    jr .tile_listo
.bosque:
    ld d, TILE_PLANETA_BOSQUE
    jr .tile_listo
.vivo:
    ld d, TILE_PLANETA_VIVO
.tile_listo:
    call CargarPaletaPlaneta

    ld hl, BG_MAP + (12 * 32) + 14
    call DibujarFilaBordePlaneta
    ld hl, BG_MAP + (13 * 32) + 14
    call DibujarFilaCentroPlaneta
    ld hl, BG_MAP + (14 * 32) + 14
    call DibujarFilaCentroPlaneta
    ld hl, BG_MAP + (15 * 32) + 14
    call DibujarFilaBordePlaneta
    call DibujarResiduosChromia
    call AplicarAtributosChromia
    ret

DibujarFilaBordePlaneta:
    ld c, TILE_VACIO
    call EscribirTileC
    ld c, d
    call EscribirTileC
    call EscribirTileC
    ld c, TILE_VACIO
    call EscribirTileC
    ret

DibujarFilaCentroPlaneta:
    ld c, d
    call EscribirTileC
    call EscribirTileC
    call EscribirTileC
    call EscribirTileC
    ret

EscribirTileC:
    call EsperarVRAM
    ld a, c
    ld [hli], a
    ret

DibujarResiduosChromia:
    ; Limpia los cuatro restos antes de reconstruir el cinturon segun etapa.
    ld c, TILE_VACIO
    ld hl, BG_MAP + (11 * 32) + 14
    call EscribirTileC
    ld hl, BG_MAP + (12 * 32) + 18
    call EscribirTileC
    ld hl, BG_MAP + (16 * 32) + 13
    call EscribirTileC
    ld hl, BG_MAP + (16 * 32) + 17
    call EscribirTileC

    ld a, [wEtapaChromia]
    cp 3
    ret z
    ld c, TILE_RESIDUO
    ld hl, BG_MAP + (11 * 32) + 14
    call EscribirTileC
    ld a, [wEtapaChromia]
    cp 2
    ret z
    ld hl, BG_MAP + (16 * 32) + 13
    call EscribirTileC
    ld a, [wEtapaChromia]
    cp 1
    ret z
    ld hl, BG_MAP + (12 * 32) + 18
    call EscribirTileC
    ld hl, BG_MAP + (16 * 32) + 17
    call EscribirTileC
    ret

AplicarAtributosChromia:
    call EsCGB
    ret nz
    ld a, 1
    ldh [rVBK], a
    ld d, 1 ; paleta BG 1 para las doce celdas visibles del planeta.
    ld hl, BG_MAP + (12 * 32) + 14
    call DibujarFilaBordePlaneta
    ld hl, BG_MAP + (13 * 32) + 14
    call DibujarFilaCentroPlaneta
    ld hl, BG_MAP + (14 * 32) + 14
    call DibujarFilaCentroPlaneta
    ld hl, BG_MAP + (15 * 32) + 14
    call DibujarFilaBordePlaneta
    xor a
    ldh [rVBK], a
    ret

CargarPaletaPlaneta:
    call EsCGB
    ret nz
    ld a, [wEtapaChromia]
    cp 3
    jr z, .vivo
    cp 2
    jr z, .bosque
    cp 1
    jr z, .agua
    ld hl, PaletaPlanetaSeco
    jr .cargar
.agua:
    ld hl, PaletaPlanetaAgua
    jr .cargar
.bosque:
    ld hl, PaletaPlanetaBosque
    jr .cargar
.vivo:
    ld hl, PaletaPlanetaVivo
.cargar:
    ld a, $88 ; BG palette 1, auto incremento.
    ldh [rBCPS], a
    ld b, 8
.loop:
    call EsperarVRAM
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .loop
    ret

DibujarTitulo:
    call EsCGB
    jr nz, .texto
    CARGAR_PANTALLA_CGB TituloCGB
    ld a, 1
    ld [wPantallaCGB], a
    ret
.texto:
    ld hl, BG_MAP + (2 * 32) + 2
    call DibujarLinea16
    ld hl, BG_MAP + (4 * 32) + 3
    ld de, TextoTitulo
    call EscribirTexto
    ld hl, BG_MAP + (6 * 32) + 2
    call DibujarLinea16
    ld hl, BG_MAP + (9 * 32) + 7
    ld de, TextoStart
    call EscribirTexto
    ret

DibujarHUD:
    ld hl, BG_MAP
    ld de, TextoScore
    call EscribirTexto
    xor a
    ld hl, BG_MAP + 6
    call EscribirNumero2

    ld hl, BG_MAP + 9
    ld a, TILE_X
    ld [hli], a
    ld a, TILE_DIGITO0 + 1
    ld [hl], a

    ld hl, BG_MAP + 12
    ld de, TextoTime
    call EscribirTexto
    ld a, SEGUNDOS_PARTIDA
    ld hl, BG_MAP + 17
    call EscribirNumero2

    ; Segunda fila: P = fase; R = restauracion de Chromia.
    ld hl, BG_MAP + 32 + 2
    ld a, TILE_P
    ld [hli], a
    ld a, TILE_DIGITO0 + 1
    ld [hl], a
    ld hl, BG_MAP + 32 + 6
    ld a, TILE_R
    ld [hli], a
    xor a
    call EscribirNumero2
    ret

DibujarLinea16:
    ld b, 16
    ld a, TILE_LINEA
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

EscribirTexto:
.loop:
    ld a, [de]
    cp $FF
    ret z
    ld [hli], a
    inc de
    jr .loop

; A = 0..99, HL = posicion del primer digito.
EscribirNumero2:
    ld b, 0
.decenas:
    cp 10
    jr c, .escribir
    sub 10
    inc b
    jr .decenas
.escribir:
    ld c, a
    call EsperarVRAM
    ld a, b
    add TILE_DIGITO0
    ld [hli], a
    call EsperarVRAM
    ld a, c
    add TILE_DIGITO0
    ld [hl], a
    ret

EsperarVRAM:
.espera:
    ldh a, [rSTAT]
    and 3
    cp 3
    jr z, .espera
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
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    call LimpiarAtributosFondo
    ret

LimpiarAtributosFondo:
    call EsCGB
    ret nz
    ld a, 1
    ldh [rVBK], a
    ld hl, BG_MAP
    ld bc, 32 * 32
.loop:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    xor a
    ldh [rVBK], a
    ret

ConfigurarPaletas:
    ; Fallback DMG con tinta oscura (#805).
    ld a, %11101100
    ldh [rBGP], a
    ld a, %11100100
    ldh [rOBP0], a

    ld a, 1
    ld [wFase], a
    xor a
    ld [wEtapaChromia], a
    call AplicarPaletaFase

    ; OBJ 0 nave; 1 croma/nucleo; 2 semilla; 3 foco/Behemoth.
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

AplicarPaletaFase:
    ld a, [wFase]
    cp 1
    jr z, .fase1
    cp 2
    jr z, .fase2

    ; Fase 3/final: el espacio entero recupera color con Chromia.
    ld a, [wEtapaChromia]
    cp 3
    jr z, .fase3_viva
    cp 2
    jr z, .fase3_bosque
    cp 1
    jr z, .fase3_agua
    ld hl, PaletaFase3
    jr .cargar
.fase3_agua:
    ld hl, PaletaFase3Agua
    jr .cargar
.fase3_bosque:
    ld hl, PaletaFase3Bosque
    jr .cargar
.fase3_viva:
    ld hl, PaletaFase3Viva
    jr .cargar
.fase1:
    ld hl, PaletaFondo
    jr .cargar
.fase2:
    ld hl, PaletaFase2
.cargar:
    ld a, $80
    ldh [rBCPS], a
    ld b, 8
.loop:
    call EsperarVRAM
    ld a, [hli]
    ldh [rBCPD], a
    dec b
    jr nz, .loop
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
    ld a, $80
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoCaptura:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F1
    ldh [rNR12], a
    ld a, [wMultiplicador]
    cp 3
    jr z, .x3
    cp 2
    jr z, .x2
    ld a, $40
    jr .frecuencia
.x2:
    ld a, $70
    jr .frecuencia
.x3:
    ld a, $A0
.frecuencia:
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoRestauracion:
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, $D2
    ldh [rNR12], a
    ld a, $C0
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret

SonidoFoco:
    xor a
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $B3
    ldh [rNR12], a
    ld a, $18
    ldh [rNR13], a
    ld a, $82
    ldh [rNR14], a
    ret

SonidoFase:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $D2
    ldh [rNR12], a
    ld a, $E0
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret

SonidoBehemoth:
    xor a
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $F4
    ldh [rNR12], a
    ld a, $10
    ldh [rNR13], a
    ld a, $82
    ldh [rNR14], a
    ret

SonidoGolpeBehemoth:
    xor a
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $E2
    ldh [rNR12], a
    ld a, $70
    ldh [rNR13], a
    ld a, $85
    ldh [rNR14], a
    ret

SonidoVictoria:
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

SonidoFin:
    xor a
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $E3
    ldh [rNR12], a
    ld a, $20
    ldh [rNR13], a
    ld a, $83
    ldh [rNR14], a
    ret

; ---------------------------- SRAM / records ----------------------------
HabilitarSRAM:
    ld a, $0A
    ld [rRAMG], a
    xor a
    ld [rRAMB], a
    ret

ProtegerSRAM:
    xor a
    ld [rRAMG], a
    ret

CargarRecords:
    call HabilitarSRAM
    ld a, [SRAM_MAGIC0]
    cp $50
    jr nz, .inicializar
    ld a, [SRAM_MAGIC1]
    cp $58
    jr nz, .inicializar
    ld a, [SRAM_MAGIC2]
    cp $39
    jr nz, .inicializar
    ld a, [SRAM_MAGIC3]
    cp $38
    jr nz, .inicializar
    ld a, [SRAM_VERSION]
    cp SRAM_VERSION_ACTUAL
    jr nz, .inicializar

    ld a, [SRAM_MEJOR_PUNTOS]
    ld [wMejorPuntos], a
    ld a, [SRAM_MEJOR_COMBO]
    ld [wMejorCombo], a
    ld a, [SRAM_MEJOR_FASE]
    ld [wMejorFase], a
    ld a, [SRAM_MEJOR_RESTAURACION]
    ld [wMejorRestauracion], a

    call CalcularChecksumRecords
    ld b, a
    ld a, [SRAM_CHECKSUM]
    cp b
    jr nz, .inicializar
    call ProtegerSRAM
    ret
.inicializar:
    xor a
    ld [wMejorPuntos], a
    ld [wMejorCombo], a
    ld [wMejorFase], a
    ld [wMejorRestauracion], a
    call EscribirRecords
    ret

GuardarRecords:
    ld a, [wMejorPuntos]
    ld b, a
    ld a, [wPuntos]
    cp b
    jr c, .combo
    jr z, .combo
    ld [wMejorPuntos], a
.combo:
    ld a, [wMejorCombo]
    ld b, a
    ld a, [wMejorComboPartida]
    cp b
    jr c, .fase
    jr z, .fase
    ld [wMejorCombo], a
.fase:
    ld a, [wMejorFase]
    ld b, a
    ld a, [wFase]
    cp b
    jr c, .restauracion
    jr z, .restauracion
    ld [wMejorFase], a
.restauracion:
    ld a, [wMejorRestauracion]
    ld b, a
    ld a, [wRestauracion]
    cp b
    jr c, .escribir
    jr z, .escribir
    ld [wMejorRestauracion], a
.escribir:
    call EscribirRecords
    ret

EscribirRecords:
    call HabilitarSRAM
    ld a, $50
    ld [SRAM_MAGIC0], a
    ld a, $58
    ld [SRAM_MAGIC1], a
    ld a, $39
    ld [SRAM_MAGIC2], a
    ld a, $38
    ld [SRAM_MAGIC3], a
    ld a, SRAM_VERSION_ACTUAL
    ld [SRAM_VERSION], a

    ld a, [wMejorPuntos]
    ld [SRAM_MEJOR_PUNTOS], a
    ld a, [wMejorCombo]
    ld [SRAM_MEJOR_COMBO], a
    ld a, [wMejorFase]
    ld [SRAM_MEJOR_FASE], a
    ld a, [wMejorRestauracion]
    ld [SRAM_MEJOR_RESTAURACION], a
    call CalcularChecksumRecords
    ld [SRAM_CHECKSUM], a
    call ProtegerSRAM
    ret

CalcularChecksumRecords:
    ld a, [wMejorPuntos]
    ld b, a
    ld a, [wMejorCombo]
    xor b
    ld b, a
    ld a, [wMejorFase]
    xor b
    ld b, a
    ld a, [wMejorRestauracion]
    xor b
    xor $A5
    ret

SECTION "Datos", ROM0
TextoTitulo:
    db TILE_C, TILE_A, TILE_Z, TILE_A, TILE_VACIO
    db TILE_P, TILE_I, TILE_X, TILE_E, TILE_L, TILE_VACIO
    db TILE_DIGITO0 + 9, TILE_DIGITO0 + 8, $FF
TextoStart:
    db TILE_S, TILE_T, TILE_A, TILE_R, TILE_T, $FF
TextoScore:
    db TILE_S, TILE_C, TILE_O, TILE_R, TILE_E, $FF
TextoMejorScore:
    db TILE_M, TILE_VACIO, TILE_S, TILE_C, TILE_O, TILE_R, TILE_E, $FF
TextoTime:
    db TILE_T, TILE_I, TILE_M, TILE_E, $FF
TextoTiempoFin:
    db TILE_T, TILE_I, TILE_M, TILE_E, TILE_EXCL, $FF

PosicionesObjetivo:
    db 24, 40
    db 136, 48
    db 72, 64
    db 120, 112
    db 40, 128
    db 152, 136
    db 88, 88
    db 32, 104
    db 144, 72
    db 56, 144
    db 104, 40
    db 16, 64
    db 128, 128
    db 48, 48
    db 112, 80
    db 64, 120

; Esquinas del Behemoth 32x32. El nucleo salta entre residuos/maquinaria.
PuntosBehemoth:
    db BEHEMOTH_X,      BEHEMOTH_Y
    db BEHEMOTH_X + 24, BEHEMOTH_Y
    db BEHEMOTH_X,      BEHEMOTH_Y + 24
    db BEHEMOTH_X + 24, BEHEMOTH_Y + 24

Tiles:
    ; 0 vacio.
    rept 8
        db $00, $00
    endr

    ; 1 nave/cursor.
    db $18,$00,$3C,$00,$7E,$00,$DB,$00,$FF,$00,$7E,$00,$24,$00,$42,$00
    ; 2 croma libre.
    db $18,$18,$3C,$3C,$7E,$7E,$FF,$FF,$FF,$FF,$7E,$7E,$3C,$3C,$18,$18
    ; 3 linea HUD.
    db $00,$00,$00,$00,$00,$00,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$00

    ; 4-13 digitos 0-9.
    db $3C,$00,$66,$00,$6E,$00,$76,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $18,$00,$38,$00,$18,$00,$18,$00,$18,$00,$18,$00,$7E,$00,$00,$00
    db $3C,$00,$66,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$7E,$00,$00,$00
    db $3C,$00,$66,$00,$06,$00,$1C,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    db $0C,$00,$1C,$00,$3C,$00,$6C,$00,$7E,$00,$0C,$00,$0C,$00,$00,$00
    db $7E,$00,$60,$00,$7C,$00,$06,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    db $1C,$00,$30,$00,$60,$00,$7C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $7E,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$30,$00,$30,$00,$00,$00
    db $3C,$00,$66,$00,$66,$00,$3C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $3C,$00,$66,$00,$66,$00,$3E,$00,$06,$00,$0C,$00,$38,$00,$00,$00

    ; 14-27: C A Z P I X E L S T R O M !
    db $3C,$00,$66,$00,$60,$00,$60,$00,$60,$00,$66,$00,$3C,$00,$00,$00
    db $18,$00,$3C,$00,$66,$00,$66,$00,$7E,$00,$66,$00,$66,$00,$00,$00
    db $7E,$00,$06,$00,$0C,$00,$18,$00,$30,$00,$60,$00,$7E,$00,$00,$00
    db $7C,$00,$66,$00,$66,$00,$7C,$00,$60,$00,$60,$00,$60,$00,$00,$00
    db $3C,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$3C,$00,$00,$00
    db $66,$00,$66,$00,$3C,$00,$18,$00,$3C,$00,$66,$00,$66,$00,$00,$00
    db $7E,$00,$60,$00,$60,$00,$7C,$00,$60,$00,$60,$00,$7E,$00,$00,$00
    db $60,$00,$60,$00,$60,$00,$60,$00,$60,$00,$60,$00,$7E,$00,$00,$00
    db $3C,$00,$66,$00,$60,$00,$3C,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    db $7E,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
    db $7C,$00,$66,$00,$66,$00,$7C,$00,$78,$00,$6C,$00,$66,$00,$00,$00
    db $3C,$00,$66,$00,$66,$00,$66,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    db $63,$00,$77,$00,$7F,$00,$6B,$00,$63,$00,$63,$00,$63,$00,$00,$00
    db $18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00,$18,$00,$00,$00

    ; 28 semilla; 29 foco contaminante.
    db $00,$00,$18,$18,$3C,$24,$18,$18,$3C,$24,$66,$42,$24,$24,$00,$00
    db $7E,$7E,$42,$7E,$5A,$66,$5A,$66,$42,$7E,$66,$5A,$3C,$3C,$18,$18

    ; 30-33 Chromia: seco -> agua -> bosque -> vivo. Patrones llenos para que
    ; su paleta CGB independiente no pinte rectangulos transparentes.
    db $FF,$00,$DB,$24,$FF,$00,$BD,$42,$FF,$00,$E7,$18,$FF,$00,$DB,$24
    db $FF,$00,$FF,$24,$FF,$18,$FF,$42,$FF,$18,$FF,$24,$FF,$00,$FF,$42
    db $FF,$18,$FF,$5A,$FF,$24,$FF,$66,$FF,$18,$FF,$7E,$FF,$24,$FF,$5A
    db $FF,$3C,$FF,$66,$FF,$5A,$FF,$7E,$FF,$66,$FF,$5A,$FF,$3C,$FF,$66

    ; 34-35 masa de chatarra/glitch del Behemoth; 36 nucleo; 37 residuo.
    db $FF,$A5,$DB,$FF,$7E,$DB,$FF,$66,$BD,$FF,$7E,$DB,$FF,$A5,$DB,$FF
    db $FF,$5A,$BD,$FF,$E7,$BD,$FF,$99,$DB,$FF,$E7,$BD,$FF,$5A,$BD,$FF
    db $18,$18,$3C,$3C,$7E,$66,$FF,$DB,$FF,$DB,$7E,$66,$3C,$3C,$18,$18
    db $24,$24,$5A,$7E,$3C,$66,$7E,$5A,$18,$3C,$66,$7E,$3C,$5A,$24,$24
TilesFin:

; PaletaFondo conserva estas etiquetas porque el smoke comun de #805 mide el
; contraste de su color de tinta. Fase 1: Chromia aun vivo.
PaletaFondo:
    dw $63BE, $10C4, $1986, $0000
PaletaFondoFin:

; Fase 2: zona muerta, fria e industrial.
PaletaFase2:
    dw $6739, $14A5, $2D2B, $0000
PaletaFase2Fin:

; Fase 3 empieza desaturada y recupera color por umbrales 25/50/75.
PaletaFase3:
    dw $6318, $14A5, $2529, $0000
PaletaFase3Fin:
PaletaFase3Agua:
    dw $6F7B, $1128, $3D8C, $0000
PaletaFase3Bosque:
    dw $73BD, $0D27, $22AC, $0000
PaletaFase3Viva:
    dw $7FDE, $0D27, $2FED, $0000

; Paleta BG 1 exclusiva del planeta: los tiles usan colores opacos.
PaletaPlanetaSeco:
    dw $6318, $39CE, $2108, $0000
PaletaPlanetaAgua:
    dw $6318, $5E94, $3D8C, $1086
PaletaPlanetaBosque:
    dw $6318, $2FED, $1DA8, $0C84
PaletaPlanetaVivo:
    dw $6318, $7F40, $2FED, $15CF

PaletasObjetos:
    ; Nave verde/cian.
    dw $7FFF, $7FE0, $03E0, $0000
    ; Croma/nucleo: rojo/naranja.
    dw $7FFF, $421F, $001F, $0000
    ; Semilla: verde vivo.
    dw $7FFF, $2FE0, $03A0, $0000
    ; Foco/Behemoth: magenta/metal contaminado.
    dw $7FFF, $7C1F, $4010, $0000
PaletasObjetosFin:

SECTION "Variables", WRAM0
wEstado:               ds 1
wJugadorX:             ds 1
wJugadorY:             ds 1
wObjetivoX:            ds 1
wObjetivoY:            ds 1
wObjetivoIndice:       ds 1
wTipoObjetivo:         ds 1
wDirX:                 ds 1
wDirY:                 ds 1
wObjetivoTick:         ds 1
wIntervaloObjetivo:    ds 1
wPuntos:               ds 1
wCombo:                ds 1
wComboFrames:          ds 1
wMultiplicador:        ds 1
wMejorComboPartida:    ds 1
wRestauracion:         ds 1
wFocosCerrados:        ds 1
wEtapaChromia:         ds 1
wFase:                 ds 1
wRng:                  ds 1
wTiempo:               ds 1
wFrames:               ds 1
wTeclas:               ds 1
wTeclasPrevias:        ds 1
wTeclasNuevas:         ds 1
wMejorPuntos:          ds 1
wMejorCombo:           ds 1
wMejorFase:            ds 1
wMejorRestauracion:    ds 1
wBossActivo:           ds 1
wBossDerrotado:        ds 1
wBossGolpes:           ds 1
wBossPunto:            ds 1
wBossPuntoX:           ds 1
wBossPuntoY:           ds 1
wBossInvuln:           ds 1

SECTION "TituloCGBVars", WRAM0
wPantallaCGB: ds 1

SECTION "TituloCGB", ROMX
    PANTALLA_CGB TituloCGB, "assets/titulo"

INCLUDE "escenario.asm"
