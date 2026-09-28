#!/usr/bin/env python3
"""Registra el gate visual/humano pendiente de #276.

No modifica diálogo, cámara ni HUD. Conserva observaciones del pase y exige
evidencia separada para interlocutor frontal/lateral, dos compañeros próximos
y reducción de movimiento.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CHECKS = (
    "export_real",
    "frontal_atribucion_inmediata",
    "lateral_atribucion_inmediata",
    "movimiento_durante_linea",
    "dos_companeros_sin_ambiguedad",
    "camara_restaura",
    "sin_conflicto_hud",
    "sonido_no_molesta",
    "reduccion_movimiento_correcta",
    "sin_incidencia_bloqueante",
)


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
    estado = {clave: bool(datos.get(clave, False)) for clave in CHECKS}
    estado["evidencia_frontal"] = bool(str(datos.get("evidencia_frontal", "")).strip())
    estado["evidencia_lateral"] = bool(str(datos.get("evidencia_lateral", "")).strip())
    estado["evidencia_reduccion"] = bool(str(datos.get("evidencia_reduccion", "")).strip())
    estado["issue_cerrable"] = all(estado.values())
    return estado


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."
    return f"""# Registro de playtest · diálogo diegético #276

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- control: {datos['control']}

## Evidencia

- frontal: {datos['evidencia_frontal']}
- lateral: {datos['evidencia_lateral']}
- reducción de movimiento: {datos['evidencia_reduccion']}

## Checks humanos

- pase realizado en export real: {_si_no(bool(datos['export_real']))}
- interlocutor frontal identificado de inmediato: {_si_no(bool(datos['frontal_atribucion_inmediata']))}
- interlocutor lateral identificado de inmediato: {_si_no(bool(datos['lateral_atribucion_inmediata']))}
- se puede mover durante la línea: {_si_no(bool(datos['movimiento_durante_linea']))}
- dos compañeros próximos no generan ambigüedad: {_si_no(bool(datos['dos_companeros_sin_ambiguedad']))}
- la cámara normal se restaura al terminar: {_si_no(bool(datos['camara_restaura']))}
- diálogo no compite con tutorial/prompt: {_si_no(bool(datos['sin_conflicto_hud']))}
- la señal sonora ayuda o al menos no molesta: {_si_no(bool(datos['sonido_no_molesta']))}
- reducción de movimiento elimina el tween sin perder atribución: {_si_no(bool(datos['reduccion_movimiento_correcta']))}
- sin incidencia reproducible bloqueante: {_si_no(bool(datos['sin_incidencia_bloqueante']))}

## Resultado

- evidencia frontal adjunta: **{'SÍ' if gate['evidencia_frontal'] else 'NO'}**
- evidencia lateral adjunta: **{'SÍ' if gate['evidencia_lateral'] else 'NO'}**
- evidencia reducción de movimiento adjunta: **{'SÍ' if gate['evidencia_reduccion'] else 'NO'}**
- #276 cerrable con esta evidencia: **{'SÍ' if gate['issue_cerrable'] else 'NO'}**

CI puede comprobar restauración y contratos de código, pero no si el hablante se
identifica de inmediato ni si la puesta en escena parece clara en un export real.

## Incidencia reproducible

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #276 — atribución y puesta en escena del diálogo.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma: "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "control": preguntar("Control usado (teclado/ratón, mando...): "),
        "evidencia_frontal": preguntar("Ruta/URL de evidencia con NPC frontal: "),
        "evidencia_lateral": preguntar("Ruta/URL de evidencia con NPC lateral: "),
        "evidencia_reduccion": preguntar("Ruta/URL de evidencia con reducción de movimiento: "),
    }
    preguntas = (
        ("export_real", "¿El pase se hizo en un export real?"),
        ("frontal_atribucion_inmediata", "¿Se identifica inmediatamente al hablante frontal?"),
        ("lateral_atribucion_inmediata", "¿Se identifica inmediatamente al hablante lateral?"),
        ("movimiento_durante_linea", "¿Se puede mover durante la línea sin romper la escena?"),
        ("dos_companeros_sin_ambiguedad", "¿Dos compañeros próximos siguen sin ambigüedad?"),
        ("camara_restaura", "¿La cámara normal se restaura al terminar/cerrar?"),
        ("sin_conflicto_hud", "¿El diálogo no compite con tutorial o prompt contextual?"),
        ("sonido_no_molesta", "¿La señal sonora es útil o al menos no molesta?"),
        ("reduccion_movimiento_correcta", "¿Reducción de movimiento elimina tween sin perder atribución?"),
        ("sin_incidencia_bloqueante", "¿No queda una incidencia reproducible bloqueante?"),
    )
    print("\n--- Checks ---")
    for clave, pregunta in preguntas:
        datos[clave] = preguntar_si_no(pregunta)
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Registra el gate humano de #276.")
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-276-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-276-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
