#!/usr/bin/env python3
"""Registra el pase humano mínimo de progresión onírica (#281).

No modifica gameplay ni infiere comprensión a partir de CI. El registro exige
una observación humana del recorrido 0/2 → 1/2 → 2/2 en export real.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CHECKS = (
    "estado_0_2_visible",
    "feedback_1_2_claro",
    "gato_reorienta",
    "reentrada_no_duplica",
    "transicion_2_2",
    "sin_salida_oculta",
    "tiempo_no_ruta_normal",
    "export_real",
    "persistencia_reapertura",
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


def preguntar_segundos() -> float:
    while True:
        valor = input("Segundos hasta identificar una primera acción válida: ").strip()
        try:
            segundos = float(valor.replace(",", "."))
        except ValueError:
            print("Introduce un número de segundos.")
            continue
        if segundos < 0:
            print("El tiempo no puede ser negativo.")
            continue
        return segundos


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    estado = {clave: bool(datos.get(clave, False)) for clave in CHECKS}
    try:
        segundos = float(datos.get("primera_accion_segundos", -1))
    except (TypeError, ValueError):
        segundos = -1
    estado["primera_accion_menos_60s"] = 0 <= segundos < 60
    estado["issue_cerrable"] = all(estado.values())
    return estado


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."
    return f"""# Registro de playtest · sueño por objetivos #281

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- mando/control: {datos['control']}
- primera acción válida: {float(datos['primera_accion_segundos']):.1f} s

## Recorrido observado

- estado 0/2 visible al entrar: {_si_no(bool(datos['estado_0_2_visible']))}
- primera acción identificada en menos de 60 s: {_si_no(gate['primera_accion_menos_60s'])}
- feedback 1/2 inequívoco: {_si_no(bool(datos['feedback_1_2_claro']))}
- gato se reorienta a contenido pendiente: {_si_no(bool(datos['gato_reorienta']))}
- reentrar en objetivo completado no duplica progreso: {_si_no(bool(datos['reentrada_no_duplica']))}
- 2/2 resuelve/transiciona automáticamente: {_si_no(bool(datos['transicion_2_2']))}
- no fue necesario localizar una salida oculta: {_si_no(bool(datos['sin_salida_oculta']))}
- el tiempo no actuó como ruta normal por defecto: {_si_no(bool(datos['tiempo_no_ruta_normal']))}
- pase realizado en export real: {_si_no(bool(datos['export_real']))}
- guardar/cerrar/reabrir conserva continuidad: {_si_no(bool(datos['persistencia_reapertura']))}
- sin incidencia reproducible bloqueante: {_si_no(bool(datos['sin_incidencia_bloqueante']))}

## Resultado

- #281 cerrable con esta evidencia: **{'SÍ' if gate['issue_cerrable'] else 'NO'}**

Este registro documenta observación humana. CI/headless no sustituye comprensión,
legibilidad, control físico ni la prueba de export real.

## Incidencia reproducible

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #281 — sueño por objetivos.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "control": preguntar("Control usado (teclado/ratón, mando físico...): "),
        "primera_accion_segundos": preguntar_segundos(),
    }
    preguntas = (
        ("estado_0_2_visible", "¿El estado 0/2 fue visible al entrar?"),
        ("feedback_1_2_claro", "¿El primer objetivo produjo feedback 1/2 claro?"),
        ("gato_reorienta", "¿El gato se reorientó hacia contenido pendiente?"),
        ("reentrada_no_duplica", "¿Reentrar en el objetivo completado evitó doble conteo?"),
        ("transicion_2_2", "¿El segundo objetivo produjo 2/2 y transición automática?"),
        ("sin_salida_oculta", "¿Se completó sin buscar una salida física oculta?"),
        ("tiempo_no_ruta_normal", "¿El tiempo no fue la ruta normal por defecto?"),
        ("export_real", "¿El pase se hizo en un export real?"),
        ("persistencia_reapertura", "¿Guardar/cerrar/reabrir mantuvo la continuidad?"),
        ("sin_incidencia_bloqueante", "¿No queda una incidencia reproducible bloqueante?"),
    )
    print("\n--- Checks ---")
    for clave, pregunta in preguntas:
        datos[clave] = preguntar_si_no(pregunta)
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Registra el pase humano mínimo de #281.")
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-281-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-281-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
