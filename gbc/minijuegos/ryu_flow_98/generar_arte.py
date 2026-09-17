"""Genera el arte de River of the Dragon para Game Boy Color (#808).

Parte de `referencia/lamina.png` y escribe en `assets/`:

- `juego_*`: el panel de juego de la lámina a pantalla completa. Los torii
  empiezan cerrados y los iconos del HUD apagados; `juego_variantes.inc` trae
  un parche por compuerta abierta o a medias, por icono encendido y por diálogo
  del anciano. `juego_paletas_amanecer.inc` y `juego_paletas_noche.inc` son las
  paletas de los niveles 1-2 y 1-3, con el color de los paneles de la lámina.
- `victoria_*`: el panel de amanecer con el texto final.
- `sprites_tiles.inc` y `sprites_paletas.inc`: cifras del HUD y cursor.

El texto se redibuja con fuentes de píxel propias: reducido desde la lámina no se
leía. Uso (numpy y Pillow):

    python gbc/minijuegos/ryu_flow_98/generar_arte.py
"""

from pathlib import Path
import sys

import numpy as np
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
RECORTE_NOCHE = (996, 312, 1304, 530)
RECORTE_RETRATO = (486, 1000, 572, 1086)

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
MARRON = (136, 80, 48)
# El croma pesa el doble al ajustar las paletas: sin ello el dragón perdía el
# dorado y los torii el rojo.
PESO_CROMA = 2.0
# HUD y cuadro de diálogo. La segunda sirve también al retrato del anciano.
PALETAS_HUD = [[CREMA, VERDE, ROJO, TINTA], [CREMA, DORADO, MARRON, TINTA]]

