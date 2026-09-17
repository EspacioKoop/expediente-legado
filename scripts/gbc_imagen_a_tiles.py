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


def paletas_por_tile(px, n_paletas=8, iteraciones=6):
    tiles = [px[y * T:(y + 1) * T, x * T:(x + 1) * T].reshape(-1, 3).astype(np.float64)
             for y in range(FILAS) for x in range(COLS)]
    # Semilla: agrupar tiles por su color medio y su dispersión.
    rasgos = np.array([np.concatenate([t.mean(0), t.std(0)]) for t in tiles])
    centros = kmeans(rasgos, n_paletas, iter_=20)
    grupo = ((rasgos[:, None, :] - centros[None]) ** 2).sum(-1).argmin(1)
    paletas = np.zeros((n_paletas, 4, 3))
    for it in range(iteraciones):
        for p in range(n_paletas):
            miembros = [tiles[i] for i in range(len(tiles)) if grupo[i] == p]
            if not miembros:
                miembros = [tiles[np.random.default_rng(it + p).integers(len(tiles))]]
            puntos = np.vstack(miembros)
            paletas[p] = np.round(kmeans(puntos, 4, iter_=10, semilla=it + p))
        errores = np.array([[error_tile(t, paletas[p])[0] for p in range(n_paletas)] for t in tiles])
        grupo = errores.argmin(1)
    return paletas.clip(0, 31).astype(np.int32), grupo, tiles


def ordenar_paleta(pal):
    lum = pal @ np.array([0.299, 0.587, 0.114])
    return pal[np.argsort(-lum)]  # índice 0 = más claro, como el blanco de la Game Boy


def convertir(ruta, salida, ancla_x=0.5, ancla_y=0.5, recorte=None):
    im = Image.open(ruta).convert("RGB")
    if recorte:
        im = im.crop(recorte)
    im = ajustar(im, ancla_x, ancla_y)
    px = a555(np.asarray(im))
    paletas, grupo, tiles = paletas_por_tile(px)
    paletas = np.array([ordenar_paleta(p) for p in paletas])

    indices = []
    for i, t in enumerate(tiles):
        _, idx = error_tile(t, paletas[grupo[i]].astype(np.float64))
        indices.append(idx.reshape(T, T).astype(np.uint8))

    # Deduplicar tiles con volteos.
    unicos, claves = [], {}
    tilemap, attrmap = [], []
    for i, idx in enumerate(indices):
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
        tilemap.append(n % 256)
        attrmap.append(int(grupo[i]) | (banco << 3) | (fx << 5) | (fy << 6))
    if len(unicos) > 512:
        raise SystemExit(f"{ruta}: {len(unicos)} tiles únicos, más de los 512 que caben en VRAM")

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
    for nombre, datos in (("tilemap", tilemap), ("attrmap", attrmap)):
        with open(f"{salida}_{nombre}.inc", "w") as f:
            for y in range(FILAS):
                fila = datos[y * COLS:(y + 1) * COLS]
                f.write("    db " + ", ".join(f"${v:02X}" for v in fila) + "\n")
    with open(f"{salida}_paletas.inc", "w") as f:
        for p, pal in enumerate(paletas):
            valores = ", ".join(f"${(b << 10) | (g << 5) | r:04X}" for r, g, b in pal)
            f.write(f"    dw {valores} ; paleta {p}\n")

    # Vista previa reconstruida desde los datos.
    previa = np.zeros((ALTO, ANCHO, 3), dtype=np.uint8)
    for i in range(COLS * FILAS):
        y, x = divmod(i, COLS)
        a = attrmap[i]
        n = tilemap[i] + (256 if a & 8 else 0)
        idx = unicos[n]
        if a & 32:
            idx = idx[:, ::-1]
        if a & 64:
            idx = idx[::-1, :]
        previa[y * T:(y + 1) * T, x * T:(x + 1) * T] = de555(paletas[a & 7])[idx]
    Image.fromarray(previa).save(f"{salida}_previa.png")
    return len(unicos)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("imagen")
    ap.add_argument("salida")
    ap.add_argument("--ancla-x", type=float, default=0.5)
    ap.add_argument("--ancla-y", type=float, default=0.5)
    ap.add_argument("--recorte", help="x0,y0,x1,y1 del panel dentro de la lámina")
    a = ap.parse_args()
    recorte = tuple(int(v) for v in a.recorte.split(",")) if a.recorte else None
    n = convertir(a.imagen, a.salida, a.ancla_x, a.ancla_y, recorte)
    print(f"{a.salida}: {n} tiles únicos")
