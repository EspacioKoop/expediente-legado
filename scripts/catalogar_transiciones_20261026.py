#!/usr/bin/env python3
"""Catálogo generado de transiciones narrativas de expedientes SIGA-98 (#2738).

Uso: python3 scripts/catalogar_transiciones_20261026.py --root . --json catalogo.json

No es un detector de errores: eso ya lo hacen `auditar_siga98_estados`
(#2692) y el recorrido de softlocks (#2736). Esto es el INVENTARIO: qué rutas
narrativas declara cada expediente (registro → pista por frase gatillo, doble
origen, conceptos y sus enlaces) y qué variables de partida las persisten, con
la escena real que consume cada variable. Determinista y offline: solo
biblioteca estándar y solo lectura del checkout.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ENLACE = re.compile(r"\[\[([^\[\]]+)\]\]")
VARIABLE = re.compile(r"[\"']([a-z][a-z0-9_]+)[\"']")

# Variables de partida que persisten progresión de expedientes y la escena
# canónica que las consume. El catálogo comprueba que cada variable citada
# siga existiendo en partida.gd (consistencia con el esquema de guardado).
CONSUMIDORES = {
    "pistas_descubiertas": ["guion/visor_expediente.gd", "guion/careo_contexto_app.gd"],
    "sellos_obtenidos": ["guion/sellos.gd"],
    "anomalias_descubiertas": ["guion/catalogo_anomalias.gd"],
    "anomalias_descubiertas_vuelta": ["guion/catalogo_anomalias.gd"],
    "veredictos": ["guion/acusacion.gd"],
    "reconstrucciones": ["guion/reconstruccion_expediente.gd"],
    "pronosticos": ["guion/pronosticos_auditoria.gd"],
}


def within(root: Path, path: Path) -> bool:
    return path.resolve().is_relative_to(root.resolve())


def _linea_de(texto: str, needle: str) -> int:
    for numero, linea in enumerate(texto.splitlines(), 1):
        if needle in linea:
            return numero
    return 0


def catalogar(root: Path) -> dict:
    root = root.resolve()
    game = root / "godot"
    datos = game / "datos" / "casos.json"
    if not datos.is_file() or not within(root, datos):
        raise ValueError("La raíz debe contener godot/datos/casos.json")

    crudo = json.loads(datos.read_text(encoding="utf-8"))
    casos = crudo.get("casos", [])
    conceptos = crudo.get("conceptos", [])

    entradas = []
    for caso in casos:
        registros = {r["id"]: r for r in caso.get("registros", []) if "id" in r}
        sospechosos = {s["id"]: s for s in caso.get("sospechosos", []) if "id" in s}
        pistas = []
        for pista in caso.get("pistas", []):
            pistas.append(
                {
                    "id": pista.get("id", ""),
                    "origenes": [
                        o
                        for o in (pista.get("registroOrigen", ""), pista.get("registroOrigen2", ""))
                        if o
                    ],
                    "gatillo": pista.get("fraseGatillo", ""),
                }
            )
        entradas.append(
            {
                "caso": caso.get("id", ""),
                "titulo": caso.get("titulo", ""),
                "estado": caso.get("estado", ""),
                "principal": bool(caso.get("principal", False)),
                "variables": [
                    "pistas_descubiertas",
                    "veredictos",
                    "reconstrucciones",
                    "pronosticos",
                ],
                "registros": sorted(registros),
                "pistas": pistas,
                "sospechosos": sorted(sospechosos),
            }
        )

    enlaces = []
    for concepto in conceptos:
        resumen = String = concepto.get("resumen", "")
        citados = ENLACE.findall(resumen)
        nombres = {c.get("nombre", "") for c in conceptos}
        enlaces.append(
            {
                "concepto": concepto.get("id", ""),
                "nombre": concepto.get("nombre", ""),
                "enlaces": sorted(set(citados)),
                "enlaces_sin_destino": sorted(
                    {c for c in citados if c not in nombres}
                ),
            }
        )

    # Consistencia: cada variable citada del catálogo debe existir en el
    # esquema de partida y tener consumidor real en escena.
    partida = (game / "guion" / "partida.gd").read_text(encoding="utf-8")
    sin_esquema = []
    sin_consumidor = []
    for variable, consumidores in CONSUMIDORES.items():
        if f'"{variable}"' not in partida:
            sin_esquema.append(variable)
            continue
        vivos = []
        for consumidor in consumidores:
            ruta = game / consumidor
            if ruta.is_file() and within(root, ruta):
                texto = ruta.read_text(encoding="utf-8")
                if f'"{variable}"' in texto or variable in texto:
                    vivos.append(
                        {
                            "escena": consumidor,
                            "linea": _linea_de(texto, variable),
                        }
                    )
        if not vivos:
            sin_consumidor.append(variable)

    totales = {
        "casos": len(entradas),
        "pistas": sum(len(e["pistas"]) for e in entradas),
        "pistas_doble_origen": sum(
            1 for e in entradas for p in e["pistas"] if len(p["origenes"]) > 1
        ),
        "conceptos": len(enlaces),
        "enlaces": sum(len(e["enlaces"]) for e in enlaces),
    }
    return {
        "fuente": "godot/datos/casos.json",
        "totales": totales,
        "casos": entradas,
        "conceptos": enlaces,
        "variables": {
            variable: {
                "escenas": [
                    {"escena": escena, "linea": _linea_de(
                        (game / escena).read_text(encoding="utf-8"), variable
                    )}
                    for escena in escenas
                    if (game / escena).is_file()
                ]
            }
            for variable, escenas in CONSUMIDORES.items()
        },
        "consistencia": {
            "variables_sin_esquema": sorted(set(sin_esquema)),
            "variables_sin_consumidor": sorted(set(sin_consumidor)),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="raíz del checkout")
    parser.add_argument("--json", help="escribir el catálogo a este fichero")
    args = parser.parse_args()

    catalogo = catalogar(Path(args.root))
    resumen = catalogo["totales"]
    print(
        "casos={casos} pistas={pistas} doble_origen={pistas_doble_origen} "
        "conceptos={conceptos} enlaces={enlaces}".format(**resumen)
    )
    inconsistentes = catalogo["consistencia"]
    if inconsistentes["variables_sin_esquema"] or inconsistentes["variables_sin_consumidor"]:
        print("INCONSISTENTE:", json.dumps(inconsistentes, ensure_ascii=False))
    else:
        print("consistencia: variables con esquema y consumidor reales")
    if args.json:
        Path(args.json).write_text(
            json.dumps(catalogo, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
    return 1 if (inconsistentes["variables_sin_esquema"] or inconsistentes["variables_sin_consumidor"]) else 0


if __name__ == "__main__":
    raise SystemExit(main())
