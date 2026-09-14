; Fixture CGB-only minimo para #456/#124.
; Codigo original del proyecto, licencia MIT (LICENSE en la raiz).
;
; No es un minijuego: existe para demostrar que el nucleo acepta una ROM
; marcada como CGB-only y ejecuta registros de paleta propios de Color.

DEF rLCDC EQU $FF40
DEF rLY   EQU $FF44
DEF rBCPS EQU $FF68
DEF rBCPD EQU $FF69

DEF VRAM_TILES EQU $8000

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "SIGA98CGB"
    ds $0143 - @, 0
    db $C0 ; CGB-only: no debe arrancar mediante fallback DMG.
    ds $0150 - @, 0

SECTION "Smoke CGB", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF

.espera_vblank:
    ldh a, [rLY]
    cp 144
    jr c, .espera_vblank

    xor a
    ldh [rLCDC], a

    ; Paleta BG 0: blanco, rojo, verde y azul en formato BGR555.
    ld a, $80
    ldh [rBCPS], a
    ld a, $FF
    ldh [rBCPD], a
    ld a, $7F
    ldh [rBCPD], a
    ld a, $1F
    ldh [rBCPD], a
    xor a
    ldh [rBCPD], a
    ld a, $E0
    ldh [rBCPD], a
    ld a, $03
    ldh [rBCPD], a
    xor a
    ldh [rBCPD], a
    ld a, $7C
    ldh [rBCPD], a

    ; Tile 0 con patron alterno para que el framebuffer no sea uniforme.
    ld hl, VRAM_TILES
    ld b, 8
.tile:
    ld a, $AA
    ld [hli], a
    ld a, $55
    ld [hli], a
    dec b
    jr nz, .tile

    ld a, $91
    ldh [rLCDC], a

.bucle:
    jr .bucle
