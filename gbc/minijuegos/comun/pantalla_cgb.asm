; Pantallas completas de Game Boy Color generadas con scripts/gbc_imagen_a_tiles.py.
;
; Una pantalla son hasta 512 tiles (256 por banco de VRAM), un mapa de 20x18,
; un mapa de atributos CGB (paleta, banco y volteo por tile) y 8 paletas de fondo.
; Todo se escribe con la LCD APAGADA: son varios KB y en VBlank no caben.
;
; Solo en Game Boy Color. En una Game Boy clásica rVBK no existe y los tiles del
; banco 1 pisarían los del banco 0, así que cada ROM pregunta antes a EsCGB y,
; si no, usa su título de texto.
;
; Uso desde una ROM:
;     ld hl, MiPantalla          ; descriptor definido con PANTALLA_CGB
;     call CargarPantallaCGB     ; LCD apagada
;     ...
;     call DescargarPantallaCGB  ; antes de volver a sus tiles: limpia atributos
;
; Las variantes de una pantalla (gbc_imagen_a_tiles.convertir_con_variantes) son
; parches de celdas que se aplican con la LCD encendida:
;     ld hl, MiPantalla_Variante     ; o MiPantalla_Variante_Base para deshacerla
;     call AplicarParcheCGB

IF !DEF(rVBK)
DEF rVBK EQU $FF4F
ENDC
IF !DEF(rBCPS)
DEF rBCPS EQU $FF68
ENDC
IF !DEF(rBCPD)
DEF rBCPD EQU $FF69
ENDC
IF !DEF(rSTAT)
DEF rSTAT EQU $FF41
ENDC

; PANTALLA_CGB etiqueta, "ruta/prefijo" — define el descriptor y los datos.
MACRO PANTALLA_CGB
\1:
    dw \1_Tiles0, \1_Tiles0Fin - \1_Tiles0
    dw \1_Tiles1, \1_Tiles1Fin - \1_Tiles1
    dw \1_Tilemap, \1_Attrmap, \1_Paletas
\1_Tiles0:
    INCLUDE STRCAT(\2, "_tiles0.inc")
\1_Tiles0Fin:
\1_Tiles1:
    INCLUDE STRCAT(\2, "_tiles1.inc")
\1_Tiles1Fin:
\1_Tilemap:
    INCLUDE STRCAT(\2, "_tilemap.inc")
\1_Attrmap:
    INCLUDE STRCAT(\2, "_attrmap.inc")
\1_Paletas:
    INCLUDE STRCAT(\2, "_paletas.inc")
ENDM

SECTION "PantallaCGB", ROM0

; Z si es una Game Boy Color. Se mira el hardware y no el registro A del
; arranque: rVBK se lee $FE|banco en GBC y $FF en una Game Boy clásica, donde no
; existe. (El registro A no es fiable en todos los emuladores sin boot ROM.)
EsCGB:
    xor a
    ldh [rVBK], a
    ldh a, [rVBK]
    cp $FE
    ret

; Lee un puntero de 16 bits de [HL] en DE y avanza HL.
LeerPunteroCGB:
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    ret

; Copia BC bytes de DE a HL.
CopiarCGB:
    ld a, b
    or c
    ret z
.bucle:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .bucle
    ret

; Copia 18 filas de 20 bytes desde DE al mapa de fondo ($9800), con el
; banco de VRAM ya seleccionado. Las columnas 20-31 no se ven.
CopiarMapaCGB:
    ld hl, $9800
    ld b, 18
.fila:
    push bc
    ld bc, 20
    call CopiarCGB
    ld bc, 32 - 20
    add hl, bc
    pop bc
    dec b
    jr nz, .fila
    ret

; HL = descriptor de PANTALLA_CGB. LCD apagada.
CargarPantallaCGB:
    ; Tiles del banco 0.
    call LeerPunteroCGB
    push de
    call LeerPunteroCGB
    ld b, d
    ld c, e
    pop de
    push hl
    xor a
    ldh [rVBK], a
    ld hl, $8000
    call CopiarCGB
    pop hl

    ; Tiles del banco 1.
    call LeerPunteroCGB
    push de
    call LeerPunteroCGB
    ld b, d
    ld c, e
    pop de
    push hl
    ld a, 1
    ldh [rVBK], a
    ld hl, $8000
    call CopiarCGB
    pop hl

    ; Mapa de tiles (banco 0) y de atributos (banco 1).
    call LeerPunteroCGB
    push hl
    xor a
    ldh [rVBK], a
    call CopiarMapaCGB
    pop hl
    call LeerPunteroCGB
    push hl
    ld a, 1
    ldh [rVBK], a
    call CopiarMapaCGB
    pop hl

    ; 8 paletas x 4 colores x 2 bytes, con autoincremento.
    call LeerPunteroCGB
    ld a, $80
    ldh [rBCPS], a
    ld b, 64
.paletas:
    ld a, [de]
    ldh [rBCPD], a
    inc de
    dec b
    jr nz, .paletas

    xor a
    ldh [rVBK], a
    ret

; Espera a HBlank o VBlank (modos 0 y 1) sin llamada: la escritura que sigue
; tiene que caer dentro de la ventana, que en HBlank dura unos 20 µs.
MACRO ESPERAR_ESCRITURA_CGB
.espera\1:
    ldh a, [rSTAT]
    and 2
    jr nz, .espera\1
ENDM

; HL = parche: n y, n veces, fila, columna, tile y atributos. Sirve con la LCD
; encendida o apagada. Deja el banco 0 de VRAM seleccionado.
AplicarParcheCGB:
    ld a, [hli]
    ld b, a
.celda:
    push bc
    ; DE = $9800 + fila * 32 + columna
    ld a, [hli]
    ld e, a
    ld d, 0
    REPT 5
    sla e
    rl d
    ENDR
    ld a, [hli]
    add e
    ld e, a
    ld a, d
    adc $98
    ld d, a
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a

    xor a
    ldh [rVBK], a
    ESPERAR_ESCRITURA_CGB tile
    ld a, c
    ld [de], a
    ld a, 1
    ldh [rVBK], a
    ESPERAR_ESCRITURA_CGB atributo
    ld a, b
    ld [de], a

    pop bc
    dec b
    jr nz, .celda
    xor a
    ldh [rVBK], a
    ret

; Devuelve el fondo a atributos neutros (paleta 0, banco 0, sin volteo) para que
; la ROM vuelva a usar sus propios tiles. LCD apagada. Los tiles del juego se
; recargan después con su propia rutina.
DescargarPantallaCGB:
    ld a, 1
    ldh [rVBK], a
    ld hl, $9800
    ld bc, 32 * 32
.bucle:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .bucle
    xor a
    ldh [rVBK], a
    ret
