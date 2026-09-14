#!/usr/bin/env python3
"""Ejecuta importación, suite y arranque sin aceptar falsos verdes de Godot."""

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

RAIZ = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"^(\d+) pasadas, (\d+) fallos$", re.MULTILINE)
ERROR_GUION = re.compile(r"^(?:SCRIPT ERROR:|.*Parse Error:)", re.MULTILINE)
ERROR_MOTOR = re.compile(r"^ERROR:", re.MULTILINE)

# Los ÚNICOS diagnósticos que la suite tiene derecho a imprimir, porque los
# provoca a propósito para comprobar que el juego los sobrevive: una partida
# corrupta al recuperarla, y un guardado que no puede escribir ni renombrar
# (#191). Se listan uno a uno y no por prefijo: la gracia de este detector es
# que un error NUEVO no se cuele entre los de siempre. Nunca en el arranque.
ERRORES_PROVOCADOS = (
    r"Parse JSON failed\.",
    r"No se pudo escribir ",
    r"No se pudo reemplazar ",
)
ESPERADO_EN_SUITE = re.compile(
    r"^ERROR: (?:%s)[^\n]*$" % "|".join(ERRORES_PROVOCADOS), re.MULTILINE
)


def validar(salida, codigo, minimo=None, importando=False):
    """Godot puede imprimir errores y terminar con código cero."""
    if codigo != 0:
        raise ValueError(f"Godot terminó con código {codigo}")
    if ERROR_GUION.search(salida):
        raise ValueError("Godot registró un error de guion")
    # La primera importación puede avisar de traducciones todavía no generadas.
    # En la suite y el arranque ya deben existir TODOS los recursos.
    errores = ERROR_MOTOR.findall(salida)
    # Las pruebas de recuperación y de guardado provocan sus diagnósticos a
    # propósito. Son los únicos esperados en la suite, nunca en el arranque.
    if minimo is not None:
        salida = ESPERADO_EN_SUITE.sub("", salida)
        errores = ERROR_MOTOR.findall(salida)
    if not importando and errores:
        raise ValueError("Godot registró un error de motor o recurso")
    if minimo is not None:
        resumenes = RESUMEN.findall(salida)
        if len(resumenes) != 1:
            raise ValueError("Falta el resumen único de la suite")
        pasadas, fallos = map(int, resumenes[0])
        if fallos or pasadas < minimo:
            raise ValueError(f"Suite incompleta: {pasadas} pasadas, {fallos} fallos; mínimo {minimo}")


def version_admitida(declarada, actual):
    """Si un motor sirve para correr la suite.

    Se compara la LÍNEA y el canal, no la versión exacta: `.godot-version` dice
    `4.7-stable` porque el CI descarga ese build concreto, pero un 4.7.2 corre
    el proyecto igual de bien —es la misma línea que declara `project.godot`— y
    rechazarlo dejaba sin forma de correr la suite en local a cualquiera que
    tuviera un parche más nuevo. Lo que hace ruido es un motor de OTRA línea,
    que es lo que esto sigue cazando.
    """
    linea, _, canal = declarada.strip().partition("-")
    if not linea or not canal:
        raise ValueError(f".godot-version mal escrito: {declarada!r}")
    patron = rf"^{re.escape(linea)}(\.\d+)*\.{re.escape(canal)}\b"
    return re.match(patron, actual.strip()) is not None


def ejecutar():
    motor = os.environ.get("GODOT_BIN", "godot4")
    declarada = (RAIZ / ".godot-version").read_text().strip()
    actual = subprocess.run(
        [motor, "--version"], text=True, capture_output=True, check=True, timeout=15
    ).stdout.strip()
    if not version_admitida(declarada, actual):
        raise ValueError(f"Se requiere Godot de la línea {declarada}; encontrado {actual}")
    minimo = int((RAIZ / "godot/pruebas/minimo.txt").read_text())
    if minimo <= 0:
        raise ValueError("El mínimo de comprobaciones debe ser positivo")
    with tempfile.TemporaryDirectory(prefix="legado-qa-") as temporal:
        entorno = os.environ.copy()
        entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
        # Las pruebas y el arranque nunca usan la partida real de quien verifica.
        for variable, carpeta in [("XDG_DATA_HOME", "datos"),
                                  ("XDG_CONFIG_HOME", "config"),
                                  ("XDG_CACHE_HOME", "cache")]:
            entorno[variable] = str(Path(temporal) / carpeta)
        etapas = [
            ("importación", ["--editor", "--import", "--quit"], 120, None),
            ("suite", ["--script", "pruebas/pruebas.gd"], 120, minimo),
            ("recorrido", ["--script", "pruebas/recorrido.gd"], 60, 95),
            ("arranque", ["--quit-after", "90"], 30, None),
        ]
        for nombre, argumentos, limite, suelo in etapas:
            print(f"\nGodot: {nombre}", flush=True)
            resultado = subprocess.run(
                [motor, "--headless", "--language", "es", "--path", str(RAIZ / "godot"),
                 *argumentos],
                env=entorno, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, timeout=limite, check=False,
            )
            print(resultado.stdout, flush=True)
            validar(resultado.stdout, resultado.returncode, suelo, nombre == "importación")


if __name__ == "__main__":
    try:
        ejecutar()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f"Validación Godot fallida: {error}", file=sys.stderr)
        sys.exit(1)
