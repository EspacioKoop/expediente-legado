#!/usr/bin/env python3
"""Prepara sets PBR 4K para #399 sin saltarse Git LFS ni procedencia.

El script no modifica `procedencia.json`: copia/organiza los mapas y emite un
fragmento JSON listo para revisar y fusionar. Esto evita inventar metadatos de
licencia o sobrescribir el registro compartido de assets.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

MAPAS = ("albedo", "normal", "roughness", "ao")
EXTENSIONES = (".png", ".jpg", ".jpeg")
RESOLUCION_MINIMA = 4096


@dataclass(frozen=True)
class Mapa:
    tipo: str
    origen: Path
    ancho: int
    alto: int
    sha256: str


def _dimensiones_png(path: Path) -> tuple[int, int]:
    with path.open("rb") as fh:
        cabecera = fh.read(24)
    if len(cabecera) < 24 or cabecera[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: PNG inválido")
    if cabecera[12:16] != b"IHDR":
        raise ValueError(f"{path}: PNG sin IHDR")
    return struct.unpack(">II", cabecera[16:24])


def _dimensiones_jpeg(path: Path) -> tuple[int, int]:
    datos = path.read_bytes()
    if len(datos) < 4 or datos[:2] != b"\xff\xd8":
        raise ValueError(f"{path}: JPEG inválido")

    i = 2
    marcadores_sof = {
        0xC0,
        0xC1,
        0xC2,
        0xC3,
        0xC5,
        0xC6,
        0xC7,
        0xC9,
        0xCA,
        0xCB,
        0xCD,
        0xCE,
        0xCF,
    }
    while i + 4 <= len(datos):
        if datos[i] != 0xFF:
            i += 1
            continue
        while i < len(datos) and datos[i] == 0xFF:
            i += 1
        if i >= len(datos):
            break
        marcador = datos[i]
        i += 1
        if marcador in (0xD8, 0xD9):
            continue
        if i + 2 > len(datos):
            break
        longitud = struct.unpack(">H", datos[i : i + 2])[0]
        if longitud < 2 or i + longitud > len(datos):
            break
        if marcador in marcadores_sof:
            if longitud < 7:
                break
            alto, ancho = struct.unpack(">HH", datos[i + 3 : i + 7])
            return ancho, alto
        i += longitud
    raise ValueError(f"{path}: JPEG sin marcador SOF")


def dimensiones(path: Path) -> tuple[int, int]:
    ext = path.suffix.lower()
    if ext == ".png":
        return _dimensiones_png(path)
    if ext in (".jpg", ".jpeg"):
        return _dimensiones_jpeg(path)
    raise ValueError(f"{path}: formato no soportado; usa PNG/JPG")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for bloque in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(bloque)
    return h.hexdigest()


def encontrar_mapa(carpeta: Path, tipo: str) -> Path:
    candidatos = [carpeta / f"{tipo}{ext}" for ext in EXTENSIONES]
    encontrados = [path for path in candidatos if path.is_file()]
    if len(encontrados) != 1:
        nombres = ", ".join(path.name for path in candidatos)
        raise ValueError(
            f"{carpeta}: debe existir exactamente un mapa {tipo}; candidatos: {nombres}"
        )
    return encontrados[0]


def validar_set(carpeta: Path, resolucion_minima: int = RESOLUCION_MINIMA) -> list[Mapa]:
    if not carpeta.is_dir():
        raise ValueError(f"{carpeta}: no es una carpeta")

    mapas: list[Mapa] = []
    dimensiones_base: tuple[int, int] | None = None
    for tipo in MAPAS:
        origen = encontrar_mapa(carpeta, tipo)
        ancho, alto = dimensiones(origen)
        if ancho < resolucion_minima or alto < resolucion_minima:
            raise ValueError(
                f"{origen}: {ancho}x{alto}; mínimo {resolucion_minima}x{resolucion_minima}"
            )
        if dimensiones_base is None:
            dimensiones_base = (ancho, alto)
        elif (ancho, alto) != dimensiones_base:
            raise ValueError(
                f"{origen}: {ancho}x{alto}; el set usa {dimensiones_base[0]}x{dimensiones_base[1]}"
            )
        mapas.append(Mapa(tipo, origen, ancho, alto, sha256(origen)))
    return mapas


def _entrada_procedencia(
    ruta: str,
    titulo: str,
    autor: str,
    licencia: str,
    fuente: str,
    digest: str,
) -> dict[str, str]:
    return {
        "ruta": ruta,
        "titulo": titulo,
        "autor": autor,
        "licencia": licencia,
        "fuente": fuente,
        "sha256": digest,
    }


def preparar(
    carpeta: Path,
    nombre: str,
    destino_assets: Path,
    autor: str,
    licencia: str,
    fuente: str,
    compat_textura_procedural: bool = True,
    resolucion_minima: int = RESOLUCION_MINIMA,
) -> dict[str, object]:
    if not nombre or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789_" for c in nombre):
        raise ValueError("nombre: usa solo minúsculas ASCII, números y guion bajo")
    if not autor.strip() or not licencia.strip() or not fuente.strip():
        raise ValueError("autor, licencia y fuente son obligatorios; no se inventan")

    mapas = validar_set(carpeta, resolucion_minima)
    set_dir = destino_assets / "texturas" / "pbr" / nombre
    set_dir.mkdir(parents=True, exist_ok=True)

    procedencia: list[dict[str, str]] = []
    salidas: dict[str, str] = {}
    for mapa in mapas:
        ext = ".jpg" if mapa.origen.suffix.lower() == ".jpeg" else mapa.origen.suffix.lower()
        destino = set_dir / f"{mapa.tipo}{ext}"
        shutil.copyfile(mapa.origen, destino)
        digest = sha256(destino)
        ruta_rel = destino.relative_to(destino_assets).as_posix()
        procedencia.append(
            _entrada_procedencia(
                ruta_rel,
                f"{nombre} — {mapa.tipo}",
                autor,
                licencia,
                fuente,
                digest,
            )
        )
        salidas[mapa.tipo] = ruta_rel

    albedo = next(mapa for mapa in mapas if mapa.tipo == "albedo")
    if compat_textura_procedural:
        if albedo.origen.suffix.lower() not in (".jpg", ".jpeg"):
            raise ValueError(
                "compatibilidad inmediata con TexturaProcedural requiere albedo.jpg/jpeg; "
                "el set PBR ya fue validado pero no se ha publicado"
            )
        compat = destino_assets / "texturas" / f"{nombre}.jpg"
        compat.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(albedo.origen, compat)
        digest = sha256(compat)
        ruta_rel = compat.relative_to(destino_assets).as_posix()
        procedencia.append(
            _entrada_procedencia(
                ruta_rel,
                f"{nombre} — albedo compatible con TexturaProcedural",
                autor,
                licencia,
                fuente,
                digest,
            )
        )
        salidas["compat_albedo"] = ruta_rel

    fragmento = {
        "material": nombre,
        "resolucion": f"{mapas[0].ancho}x{mapas[0].alto}",
        "salidas": salidas,
        "procedencia": procedencia,
    }
    fragment_path = set_dir / "procedencia.fragment.json"
    fragment_path.write_text(
        json.dumps(fragmento, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return fragmento


def construir_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Valida y prepara un set PBR 4K para godot/assets/texturas."
    )
    parser.add_argument("carpeta", type=Path, help="Carpeta con albedo/normal/roughness/ao")
    parser.add_argument("--nombre", required=True, help="slug del material, p. ej. acera_barcelona")
    parser.add_argument(
        "--destino-assets",
        type=Path,
        default=Path("godot/assets"),
        help="raíz de assets del proyecto",
    )
    parser.add_argument("--autor", required=True)
    parser.add_argument("--licencia", required=True)
    parser.add_argument("--fuente", required=True)
    parser.add_argument(
        "--sin-compat-textura-procedural",
        action="store_true",
        help="no duplica albedo JPG en texturas/<nombre>.jpg",
    )
    parser.add_argument(
        "--resolucion-minima",
        type=int,
        default=RESOLUCION_MINIMA,
        help="lado mínimo; por defecto 4096",
    )
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = construir_parser().parse_args(argv)
    try:
        fragmento = preparar(
            carpeta=args.carpeta,
            nombre=args.nombre,
            destino_assets=args.destino_assets,
            autor=args.autor,
            licencia=args.licencia,
            fuente=args.fuente,
            compat_textura_procedural=not args.sin_compat_textura_procedural,
            resolucion_minima=args.resolucion_minima,
        )
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    print(json.dumps(fragmento, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
