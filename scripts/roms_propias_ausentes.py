#!/usr/bin/env python3
"""Lista las ROMs jugables del índice que faltan en ``godot/roms/`` (#1507).

``preparar_entorno.sh`` la usa para decidir si compila. Mirar solo si existe
algún ``.gbc`` dejaba sin compilar las ROMs que ``main`` añadía después, y la
suite fallaba mandando a ejecutar justo el script que se las saltaba.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
INDICE_REL = Path("godot/datos/roms_propias.json")


def ausentes(raiz: Path = RAIZ) -> list[str]:
    indice = json.loads((raiz / INDICE_REL).read_text(encoding="utf-8"))
    faltan = []
    for rom in indice["roms"]:
        if rom["estado"] != "jugable" or not rom["rom"].startswith("res://"):
            continue
        if not (raiz / "godot" / rom["rom"].removeprefix("res://")).is_file():
            faltan.append(rom["id"])
    return faltan


if __name__ == "__main__":
    raiz = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ
    print(" ".join(ausentes(raiz)))
