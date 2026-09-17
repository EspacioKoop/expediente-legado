"""Genera el arte de River of the Dragon para Game Boy Color (#808).

Parte de `referencia/lamina.png` y escribe en `assets/`:

- `juego_*`: el panel de juego de la lámina a pantalla completa. Los torii
  empiezan cerrados y los iconos del HUD apagados; `juego_variantes.inc` trae
  un parche por compuerta abierta o a medias, por icono encendido y por diálogo
  del anciano. `juego_paletas_amanecer.inc` y `juego_paletas_noche.inc` son las
  paletas de los niveles 1-2 y 1-3, con el color de los paneles de la lámina.
- `victoria_*`: el panel de amanecer con el texto final.
- `sprites_tiles.inc` y `sprites_paletas.inc`: cifras del HUD y cursor.
- `dragon_*`: la cabeza del dragón (reposo y despertar) y su rugido de victoria,
  sacados de `referencia/dragon_sprites.png`, una hoja de sprites GBC nativa. Los
  tiles se deduplican y cada fotograma es una lista de (fila, columna, tile).

El agua usa una paleta reservada (`PALETA_AGUA`) que ninguna otra celda comparte:
la ROM la anima con `juego_agua.inc`, tres tonos de esa paleta por nivel, cada
uno más aclarado hacia la espuma.

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
HOJA_DRAGON = AQUI / "referencia" / "dragon_sprites.png"
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

# Hoja del dragón: magenta = transparente, y sus tres colores.
PALETA_HOJA_DRAGON = [(249, 3, 248), (0xE0, 0xA8, 0x30), (0x28, 0x68, 0x30), (0x18, 0x20, 0x38)]
# Filas de la hoja: cabeza en reposo (4), despertar (3), cuerpo (4), cola (4), rugido (2).
FILAS_HOJA_DRAGON = (4, 3, 4, 4, 2)
CABEZA = (32, 24)   # ancho, alto en píxeles de Game Boy
RUGIDO = (48, 40)
# Del despertar se usan el ojo cerrado y el abierto: con el intermedio la
# cabeza no cabe en VRAM junto a la escena.
DESPERTAR = (0, 2)
PALETA_AGUA = 2
BRILLOS_AGUA = (0.0, 0.18, 0.36)

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
    agua = {"dia": np.asarray(paletas[PALETA_AGUA], float)}
    for nombre, recorte in (("amanecer", RECORTE_AMANECER), ("noche", RECORTE_NOCHE)):
        destino = lamina.crop(recorte)
        filas, mapa = [], {}
        for p, colores in enumerate(paletas):
            nuevos = colores if p < fijas else transferir_color(colores, escena, destino)
            filas.append("    dw " + ", ".join(f"${v:04X}" for v in a_bgr555(nuevos)) + f" ; paleta {p}")
            for antes, despues in zip(a_bgr555(colores), a_bgr555(nuevos)):
                mapa.setdefault(antes, despues)
        (ASSETS / f"juego_paletas_{nombre}.inc").write_text("\n".join(filas) + "\n", encoding="utf-8")
        agua[nombre] = transferir_color(paletas[PALETA_AGUA], escena, destino)
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

    # Brillo del agua: cada color claro se acerca al anterior (la espuma, al blanco).
    filas = ["; Paleta del agua por nivel (día, amanecer, noche) en tres brillos."]
    for nombre in ("dia", "amanecer", "noche"):
        colores = np.asarray(agua[nombre], float)
        for brillo in BRILLOS_AGUA:
            nuevos = colores.copy()
            nuevos[0] = colores[0] + (255 - colores[0]) * brillo
            nuevos[1] = colores[1] + (colores[0] - colores[1]) * brillo
            nuevos[2] = colores[2] + (colores[1] - colores[2]) * brillo
            filas.append("    dw " + ", ".join(f"${v:04X}" for v in a_bgr555(nuevos.clip(0, 255)))
                         + f" ; {nombre} {brillo}")
    (ASSETS / "juego_agua.inc").write_text("\n".join(filas) + "\n", encoding="utf-8")


def celdas_de_agua(base):
    """Celdas de la escena que son sobre todo agua o espuma (el monte no cuenta)."""
    px = np.asarray(base).astype(int)
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    agua = ((b > r + 25) & (b >= g - 10) & (b > 70)) | ((r > 185) & (g > 195) & (b > 200) & (b >= r))
    celdas = []
    for y in range(15):
        for x in range(20):
            if y < 2 or (y < 3 and x < 17) or (y < 5 and 5 <= x <= 12):
                continue
            # Fuera las celdas con rojo de torii: la paleta rota y se verían naranjas.
            rojizo = (r > g + 40)[y * 8:y * 8 + 8, x * 8:x * 8 + 8].mean()
            if agua[y * 8:y * 8 + 8, x * 8:x * 8 + 8].mean() >= 0.4 and rojizo <= 0.05:
                celdas.append(y * 20 + x)
    return celdas


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


def _tramos(v, minimo=3, hueco=10):
    res, ini, vacio, fin = [], None, 0, 0
    for i, x in enumerate(v):
        if x >= minimo:
            ini = i if ini is None else ini
            fin, vacio = i, 0
        elif ini is not None:
            vacio += 1
            if vacio > hueco:
                res.append((ini, fin + 1))
                ini = None
    if ini is not None:
        res.append((ini, fin + 1))
    return res


def hoja_dragon():
    """Índices de color (0 transparente) y cajas de cada sprite, fila a fila."""
    rgb = np.asarray(Image.open(HOJA_DRAGON).convert("RGB")).astype(int)
    paleta = np.array(PALETA_HOJA_DRAGON)
    indices = ((rgb[..., None, :] - paleta[None, None]) ** 2).sum(-1).argmin(-1)
    opaco = indices != 0
    filas = []
    for y0, y1 in _tramos(opaco.sum(1)):
        cajas = []
        for x0, x1 in _tramos(opaco[y0:y1].sum(0), hueco=12):
            ys = np.where(opaco[y0:y1, x0:x1].any(1))[0]
            cajas.append((x0, y0 + ys[0], x1, y0 + ys[-1] + 1))
        filas.append(cajas)
    if [len(f) for f in filas] != list(FILAS_HOJA_DRAGON):
        raise SystemExit(f"hoja del dragón inesperada: {[len(f) for f in filas]} sprites por fila")
    return indices, filas


def reducir_sprite(indices, caja, ancho, alto, por_alto=False):
    """Reduce por moda al ancho (o al alto) dado; arriba a la izquierda, recortando lo que sobre."""
    sub = indices[caja[1]:caja[3], caja[0]:caja[2]]
    h, w = sub.shape
    esc = h / alto if por_alto else w / ancho
    salida = np.zeros((alto, ancho), int)
    for y in range(min(alto, int(h / esc))):
        for x in range(min(ancho, int(w / esc))):
            bloque = sub[int(y * esc):max(int((y + 1) * esc), int(y * esc) + 1),
                         int(x * esc):max(int((x + 1) * esc), int(x * esc) + 1)]
            cuenta = np.bincount(bloque.ravel(), minlength=4)
            valor = cuenta.argmax()
            # El contorno oscuro gana con poca presencia: si no, las líneas finas se pierden.
            if valor != 3 and cuenta[3] >= 0.3 * bloque.size:
                valor = 3
            salida[y, x] = valor
    return salida


def exportar_fotogramas(fotogramas, nombre, etiqueta):
    """Tiles únicos y, por fotograma, n y n veces (fila, columna, tile) de las celdas no vacías."""
    unicos, claves, tablas = [], {}, []
    for f in fotogramas:
        entradas = []
        for ty in range(f.shape[0] // 8):
            for tx in range(f.shape[1] // 8):
                bloque = f[ty * 8:ty * 8 + 8, tx * 8:tx * 8 + 8]
                if not bloque.any():
                    continue
                clave = bloque.tobytes()
                if clave not in claves:
                    claves[clave] = len(unicos)
                    unicos.append(bloque)
                entradas.append((ty, tx, claves[clave]))
        tablas.append(entradas)
    lineas = [f"; {len(unicos)} tiles de sprite de {nombre} (generar_arte.py)"]
    lineas += [tile_2bpp(t) for t in unicos]
    (ASSETS / f"dragon_{nombre}_tiles.inc").write_text("\n".join(lineas) + "\n", encoding="utf-8")
    lineas = [f"; {nombre}: por fotograma, n y n veces (fila, columna, tile)."]
    for k, entradas in enumerate(tablas):
        lineas.append(f"{etiqueta}{k}:")
        lineas.append(f"    db {len(entradas)}")
        lineas += [f"    db {ty}, {tx}, {t}" for ty, tx, t in entradas]
    (ASSETS / f"dragon_{nombre}_fotogramas.inc").write_text("\n".join(lineas) + "\n", encoding="utf-8")
    return len(unicos), max(len(e) for e in tablas)


def sprites_dragon():
    indices, filas = hoja_dragon()
    cabezas = [reducir_sprite(indices, c, *CABEZA) for c in filas[0] + [filas[1][k] for k in DESPERTAR]]
    rugidos = [reducir_sprite(indices, c, *RUGIDO, por_alto=True) for c in filas[4]]
    n_cabeza, max_cabeza = exportar_fotogramas(cabezas, "cabeza", "DragonCabeza")
    n_rugido, max_rugido = exportar_fotogramas(rugidos, "rugido", "DragonRugido")

    # Colores del dragón con la luz de cada nivel, como la escena.
    lamina = Image.open(LAMINA).convert("RGB")
    escena = lamina.crop(RECORTE_ESCENA)
    propios = PALETA_HOJA_DRAGON[1:]
    lineas = ["; Paleta de sprite del dragón por luz: día, amanecer, noche."]
    for nombre, recorte in (("dia", None), ("amanecer", RECORTE_AMANECER), ("noche", RECORTE_NOCHE)):
        colores = propios if recorte is None else transferir_color(propios, escena, lamina.crop(recorte))
        lineas.append("    dw " + ", ".join(f"${v:04X}" for v in a_bgr555([(255, 255, 255)] + list(colores)))
                      + f" ; {nombre}")
    (ASSETS / "dragon_paletas.inc").write_text("\n".join(lineas) + "\n", encoding="utf-8")

    constantes = [
        "; Generado por generar_arte.py: dónde van los tiles del dragón en el banco 1 de VRAM.",
        f"DEF DRAGON_TILES_CABEZA EQU {n_cabeza}",
        f"DEF DRAGON_TILES_RUGIDO EQU {n_rugido}",
        f"DEF DRAGON_SPRITES_CABEZA EQU {max_cabeza}",
        f"DEF DRAGON_SPRITES_RUGIDO EQU {max_rugido}",
        f"DEF DRAGON_FOTOGRAMAS_CABEZA EQU {len(cabezas)}",
    ]
    (ASSETS / "dragon_constantes.inc").write_text("\n".join(constantes) + "\n", encoding="utf-8")

    # Vista previa ampliada de todos los fotogramas.
    colores = [(90, 120, 140)] + PALETA_HOJA_DRAGON[1:]
    previa = Image.new("RGB", (len(cabezas) * 40 + len(rugidos) * 56, 48), colores[0])
    x = 0
    for f in cabezas + rugidos:
        for (fy, fx), v in np.ndenumerate(f):
            if v:
                previa.putpixel((x + fx, fy), colores[v])
        x += f.shape[1] + 8
    previa.resize((previa.width * 4, previa.height * 4), Image.NEAREST).save(ASSETS / "dragon_previa.png")
    return n_cabeza, n_rugido


def main():
    n_cabeza, n_rugido = sprites_dragon()
    print(f"dragón: {n_cabeza} tiles de cabeza, {n_rugido} de rugido")
    base, variantes = escena_juego()
    n = convertir_con_variantes(base, variantes, ASSETS / "juego", etiqueta="JuegoCGB",
                                max_tiles=256 + PRIMER_TILE_SPRITE - n_cabeza,
                                paletas_fijas=PALETAS_HUD, filas_fijas=FILAS_HUD, peso_croma=PESO_CROMA,
                                variantes_fijas=[f"Dialogo{n + 1}" for n in range(len(DIALOGOS))],
                                paleta_reservada=PALETA_AGUA, celdas_reservadas=celdas_de_agua(base))
    print(f"juego: {n} tiles únicos")
    paletas_de_nivel()
    n = convertir_con_variantes(escena_victoria(), {}, ASSETS / "victoria",
                                max_tiles=256 + PRIMER_TILE_SPRITE - n_rugido)
    print(f"victoria: {n} tiles únicos")
    sprites()


if __name__ == "__main__":
    main()
