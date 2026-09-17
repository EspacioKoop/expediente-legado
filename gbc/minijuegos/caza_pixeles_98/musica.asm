; Musica secuenciada de Pixel Exodus (#882).
; Usa exclusivamente el canal 2 para que los SFX existentes del canal 1
; puedan sonar encima sin cortar la base musical.

DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19

DEF MUSICA_SILENCIO EQU 0
DEF MUSICA_FASE1    EQU 1
DEF MUSICA_FASE2    EQU 2
DEF MUSICA_FASE3    EQU 3
DEF MUSICA_BOSS     EQU 4
DEF MUSICA_FINAL_OK EQU 5
DEF MUSICA_FINAL_KO EQU 6

DEF MUSICA_STEP_FRAMES EQU 12
DEF MUSICA_PASOS       EQU 8

SECTION "MusicaPixelExodus", ROM0

InicializarMusicaSistema:
    ; Canal 1 (SFX) + canal 2 (musica) a ambos lados.
    ld a, $33
    ldh [rNR51], a
    xor a
    ld [wMusicaModo], a
    ld [wMusicaTick], a
    ld [wMusicaPaso], a
    ldh [rNR22], a
    ret

IniciarMusicaFase1:
    ld a, MUSICA_FASE1
    jp SeleccionarMusica

CambiarMusicaFase:
    ld a, [wFase]
    cp 1
    jp z, IniciarMusicaFase1
    cp 2
    jr z, .fase2
    ld a, MUSICA_FASE3
    jp SeleccionarMusica
.fase2:
    ld a, MUSICA_FASE2
    jp SeleccionarMusica

IniciarMusicaBoss:
    ld a, MUSICA_BOSS
    jp SeleccionarMusica

IniciarMusicaFinal:
    ld a, [wBossDerrotado]
    or a
    jr z, .derrota
    ld a, MUSICA_FINAL_OK
    jp SeleccionarMusica
.derrota:
    ld a, MUSICA_FINAL_KO
    jp SeleccionarMusica

SeleccionarMusica:
    ld [wMusicaModo], a
    xor a
    ld [wMusicaTick], a
    ld [wMusicaPaso], a
    call TocarPasoMusicaActual
    ret

SilenciarMusica:
    xor a
    ld [wMusicaModo], a
    ld [wMusicaTick], a
    ld [wMusicaPaso], a
    ldh [rNR22], a
    ret

; Secuenciador deliberadamente pequeno: ocho pasos por patron. El duty/envelope
; son suaves para dejar los SFX del canal 1 al frente de la mezcla.
TickMusica:
    ld a, [wMusicaModo]
    or a
    ret z

    ld a, [wMusicaTick]
    inc a
    cp MUSICA_STEP_FRAMES
    jr c, .guardar_tick
    xor a
    ld [wMusicaTick], a
    call TocarPasoMusicaActual
    ret
.guardar_tick:
    ld [wMusicaTick], a
    ret

TocarPasoMusicaActual:
    call TablaMusicaActual
    ld a, [wMusicaPaso]
    add a
    ld e, a
    ld d, 0
    add hl, de

    ld a, $80 ; duty 50 %, longitud libre.
    ldh [rNR21], a
    ld a, $72 ; volumen moderado, decay corto.
    ldh [rNR22], a
    ld a, [hli]
    ldh [rNR23], a
    ld a, [hl]
    and 7
    or $80
    ldh [rNR24], a

    ld a, [wMusicaPaso]
    inc a
    and MUSICA_PASOS - 1
    ld [wMusicaPaso], a
    ret

TablaMusicaActual:
    ld a, [wMusicaModo]
    cp MUSICA_FASE1
    jr z, .fase1
    cp MUSICA_FASE2
    jr z, .fase2
    cp MUSICA_FASE3
    jr z, .fase3
    cp MUSICA_BOSS
    jr z, .boss
    cp MUSICA_FINAL_OK
    jr z, .final_ok
    ld hl, PatronFinalKO
    ret
.fase1:
    ld hl, PatronFase1
    ret
.fase2:
    ld hl, PatronFase2
    ret
.fase3:
    ld hl, PatronFase3
    ret
.boss:
    ld hl, PatronBoss
    ret
.final_ok:
    ld hl, PatronFinalOK
    ret

SECTION "MusicaPixelExodusDatos", ROM0
; Parejas NR23/NR24. Son motivos originales y cortos, pensados como identidad
; de fase, no como reproduccion de ninguna obra existente.
PatronFase1:
    db $16,6, $72,6, $B0,6, $D6,6, $B0,6, $72,6, $3E,6, $72,6
PatronFase2:
    db $40,5, $40,5, $90,5, $20,5, $40,5, $D0,4, $20,5, $90,5
PatronFase3:
    db $72,6, $B0,6, $E8,6, $16,7, $E8,6, $B0,6, $D6,6, $16,7
PatronBoss:
    db $20,4, $90,4, $20,4, $D0,4, $40,5, $20,4, $90,4, $D0,4
PatronFinalOK:
    db $72,6, $B0,6, $D6,6, $16,7, $3E,7, $16,7, $D6,6, $3E,7
PatronFinalKO:
    db $90,5, $40,5, $20,5, $D0,4, $90,4, $40,4, $20,4, $D0,3

SECTION "MusicaPixelExodusVars", WRAM0
wMusicaModo: ds 1
wMusicaTick: ds 1
wMusicaPaso: ds 1
