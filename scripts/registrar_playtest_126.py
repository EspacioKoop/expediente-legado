#!/usr/bin/env python3
"""Registra el playtest humano de lectura espacial de la oficina para #126.

No interpreta semánticamente las respuestas. Conserva texto literal y resume
solo checks explícitos marcados por el facilitador.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


def preguntar(prompt: str) -> str:
    while True:
        valor = input(prompt).strip()
        if valor:
            return valor
        print("La respuesta no puede quedar vacía.")


def preguntar_si_no(prompt: str) -> bool:
    while True:
        valor = input(f"{prompt} [s/n]: ").strip().lower()
        if valor in {"s", "si", "sí"}:
            return True
        if valor in {"n", "no"}:
            return False
        print("Responde s o n.")


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    build_sha = str(datos["build_sha"]).strip()
    gate_visual_sha = str(datos["gate_visual_sha"]).strip()
    evidencia_misma_build = bool(build_sha and gate_visual_sha and build_sha == gate_visual_sha)
    participante_nuevo = not bool(datos["conocimiento_previo"])
    lugar_reconocido = bool(datos["lugar_reconocido"])
    zonas_reconocidas = bool(datos["zonas_reconocidas"])
    salida_encontrada = bool(datos["salida_encontrada"])
    recorrido_claro = bool(datos["recorrido_claro"])
    sin_lectura_tecnica = not bool(datos["problema_sala_tecnica"])
    sin_incidencia = not bool(datos["incidencia_reproducible"])

    listo = all(
        (
            evidencia_misma_build,
            participante_nuevo,
            lugar_reconocido,
            zonas_reconocidas,
            salida_encontrada,
            recorrido_claro,
            sin_lectura_tecnica,
            sin_incidencia,
        )
    )
    return {
        "evidencia_misma_build": evidencia_misma_build,
        "participante_nuevo": participante_nuevo,
        "lugar_reconocido": lugar_reconocido,
        "zonas_reconocidas": zonas_reconocidas,
        "salida_encontrada": salida_encontrada,
        "recorrido_claro": recorrido_claro,
        "sin_lectura_tecnica": sin_lectura_tecnica,
        "sin_incidencia": sin_incidencia,
        "listo_para_valorar_cierre": listo,
    }


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest humano · #126

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- gate visual SHA: `{datos['gate_visual_sha']}`
- conocimiento previo del proyecto/layout: {_si_no(bool(datos['conocimiento_previo']))}

## Respuestas literales

**¿Qué tipo de lugar dirías que es?**

> {datos['respuesta_lugar']}

**¿Qué zonas o funciones distintas has reconocido?**

> {datos['respuesta_zonas']}

**¿Hubo algún momento en que no supieras por dónde pasar o qué era una puerta/salida?**

> {datos['respuesta_recorrido']}

**¿Algo te hizo pensar que era una sala técnica, una demo o un escenario sin uso real?**

> {datos['respuesta_tecnica']}

## Checks del facilitador

- oficina/archivo reconocido: {_si_no(bool(datos['lugar_reconocido']))}
- distingue trabajo + archivo + pausa: {_si_no(bool(datos['zonas_reconocidas']))}
- encuentra la salida sin ayuda: {_si_no(bool(datos['salida_encontrada']))}
- recorrido entre zonas sin bloqueo relevante: {_si_no(bool(datos['recorrido_claro']))}
- reaparece lectura de sala técnica/demo: {_si_no(bool(datos['problema_sala_tecnica']))}
- incidencia reproducible de navegación/lectura: {_si_no(bool(datos['incidencia_reproducible']))}
- detalle: {incidencia}

## Resumen del gate

- gate visual y build corresponden al mismo SHA: **{_estado(gate['evidencia_misma_build'])}**
- participante nuevo: **{_estado(gate['participante_nuevo'])}**
- lugar reconocido: **{_estado(gate['lugar_reconocido'])}**
- zonas funcionales reconocidas: **{_estado(gate['zonas_reconocidas'])}**
- salida encontrada: **{_estado(gate['salida_encontrada'])}**
- recorrido claro: **{_estado(gate['recorrido_claro'])}**
- sin lectura de sala técnica/demo: **{_estado(gate['sin_lectura_tecnica'])}**
- sin incidencia reproducible: **{_estado(gate['sin_incidencia'])}**
- listo para valorar cierre de #126: **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Este resumen no interpreta las respuestas por IA: deriva únicamente de los checks introducidos por el facilitador.

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #126 — registrar respuestas literales antes de explicar el espacio.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "gate_visual_sha": preguntar("SHA del artifact visual #126 revisado: "),
        "conocimiento_previo": preguntar_si_no(
            "¿Conocía previamente el proyecto o el layout de la oficina?"
        ),
    }

    print("\n--- Respuestas del participante ---")
    datos["respuesta_lugar"] = preguntar("¿Qué tipo de lugar dirías que es? ")
    datos["respuesta_zonas"] = preguntar("¿Qué zonas o funciones distintas has reconocido? ")
    datos["respuesta_recorrido"] = preguntar(
        "¿Hubo algún momento en que no supieras por dónde pasar o qué era una puerta/salida? "
    )
    datos["respuesta_tecnica"] = preguntar(
        "¿Algo te hizo pensar que era una sala técnica, una demo o un escenario sin uso real? "
    )

    print("\n--- Checks del facilitador ---")
    datos["lugar_reconocido"] = preguntar_si_no(
        "¿Reconoció espontáneamente una oficina/archivo o equivalente funcional?"
    )
    datos["zonas_reconocidas"] = preguntar_si_no(
        "¿Distinguió trabajo + archivo/almacenamiento + pausa?"
    )
    datos["salida_encontrada"] = preguntar_si_no("¿Encontró la salida sin ayuda?")
    datos["recorrido_claro"] = preguntar_si_no(
        "¿Recorrió puestos, archivo, café y salida sin bloqueo relevante?"
    )
    datos["problema_sala_tecnica"] = preguntar_si_no(
        "¿Reapareció una lectura de sala técnica/demo por un defecto reproducible?"
    )
    datos["incidencia_reproducible"] = preguntar_si_no(
        "¿Queda alguna incidencia reproducible de navegación o lectura espacial?"
    )
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia humana del gate de oficina #126."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-126-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-126-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
