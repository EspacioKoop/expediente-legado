"""Convierte una imagen en una pantalla Game Boy Color real (160x144).

Respeta los límites del hardware:
- 8 paletas de fondo de 4 colores (RGB555);
- una paleta por tile de 8x8 (mapa de atributos CGB);
- tiles deduplicados, contando volteos horizontales y verticales;
- hasta 512 tiles: 256 en el banco 0 de VRAM y 256 en el banco 1.

Genera `<salida>_tiles0.inc` y `<salida>_tiles1.inc` (bancos 0 y 1 de VRAM),
`<salida>_tilemap.inc`, `<salida>_attrmap.inc`, `<salida>_paletas.inc` y
`<salida>_previa.png`. La vista previa se reconstruye a partir de esos datos, no
de la imagen original. Las pantallas se cargan con `CargarPantallaCGB` de
`gbc/minijuegos/comun/pantalla_cgb.asm`.

`convertir_con_variantes` admite además variantes de la misma pantalla (una
compuerta abierta, un icono encendido...): comparten paletas y tiles con la base
y se exportan como parches de celdas en `<salida>_variantes.inc`, que la ROM
aplica y deshace con `AplicarParcheCGB`.

Uso (necesita numpy y Pillow):

    python scripts/gbc_imagen_a_tiles.py lamina.png gbc/minijuegos/x/assets/titulo \\
        --recorte 16,37,449,531 --ancla-y 0.3
"""

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ANCHO, ALTO, T = 160, 144, 8
COLS, FILAS = ANCHO // T, ALTO // T


def a555(rgb):
    return (np.asarray(rgb, dtype=np.int32) >> 3).clip(0, 31)


def de555(c):
    c = np.asarray(c, dtype=np.int32)
    return (c << 3) | (c >> 2)


def ajustar(im, ancla_x=0.5, ancla_y=0.5):
    """Recorta al 10:9 de la pantalla y reduce a 160x144."""
    w, h = im.size
    objetivo = ANCHO / ALTO
    if w / h > objetivo:
        nw = int(h * objetivo)
        x0 = int((w - nw) * ancla_x)
        im = im.crop((x0, 0, x0 + nw, h))
    else:
        nh = int(w / objetivo)
        y0 = int((h - nh) * ancla_y)
        im = im.crop((0, y0, w, y0 + nh))
    im = im.resize((ANCHO, ALTO), Image.Resampling.BOX)
    return im.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))


def kmeans(puntos, k, pesos=None, iter_=12, semilla=0):
    rnd = np.random.default_rng(semilla)
    puntos = puntos.astype(np.float64)
    if pesos is None:
        pesos = np.ones(len(puntos))
    unicos = np.unique(puntos, axis=0)
    if len(unicos) <= k:
        centros = np.vstack([unicos, np.repeat(unicos[:1], k - len(unicos), axis=0)])
        return centros
    # k-means++ ponderado
    centros = [puntos[rnd.choice(len(puntos), p=pesos / pesos.sum())]]
    for _ in range(1, k):
        d = np.min(((puntos[:, None, :] - np.array(centros)[None]) ** 2).sum(-1), axis=1) * pesos
        centros.append(puntos[rnd.choice(len(puntos), p=d / d.sum())] if d.sum() > 0 else puntos[0])
    centros = np.array(centros)
    for _ in range(iter_):
        asig = ((puntos[:, None, :] - centros[None]) ** 2).sum(-1).argmin(1)
        for j in range(k):
            m = asig == j
            if m.any():
                centros[j] = (puntos[m] * pesos[m, None]).sum(0) / pesos[m].sum()
    return centros


def error_tile(tile, paleta):
    d = ((tile[:, None, :] - paleta[None]) ** 2).sum(-1)
    return d.min(1).sum(), d.argmin(1)


def paletas_por_tile(tiles, n_paletas=8, iteraciones=6, fijas=(), solo_fijas=None, recortar=True):
    """Reparte 8 paletas de 4 colores entre los tiles.

    `fijas` son paletas RGB555 que no se ajustan y ocupan los primeros índices;
    los tiles marcados en `solo_fijas` solo pueden usar esas.
    """
    fijas = np.asarray(fijas, dtype=np.float64).reshape(-1, 4, 3)
    n_fijas = len(fijas)
    solo_fijas = np.zeros(len(tiles), bool) if solo_fijas is None else np.asarray(solo_fijas, bool)
    libres = [i for i in range(len(tiles)) if not solo_fijas[i]]
    n_libres = n_paletas - n_fijas
    # Semilla: agrupar tiles por su color medio y su dispersión.
    rasgos = np.array([np.concatenate([tiles[i].mean(0), tiles[i].std(0)]) for i in libres])
    centros = kmeans(rasgos, n_libres, iter_=20)
    grupo = np.zeros(len(tiles), int)
    grupo[libres] = n_fijas + ((rasgos[:, None, :] - centros[None]) ** 2).sum(-1).argmin(1)
    paletas = np.zeros((n_paletas, 4, 3))
    paletas[:n_fijas] = fijas
    for it in range(iteraciones):
        for p in range(n_fijas, n_paletas):
            miembros = [tiles[i] for i in libres if grupo[i] == p]
            if not miembros:
                miembros = [tiles[libres[np.random.default_rng(it + p).integers(len(libres))]]]
            puntos = np.vstack(miembros)
            paletas[p] = np.round(kmeans(puntos, 4, iter_=10, semilla=it + p))
        errores = np.array([[error_tile(t, paletas[p])[0] for p in range(n_paletas)] for t in tiles])
        errores[solo_fijas, n_fijas:] = np.inf
        grupo = errores.argmin(1)
    if not recortar:
        return paletas, grupo
    return paletas.clip(0, 31).astype(np.int32), grupo


