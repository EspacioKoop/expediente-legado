; Fixture DMG-only minimo para #456/#124.
; Codigo original del proyecto, licencia MIT (LICENSE en la raiz).
;
; Demuestra que SameBoy mantiene compatibilidad con cartuchos Game Boy clasicos:
; cabecera CGB $00, paleta DMG y framebuffer 160x144 no uniforme.

DEF rLCDC EQU $FF40
DEF rLY   EQU $FF44
DEF rBGP  EQU $FF47

DEF VRAM_TILES EQU $8000

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "SIGA98DMG"
    ds $0143 - @, 0
    db $00 ; DMG-only: cartucho Game Boy clasico, sin flag CGB.
    ds $0150 - @, 0

SECTION "Smoke DMG", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF

.espera_vblank:
    ldh a, [rLY]
    cp 144
    jr c, .espera_vblank

    xor a
    ldh [rLCDC], a

    ; Mapeo DMG 0->blanco, 1->gris claro, 2->gris oscuro, 3->negro.
    ld a, $E4
    ldh [rBGP], a

    ; Tile 0 alternando indices 1 y 2: el framebuffer debe contener variacion
    ; visible sin depender de registros exclusivos de CGB.
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
