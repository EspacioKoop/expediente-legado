"""Genera el arte de River of the Dragon para Game Boy Color (#808).

Parte de `referencia/lamina.png` y escribe en `assets/`:

- `juego_*`: el panel de juego de la lámina a pantalla completa. Los torii
  empiezan cerrados y los iconos del HUD apagados; `juego_variantes.inc` trae
  un parche por compuerta abierta y por icono encendido.
- `victoria_*`: el panel de amanecer con el texto final.
- `sprites_tiles.inc` y `sprites_paletas.inc`: cifras del HUD y cursor.

El texto se redibuja con fuentes de píxel propias: reducido desde la lámina no se
leía. Uso (numpy y Pillow):

    python gbc/minijuegos/ryu_flow_98/generar_arte.py
"""

from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFilter

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parents[2] / "scripts"))

from gbc_imagen_a_tiles import convertir_con_variantes, preparar  # noqa: E402

LAMINA = AQUI / "referencia" / "lamina.png"
ASSETS = AQUI / "assets"

# La escena y el HUD se reducen por separado para que el HUD ocupe justo las
# tres últimas filas de tiles y pueda llevar paletas propias.
RECORTE_ESCENA = (467, 39, 977, 453)
RECORTE_HUD = (467, 453, 977, 528)
FILAS_HUD = (15, 16, 17)
RECORTE_AMANECER = (990, 40, 1308, 268)

# Hueco entre las columnas de cada torii: ahí van los portones o el agua.
SEPARACION_TORII = 45
HUECO_TORII = (23, 53, 33, 63)
# Iconos de torii del HUD.
ICONOS_HUD = [(32, 124), (50, 124), (69, 124)]
TAM_ICONO = (14, 16)
# Icono de torii del HUD dibujado a mano: R rojo, T tinta, H hueco.
ICONO_TORII = [
    "TRRRRRRRRRRRRT",
    ".RRRRRRRRRRRR.",
    "..RR......RR..",
    ".RRRRRRRRRRRR.",
    "..RR......RR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    "..RRHHHHHHRR..",
    ".TTTT....TTTT.",
    "..............",
]

# Primer tile del banco 1 de VRAM reservado a los sprites.
PRIMER_TILE_SPRITE = 240

CREMA = (238, 226, 196)
TINTA = (28, 36, 56)
VERDE = (88, 200, 72)
ROJO = (208, 72, 40)
DORADO = (224, 168, 48)
VERDE_OSCURO = (40, 104, 48)
# El croma pesa el doble al ajustar las paletas: sin ello el dragón perdía el
# dorado y los torii el rojo.
PESO_CROMA = 2.0
PALETAS_HUD = [[CREMA, VERDE, ROJO, TINTA], [CREMA, DORADO, VERDE_OSCURO, TINTA]]

FUENTE_3X5 = {
    "N": ["X..X", "XX.X", "X.XX", "X..X", "X..X"],
    "I": ["XXX", ".X.", ".X.", ".X.", "XXX"],
    "V": ["X.X", "X.X", "X.X", "X.X", ".X."],
    "E": ["XXX", "X..", "XX.", "X..", "XXX"],
    "L": ["X..", "X..", "X..", "X..", "XXX"],
}

