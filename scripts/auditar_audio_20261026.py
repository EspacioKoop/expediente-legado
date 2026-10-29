#!/usr/bin/env python3
"""Auditor offline del inventario de audio de Godot 4 (#2740).

Uso: python3 scripts/auditar_audio_20261026.py --root . --json reporte.json

Solo lee el checkout local: nunca sigue enlaces externos ni toca la red. Los
ficheros de audio entran por LFS con ficha en assets/procedencia.json, así que
aqui no se descarga nada; lo que no está, simplemente no está y se registra.

Qué comprueba:
- referencias ``res://`` completas a .ogg/.wav/.mp3 en .gd/.tscn/.tres;
- nombres desnudos de audio en los catalogos de sonido.gd y musica.gd,
  resueltos contra la constante RUTA de su propio fichero (la unica forma
  inequivoca de componer la ruta real);
- ficheros de audio presentes pero nunca referenciados (huerfanos);
- fichas de procedencia: fichero sin ficha y ficha sin fichero.

Las pruebas de Godot usan nombres de pistas que no existen a proposito
(``otra-pista.ogg``) para verificar la configuracion de bucle sin binario LFS:
los nombres desnudos bajo ``pruebas/`` no se tratan como referencias.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

EXTENSIONES = {".ogg", ".wav", ".mp3"}
ESCANEA = {".gd", ".tscn", ".tres"}

REFERENCIA_COMPLETA = re.compile(r'"(res://[^"\n]+\.(?:ogg|wav|mp3))"')
NOMBRE_DESNUDO = re.compile(r'"([A-Za-z0-9_\-./]+\.(?:ogg|wav|mp3))"')
RUTA_CONST = re.compile(r'(?m)^\s*const RUTA := "([^"\n]+)"')
CATALOGOS = {
    "guion/sonido.gd",
    "guion/musica.gd",
}

# Claves de configuracion de bucle, no rutas de carga: `musica.gd` nombra
# `battle_music_01-loop.ogg` para fijar donde arranca la repeticion aunque la
# pista aun no haya entrado por LFS (#76). Tratarla como referencia rota seria
# un falso positivo: el catalogo la deja vacia a proposito.
BUCLE = re.compile(r'(?m)^\s*const INICIO_BUCLE_POR_FICHERO')


def within(root: Path, path: Path) -> bool:
    return path.resolve().is_relative_to(root.resolve())


def finding(code: str, path: str, line: int, detail: str, severity="error") -> dict:
    return {
        "code": code,
        "file": path,
        "line": line,
        "severity": severity,
        "detail": detail,
    }


def _ruta_del_catalogo(texto: str) -> str:
    encontrado = RUTA_CONST.search(texto)
    return encontrado.group(1) if encontrado else ""


def scan(root: Path) -> dict:
    root = root.resolve()
    game = root / "godot"
    if not game.is_dir() or not within(root, game):
        raise ValueError("La raíz debe contener el directorio godot")

    referencias: dict[str, list[dict]] = {}
    fuentes = [
        path
        for path in sorted(game.rglob("*"))
        if path.is_file() and path.suffix in ESCANEA and within(root, path)
    ]
    for path in fuentes:
        rel = path.relative_to(root).as_posix()
        texto = path.read_text(encoding="utf-8", errors="replace")
        base = _ruta_del_catalogo(texto) if rel.removeprefix("godot/") in CATALOGOS else ""
        en_bucle = bool(BUCLE.search(texto))
        for numero, linea in enumerate(texto.splitlines(), 1):
            for hallazgo in REFERENCIA_COMPLETA.finditer(linea):
                destino = hallazgo.group(1)
                referencias.setdefault(destino, []).append(
                    {"file": rel, "line": numero}
                )
            if not base:
                continue
            for hallazgo in NOMBRE_DESNUDO.finditer(linea):
                if en_bucle:
                    continue
                destino = base + hallazgo.group(1)
                referencias.setdefault(destino, []).append(
                    {"file": rel, "line": numero}
                )

    findings = []
    usadas: set[str] = set()
    for destino in sorted(referencias):
        relativo = destino.removeprefix("res://")
        local = game / relativo
        usadas.add(relativo.removeprefix("assets/"))
        if not local.exists():
            for origen in referencias[destino]:
                findings.append(
                    finding(
                        "audio_roto",
                        origen["file"],
                        origen["line"],
                        f"referencia sin fichero: {destino}",
                    )
                )

    audio = game / "assets/audio"
    presentes: set[str] = set()
    for path in sorted(audio.rglob("*")) if audio.is_dir() else []:
        if not path.is_file() or path.suffix not in EXTENSIONES:
            continue
        if not within(root, path):
            continue
        relativo = path.relative_to(game / "assets").as_posix()
        presentes.add(relativo)
        if relativo not in usadas:
            findings.append(
                finding(
                    "audio_huerfano",
                    "godot/assets/" + relativo,
                    0,
                    "fichero de audio sin ninguna referencia estática",
                    severity="warning",
                )
            )

    procedencia = game / "assets/procedencia.json"
    fichas: set[str] = set()
    if procedencia.is_file() and within(root, procedencia):
        registro = json.loads(procedencia.read_text(encoding="utf-8"))
        fichas = {
            str(ficha["ruta"])
            for ficha in registro.get("assets", [])
            if str(ficha.get("ruta", "")).startswith("audio/")
        }
        for relativo in sorted(presentes - fichas):
            findings.append(
                finding(
                    "ficha_ausente",
                    "godot/assets/" + relativo,
                    0,
                    "fichero de audio sin ficha en assets/procedencia.json",
                )
            )
    for relativo in sorted(fichas - presentes):
        findings.append(
            finding(
                "ficha_huerfana",
                "godot/assets/" + relativo,
                0,
                "ficha de procedencia sin fichero de audio",
            )
        )

    resumen = {
        "referencias": len(referencias),
        "ficheros_audio": len(presentes),
        "fichas_audio": len(fichas),
        "hallazgos": len(findings),
        "findings": findings,
    }
    return resumen


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="raíz del checkout")
    parser.add_argument("--json", help="escribir el reporte a este fichero")
    argumentos = parser.parse_args()

    resumen = scan(Path(argumentos.root))
    for hallazgo in resumen["findings"]:
        donde = f'{hallazgo["file"]}:{hallazgo["line"]}'
        print(f'[{hallazgo["severity"]}] {hallazgo["code"]} {donde} {hallazgo["detail"]}')
    print(
        "audio: {referencias} referencias, {ficheros_audio} ficheros, "
        "{fichas_audio} fichas, {hallazgos} hallazgos".format(**resumen)
    )
    if argumentos.json:
        Path(argumentos.json).write_text(
            json.dumps(resumen, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
    errores = sum(1 for h in resumen["findings"] if h["severity"] == "error")
    return 1 if errores else 0


if __name__ == "__main__":
    raise SystemExit(main())