def ordenar_paleta(pal):
    lum = pal @ np.array([0.299, 0.587, 0.114])
    return pal[np.argsort(-lum)]  # índice 0 = más claro, como el blanco de la Game Boy


def preparar(ruta, ancla_x=0.5, ancla_y=0.5, recorte=None, estirar=False):
    """Abre la imagen, recorta el panel y la deja en 160x144."""
    im = Image.open(ruta).convert("RGB")
    if recorte:
        im = im.crop(recorte)
    if estirar:
        im = im.resize((ANCHO, ALTO), Image.Resampling.BOX)
        return im.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    return ajustar(im, ancla_x, ancla_y)


def _celdas(im):
    px = a555(np.asarray(im.convert("RGB")))
    return [px[y * T:(y + 1) * T, x * T:(x + 1) * T].reshape(-1, 3).astype(np.float64)
            for y in range(FILAS) for x in range(COLS)]


def a_luma_croma(peso_croma):
    """Matriz RGB -> YCbCr con el croma multiplicado por `peso_croma`."""
    m = np.array([[0.299, 0.587, 0.114], [-0.169, -0.331, 0.5], [0.5, -0.419, -0.081]])
    m[1:] *= peso_croma
    return m


def convertir_con_variantes(base, variantes, salida, etiqueta="Pantalla", max_tiles=512,
                            paletas_fijas=(), filas_fijas=(), peso_croma=1.0):
    """Convierte una imagen 160x144 y sus variantes con paletas y tiles comunes.

    `variantes` es un dict ordenado nombre -> imagen 160x144. De cada variante
    solo se guardan las celdas que difieren de la base. `paletas_fijas` (colores
    RGB de 8 bits, 4 por paleta) se reservan para las filas de tiles de
    `filas_fijas`, como un HUD que no debe perder sus colores. Con `peso_croma`
    mayor que 1 las paletas se ajustan dando más peso al tono que al brillo:
    detalles pequeños y saturados (un dragón dorado) no se pierden en grises.
    """
    celdas_base = _celdas(base)
    parches = {}
    celdas = list(celdas_base)
    for nombre, im in variantes.items():
        propias = _celdas(im)
        distintas = [i for i in range(COLS * FILAS) if not np.array_equal(propias[i], celdas_base[i])]
        if not distintas:
            raise SystemExit(f"la variante {nombre} no cambia ninguna celda")
        parches[nombre] = [(i, len(celdas) + k) for k, i in enumerate(distintas)]
        celdas += [propias[i] for i in distintas]

    fila_de = list(range(COLS * FILAS)) + [i for pares in parches.values() for i, _ in pares]
    solo_fijas = [fila_de[k] // COLS in filas_fijas for k in range(len(celdas))]
    fijas = a555(paletas_fijas) if paletas_fijas else np.zeros((0, 4, 3))
    if peso_croma == 1.0:
        paletas, grupo = paletas_por_tile(celdas, fijas=fijas, solo_fijas=solo_fijas)
    else:
        m = a_luma_croma(peso_croma)
        paletas, grupo = paletas_por_tile([c @ m.T for c in celdas], fijas=np.asarray(fijas, float) @ m.T,
                                          solo_fijas=solo_fijas, recortar=False)
        paletas = np.rint(paletas @ np.linalg.inv(m).T).clip(0, 31).astype(np.int32)
        paletas[:len(fijas)] = fijas
    paletas = np.array([ordenar_paleta(p) for p in paletas])

    # Deduplicar tiles con volteos.
    unicos, claves = [], {}
    tiles, attrs = [], []
    for i, t in enumerate(celdas):
        _, idx = error_tile(t, paletas[grupo[i]].astype(np.float64))
        idx = idx.reshape(T, T).astype(np.uint8)
        encontrado = None
        for (fx, fy) in [(0, 0), (1, 0), (0, 1), (1, 1)]:
            v = idx[:, ::-1] if fx else idx
            v = v[::-1, :] if fy else v
            clave = v.tobytes()
            if clave in claves:
                encontrado = (claves[clave], fx, fy)
                break
        if encontrado is None:
            claves[idx.tobytes()] = len(unicos)
            unicos.append(idx)
            encontrado = (len(unicos) - 1, 0, 0)
        n, fx, fy = encontrado
        banco = 1 if n >= 256 else 0
        tiles.append(n % 256)
        attrs.append(int(grupo[i]) | (banco << 3) | (fx << 5) | (fy << 6))
    if len(unicos) > max_tiles:
        raise SystemExit(f"{salida}: {len(unicos)} tiles únicos, más de los {max_tiles} permitidos")

    n_base = COLS * FILAS
    salida = Path(salida)
    salida.parent.mkdir(parents=True, exist_ok=True)
    for banco in (0, 1):
        with open(f"{salida}_tiles{banco}.inc", "w") as f:
            grupo_tiles = unicos[banco * 256:(banco + 1) * 256]
            f.write(f"; banco {banco} de VRAM: {len(grupo_tiles)} tiles 2bpp (gbc_imagen_a_tiles.py)\n")
            for idx in grupo_tiles:
                # bit 7 = píxel de la izquierda, como espera la Game Boy
                bajo = [int("".join(str(int(v) & 1) for v in fila), 2) for fila in idx]
                alto = [int("".join(str((int(v) >> 1) & 1) for v in fila), 2) for fila in idx]
                pares = ", ".join(f"${a:02X}, ${b:02X}" for a, b in zip(bajo, alto))
                f.write(f"    db {pares}\n")
    for nombre, datos in (("tilemap", tiles[:n_base]), ("attrmap", attrs[:n_base])):
        with open(f"{salida}_{nombre}.inc", "w") as f:
            for y in range(FILAS):
                fila = datos[y * COLS:(y + 1) * COLS]
                f.write("    db " + ", ".join(f"${v:02X}" for v in fila) + "\n")
    with open(f"{salida}_paletas.inc", "w") as f:
        for p, pal in enumerate(paletas):
            valores = ", ".join(f"${(b << 10) | (g << 5) | r:04X}" for r, g, b in pal)
            f.write(f"    dw {valores} ; paleta {p}\n")
    if parches:
        with open(f"{salida}_variantes.inc", "w") as f:
            f.write("; Parches de celdas: n, y n veces (fila, columna, tile, atributos).\n")
            f.write("; <Etiqueta>_<variante> aplica la variante; ..._Base la deshace.\n")
            for nombre, pares in parches.items():
                for sufijo, fuente in ((nombre, None), (nombre + "_Base", "base")):
                    f.write(f"{etiqueta}_{sufijo}:\n    db {len(pares)}\n")
                    for celda, k in pares:
                        y, x = divmod(celda, COLS)
                        j = celda if fuente else k
                        f.write(f"    db {y}, {x}, ${tiles[j]:02X}, ${attrs[j]:02X}\n")

    def reconstruir(mapa_tiles, mapa_attrs):
        previa = np.zeros((ALTO, ANCHO, 3), dtype=np.uint8)
        for i in range(n_base):
            y, x = divmod(i, COLS)
            a = mapa_attrs[i]
            idx = unicos[mapa_tiles[i] + (256 if a & 8 else 0)]
            if a & 32:
                idx = idx[:, ::-1]
            if a & 64:
                idx = idx[::-1, :]
            previa[y * T:(y + 1) * T, x * T:(x + 1) * T] = de555(paletas[a & 7])[idx]
        return Image.fromarray(previa)

    # Vistas previas reconstruidas desde los datos.
    reconstruir(tiles, attrs).save(f"{salida}_previa.png")
    for nombre, pares in parches.items():
        t, a = list(tiles[:n_base]), list(attrs[:n_base])
        for celda, k in pares:
            t[celda], a[celda] = tiles[k], attrs[k]
        reconstruir(t, a).save(f"{salida}_previa_{nombre}.png")
    return len(unicos)


def convertir(ruta, salida, ancla_x=0.5, ancla_y=0.5, recorte=None, estirar=False):
    return convertir_con_variantes(preparar(ruta, ancla_x, ancla_y, recorte, estirar), {}, salida)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("imagen")
    ap.add_argument("salida")
    ap.add_argument("--ancla-x", type=float, default=0.5)
    ap.add_argument("--ancla-y", type=float, default=0.5)
    ap.add_argument("--recorte", help="x0,y0,x1,y1 del panel dentro de la lámina")
    ap.add_argument("--estirar", action="store_true", help="escala a 160x144 sin recortar")
    a = ap.parse_args()
    recorte = tuple(int(v) for v in a.recorte.split(",")) if a.recorte else None
    n = convertir(a.imagen, a.salida, a.ancla_x, a.ancla_y, recorte, a.estirar)
    print(f"{a.salida}: {n} tiles únicos")
