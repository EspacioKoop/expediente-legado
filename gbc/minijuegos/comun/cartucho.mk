# Cartucho estándar de las ROMs propias (#808): MBC5 con 8 KiB de RAM y batería.
# La portátil guarda la RAM con batería de cada ROM en su propio .sav, así que
# cualquier ROM puede guardar récords sin cambiar de cartucho.
#
# Uso en el Makefile de cada ROM:
#     include ../comun/cartucho.mk
#     rgbfix $(RGBFIX_CARTUCHO) $@
RGBFIX_CARTUCHO := -m 0x1B -r 0x02 -p 255 -v
