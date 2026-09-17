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

DEF TILE_VACIO    EQU 0
DEF TILE_JUGADOR  EQU 1
DEF TILE_OBJETIVO EQU 2
DEF TILE_LINEA    EQU 3
DEF TILE_DIGITO0  EQU 4
DEF TILE_C        EQU 14
DEF TILE_A        EQU 15
DEF TILE_Z        EQU 16
DEF TILE_P        EQU 17
DEF TILE_I        EQU 18
DEF TILE_X        EQU 19
DEF TILE_E        EQU 20
DEF TILE_L        EQU 21
DEF TILE_S        EQU 22
DEF TILE_T        EQU 23
DEF TILE_R        EQU 24
DEF TILE_O        EQU 25
DEF TILE_M        EQU 26
DEF TILE_EXCL     EQU 27
DEF TILE_SEMILLA  EQU 28
DEF TILE_FOCO     EQU 29

DEF TIPO_CROMA   EQU 0
DEF TIPO_SEMILLA EQU 1
DEF TIPO_FOCO    EQU 2

DEF SEGUNDOS_PARTIDA EQU 45
DEF FASE2_TIEMPO     EQU 30
DEF FASE3_TIEMPO     EQU 15
DEF FRAMES_SEGUNDO   EQU 60
DEF COMBO_DURACION   EQU 90
DEF COMBO_X2         EQU 3
DEF COMBO_X3         EQU 6
DEF RESTAURA_SEMILLA EQU 4
DEF RESTAURA_FOCO    EQU 12

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
    ; Se entra aqui justo despues del VBlank. El HUD y los sprites se mantienen
    ; pequenos para dejar la mayor parte de las 160x144 a la accion.
    call ActualizarHUD
    call MoverJugador
    call MoverObjetivo
    call TickCombo
    call ComprobarCaptura
    call TickTiempo
    call ActualizarOAM

    ld a, [wTiempo]
    or a
    jr nz, Bucle
    call SonidoFin
    call MostrarFin
    jr Bucle

EstadoFin:
    ld a, [wTeclasNuevas]
    and KEY_A | KEY_START
    jr z, Bucle
    call SonidoInicio
    call IniciarPartida
    jr Bucle

; Lee cruceta y botones. Los cuatro bits bajos son direcciones y los cuatro
; altos son A/B/Select/Start. Tambien calcula pulsaciones nuevas.
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

    ld a, 1
    ld [wMultiplicador], a
    ld [wFase], a

    ; La semilla depende del reloj hardware en el instante de empezar. Evita
    ; que cada partida repita la misma secuencia sin meter estado externo.
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
    call SiguienteObjetivo
    call ActualizarOAM

    ld a, ESTADO_JUEGO
    ld [wEstado], a
    call ActivarLCD
    ret

MostrarFin:
    ; El record se consolida antes de pintar la pantalla final. La persistencia
    ; es privada de esta ROM y no toca Partida/Jornada ni ningun reward externo.
    call GuardarRecords
    call DesactivarLCD
    call LimpiarOAM
    call LimpiarFondo

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

    ; R = mejor restauracion. X = mejor combo. P = fase maxima.
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
    cp 33 ; reserva las dos primeras filas para el HUD.
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
    ; Los focos contaminantes son instalaciones: permanecen fijos hasta que la
    ; nave se desvia de su ruta para cerrarlos. Las semillas se mueven mas lento.
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
    ; Encadenar capturas antes de que expire el contador sube el multiplicador.
    ; El combo se capa en 9 porque el HUD comunica x1/x2/x3 y el record cabe
    ; en una cifra sin ampliar el HUD.
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

    ; Suma x1/x2/x3 y satura en 99 incluso si el salto cruza el limite.
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
    ; Cerrar una fuente de dano es deliberadamente incompatible con mantener
    ; el combo: obliga a elegir entre puntuacion inmediata y restauracion.
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

    ; El cierre aporta un punto fijo, nunca multiplicado.
    ld a, [wPuntos]
    cp 99
    ret nc
    inc a
    ld [wPuntos], a
    ret

; A = incremento de restauracion. Satura a 99.
SumarRestauracion:
    ld b, a
    ld a, [wRestauracion]
    add b
    cp 100
    jr c, .guardar
    ld a, 99
.guardar:
    ld [wRestauracion], a
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
    ; Usa rangos, no igualdad: con multiplicadores el score puede saltar
    ; directamente por encima de 5/10/20. Cada fase tambien baja el techo.
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
    ; LFSR de 8 bits. $B8 corresponde al polinomio x^8+x^6+x^5+x^4+1
    ; usando desplazamiento a la derecha. El estado cero se evita explicitamente.
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

    ; Fase 1: croma y semillas. Fases 2/3: aparece la contaminacion activa.
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
    ret

