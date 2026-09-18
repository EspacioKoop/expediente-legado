#!/usr/bin/env python3
"""Valida y prepara un staging mínimo del School Classrooms Asset Pack de Styloo.

No descarga el pack, no escribe en ``godot/assets`` y no crea punteros LFS.
Trabaja contra el manifiesto auditado de #223 y extrae únicamente GLB individuales
aprobados a ``dist/.cache`` (o al directorio indicado) para revisión humana.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MANIFIESTO_DEFECTO = ROOT / "docs" / "assets" / "school-classrooms-styloo.manifest.json"
SALIDA_DEFECTO = ROOT / "dist" / ".cache" / "styloo-classrooms"


class StylooImportError(RuntimeError):
    """El ZIP no coincide con el lote auditado o el staging no es seguro."""


def sha256_bytes(datos: bytes) -> str:
    return hashlib.sha256(datos).hexdigest()


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
        raise StylooImportError("Manifiesto incompleto: " + ", ".join(faltan))
    if datos["licencia"] != "CC0-1.0":
        raise StylooImportError("La licencia auditada debe ser CC0-1.0")
    ids = [asset.get("id") for asset in datos["assets"]]
    if len(ids) != len(set(ids)):
        raise StylooImportError("El manifiesto contiene IDs de asset duplicados")
    return datos


def assets_por_id(manifiesto: dict) -> dict[str, dict]:
    return {asset["id"]: asset for asset in manifiesto["assets"]}


def seleccionar_assets(manifiesto: dict, lotes: list[str]) -> list[dict]:
    disponibles = manifiesto["lotes"]
    desconocidos = sorted(set(lotes) - set(disponibles))
    if desconocidos:
        raise StylooImportError("Lotes desconocidos: " + ", ".join(desconocidos))
    por_id = assets_por_id(manifiesto)
    seleccion: list[dict] = []
    vistos: set[str] = set()
    for lote in lotes:
        for asset_id in disponibles[lote]:
            if asset_id not in por_id:
                raise StylooImportError(f"El lote {lote!r} referencia el asset ausente {asset_id!r}")
            if asset_id not in vistos:
                seleccion.append(por_id[asset_id])
                vistos.add(asset_id)
    return seleccion


def validar_zip(
    ruta_zip: Path,
    manifiesto: dict,
    seleccion: list[dict],
    *,
    aceptar_reempaquetado: bool = False,
) -> dict[str, bytes]:
    if not ruta_zip.is_file():
        raise StylooImportError(f"No existe el ZIP: {ruta_zip}")
    hash_zip = sha256_fichero(ruta_zip)
    esperado = manifiesto["archivo_sha256"]
    if hash_zip != esperado and not aceptar_reempaquetado:
        raise StylooImportError(
            "El SHA-256 del ZIP no coincide con la revisión auditada: "
            f"esperado={esperado} real={hash_zip}. "
            "Usa --aceptar-reempaquetado solo si quieres validar por fichero."
        )

    extraidos: dict[str, bytes] = {}
    with zipfile.ZipFile(ruta_zip) as archivo:
        nombres = set(archivo.namelist())
        readme = manifiesto.get("readme_interno")
        if readme and readme not in nombres:
            raise StylooImportError(f"Falta el README esperado: {readme}")
        for asset in seleccion:
            miembro = asset["miembro_zip"]
            if "demoscene" in miembro.lower():
                raise StylooImportError(f"El allowlist no puede contener demo scenes: {miembro}")
            if not miembro.lower().endswith(".glb"):
                raise StylooImportError(f"El primer corte solo admite GLB individuales: {miembro}")
            if miembro not in nombres:
                raise StylooImportError(f"Falta el fichero auditado: {miembro}")
            datos = archivo.read(miembro)
            if len(datos) != asset["bytes"]:
                raise StylooImportError(
                    f"{asset['id']}: tamaño distinto; esperado={asset['bytes']} real={len(datos)}"
                )
            real = sha256_bytes(datos)
            if real != asset["sha256"]:
                raise StylooImportError(
                    f"{asset['id']}: SHA-256 distinto; esperado={asset['sha256']} real={real}"
                )
            extraidos[asset["id"]] = datos
    return extraidos


def preparar_staging(
    salida: Path,
    manifiesto: dict,
    seleccion: list[dict],
    extraidos: dict[str, bytes],
) -> dict:
    nombres_permitidos = {asset["destino_sugerido"] for asset in seleccion} | {
        "styloo-classrooms-staging.json"
    }
    if salida.exists():
        ajenos = sorted(p.name for p in salida.iterdir() if p.name not in nombres_permitidos)
        if ajenos:
            raise StylooImportError(
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
        destino.write_bytes(extraidos[asset["id"]])
        entradas.append(
            {
                "id": asset["id"],
                "fichero": destino.name,
                "sha256": asset["sha256"],
                "procedencia_sugerida": {
                    "ruta": f"modelos/styloo_school/{destino.name}",
                    "titulo": asset["titulo"],
                    "autor": manifiesto["autor"],
                    "licencia": manifiesto["licencia"],
                    "fuente": manifiesto["fuente"],
                    "sha256": asset["sha256"],
                },
            }
        )

    staging = {
        "fuente": manifiesto["fuente"],
        "licencia": manifiesto["licencia"],
        "cantidad": len(entradas),
        "assets": entradas,
        "nota": (
            "Staging local: aún no está integrado. Antes de copiar a godot/assets hay que "
            "validar escala/materiales/época en Godot y subir los GLB mediante Git LFS real."
        ),
    }
    (salida / "styloo-classrooms-staging.json").write_text(
        json.dumps(staging, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return staging


def ejecutar(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path, help="ZIP oficial StylooClassroomAssetPack GLTF & FBX.zip")
    parser.add_argument("--manifest", type=Path, default=MANIFIESTO_DEFECTO)
    parser.add_argument("--output", type=Path, default=SALIDA_DEFECTO)
    parser.add_argument(
        "--lote",
        action="append",
        dest="lotes",
        help="Lote a preparar. Repetible; por defecto: administrativo.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Valida sin escribir staging")
    parser.add_argument(
        "--aceptar-reempaquetado",
        action="store_true",
        help="Acepta un ZIP con hash global distinto si cada GLB seleccionado conserva tamaño y SHA-256.",
    )
    args = parser.parse_args(argv)

    try:
        manifiesto = cargar_manifiesto(args.manifest)
        lotes = args.lotes or ["administrativo"]
        seleccion = seleccionar_assets(manifiesto, lotes)
        extraidos = validar_zip(
            args.zip,
            manifiesto,
            seleccion,
            aceptar_reempaquetado=args.aceptar_reempaquetado,
        )
        if args.dry_run:
            for asset in seleccion:
                print(
                    f"{asset['id']:18s} <- {asset['miembro_zip']} "
                    f"sha256={asset['sha256']}"
                )
            print(f"OK: {len(seleccion)} GLB auditados; no se escribió ningún fichero.")
            return 0
        staging = preparar_staging(args.output, manifiesto, seleccion, extraidos)
        print(f"OK: {staging['cantidad']} GLB preparados en {args.output}")
        print(f"Manifiesto de staging: {args.output / 'styloo-classrooms-staging.json'}")
        return 0
    except (OSError, json.JSONDecodeError, zipfile.BadZipFile, StylooImportError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(ejecutar())
