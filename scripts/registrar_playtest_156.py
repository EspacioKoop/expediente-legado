#!/usr/bin/env python3
"""Registra el pase humano pendiente de la ronda de cierre (#156)."""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CHECKS = (
    "oferta_comprensible",
    "puntos_fisicos_claros",
    "recorrido_completo",
    "progreso_visible",
    "abandono_seguro",
    "jornada_continua",
    "rehidratacion_correcta",
    "opt_out_funciona",
    "mando_fisico",
    "foco_mando",
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
    estado["listo_para_valorar_cierre"] = all(estado.values())
    return estado


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest humano · ronda de cierre #156

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- mando: {datos['mando_modelo']}

## Checks

- la oferta de ronda se entiende y se percibe como opcional: {_si_no(bool(datos['oferta_comprensible']))}
- los puntos físicos se reconocen sin marcadores permanentes: {_si_no(bool(datos['puntos_fisicos_claros']))}
- una ronda completa puede terminarse: {_si_no(bool(datos['recorrido_completo']))}
- el progreso de 3–5 puntos resulta comprensible: {_si_no(bool(datos['progreso_visible']))}
- abandonar a mitad es seguro y comprensible: {_si_no(bool(datos['abandono_seguro']))}
- abandonar no bloquea archivo → trayecto: {_si_no(bool(datos['jornada_continua']))}
- guardar/recargar conserva el progreso sin duplicarlo: {_si_no(bool(datos['rehidratacion_correcta']))}
- desactivar nuevas ofertas funciona sin borrar una ronda iniciada: {_si_no(bool(datos['opt_out_funciona']))}
- pase realizado con mando físico real: {_si_no(bool(datos['mando_fisico']))}
- foco/interacción/salida funcionan con mando: {_si_no(bool(datos['foco_mando']))}
- sin incidencia reproducible bloqueante: {_si_no(bool(datos['sin_incidencia_bloqueante']))}

## Resumen

{chr(10).join(f"- {clave.replace('_', ' ')}: **{_estado(gate[clave])}**" for clave in CHECKS)}

- listo para valorar cierre de #156: **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

El script conserva respuestas humanas; no simula comprensión, gamefeel ni un mando físico.

## Incidencia reproducible

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #156 — ronda de cierre en una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "mando_modelo": preguntar("Modelo/nombre detectado del mando: "),
    }
    preguntas = (
        ("oferta_comprensible", "¿La oferta se entiende y queda claro que es opcional?"),
        ("puntos_fisicos_claros", "¿Los puntos físicos se reconocen sin marcadores permanentes?"),
        ("recorrido_completo", "¿Se pudo completar una ronda de principio a fin?"),
        ("progreso_visible", "¿El progreso de la ruta resulta comprensible?"),
        ("abandono_seguro", "¿Se pudo abandonar a mitad sin confusión ni bloqueo?"),
        ("jornada_continua", "¿Tras abandonar la jornada continuó al trayecto?"),
        ("rehidratacion_correcta", "¿Guardar/recargar conservó el progreso sin duplicarlo?"),
        ("opt_out_funciona", "¿Desactivar nuevas ofertas respetó una ronda ya iniciada?"),
        ("mando_fisico", "¿El pase se realizó con un mando físico real?"),
        ("foco_mando", "¿Foco, interacción y salida funcionaron solo con mando?"),
        ("sin_incidencia_bloqueante", "¿No queda una incidencia reproducible bloqueante?"),
    )
    for clave, pregunta in preguntas:
        datos[clave] = preguntar_si_no(pregunta)
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia del pase humano pendiente de #156."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-156-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-156-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
