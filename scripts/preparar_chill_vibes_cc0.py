#!/usr/bin/env python3
"""Valida y prepara un staging curado de Chill Vibes Art Jam 4 para #220.

El script trabaja sobre el directorio ya extraído del .7z aportado. No descarga,
no escribe en ``godot/assets``, no crea punteros LFS y no modifica runtime.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
MANIFIESTO_DEFECTO = ROOT / "docs" / "assets" / "chill-vibes-art-jam-4.manifest.json"
SALIDA_DEFECTO = ROOT / "dist" / ".cache" / "chill-vibes-art-jam-4"
CARPETA_RAIZ = "Chill Vibes Art jam 4 (2025)"


class ChillVibesImportError(RuntimeError):
    """La fuente extraída no coincide con el lote auditado o el staging no es seguro."""


def sha256_fichero(ruta: Path) -> str:
    digest = hashlib.sha256()
    with ruta.open("rb") as fh:
        for bloque in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(bloque)
    return digest.hexdigest()


def cargar_manifiesto(ruta: Path) -> dict:
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    obligatorios = {"fuente", "autor", "licencia", "archivo_sha256", "lotes", "assets"}
    faltan = sorted(obligatorios - set(datos))
    if faltan:
        raise ChillVibesImportError("Manifiesto incompleto: " + ", ".join(faltan))
    if datos["licencia"] != "CC0-1.0":
        raise ChillVibesImportError("La licencia auditada debe ser CC0-1.0")
    ids = [asset.get("id") for asset in datos["assets"]]
    if len(ids) != len(set(ids)):
        raise ChillVibesImportError("El manifiesto contiene IDs duplicados")
    return datos


def resolver_raiz_extraida(ruta: Path) -> Path:
    if not ruta.is_dir():
        raise ChillVibesImportError(f"No existe el directorio extraído: {ruta}")
    if (ruta / "3D").is_dir() and (ruta / "README.txt").is_file():
        return ruta
    candidata = ruta / CARPETA_RAIZ
    if (candidata / "3D").is_dir() and (candidata / "README.txt").is_file():
        return candidata
    raise ChillVibesImportError(
        "No encuentro la raíz extraída esperada: debe contener 3D/ y README.txt "
        f"o una subcarpeta {CARPETA_RAIZ!r}."
    )


def assets_por_id(manifiesto: dict) -> dict[str, dict]:
    return {asset["id"]: asset for asset in manifiesto["assets"]}


def seleccionar_assets(manifiesto: dict, lotes: list[str]) -> list[dict]:
    disponibles = manifiesto["lotes"]
    desconocidos = sorted(set(lotes) - set(disponibles))
    if desconocidos:
        raise ChillVibesImportError("Lotes desconocidos: " + ", ".join(desconocidos))
    por_id = assets_por_id(manifiesto)
    seleccion: list[dict] = []
    vistos: set[str] = set()
    for lote in lotes:
        for asset_id in disponibles[lote]:
            if asset_id not in por_id:
                raise ChillVibesImportError(f"El lote {lote!r} referencia {asset_id!r}, ausente")
            if asset_id not in vistos:
                seleccion.append(por_id[asset_id])
                vistos.add(asset_id)
    return seleccion


def validar_archivo_fuente(ruta: Path | None, manifiesto: dict) -> None:
    if ruta is None:
        return
    if not ruta.is_file():
        raise ChillVibesImportError(f"No existe el .7z fuente: {ruta}")
    real = sha256_fichero(ruta)
    esperado = manifiesto["archivo_sha256"]
    if real != esperado:
        raise ChillVibesImportError(
            f"SHA-256 del .7z distinto: esperado={esperado} real={real}"
        )


def validar_extraidos(raiz: Path, seleccion: list[dict]) -> dict[str, Path]:
    encontrados: dict[str, Path] = {}
    for asset in seleccion:
        ruta = raiz / asset["miembro_extraido"]
        if not ruta.is_file():
            raise ChillVibesImportError(f"Falta el GLB auditado: {asset['miembro_extraido']}")
        if ruta.stat().st_size != asset["bytes"]:
            raise ChillVibesImportError(
                f"{asset['id']}: tamaño distinto; esperado={asset['bytes']} real={ruta.stat().st_size}"
            )
        real = sha256_fichero(ruta)
        if real != asset["sha256"]:
            raise ChillVibesImportError(
                f"{asset['id']}: SHA-256 distinto; esperado={asset['sha256']} real={real}"
            )
        encontrados[asset["id"]] = ruta
    return encontrados


def preparar_staging(
    salida: Path,
    manifiesto: dict,
    seleccion: list[dict],
    encontrados: dict[str, Path],
) -> dict:
    nombres_permitidos = {asset["destino_sugerido"] for asset in seleccion} | {
        "chill-vibes-staging.json"
    }
    if salida.exists():
        ajenos = sorted(p.name for p in salida.iterdir() if p.name not in nombres_permitidos)
        if ajenos:
            raise ChillVibesImportError(
                f"El staging {salida} contiene ficheros ajenos: {', '.join(ajenos)}"
            )
        for nombre in nombres_permitidos:
            objetivo = salida / nombre
            if objetivo.exists():
                objetivo.unlink()
    salida.mkdir(parents=True, exist_ok=True)

    entradas = []
    for asset in seleccion:
        destino = salida / asset["destino_sugerido"]
        shutil.copyfile(encontrados[asset["id"]], destino)
        if sha256_fichero(destino) != asset["sha256"]:
            raise ChillVibesImportError(f"{asset['id']}: el fichero copiado no conserva su hash")
        entradas.append(
            {
                "id": asset["id"],
                "fichero": destino.name,
                "sha256": asset["sha256"],
                "procedencia_sugerida": {
                    "ruta": f"modelos/chill_vibes/{destino.name}",
                    "titulo": asset["titulo"],
                    "autor": manifiesto["autor"],
                    "licencia": manifiesto["licencia"],
                    "fuente": manifiesto["fuente"],
                    "sha256": asset["sha256"],
                    "archivo_origen": manifiesto["archivo_fuente"],
                    "paquete_sha256": manifiesto["archivo_sha256"],
                },
            }
        )

    staging = {
        "fuente": manifiesto["fuente"],
        "licencia": manifiesto["licencia"],
        "cantidad": len(entradas),
        "assets": entradas,
        "nota": (
            "Staging local: aún no está integrado. Validar escala/materiales y una escena concreta "
            "antes de copiar a godot/assets; los GLB finales deben entrar mediante Git LFS real."
        ),
    }
    (salida / "chill-vibes-staging.json").write_text(
        json.dumps(staging, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return staging


def ejecutar(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("extraido", type=Path, help="Directorio extraído del .7z oficial")
    parser.add_argument("--archivo", type=Path, help=".7z original; si se indica, valida su SHA-256")
    parser.add_argument("--manifest", type=Path, default=MANIFIESTO_DEFECTO)
    parser.add_argument("--output", type=Path, default=SALIDA_DEFECTO)
    parser.add_argument(
        "--lote",
        action="append",
        dest="lotes",
        help="Lote a preparar. Repetible; por defecto: dressing_servicio.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Valida sin escribir staging")
    args = parser.parse_args(argv)

    try:
        manifiesto = cargar_manifiesto(args.manifest)
        validar_archivo_fuente(args.archivo, manifiesto)
        raiz = resolver_raiz_extraida(args.extraido)
        lotes = args.lotes or ["dressing_servicio"]
        seleccion = seleccionar_assets(manifiesto, lotes)
        encontrados = validar_extraidos(raiz, seleccion)
        if args.dry_run:
            for asset in seleccion:
                print(
                    f"{asset['id']:20s} <- {asset['miembro_extraido']} "
                    f"sha256={asset['sha256']}"
                )
            print(f"OK: {len(seleccion)} GLB auditados; no se escribió ningún fichero.")
            return 0
        staging = preparar_staging(args.output, manifiesto, seleccion, encontrados)
        print(f"OK: {staging['cantidad']} GLB preparados en {args.output}")
        print(f"Manifiesto de staging: {args.output / 'chill-vibes-staging.json'}")
        return 0
    except (OSError, json.JSONDecodeError, ChillVibesImportError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(ejecutar())