# Diálogos del anciano al empezar cada nivel: 4 líneas de hasta 12 letras, una
# por celda para que las letras se repitan como tiles.
DIALOGOS = [
    ["EL AGUA", "SIEMPRE", "ENCUENTRA SU", "CAMINO..."],
    ["AL ALBA,", "CADA PUERTA", "PUEDE QUEDAR", "A MEDIAS."],
    ["DE NOCHE,", "CADA PUERTA", "MUEVE LA DE", "SU DERECHA."],
]
FILA_DIALOGO = 12
COLUMNA_TEXTO = 6

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
    "B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
    "C": [".XXX.", "X...X", "X....", "X....", "X....", "X...X", ".XXX."],
    "M": ["X...X", "XX.XX", "X.X.X", "X.X.X", "X...X", "X...X", "X...X"],
    "Q": [".XXX.", "X...X", "X...X", "X...X", "X.X.X", "X..X.", ".XX.X"],
    "H": ["X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
    ",": [".....", ".....", ".....", ".....", ".....", "..X..", ".X..."],
    ".": [".....", ".....", ".....", ".....", ".....", ".....", "..X.."],
    "v": [".....", "XXXXX", ".XXX.", "..X..", ".....", ".....", "....."],
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
    # La cifra del nivel la pone la ROM con un sprite.
    escribir(base, 7, 132, "1-", FUENTE_5X7, TINTA)
    escribir(base, 114, 130, "/3", FUENTE_5X7, TINTA)
    for i in range(3):
        base.paste(cerrada, (x0 + SEPARACION_TORII * i, y0))
        base.paste(icono_apagado, ICONOS_HUD[i])

    # A medias: portones arriba y el agua asomando por debajo.
    media = cerrada.copy()
    mitad = (y1 - y0) // 2
    media.paste(abierta.crop((0, mitad, x1 - x0, y1 - y0)), (0, mitad))
    ImageDraw.Draw(media).line((0, mitad, x1 - x0 - 1, mitad), fill=MARRON)

    variantes = {}
    for nombre, hueco in (("Abierta", abierta), ("Media", media)):
        for i in range(3):
            im = base.copy()
            im.paste(hueco, (x0 + SEPARACION_TORII * i, y0))
            variantes[f"{nombre}{i + 1}"] = im
    for i in range(3):
        im = base.copy()
        im.paste(icono_encendido, ICONOS_HUD[i])
        variantes[f"Correcta{i + 1}"] = im
    for n, lineas in enumerate(DIALOGOS):
        variantes[f"Dialogo{n + 1}"] = dialogo(base, lineas)
    return base, variantes


def dialogo(base, lineas):
    """Cuadro del anciano sobre las seis últimas filas, como en la lámina."""
    im = base.copy()
    d = ImageDraw.Draw(im)
    y0 = FILA_DIALOGO * 8
    d.rectangle((0, y0, 159, 143), fill=TINTA)
    d.rectangle((3, y0 + 3, 156, 140), fill=CREMA, outline=TINTA)
    d.rectangle((5, y0 + 5, 154, 138), outline=MARRON)
    retrato = Image.open(LAMINA).convert("RGB").crop(RECORTE_RETRATO).resize((32, 32), Image.Resampling.BOX)
    im.paste(retrato, (8, (FILA_DIALOGO + 1) * 8))
    d.rectangle((7, (FILA_DIALOGO + 1) * 8 - 1, 40, (FILA_DIALOGO + 5) * 8), outline=TINTA)
    for n, texto in enumerate(lineas):
        for c, caracter in enumerate(texto):
            escribir(im, (COLUMNA_TEXTO + c) * 8 + 1, (FILA_DIALOGO + 1 + n) * 8, caracter, FUENTE_5X7, TINTA)
    escribir(im, 18 * 8 + 1, (FILA_DIALOGO + 4) * 8 + 1, "v", FUENTE_5X7, MARRON)
    return im


def transferir_color(colores, origen, destino):
    """Lleva colores RGB al ambiente de otro panel (media y desviación por canal)."""
    o = np.asarray(origen, float).reshape(-1, 3)
    t = np.asarray(destino, float).reshape(-1, 3)
    c = (np.asarray(colores, float) - o.mean(0)) / (o.std(0) + 1e-6) * t.std(0) + t.mean(0)
    return c.clip(0, 255)


def a_bgr555(colores):
    return [(int(b) >> 3) << 10 | (int(g) >> 3) << 5 | (int(r) >> 3) for r, g, b in colores]


def paletas_de_nivel():
    """Paletas de amanecer y noche: mismas tiles, otra luz (paletas 2 y 3 de la lámina)."""
    lamina = Image.open(LAMINA).convert("RGB")
    escena = lamina.crop(RECORTE_ESCENA)
    fijas = len(PALETAS_HUD)
    paletas = []
    for linea in (ASSETS / "juego_paletas.inc").read_text(encoding="utf-8").splitlines():
        valores = [int(v.strip().lstrip("$"), 16) for v in linea.split(";")[0].replace("dw", "").split(",")]
        paletas.append([((v & 31) << 3, (v >> 5 & 31) << 3, (v >> 10 & 31) << 3) for v in valores])
    for nombre, recorte in (("amanecer", RECORTE_AMANECER), ("noche", RECORTE_NOCHE)):
        destino = lamina.crop(recorte)
        filas, mapa = [], {}
        for p, colores in enumerate(paletas):
            nuevos = colores if p < fijas else transferir_color(colores, escena, destino)
            filas.append("    dw " + ", ".join(f"${v:04X}" for v in a_bgr555(nuevos)) + f" ; paleta {p}")
            for antes, despues in zip(a_bgr555(colores), a_bgr555(nuevos)):
                mapa.setdefault(antes, despues)
        (ASSETS / f"juego_paletas_{nombre}.inc").write_text("\n".join(filas) + "\n", encoding="utf-8")
        # Vista previa: la escena (no el HUD) con los colores cambiados.
        previa = Image.open(ASSETS / "juego_previa.png").convert("RGB")
        pix = previa.load()
        for y in range(120):
            for x in range(160):
                r, g, b = (v >> 3 for v in pix[x, y])
                nuevo = mapa.get(b << 10 | g << 5 | r)
                if nuevo is not None:
                    pix[x, y] = tuple(((nuevo >> k) & 31) << 3 | ((nuevo >> k) & 31) >> 2 for k in (0, 5, 10))
        previa.save(ASSETS / f"juego_previa_{nombre}.png")


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
                                paletas_fijas=PALETAS_HUD, filas_fijas=FILAS_HUD, peso_croma=PESO_CROMA,
                                variantes_fijas=[f"Dialogo{n + 1}" for n in range(len(DIALOGOS))])
    print(f"juego: {n} tiles únicos")
    paletas_de_nivel()
    n = convertir_con_variantes(escena_victoria(), {}, ASSETS / "victoria", max_tiles=256 + PRIMER_TILE_SPRITE)
    print(f"victoria: {n} tiles únicos")
    sprites()


if __name__ == "__main__":
    main()
