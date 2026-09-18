; Fixture SRAM end-to-end para #456/#124.
; Codigo original del proyecto, licencia MIT (LICENSE en la raiz).
;
; Cada variante usa MBC5 + 8 KiB RAM + bateria. Al arrancar escribe un
; marcador propio en $A000 y aumenta una sola vez el contador de $A001.
; Un save restaurado se distingue de un arranque limpio porque conserva ambos.

IF !DEF(MARCADOR_SRAM)
    FAIL "MARCADOR_SRAM debe definirse antes de incluir main.asm"
ENDC

DEF rRAMG EQU $0000
DEF rRAMB EQU $4000
DEF SRAM_BASE EQU $A000

SECTION "Header", ROM0[$0100]
    jp Inicio
    ds $0134 - @, 0
    db "SIGA98SRAM"
    ds $0143 - @, 0
    db $80 ; Dual-mode: tambien prueba la ruta usada por las ROMs propias.
    ds $0150 - @, 0

SECTION "SRAM smoke", ROM0[$0150]
Inicio:
    di
    ld sp, $DFFF

    ; Habilita la RAM externa y selecciona el banco 0.
    ld a, $0A
    ld [rRAMG], a
    xor a
    ld [rRAMB], a

    ; Si no es nuestro save, inicializa marcador + contador.
    ld a, [SRAM_BASE]
    cp MARCADOR_SRAM
    jr z, .estado_valido
    ld a, MARCADOR_SRAM
    ld [SRAM_BASE], a
    xor a
    ld [SRAM_BASE + 1], a

.estado_valido:
    ld a, [SRAM_BASE + 1]
    inc a
    ld [SRAM_BASE + 1], a

.bucle:
    jr .bucle
