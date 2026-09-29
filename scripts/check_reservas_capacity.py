#!/usr/bin/env python3
"""Avisa antes de que el registro activo de reservas agote sus comentarios."""

from __future__ import annotations

import os
from pathlib import Path

try:
    from . import gestionar_reservas_rollover as rollover
except ImportError:  # ejecución directa desde el workflow
    import gestionar_reservas_rollover as rollover


AVISO = 2000
URGENTE = 2300
LIMITE_OBSERVADO = 2500


def mensaje(numero: int, total: int) -> str:
    if total < 0:
        raise ValueError("el contador de comentarios no puede ser negativo")
    if total >= URGENTE:
        nivel = "URGENTE"
    elif total >= AVISO:
        nivel = "ROTAR"
    else:
        nivel = "OK"
    return f"{nivel}: registro #{numero} con {total}/{LIMITE_OBSERVADO} comentarios"


def comprobar() -> tuple[int, int]:
    activo, _ = rollover.cargar_config()
    if not rollover.base.REPO:
        raise RuntimeError("GITHUB_REPOSITORY es obligatorio")
    payload, _ = rollover.base.api_json(
        "GET", f"/repos/{rollover.base.REPO}/issues/{activo}"
    )
    if not isinstance(payload, dict) or type(payload.get("comments")) is not int:
        raise ValueError("GitHub no devolvió un contador de comentarios válido")
    total = payload["comments"]
    if total < 0:
        raise ValueError("GitHub devolvió un contador de comentarios negativo")
    return activo, total


def main() -> int:
    try:
        activo, total = comprobar()
    except (RuntimeError, ValueError, OSError):
        # La vigilancia nunca impide liberar reservas en el mismo job.
        print("::warning::No se pudo comprobar la capacidad del registro activo")
        return 0

    estado = mensaje(activo, total)
    print(estado)
    if total >= AVISO:
        print(
            f"::warning::Registro de reservas #{activo} cerca del límite: "
            f"{total}/{LIMITE_OBSERVADO}. Rotar según docs/agents/reservas-rotacion.md"
        )
    resumen = os.environ.get("GITHUB_STEP_SUMMARY")
    if resumen:
        try:
            with Path(resumen).open("a", encoding="utf-8") as salida:
                salida.write(
                    f"- {estado}. [Procedimiento](https://github.com/"
                    "EspacioKoop/expediente-legado/blob/main/docs/agents/reservas-rotacion.md).\n"
                )
        except OSError:
            print("::warning::No se pudo escribir el resumen de capacidad")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