.fase2:
    ld a, 2
    ld [wFase], a
    ld a, 3
    ld [wIntervaloObjetivo], a
    call AplicarPaletaFase
    call SonidoFase
    ret
.fase3:
    ld a, 3
    ld [wFase], a
    ld a, 2
    ld [wIntervaloObjetivo], a
    call AplicarPaletaFase
    call SonidoFase
    ret
.guardar_frame:
    ld [wFrames], a
    ret

ActualizarOAM:
    ld hl, OAM_BASE
    ld a, [wJugadorY]
    ld [hli], a
    ld a, [wJugadorX]
    ld [hli], a
    ld a, TILE_JUGADOR
    ld [hli], a
    xor a
    ld [hli], a

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
    add TILE_DIGITO0
    ld [hl], a

    ld a, [wRestauracion]
    ld hl, BG_MAP + 32 + 7
    call EscribirNumero2
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
    ; Al salir del titulo a pantalla completa se recuperan tiles, paleta y
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
    ; El OR del contador modifica A: sin repetir el xor, cada celda recibia el
    ; contador y el mapa se llenaba de tiles de letras (#805).
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

ConfigurarPaletas:
    ; Fallback DMG. La tinta permanece oscura y legible (#805).
    ld a, %11101100
    ldh [rBGP], a
    ld a, %11100100
    ldh [rOBP0], a

    ld a, 1
    ld [wFase], a
    call AplicarPaletaFase

    ; OBJ 0 = nave; 1 = croma; 2 = semilla; 3 = foco contaminante.
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
    cp 3
    jr z, .fase3
    cp 2
    jr z, .fase2
    ld hl, PaletaFondo
    jr .cargar
.fase2:
    ld hl, PaletaFase2
    jr .cargar
.fase3:
    ld hl, PaletaFase3
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

    ; El combo se oye: x2 y x3 elevan progresivamente el tono de captura.
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
    cp $50 ; P
    jr nz, .inicializar
    ld a, [SRAM_MAGIC1]
    cp $58 ; X
    jr nz, .inicializar
    ld a, [SRAM_MAGIC2]
    cp $39 ; 9
    jr nz, .inicializar
    ld a, [SRAM_MAGIC3]
    cp $38 ; 8
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

; Tile 0: vacio.
; Tile 1: nave/cursor.
; Tile 2: croma libre (rombo).
; Tile 3: separador horizontal.
Tiles:
    rept 8
        db $00, $00
    endr

    db $18, $00, $3C, $00, $7E, $00, $DB, $00
    db $FF, $00, $7E, $00, $24, $00, $42, $00

    db $18, $18, $3C, $3C, $7E, $7E, $FF, $FF
    db $FF, $FF, $7E, $7E, $3C, $3C, $18, $18

    db $00, $00, $00, $00, $00, $00, $FF, $00
    db $FF, $00, $00, $00, $00, $00, $00, $00

; Digitos 0-9, color de fondo 1.
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

; C A Z P I X E L S T R O M !
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

; Tile 28: semilla de ecosistema (brote/pixel vivo).
    db $00,$00,$18,$18,$3C,$24,$18,$18,$3C,$24,$66,$42,$24,$24,$00,$00
; Tile 29: foco contaminante / instalacion extractiva.
    db $7E,$7E,$42,$7E,$5A,$66,$5A,$66,$42,$7E,$66,$5A,$3C,$3C,$18,$18
TilesFin:

; PaletaFondo conserva estas etiquetas porque el smoke comun de #805 mide el
; contraste de su color de tinta. Fase 1: Chromia aun vivo.
PaletaFondo:
    dw $63BE, $10C4, $1986, $0000
PaletaFondoFin:

; Fase 2: zona muerta, mas fria e industrial pero con tinta de alto contraste.
PaletaFase2:
    dw $6739, $14A5, $2D2B, $0000
PaletaFase2Fin:

; Fase 3: restauracion, vuelve una gama mas viva de agua y vegetacion.
PaletaFase3:
    dw $7FDE, $0D27, $22AC, $0000
PaletaFase3Fin:

PaletasObjetos:
    ; Nave verde/cian.
    dw $7FFF, $7FE0, $03E0, $0000
    ; Croma libre: rojo/naranja.
    dw $7FFF, $421F, $001F, $0000
    ; Semilla: verde vivo.
    dw $7FFF, $2FE0, $03A0, $0000
    ; Foco: magenta/metal contaminado.
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

; Pantalla completa CGB (#808): si el fondo la tiene cargada, para devolverle
; sus tiles al juego al salir.
SECTION "TituloCGBVars", WRAM0
wPantallaCGB: ds 1

SECTION "TituloCGB", ROMX
    PANTALLA_CGB TituloCGB, "assets/titulo"
