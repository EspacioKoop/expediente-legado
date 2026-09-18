#!/usr/bin/env python3
"""Prepara la matriz reproducible de validación humana del tarot (#645).

Genera:
- 8 cartas ocultas × 3 recorridos: frontal normal, frontal con reducción de
  movimiento y skip;
- El Mago × 2 recorridos (normal/reducido) obtenido primero por progreso real.

Cada ejecución usa directorios XDG aislados para no leer ni modificar la partida
personal. Las capturas son evidencia de preflight; no sustituyen el pase humano
sobre un export candidato.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
GODOT_DIR = ROOT / "godot"
CAPTURADOR = "pruebas/capturar.gd"

CARTAS_OCULTAS = (
    ("ACTA-1999-014", "la-justicia"),
    ("OF-1990-114", "la-rueda"),
    ("MEMO-1993-201", "el-juicio"),
    ("F-1996-00187", "la-luna"),
    ("ACTA-2007-002", "el-carro"),
    ("FAX-1996-077", "el-sol"),
    ("OF-1998-077", "la-emperatriz"),
    ("ACTA-1998-427B", "la-sacerdotisa"),
)

RECORRIDOS_OCULTAS = (
    ("normal", "2", "normal"),
    ("reducido", "2", "reducido"),
    ("skip", "-1", "normal"),
)

RECORRIDOS_PROGRESO = (
    ("normal", "2", "normal"),
    ("reducido", "2", "reducido"),
)


def _ejecutable_godot(preferido: str | None) -> str:
    candidatos = [preferido] if preferido else ["godot4", "godot"]
    for candidato in candidatos:
        if candidato and (Path(candidato).is_file() or shutil.which(candidato)):
            return candidato
    raise SystemExit("No se encontró Godot. Use --godot /ruta/al/ejecutable.")


def _envolver_xvfb(base: list[str]) -> list[str]:
    if os.name != "nt" and shutil.which("xvfb-run"):
        return ["xvfb-run", "-a", *base]
    return base


def _comando_oculta(
    godot: str, salida: Path, folio: str, plano: str, modo: str
) -> list[str]:
    return _envolver_xvfb(
        [
            godot,
            "--path",
            str(GODOT_DIR),
            "--script",
            CAPTURADOR,
            "--",
            str(salida),
            folio,
            plano,
            modo,
        ]
    )


def _comando_progreso(godot: str, salida: Path, plano: str, modo: str) -> list[str]:
    return _envolver_xvfb(
        [
            godot,
            "--path",
            str(GODOT_DIR),
            "--script",
            CAPTURADOR,
            "--",
            str(salida),
            plano,
            modo,
        ]
    )


def _ejecutar(comando: list[str], salida: Path) -> dict:
    with tempfile.TemporaryDirectory(prefix="tarot-645-") as temporal:
        temporal = Path(temporal)
        env = os.environ.copy()
        env["XDG_DATA_HOME"] = str(temporal / "data")
        env["XDG_CONFIG_HOME"] = str(temporal / "config")
        env["XDG_CACHE_HOME"] = str(temporal / "cache")
        proceso = subprocess.run(
            comando,
            cwd=ROOT,
            env=env,
            check=False,
            text=True,
            capture_output=True,
        )
    return {
        "ok": proceso.returncode == 0 and salida.is_file(),
        "returncode": proceso.returncode,
        "stdout": proceso.stdout[-4000:],
        "stderr": proceso.stderr[-4000:],
    }


def preparar(destino: Path, godot: str, ejecutar: bool = True) -> dict:
    destino.mkdir(parents=True, exist_ok=True)
    entradas: list[dict] = []

    for folio, carta in CARTAS_OCULTAS:
        for nombre, plano, modo in RECORRIDOS_OCULTAS:
            # El propio nombre contiene "tarot": así un --output personalizado
            # no desactiva por accidente el dispatcher especial del capturador.
            salida = destino / f"tarot-{carta}-{nombre}.png"
            comando = _comando_oculta(godot, salida, folio, plano, modo)
            entrada = {
                "tipo": "oculta",
                "folio": folio,
                "carta": carta,
                "recorrido": nombre,
                "plano": int(plano),
                "modo": modo,
                "captura": salida.name,
                "comando": comando,
                "ok": None,
            }
            if ejecutar:
                entrada.update(_ejecutar(comando, salida))
            entradas.append(entrada)

    for nombre, plano, modo in RECORRIDOS_PROGRESO:
        # "tarot" y "progreso" deben vivir en el fichero, no depender del
        # directorio: capturar.gd usa ambas palabras para escoger esta ruta.
        salida = destino / f"tarot-el-mago-progreso-{nombre}.png"
        comando = _comando_progreso(godot, salida, plano, modo)
        entrada = {
            "tipo": "progreso",
            "folio": None,
            "carta": "el-mago",
            "recorrido": nombre,
            "plano": int(plano),
            "modo": modo,
            "captura": salida.name,
            "comando": comando,
            "ok": None,
        }
        if ejecutar:
            entrada.update(_ejecutar(comando, salida))
        entradas.append(entrada)

    esperadas = (
        len(CARTAS_OCULTAS) * len(RECORRIDOS_OCULTAS) + len(RECORRIDOS_PROGRESO)
    )
    manifiesto = {
        "issue": 645,
        "nota": (
            "Preflight reproducible. La aceptación visual sigue requiriendo "
            "revisión humana sobre un export candidato."
        ),
        "total": len(entradas),
        "esperadas": esperadas,
        "entradas": entradas,
    }
    (destino / "manifest.json").write_text(
        json.dumps(manifiesto, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifiesto


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "dist" / "qa" / "tarot-645",
        help="Directorio de capturas y manifest.json.",
    )
    parser.add_argument("--godot", help="Ejecutable de Godot (por defecto godot4/godot).")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Escribe el manifiesto y los comandos sin ejecutar Godot.",
    )
    args = parser.parse_args()

    godot = args.godot or "godot4"
    if not args.dry_run:
        godot = _ejecutable_godot(args.godot)

    manifiesto = preparar(args.output, godot, ejecutar=not args.dry_run)
    fallos = [e for e in manifiesto["entradas"] if e["ok"] is False]
    print(f"Tarot #645: {manifiesto['total']} recorridos preparados en {args.output}")
    if args.dry_run:
        print("Dry-run: no se ejecutó Godot.")
        return 0
    if fallos:
        print(f"Fallaron {len(fallos)} recorridos; revise manifest.json.")
        return 1
    print("Capturas generadas. Falta la revisión humana del export candidato.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
