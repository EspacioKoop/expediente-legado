; Parches de celdas: n, y n veces (fila, columna, tile, atributos).
; <Etiqueta>_<variante> aplica la variante; ..._Base la deshace.
JuegoCGB_Abierta1:
    db 6
    db 6, 2, $5C, $0B
    db 6, 3, $5D, $0B
    db 6, 4, $5E, $0B
    db 7, 2, $5F, $0A
    db 7, 3, $60, $0F
    db 7, 4, $8F, $03
JuegoCGB_Abierta1_Base:
    db 6
    db 6, 2, $79, $03
    db 6, 3, $7A, $06
    db 6, 4, $7B, $03
    db 7, 2, $8D, $02
    db 7, 3, $8E, $06
    db 7, 4, $8F, $03
JuegoCGB_Abierta2:
    db 4
    db 6, 8, $61, $0B
    db 6, 9, $62, $0B
    db 7, 8, $63, $0A
    db 7, 9, $64, $0B
JuegoCGB_Abierta2_Base:
    db 4
    db 6, 8, $7F, $06
    db 6, 9, $80, $06
    db 7, 8, $93, $06
    db 7, 9, $94, $06
JuegoCGB_Abierta3:
    db 4
    db 6, 14, $65, $0B
    db 6, 15, $66, $0E
    db 7, 14, $67, $0A
    db 7, 15, $68, $0B
JuegoCGB_Abierta3_Base:
    db 4
    db 6, 14, $85, $06
    db 6, 15, $86, $06
    db 7, 14, $99, $06
    db 7, 15, $9A, $06
JuegoCGB_Correcta1:
    db 4
    db 16, 4, $69, $08
    db 16, 5, $6A, $08
    db 17, 4, $6B, $08
    db 17, 5, $6C, $08
JuegoCGB_Correcta1_Base:
    db 4
    db 16, 4, $3D, $08
    db 16, 5, $3E, $08
    db 17, 4, $4E, $08
    db 17, 5, $4F, $08
JuegoCGB_Correcta2:
    db 4
    db 16, 6, $6A, $28
    db 16, 7, $69, $28
    db 17, 6, $6C, $28
    db 17, 7, $6B, $28
JuegoCGB_Correcta2_Base:
    db 4
    db 16, 6, $3E, $28
    db 16, 7, $3D, $28
    db 17, 6, $4F, $28
    db 17, 7, $4E, $28
JuegoCGB_Correcta3:
    db 2
    db 16, 9, $6D, $08
    db 17, 9, $6E, $08
JuegoCGB_Correcta3_Base:
    db 2
    db 16, 9, $40, $08
    db 17, 9, $51, $08
