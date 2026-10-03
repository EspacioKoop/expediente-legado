#!/usr/bin/env python3
"""Preflight dirigido del worker del pool (#1636).

El worker ejecutaba la suite Python completa para cualquier cambio en
`scripts/`, y el runner del worker no tiene Godot: 48 tests morían con
`FileNotFoundError: 'godot4'` fuera cual fuera el diff (piloto #1656). La
suite completa es trabajo del CI canónico, que se lanza igualmente sobre la
PR draft y es la autoridad. Aquí solo se comprueba lo que toca el diff:

- los tests Python relacionados con las rutas cambiadas;
- `gdformat --check` y `gdlint` sobre los `.gd` cambiados.

Un error cuya causa es que falta el binario de Godot cuenta como omitido, y
solo ese: cualquier otro error o fallo es real.

Uso:
    python3 scripts/agent_preflight.py --changed a.py b.gd [--report out.json]
"""

from __future__ import annotations

import argparse
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import unittest
from typing import Any

RAIZ = Path(__file__).resolve().parents[1]
SCRIPTS = RAIZ / "scripts"
MAX_TESTS = 25


def tests_relacionados(cambiadas: list[str], raiz: Path = RAIZ) -> list[str]:
    """Ficheros `scripts/test_*.py` que ejercitan las rutas cambiadas, ordenados."""

    scripts = raiz / "scripts"
    todos = sorted(scripts.glob("test_*.py"))
    elegidos: set[str] = set()
    for ruta in cambiadas:
        p = Path(ruta)
        if p.parts[:1] == ("scripts",) and p.suffix == ".py":
            if p.name.startswith("test_"):
                if (raiz / p).exists():
                    elegidos.add(p.name)
                continue
            modulo = p.stem
            propio = scripts / f"test_{modulo}.py"
            if propio.exists():
                elegidos.add(propio.name)
            importa = re.compile(rf"^\s*(?:import|from)\s+(?:scripts\.)?{re.escape(modulo)}\b", re.M)
            for test in todos:
                if importa.search(test.read_text(encoding="utf-8")):
                    elegidos.add(test.name)
        elif p.suffix == ".gd":
            # Los contratos citan el .gd por su ruta (desde la raíz o desde godot/)
            # o la construyen a trozos con Path: basta el nombre entre comillas.
            citas = {ruta, ruta.removeprefix("godot/"), f'"{p.name}"'}
            for test in todos:
                texto = test.read_text(encoding="utf-8")
                if any(cita in texto for cita in citas):
                    elegidos.add(test.name)
    return sorted(elegidos)


def es_godot_ausente(traza: str, binario: str) -> bool:
    return f"No such file or directory: '{binario}'" in traza


def ejecutar_tests(nombres: list[str], raiz: Path = RAIZ) -> dict[str, Any]:
    """Ejecuta los tests en este proceso y separa «falta Godot» de errores reales."""

    binario = os.environ.get("GODOT_BIN", "godot4")
    for ruta in (str(raiz), str(raiz / "scripts")):
        if ruta not in sys.path:
            sys.path.insert(0, ruta)
    suite = unittest.TestSuite()
    for nombre in nombres:
        # Loader nuevo: el por defecto recuerda el top-level de un discover previo.
        sys.modules.pop(Path(nombre).stem, None)
        cargador = unittest.TestLoader()
        suite.addTests(
            cargador.discover(str(raiz / "scripts"), pattern=nombre, top_level_dir=str(raiz / "scripts"))
        )
    salida = io.StringIO()
    resultado = unittest.TextTestRunner(stream=salida, verbosity=1).run(suite)
    sin_godot = [str(test) for test, traza in resultado.errors if es_godot_ausente(traza, binario)]
    errores = [
        {"test": str(test), "traza": traza[-1500:]}
        for test, traza in resultado.errors
        if not es_godot_ausente(traza, binario)
    ]
    fallos = [{"test": str(test), "traza": traza[-1500:]} for test, traza in resultado.failures]
    return {
        "ejecutados": resultado.testsRun,
        "omitidos": len(resultado.skipped),
        "sin_godot": sin_godot,
        "errores": errores,
        "fallos": fallos,
        "exitos_inesperados": [str(test) for test in resultado.unexpectedSuccesses],
    }


def comprobar_gd(gd: list[str], raiz: Path = RAIZ) -> dict[str, Any]:
    if not gd:
        return {"archivos": [], "problemas": []}
    problemas = []
    for herramienta, args in (("gdformat", ["--check"]), ("gdlint", [])):
        if shutil.which(herramienta) is None:
            problemas.append(f"{herramienta} no disponible (instala gdtoolkit==4.3.4)")
            continue
        proc = subprocess.run(
            [herramienta, *args, *gd], cwd=raiz, capture_output=True, text=True, check=False
        )
        if proc.returncode != 0:
            problemas.append(f"{herramienta}: {(proc.stdout + proc.stderr)[-1500:]}")
    return {"archivos": gd, "problemas": problemas}


def preflight(cambiadas: list[str], raiz: Path = RAIZ) -> dict[str, Any]:
    tests = tests_relacionados(cambiadas, raiz)
    informe: dict[str, Any] = {"tests": tests}
    if len(tests) > MAX_TESTS:
        # Un diff que toca módulos muy compartidos se deja al CI canónico.
        informe["python"] = {"ejecutados": 0, "aviso": f"{len(tests)} tests > {MAX_TESTS}; se delega al CI"}
    else:
        informe["python"] = ejecutar_tests(tests, raiz) if tests else {"ejecutados": 0}
    gd = [ruta for ruta in cambiadas if ruta.endswith(".gd") and (raiz / ruta).exists()]
    informe["gd"] = comprobar_gd(gd, raiz)
    python = informe["python"]
    informe["ok"] = (
        not python.get("errores")
        and not python.get("fallos")
        and not python.get("exitos_inesperados")
        and not informe["gd"]["problemas"]
    )
    return informe


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--changed", nargs="*", default=[], help="rutas cambiadas (staged)")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    informe = preflight(args.changed)
    texto = json.dumps(informe, ensure_ascii=False, indent=2)
    if args.report:
        args.report.write_text(texto + "\n", encoding="utf-8")
    python = informe["python"]
    print(
        f"preflight: tests={len(informe['tests'])} ejecutados={python.get('ejecutados', 0)} "
        f"sin_godot={len(python.get('sin_godot', []))} errores={len(python.get('errores', []))} "
        f"fallos={len(python.get('fallos', []))} "
        f"exitos_inesperados={len(python.get('exitos_inesperados', []))} "
        f"gd_problemas={len(informe['gd']['problemas'])}"
    )
    for problema in python.get("errores", []) + python.get("fallos", []):
        print(f"--- {problema['test']}\n{problema['traza']}")
    for test in python.get("exitos_inesperados", []):
        print(f"--- {test}\nÉxito inesperado de una prueba marcada expectedFailure")
    for problema in informe["gd"]["problemas"]:
        print(f"--- {problema}")
    return 0 if informe["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
