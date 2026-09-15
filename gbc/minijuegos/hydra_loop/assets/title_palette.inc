; HYDRA_LOOP - paleta BG GBC de 4 colores, formato BGR555 little-endian via dw.
; Indices iguales a los usados por title_tiles.asm.

HydraLoopTitlePalette:
    dw $21AD ; 0: rgb(105,110,67) #696E43
    dw $0C83 ; 1: rgb(25,36,29) #19241D
    dw $0820 ; 2: rgb(6,13,16) #060D10
    dw $0000 ; 3: rgb(4,11,16) #040B10 -> negro GBC para separar sombras
HydraLoopTitlePaletteFin:
