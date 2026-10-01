#!/usr/bin/env python3
"""Genera el primer pack textual GBC de MYRMIDON 98 (#1804).

No usa Pillow ni binarios. Redibuja de forma determinista, sobre grid 8x8,
la gramática visual ya versionada de Aquiles y emite datos RGBDS, paletas,
manifest y dos previews SVG 160x144.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent
ASSETS = RAIZ / "assets"
TILE = 8
FRAME_W = 24
FRAME_H = 32
ESTADOS = ("idle", "advance", "attack", "block", "vulnerable", "defeat")

FUENTES = {
    "aquiles_atlas_referencia.jpg": "2d379bf598c19b87822d6d6d723a223d73fc4dca",
    "aquiles_entorno_referencia.jpg": "48b932eb8e219aa9e0d2630358c5863ec07b0aa5",
    "icono_observar.svg": "be6f54cb141e08b00e5ddfd4cfd23fa9bfedb4b4",
    "icono_reflejo.svg": "ecaf73491601ebcfd42a36606c5313aad869f0a1",
    "icono_talon.svg": "c4ac5950f93111ae515b9dd910c6923cda35df7c",
    "estandarte_aquiles.svg": "b807fea6f4fba2c8d4e878955af9c24365222293",
}

COLORES = {
    0: "#11131a",
    1: "#38455b",
    2: "#93a3b9",
    3: "#f4e9c7",
}
PALETAS = {
    "BG_MARMOL": ("#11131a", "#38455b", "#93a3b9", "#f4e9c7"),
    "BG_COLUMNA": ("#11131a", "#4a3f49", "#b7a7a0", "#f4e9c7"),
    "BG_ESTANTE": ("#11131a", "#3b273d", "#a55155", "#f1d28a"),
    "BG_AGUA": ("#11131a", "#1e4155", "#4f91a6", "#c2e0da"),
    "OBJ_AQUILES": ("#000000", "#20273a", "#5471a7", "#e8d9bb"),
    "OBJ_GUARDIA": ("#000000", "#2e2527", "#a44d3d", "#f1cf7a"),
    "OBJ_HUD": ("#000000", "#24313a", "#76a7a9", "#f4e9c7"),
    "OBJ_VULNERABLE": ("#000000", "#382426", "#bd5b3d", "#f5df79"),
}


def lienzo(w: int, h: int, valor: int = 0):
    return [[valor for _ in range(w)] for _ in range(h)]


def rect(img, x, y, w, h, c):
    for yy in range(max(0, y), min(len(img), y + h)):
        for xx in range(max(0, x), min(len(img[0]), x + w)):
            img[yy][xx] = c


def linea(img, x0, y0, x1, y1, c):
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        if 0 <= y0 < len(img) and 0 <= x0 < len(img[0]):
            img[y0][x0] = c
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def frame_pixels(estado: str, frame: int):
    img = lienzo(FRAME_W, FRAME_H)
    # Casco/penacho
    rect(img, 9, 2, 6, 4, 2)
    rect(img, 10, 0, 4, 2, 3)
    rect(img, 8, 6, 8, 3, 1)
    # Torso y capa
    rect(img, 8, 9, 8, 10, 2)
    rect(img, 6, 11, 2, 9, 1)
    rect(img, 16, 10, 2, 11, 1)
    # Piernas base
    rect(img, 8, 19, 3, 10, 2)
    rect(img, 13, 19, 3, 10, 2)
    rect(img, 7, 29, 5, 2, 1)
    rect(img, 12, 29, 5, 2, 1)
    # Escudo y lanza base
    rect(img, 3, 10, 4, 9, 3)
    rect(img, 2, 12, 1, 5, 2)
    linea(img, 18, 7, 20, 29, 2)

    if estado == "idle":
        if frame:
            rect(img, 9, 20, 2, 8, 1)
            rect(img, 14, 19, 2, 9, 3)
    elif estado == "advance":
        rect(img, 5, 10, 4, 8, 3)
        if frame == 0:
            rect(img, 5, 27, 7, 2, 2)
            rect(img, 14, 29, 7, 2, 2)
        else:
            rect(img, 3, 29, 8, 2, 2)
            rect(img, 13, 27, 8, 2, 2)
    elif estado == "attack":
        rect(img, 2, 13, 3, 6, 1)
        linea(img, 12, 13, 23, 10 + frame * 2, 3)
        linea(img, 12, 14, 23, 11 + frame * 2, 2)
        rect(img, 15, 18, 3, 3, 3)
    elif estado == "block":
        rect(img, 1, 8, 7, 14, 3)
        rect(img, 2, 10, 5, 10, 2)
        rect(img, 4, 12 + frame, 2, 6, 1)
        linea(img, 17, 6, 19, 28, 2)
    elif estado == "vulnerable":
        # Guardia rota y apoyo retrasado: se distingue por silueta, no por paleta.
        rect(img, 2, 17, 4, 4, 1)
        rect(img, 7, 18, 3, 8, 2)
        rect(img, 14, 19, 3, 7, 2)
        rect(img, 4, 26, 7, 3, 2)
        rect(img, 15, 27, 7, 3, 3)  # talón saliente inequívoco
        rect(img, 18, 25, 3, 2, 3)
        linea(img, 18, 7, 22, 22, 1)
        if frame:
            rect(img, 16, 29, 8, 2, 3)
    elif estado == "defeat":
        img = lienzo(FRAME_W, FRAME_H)
        # Silueta caída diagonal.
        rect(img, 4, 20, 15, 5, 2)
        rect(img, 2, 18, 6, 5, 1)
        rect(img, 17, 22, 5, 3, 3)
        linea(img, 7, 18, 15, 10 + frame, 2)
        linea(img, 8, 19, 16, 11 + frame, 1)
        rect(img, 13, 8 + frame, 5, 4, 3)
    else:
        raise ValueError(estado)
    return img


def tile_desde(img, tx, ty):
    return tuple(
        tuple(img[ty * TILE + y][tx * TILE + x] for x in range(TILE))
        for y in range(TILE)
    )


def tile_bytes(tile):
    out = []
    for fila in tile:
        lo = hi = 0
        for x, px in enumerate(fila):
            bit = 7 - x
            lo |= (px & 1) << bit
            hi |= ((px >> 1) & 1) << bit
        out.extend((lo, hi))
    return out


def patrones_bg():
    p = {}
    a = lienzo(8, 8, 1)
    linea(a, 0, 6, 7, 3, 2)
    linea(a, 1, 1, 6, 0, 3)
    p["marmol_a"] = a

    a = lienzo(8, 8, 1)
    linea(a, 0, 2, 7, 5, 2)
    linea(a, 3, 0, 4, 7, 3)
    p["marmol_b"] = a

    a = lienzo(8, 8, 0)
    rect(a, 2, 0, 4, 8, 2)
    rect(a, 3, 0, 2, 8, 3)
    p["columna"] = a

    a = lienzo(8, 8, 0)
    rect(a, 1, 1, 6, 6, 1)
    rect(a, 2, 2, 4, 4, 2)
    rect(a, 3, 3, 2, 2, 3)
    p["relieve"] = a

    a = lienzo(8, 8, 0)
    rect(a, 1, 0, 1, 8, 2)
    rect(a, 2, 1, 5, 6, 3)
    rect(a, 2, 5, 5, 2, 2)
    p["estandarte"] = a

    a = lienzo(8, 8, 1)
    rect(a, 0, 6, 8, 2, 2)
    for x in (1, 5):
        a[2][x] = 3
    p["suelo"] = a

    a = lienzo(8, 8, 0)
    rect(a, 0, 3, 8, 5, 2)
    rect(a, 0, 3, 8, 1, 3)
    p["plataforma"] = a

    a = lienzo(8, 8, 0)
    rect(a, 3, 1, 2, 5, 2)
    rect(a, 2, 6, 4, 2, 3)
    a[1][2] = a[1][5] = 2
    p["estatua"] = a
    return p


def iconos_hud():
    observar = lienzo(8, 8, 0)
    for x in range(1, 7):
        observar[2][x] = 2
        observar[5][x] = 2
    observar[3][0] = observar[4][0] = 2
    observar[3][7] = observar[4][7] = 2
    rect(observar, 3, 3, 2, 2, 3)

    reflejo = lienzo(8, 8, 0)
    linea(reflejo, 1, 6, 6, 1, 2)
    linea(reflejo, 2, 7, 7, 2, 3)
    rect(reflejo, 1, 1, 2, 2, 1)

    talon = lienzo(8, 8, 0)
    rect(talon, 1, 4, 5, 2, 2)
    rect(talon, 4, 2, 2, 4, 3)
    rect(talon, 0, 6, 4, 1, 1)
    return {"observar": observar, "reflejo": reflejo, "talon": talon}


def construir_pack():
    pool = []
    indice = {}
    mapas = {}
    for estado in ESTADOS:
        mapas[estado] = []
        for frame in range(2):
            img = frame_pixels(estado, frame)
            mapa = []
            for ty in range(FRAME_H // TILE):
                for tx in range(FRAME_W // TILE):
                    t = tile_desde(img, tx, ty)
                    if t not in indice:
                        indice[t] = len(pool)
                        pool.append(t)
                    mapa.append(indice[t])
            mapas[estado].append(mapa)
    return pool, mapas


def rgbds_tiles():
    pool, mapas = construir_pack()
    bg = patrones_bg()
    hud = iconos_hud()
    lineas = [
        "; Generado por generar_arte_v1.py. No editar a mano.",
        "; Tiles 2bpp compatibles con RGBDS.",
        "",
        "MyrmidonObjTiles::",
    ]
    for i, t in enumerate(pool):
        lineas.append(f"; OBJ tile {i:02d}")
        bs = tile_bytes(t)
        lineas.append("    db " + ", ".join(f"${b:02X}" for b in bs))
    lineas += ["", "MyrmidonFrameMaps::"]
    for estado in ESTADOS:
        for n, mapa in enumerate(mapas[estado]):
            nombre = estado.capitalize()
            lineas.append(f"MyrmidonFrame_{nombre}_{n}::")
            lineas.append("    db " + ", ".join(f"${x:02X}" for x in mapa))
    lineas += ["", "MyrmidonBgTiles::"]
    for nombre, t in bg.items():
        lineas.append(f"MyrmidonBg_{nombre}::")
        bs = tile_bytes(tuple(tuple(r) for r in t))
        lineas.append("    db " + ", ".join(f"${b:02X}" for b in bs))
    lineas += ["", "; HUD base: seguro antes de deducir la vulnerabilidad.", "MyrmidonHudBase::"]
    for nombre in ("observar", "reflejo"):
        lineas.append(f"MyrmidonHud_{nombre}::")
        bs = tile_bytes(tuple(tuple(r) for r in hud[nombre]))
        lineas.append("    db " + ", ".join(f"${b:02X}" for b in bs))
    lineas += [
        "",
        "; Banco separado: NO cargar/mostrar antes de que la vulnerabilidad haya sido deducida.",
        "MyrmidonHudRevealed::",
        "MyrmidonHud_talon::",
    ]
    bs = tile_bytes(tuple(tuple(r) for r in hud["talon"]))
    lineas.append("    db " + ", ".join(f"${b:02X}" for b in bs))
    return "\n".join(lineas) + "\n"


def bgr555(hex_color: str):
    s = hex_color.lstrip("#")
    r, g, b = (int(s[i:i+2], 16) for i in (0, 2, 4))
    r5, g5, b5 = (round(v * 31 / 255) for v in (r, g, b))
    return r5 | (g5 << 5) | (b5 << 10)


def rgbds_paletas():
    out = [
        "; Generado por generar_arte_v1.py. CGB BGR555, 4 colores por paleta.",
        "; 4 BG + 4 OBJ = 8 paletas totales.",
        "",
    ]
    for nombre, colores in PALETAS.items():
        out.append(f"MyrmidonPal_{nombre}::")
        out.append("    dw " + ", ".join(f"${bgr555(c):04X}" for c in colores))
    return "\n".join(out) + "\n"


def manifest():
    pool, mapas = construir_pack()
    return {
        "version": 1,
        "issue": 1804,
        "formato": "RGBDS 2bpp textual",
        "fuentes_visuales": [
            {"ruta": f"godot/arte/aquiles/{nombre}", "git_blob_sha": sha}
            for nombre, sha in FUENTES.items()
        ],
        "sprite": {
            "grid": [8, 8],
            "frame_px": [FRAME_W, FRAME_H],
            "states": list(ESTADOS),
            "frames_per_state": 2,
            "tiles_per_frame": 12,
            "unique_obj_tiles": len(pool),
            "frame_maps": mapas,
        },
        "bg": {
            "familias": list(patrones_bg().keys()),
            "unique_tiles": len(patrones_bg()),
        },
        "hud": {
            "base": ["observar", "reflejo"],
            "revealed_only": ["talon"],
            "regla": "talon permanece en banco separado hasta deducir vulnerabilidad",
        },
        "paletas": {
            "total": len(PALETAS),
            "bg": 4,
            "obj": 4,
            "colores_por_paleta": 4,
        },
        "presupuesto": {
            "obj_tiles_max": 64,
            "bg_tiles_max": 16,
            "hud_tiles_max": 4,
            "obj_tiles_actual": len(pool),
            "bg_tiles_actual": len(patrones_bg()),
            "hud_tiles_actual": len(iconos_hud()),
        },
        "previews": [
            {"ruta": "myrmidon_v1_preview_normal.svg", "px": [160, 144], "estado": "idle", "vulnerabilidad_revelada": False},
            {"ruta": "myrmidon_v1_preview_vulnerable.svg", "px": [160, 144], "estado": "vulnerable", "vulnerabilidad_revelada": True},
        ],
    }


def _rects_por_runs(img, ox, oy, pal):
    out = []
    for y, row in enumerate(img):
        x = 0
        while x < len(row):
            px = row[x]
            if px == 0:
                x += 1
                continue
            x2 = x + 1
            while x2 < len(row) and row[x2] == px:
                x2 += 1
            out.append(
                f'<rect x="{ox+x}" y="{oy+y}" width="{x2-x}" height="1" fill="{pal[px]}"/>'
            )
            x = x2
    return out


def svg_preview(estado: str, revelar: bool):
    width, height = 160, 144
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" shape-rendering="crispEdges">',
        f'<title>MYRMIDON 98 preview — {estado}</title>',
        '<rect width="160" height="144" fill="#11131a"/>',
    ]
    for y in range(96, 144, 8):
        for x in range(0, 160, 8):
            c = "#38455b" if ((x//8 + y//8) % 2) else "#4a3f49"
            parts.append(f'<rect x="{x}" y="{y}" width="8" height="8" fill="{c}"/>')
    parts += [
        '<rect x="20" y="24" width="12" height="72" fill="#93a3b9"/>',
        '<rect x="23" y="24" width="6" height="72" fill="#f4e9c7"/>',
        '<rect x="128" y="28" width="4" height="68" fill="#93a3b9"/>',
        '<rect x="132" y="32" width="20" height="34" fill="#a55155"/>',
        '<rect x="132" y="54" width="20" height="12" fill="#f1d28a"/>',
        '<rect x="48" y="92" width="76" height="4" fill="#f4e9c7"/>',
    ]
    img = frame_pixels(estado, 1 if revelar else 0)
    parts += _rects_por_runs(
        img, 68, 56, PALETAS["OBJ_VULNERABLE" if revelar else "OBJ_AQUILES"]
    )
    hud = iconos_hud()
    nombres = ("observar", "reflejo", "talon") if revelar else ("observar", "reflejo")
    for idx, nombre in enumerate(nombres):
        parts += _rects_por_runs(hud[nombre], 6 + idx * 12, 6, PALETAS["OBJ_HUD"])
    if revelar:
        parts.append('<rect x="149" y="6" width="5" height="5" fill="#f5df79"/>')
    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def salidas():
    return {
        "myrmidon_v1_tiles.inc": rgbds_tiles(),
        "myrmidon_v1_palettes.inc": rgbds_paletas(),
        "myrmidon_v1_manifest.json": json.dumps(
            manifest(), indent=2, ensure_ascii=False, sort_keys=True
        ) + "\n",
    }


def escribir_previews(destino: Path):
    destino.mkdir(parents=True, exist_ok=True)
    (destino / "myrmidon_v1_preview_normal.svg").write_text(
        svg_preview("idle", False), encoding="utf-8"
    )
    (destino / "myrmidon_v1_preview_vulnerable.svg").write_text(
        svg_preview("vulnerable", True), encoding="utf-8"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check", action="store_true", help="falla si los generados versionados no coinciden"
    )
    parser.add_argument(
        "--preview-dir",
        type=Path,
        help="genera dos previews 160x144 fuera del árbol versionado",
    )
    args = parser.parse_args()
    esperado = salidas()
    ASSETS.mkdir(parents=True, exist_ok=True)
    if args.check:
        fallos = []
        for nombre, contenido in esperado.items():
            ruta = ASSETS / nombre
            if not ruta.exists() or ruta.read_text(encoding="utf-8") != contenido:
                fallos.append(nombre)
        if fallos:
            raise SystemExit("desactualizados: " + ", ".join(fallos))
        print("MYRMIDON assets v1 reproducibles: OK")
    else:
        for nombre, contenido in esperado.items():
            (ASSETS / nombre).write_text(contenido, encoding="utf-8")
        print("Generados:", ", ".join(esperado))
    if args.preview_dir:
        escribir_previews(args.preview_dir)
        print("Previews:", args.preview_dir)


if __name__ == "__main__":
    main()
