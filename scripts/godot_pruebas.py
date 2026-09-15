#!/usr/bin/env python3
"""Arranque compartido de las pruebas que ejecutan Godot de verdad.

Antes, cada prueba de contrato repetía el mismo bloque: leer `GODOT_BIN`,
lanzar `--editor --import` del proyecto entero y después el script de pruebas.
Con 25 ficheros haciéndolo, el proyecto se importaba 25 veces por suite aunque
el resultado fuese idéntico. Aquí la importación ocurre una sola vez por
proceso y el resto de ficheros la reutilizan.

Además se comprueba antes la GDExtension de #124: sin ella Godot arranca igual
pero escupe `ERROR: Can't open dynamic library`, y las pruebas fallaban con un
rastro que no dice qué hacer. Ahora se dice.
"""

from __future__ import annotations

import os
import subprocess
import unittest
from functools import lru_cache
from pathlib import Path

from scripts.verificar_godot import validar

RAIZ = Path(__file__).resolve().parents[1]
PROYECTO = RAIZ / "godot"
EXTENSION = PROYECTO / "addons" / "siga98_gb" / "bin" / "linux"
BIBLIOTECA = EXTENSION / "libsiga98_gb.linux.template_debug.x86_64.so"
PREPARAR = "bash scripts/preparar_emulador_gb.sh linux-debug"

# CI compila la extensión antes de la suite, así que allí su ausencia es un
# fallo real y no un entorno a medio montar. En local se salta con la orden
# exacta que hay que ejecutar, en vez de once fallos que no explican nada.
EXIGIR_EXTENSION = os.environ.get("SIGA98_EXIGIR_EXTENSION") == "1"


def motor() -> str:
    return os.environ.get("GODOT_BIN", "godot4")


def exigir_extension() -> None:
    """Corta con un mensaje accionable si falta la GDExtension de #124."""
    if BIBLIOTECA.exists():
        return
    aviso = (
        f"Falta la GDExtension GB/GBC en {BIBLIOTECA.relative_to(RAIZ)}. "
        f"Compílala con: {PREPARAR}"
    )
    if EXIGIR_EXTENSION:
        raise AssertionError(aviso)
    raise unittest.SkipTest(aviso)


@lru_cache(maxsize=1)
def importar_proyecto() -> None:
    """Importa el proyecto una única vez por proceso."""
    exigir_extension()
    importacion = subprocess.run(
        [motor(), "--headless", "--path", str(PROYECTO), "--editor", "--import"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=300,
        check=False,
    )
    validar(importacion.stdout, importacion.returncode, importando=True)


def ejecutar_script(guion: str, timeout: int = 30) -> subprocess.CompletedProcess[str]:
    """Lanza un script de `godot/pruebas/` sobre el proyecto ya importado."""
    importar_proyecto()
    return subprocess.run(
        [motor(), "--headless", "--path", str(PROYECTO), "--script", guion],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
        check=False,
    )


def comprobar_contrato(caso: unittest.TestCase, guion: str, resumen: str, timeout: int = 30) -> str:
    """Ejecuta un guion de contrato y exige salida limpia y el resumen esperado."""
    resultado = ejecutar_script(guion, timeout=timeout)
    caso.assertEqual(resultado.returncode, 0, resultado.stdout)
    caso.assertIn(resumen, resultado.stdout)
    caso.assertNotIn("ERROR:", resultado.stdout)
    caso.assertNotIn("Parse Error:", resultado.stdout)
    return resultado.stdout
