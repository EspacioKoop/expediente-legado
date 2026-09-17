; Cartucho estándar de las ROMs propias (#808): MBC5 con 8 KiB de RAM y batería.
;
; La cabecera la fija rgbfix con comun/cartucho.mk. Al encenderse, el MBC5 mapea
; el banco 1 en $4000-$7FFF y deja la RAM del cartucho protegida. Las secciones
; ROMX pueden caer en cualquier banco: antes de leer una hay que mapearla con
; CAMBIAR_BANCO etiqueta, y quien cambie de banco temporalmente debe devolver
; el que hubiera (wBancoROM).
;
; Uso desde una ROM:
;     INCLUDE "../comun/cartucho.asm"
;     ...
;     call IniciarCartucho      ; al arrancar, tras fijar la pila

DEF rRAMG  EQU $0000 ; $0A habilita la RAM del cartucho; $00 la protege
DEF rROMB0 EQU $2000 ; banco ROM mapeado en $4000-$7FFF
DEF rRAMB  EQU $4000 ; banco de RAM mapeado en $A000-$BFFF

; CAMBIAR_BANCO etiqueta: mapea el banco donde está la etiqueta.
MACRO CAMBIAR_BANCO
    ld a, BANK(\1)
    call CambiarBanco
ENDM

SECTION "CartuchoVars", WRAM0
wBancoROM: ds 1

SECTION "Cartucho", ROM0

; Estado conocido al arrancar: banco 1 mapeado y RAM del cartucho protegida.
IniciarCartucho:
    xor a
    ld [rRAMG], a
    ld [rRAMB], a
    ld a, 1
    ; sigue en CambiarBanco

; A = banco. Lo mapea y lo recuerda para poder volver a él.
CambiarBanco:
    ld [wBancoROM], a
    ld [rROMB0], a
    ret