FUENTE_5X7 = {
    "0": [".XXX.", "X...X", "X..XX", "X.X.X", "XX..X", "X...X", ".XXX."],
    "1": ["..X..", ".XX..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
    "2": [".XXX.", "X...X", "....X", "...X.", "..X..", ".X...", "XXXXX"],
    "3": ["XXXX.", "....X", "....X", ".XXX.", "....X", "....X", "XXXX."],
    "4": ["...X.", "..XX.", ".X.X.", "X..X.", "XXXXX", "...X.", "...X."],
    "5": ["XXXXX", "X....", "XXXX.", "....X", "....X", "X...X", ".XXX."],
    "6": ["..XX.", ".X...", "X....", "XXXX.", "X...X", "X...X", ".XXX."],
    "7": ["XXXXX", "....X", "...X.", "..X..", ".X...", ".X...", ".X..."],
    "8": [".XXX.", "X...X", "X...X", ".XXX.", "X...X", "X...X", ".XXX."],
    "9": [".XXX.", "X...X", "X...X", ".XXXX", "....X", "...X.", ".XX.."],
    "-": [".....", ".....", ".....", "XXXXX", ".....", ".....", "....."],
    "/": ["....X", "....X", "...X.", "..X..", ".X...", "X....", "X...."],
    " ": ["....."] * 7,
    "A": [".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
    "D": ["XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX."],
    "E": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX"],
    "G": [".XXX.", "X...X", "X....", "X.XXX", "X...X", "X...X", ".XXXX"],
    "I": [".XXX.", "..X..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
    "J": ["..XXX", "...X.", "...X.", "...X.", "...X.", "X..X.", ".XX.."],
    "L": ["X....", "X....", "X....", "X....", "X....", "X....", "XXXXX"],
    "N": ["X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X"],
    "O": [".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
    "P": ["XXXX.", "X...X", "X...X", "XXXX.", "X....", "X....", "X...."],
    "R": ["XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X"],
    "S": [".XXXX", "X....", "X....", ".XXX.", "....X", "....X", "XXXX."],
    "T": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.."],
    "U": ["X...X", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
    "V": ["X...X", "X...X", "X...X", "X...X", "X...X", ".X.X.", "..X.."],
    "Z": ["XXXXX", "....X", "...X.", "..X..", ".X...", "X....", "XXXXX"],
}

# 0 transparente, 2 dorado, 3 contorno.
CURSOR = [
    "..3333..",
    "..3223..",
    "..3223..",
    "33322333",
    ".322223.",
    "..3223..",
    "...33...",
    "........",
]


def escribir(im, x, y, texto, fuente, color, sombra=None):
    d = ImageDraw.Draw(im)
    for caracter in texto:
        glifo = fuente[caracter]
        for fy, fila in enumerate(glifo):
            for fx, v in enumerate(fila):
                if v == "X":
                    if sombra:
                        d.point((x + fx + 1, y + fy + 1), fill=sombra)
                    d.point((x + fx, y + fy), fill=color)
        x += len(glifo[0]) + 1


def ancho(texto, fuente):
    return sum(len(fuente[c][0]) + 1 for c in texto) - 1


def icono_torii(hueco):
    colores = {".": CREMA, "R": ROJO, "T": TINTA, "H": hueco}
    im = Image.new("RGB", TAM_ICONO)
    for y, fila in enumerate(ICONO_TORII):
        for x, c in enumerate(fila):
            im.putpixel((x, y), colores[c])
    return im


def reducir(caja, tam):
    im = Image.open(LAMINA).convert("RGB").crop(caja).resize(tam, Image.Resampling.BOX)
    return im.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))


def escena_juego():
    escena = Image.new("RGB", (160, 144))
    escena.paste(reducir(RECORTE_ESCENA, (160, 120)), (0, 0))
    escena.paste(reducir(RECORTE_HUD, (160, 24)), (0, 120))
    x0, y0, x1, y1 = HUECO_TORII
    abierta = escena.crop(HUECO_TORII)
    cerrada = escena.crop((x0 + SEPARACION_TORII, y0, x1 + SEPARACION_TORII, y1))
    # Hueco oscuro apagado y verde encendido: reducidos de la lámina no se
    # distinguían.
    icono_apagado = icono_torii(TINTA)
    icono_encendido = icono_torii(VERDE)

    base = escena.copy()
    d = ImageDraw.Draw(base)
    # Texto del HUD: se borra el de la lámina y se escribe nítido. Las cifras
    # variables (dragones y movimientos) las pone la ROM con sprites.
    d.rectangle((0, 120, 159, 121), fill=TINTA)
    d.rectangle((0, 142, 159, 143), fill=TINTA)
    d.rectangle((30, 123, 86, 141), fill=CREMA)
    d.rectangle((3, 124, 29, 140), fill=CREMA)
    d.rectangle((108, 127, 124, 139), fill=CREMA)
    d.rectangle((140, 127, 157, 139), fill=CREMA)
    escribir(base, 6, 125, "NIVEL", FUENTE_3X5, TINTA)
    escribir(base, 7, 132, "1-3", FUENTE_5X7, TINTA)
    escribir(base, 114, 130, "/3", FUENTE_5X7, TINTA)
    for i in range(3):
        base.paste(cerrada, (x0 + SEPARACION_TORII * i, y0))
        base.paste(icono_apagado, ICONOS_HUD[i])

    variantes = {}
    for i in range(3):
        im = base.copy()
        im.paste(abierta, (x0 + SEPARACION_TORII * i, y0))
        variantes[f"Abierta{i + 1}"] = im
    for i in range(3):
        im = base.copy()
        im.paste(icono_encendido, ICONOS_HUD[i])
        variantes[f"Correcta{i + 1}"] = im
    return base, variantes


def escena_victoria():
    im = preparar(LAMINA, recorte=RECORTE_AMANECER, ancla_x=0.8)
    d = ImageDraw.Draw(im)
    lineas = ["EL DRAGON DESPIERTA", "PULSA A PARA JUGAR"]
    # Arriba, sobre el cielo: abajo taparía al dragón.
    d.rectangle((6, 4, 153, 29), fill=CREMA, outline=TINTA)
    for n, texto in enumerate(lineas):
        escribir(im, (160 - ancho(texto, FUENTE_5X7)) // 2, 7 + 11 * n, texto, FUENTE_5X7, TINTA)
    return im


def tile_2bpp(filas):
    pares = []
    for fila in filas:
        bajo = int("".join(str(int(v) & 1) for v in fila), 2)
        alto = int("".join(str((int(v) >> 1) & 1) for v in fila), 2)
        pares.append(f"${bajo:02X}, ${alto:02X}")
    return "    db " + ", ".join(pares)


def sprites():
    lineas = ["; Tiles de sprite (banco 1 de VRAM desde PRIMER_TILE_SPRITE): cifras 0-9 y cursor."]
    for cifra in "0123456789":
        glifo = FUENTE_5X7[cifra]
        filas = [[3 if c == "X" else 0 for c in fila] + [0] * 3 for fila in glifo] + [[0] * 8]
        lineas.append(tile_2bpp(filas) + f" ; {cifra}")
    lineas.append(tile_2bpp([[int(c) if c != "." else 0 for c in fila] for fila in CURSOR]) + " ; cursor")
    (ASSETS / "sprites_tiles.inc").write_text("\n".join(lineas) + "\n", encoding="utf-8")

    def rgb555(r, g, b):
        return (b >> 3) << 10 | (g >> 3) << 5 | (r >> 3)

    paletas = [
        ("cifras", [CREMA, CREMA, TINTA, TINTA]),
        ("cursor", [(255, 255, 255), (255, 255, 255), (248, 192, 32), (96, 16, 16)]),
    ]
    texto = ["; Paletas de sprite: el color 0 es transparente."]
    for nombre, colores in paletas:
        texto.append("    dw " + ", ".join(f"${rgb555(*c):04X}" for c in colores) + f" ; {nombre}")
    (ASSETS / "sprites_paletas.inc").write_text("\n".join(texto) + "\n", encoding="utf-8")


def main():
    base, variantes = escena_juego()
    n = convertir_con_variantes(base, variantes, ASSETS / "juego", etiqueta="JuegoCGB",
                                max_tiles=256 + PRIMER_TILE_SPRITE,
                                paletas_fijas=PALETAS_HUD, filas_fijas=FILAS_HUD, peso_croma=PESO_CROMA)
    print(f"juego: {n} tiles únicos")
    n = convertir_con_variantes(escena_victoria(), {}, ASSETS / "victoria", max_tiles=256 + PRIMER_TILE_SPRITE)
    print(f"victoria: {n} tiles únicos")
    sprites()


if __name__ == "__main__":
    main()
