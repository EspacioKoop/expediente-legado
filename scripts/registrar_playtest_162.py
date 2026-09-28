#!/usr/bin/env python3
"""Registra el gate visual y de mando de memoria nocturna (#162).

El issue conserva aparte la semántica canónica de contradicciones. Este script
no la infiere y solo considera ese gate resuelto si se aporta una fuente
canónica versionada concreta.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CHECKS = (
    "ui_tres_huecos",
    "foco_teclado_mando",
    "seleccion_vacia_segura",
    "repeticion_visible",
    "relacion_conocida_visible",
    "selecciones_distintas_visibles",
    "recarga_determinista",
    "sin_documentos_desconocidos",
    "salida_segura",
    "sin_recompensa_mecanica",
    "mando_fisico",
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
    estado["gate_visual_mando"] = all(estado.values())
    fuente_contradicciones = str(datos.get("fuente_contradicciones", "")).strip()
    estado["contradicciones_canonicas_resueltas"] = bool(
        datos.get("contradicciones_canonicas_resueltas", False)
    ) and bool(fuente_contradicciones)
    estado["issue_completamente_cerrable"] = (
        estado["gate_visual_mando"] and estado["contradicciones_canonicas_resueltas"]
    )
    return estado


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest · memoria nocturna #162

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- mando: {datos['mando_modelo']}

## Checks visuales y de control

- UI de tres huecos comprensible: {_si_no(bool(datos['ui_tres_huecos']))}
- foco navegable con teclado y mando: {_si_no(bool(datos['foco_teclado_mando']))}
- selección vacía conserva una ruta segura/base: {_si_no(bool(datos['seleccion_vacia_segura']))}
- repetir un folio intensifica su presencia de forma visible: {_si_no(bool(datos['repeticion_visible']))}
- una relación ya descubierta produce una diferencia visible: {_si_no(bool(datos['relacion_conocida_visible']))}
- dos selecciones distintas producen alguna diferencia observable: {_si_no(bool(datos['selecciones_distintas_visibles']))}
- misma selección + misma semilla se reproduce tras recarga: {_si_no(bool(datos['recarga_determinista']))}
- no aparecen documentos desconocidos: {_si_no(bool(datos['sin_documentos_desconocidos']))}
- siempre existe salida segura: {_si_no(bool(datos['salida_segura']))}
- no concede dinero, acciones ni pistas directas: {_si_no(bool(datos['sin_recompensa_mecanica']))}
- pase realizado con mando físico real: {_si_no(bool(datos['mando_fisico']))}
- sin incidencia reproducible bloqueante: {_si_no(bool(datos['sin_incidencia_bloqueante']))}

## Resumen

{chr(10).join(f"- {clave.replace('_', ' ')}: **{_estado(gate[clave])}**" for clave in CHECKS)}

- gate visual/mando de #162: **{'CUMPLE' if gate['gate_visual_mando'] else 'PENDIENTE'}**
- semántica canónica de contradicciones: **{'RESUELTA' if gate['contradicciones_canonicas_resueltas'] else 'PENDIENTE'}**
- fuente canónica declarada: {str(datos.get('fuente_contradicciones', '')).strip() or '—'}
- #162 completamente cerrable: **{'SÍ' if gate['issue_completamente_cerrable'] else 'NO'}**

La semántica de contradicciones no se deduce de texto, colores ni similitud de
documentos. Debe existir una fuente canónica separada antes de marcarla resuelta.
Este registro tampoco sustituye un pase humano ni un mando físico.

## Incidencia reproducible

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #162 — validar UI, presentación, determinismo y mando físico.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "mando_modelo": preguntar("Modelo/nombre detectado del mando: "),
    }
    preguntas = (
        ("ui_tres_huecos", "¿La UI de tres huecos se entiende sin instrucciones externas?"),
        ("foco_teclado_mando", "¿Se navega por foco con teclado y mando?"),
        ("seleccion_vacia_segura", "¿Confirmar 0 documentos conserva una ruta segura/base?"),
        ("repeticion_visible", "¿Repetir un folio intensifica su presencia de forma visible?"),
        ("relacion_conocida_visible", "¿Una relación ya descubierta cambia visiblemente la presentación?"),
        ("selecciones_distintas_visibles", "¿Dos selecciones distintas producen al menos una diferencia observable?"),
        ("recarga_determinista", "¿Misma selección y semilla reproducen la misma configuración tras recarga?"),
        ("sin_documentos_desconocidos", "¿No aparece ningún documento que no se hubiese leído/tocado?"),
        ("salida_segura", "¿Existe salida segura en todos los casos probados?"),
        ("sin_recompensa_mecanica", "¿La memoria nocturna no concede dinero, acciones ni pistas directas?"),
        ("mando_fisico", "¿El pase se realizó con un mando físico real?"),
        ("sin_incidencia_bloqueante", "¿No queda una incidencia reproducible bloqueante?"),
    )
    print("\n--- Checks ---")
    for clave, pregunta in preguntas:
        datos[clave] = preguntar_si_no(pregunta)

    datos["contradicciones_canonicas_resueltas"] = preguntar_si_no(
        "¿Existe ya una fuente canónica versionada que declare qué pares son contradictorios?"
    )
    datos["fuente_contradicciones"] = (
        preguntar("Ruta/issue/commit de la fuente canónica: ")
        if datos["contradicciones_canonicas_resueltas"]
        else ""
    )
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra el gate visual/de mando pendiente de #162."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-162-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-162-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
