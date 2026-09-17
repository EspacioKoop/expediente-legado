#!/usr/bin/env python3
"""Valida las fuentes procedurales originales de ambiente de #119."""
from __future__ import annotations

import importlib.util
import json
import math
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
ORIGEN = RAIZ / "referencia" / "audio" / "ambientes_originales"
GENERADOR = RAIZ / "scripts" / "generar_ambientes_originales.py"
ESPERADOS = {"fluorescente", "teclado_oficina", "calle_noche", "sueno"}


def cargar_generador():
    spec = importlib.util.spec_from_file_location("ambientes", GENERADOR)
    modulo = importlib.util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(modulo)
    return modulo


def main() -> None:
    specs = [json.loads(p.read_text(encoding="utf-8")) for p in sorted(ORIGEN.glob("*.json"))]
    assert {s["id"] for s in specs} == ESPERADOS
    assert len({s["semilla"] for s in specs}) == 4
    assert all(s["salida"].endswith("_original.ogg") for s in specs)
    assert all(0.5 <= float(s["duracion"]) <= 30.0 for s in specs)
    assert all(4000 <= int(s["muestras_por_segundo"]) <= 48000 for s in specs)

    g = cargar_generador()
    for cfg in specs:
        a = g.SINTESIS[cfg["tipo"]](cfg)
        b = g.SINTESIS[cfg["tipo"]](cfg)
        esperado = int(cfg["muestras_por_segundo"] * cfg["duracion"])
        assert len(a) == esperado
        assert a == b, f"{cfg['id']}: síntesis no determinista"
        assert all(math.isfinite(x) for x in a)
        assert max(abs(x) for x in a) <= 1.0

    print("OK: 4 fuentes de ambiente originales, deterministas y renderizables")


if __name__ == "__main__":
    main()
