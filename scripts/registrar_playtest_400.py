#!/usr/bin/env python3
"""Registra el playtest humano transversal de reactividad para #400.

No interpreta semánticamente las respuestas. Conserva texto literal y resume
sólo datos/checks explícitos introducidos por el facilitador.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


MIN_INTERACCIONES = {
    "oficina": 2,
    "calle": 2,
    "casa": 3,
    "sueno": 2,
}


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


def preguntar_entero(prompt: str, minimo: int = 0) -> int:
    while True:
        valor = input(prompt).strip()
        try:
            numero = int(valor)
        except ValueError:
            print("Introduce un número entero.")
            continue
        if numero < minimo:
            print(f"El valor mínimo es {minimo}.")
            continue
        return numero


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    build_sha = str(datos["build_sha"]).strip()
    evidencia_sha = str(datos["evidencia_sha"]).strip()
    evidencia_misma_build = bool(
        build_sha and evidencia_sha and build_sha == evidencia_sha
    )
    participante_nuevo = not bool(datos["conocimiento_previo"])
    oficina_reactiva = int(datos["interacciones_oficina"]) >= MIN_INTERACCIONES["oficina"]
    calle_reactiva = int(datos["interacciones_calle"]) >= MIN_INTERACCIONES["calle"]
    casa_reactiva = int(datos["interacciones_casa"]) >= MIN_INTERACCIONES["casa"]
    sueno_reactivo = int(datos["interacciones_sueno"]) >= MIN_INTERACCIONES["sueno"]
    feedback_inmediato = bool(datos["feedback_inmediato"])
    sin_affordances_enganosas = not bool(datos["affordances_enganosas"])
    sin_ayuda_directa = not bool(datos["ayuda_directa"])
    sin_incidencia = not bool(datos["incidencia_reproducible"])

    listo = all(
        (
            evidencia_misma_build,
            participante_nuevo,
            oficina_reactiva,
            calle_reactiva,
            casa_reactiva,
            sueno_reactivo,
            feedback_inmediato,
            sin_affordances_enganosas,
            sin_ayuda_directa,
            sin_incidencia,
        )
    )
    return {
        "evidencia_misma_build": evidencia_misma_build,
        "participante_nuevo": participante_nuevo,
        "oficina_reactiva": oficina_reactiva,
        "calle_reactiva": calle_reactiva,
        "casa_reactiva": casa_reactiva,
        "sueno_reactivo": sueno_reactivo,
        "feedback_inmediato": feedback_inmediato,
        "sin_affordances_enganosas": sin_affordances_enganosas,
        "sin_ayuda_directa": sin_ayuda_directa,
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
    observaciones = (
        str(datos.get("observaciones", "")).strip()
        or "Sin observaciones adicionales."
    )

    return f"""# Registro de playtest humano · #400

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- evidencia densidad #282 SHA: `{datos['evidencia_sha']}`
- conocimiento previo del layout/interactuables: {_si_no(bool(datos['conocimiento_previo']))}

## Respuestas literales

### Oficina / archivo

> {datos['respuesta_oficina']}

Interacciones ambientales distintas con respuesta observable: **{datos['interacciones_oficina']}**

### Calle / trayecto

> {datos['respuesta_calle']}

Respuestas contextuales distintas observadas: **{datos['interacciones_calle']}**

### Casa

> {datos['respuesta_casa']}

Microinteracciones distintas con respuesta observable: **{datos['interacciones_casa']}**

### Sueño

> {datos['respuesta_sueno']}

Respuestas ambientales/oníricas distintas observadas: **{datos['interacciones_sueno']}**

### Impresión transversal

> {datos['respuesta_general']}

## Checks del facilitador

- feedback inmediato/comprensible en las interacciones probadas: {_si_no(bool(datos['feedback_inmediato']))}
- affordances engañosas reproducibles: {_si_no(bool(datos['affordances_enganosas']))}
- hubo que señalar interactuables concretos para alcanzar los mínimos: {_si_no(bool(datos['ayuda_directa']))}
- incidencia reproducible que invalida lectura/reactividad: {_si_no(bool(datos['incidencia_reproducible']))}
- detalle: {incidencia}

## Resumen del gate

- build y evidencia #282 corresponden al mismo SHA: **{_estado(gate['evidencia_misma_build'])}**
- participante nuevo: **{_estado(gate['participante_nuevo'])}**
- oficina ≥{MIN_INTERACCIONES['oficina']} respuestas distintas: **{_estado(gate['oficina_reactiva'])}**
- calle ≥{MIN_INTERACCIONES['calle']} respuestas distintas: **{_estado(gate['calle_reactiva'])}**
- casa ≥{MIN_INTERACCIONES['casa']} respuestas distintas: **{_estado(gate['casa_reactiva'])}**
- sueño ≥{MIN_INTERACCIONES['sueno']} respuestas distintas: **{_estado(gate['sueno_reactivo'])}**
- feedback inmediato/comprensible: **{_estado(gate['feedback_inmediato'])}**
- sin affordances engañosas reproducibles: **{_estado(gate['sin_affordances_enganosas'])}**
- sin ayuda directa del facilitador: **{_estado(gate['sin_ayuda_directa'])}**
- sin incidencia reproducible invalidante: **{_estado(gate['sin_incidencia'])}**
- listo para valorar cierre de #400: **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Este resumen no interpreta las respuestas por IA: deriva únicamente de los recuentos y checks introducidos por el facilitador.

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print(
        "Playtest #400 — registrar respuestas literales sin señalar interactuables.\n"
    )
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "evidencia_sha": preguntar("SHA del artifact Evidencia densidad #282: "),
        "conocimiento_previo": preguntar_si_no(
            "¿Conocía previamente el layout o qué objetos están cableados?"
        ),
    }

    print("\n--- Respuestas del participante, antes de explicar el objetivo ---")
    datos["respuesta_oficina"] = preguntar(
        "Oficina: ¿qué cosas probaste y qué ocurrió al usarlas? "
    )
    datos["interacciones_oficina"] = preguntar_entero(
        "Número de interacciones ambientales distintas que respondieron en oficina: "
    )

    datos["respuesta_calle"] = preguntar(
        "Calle: ¿qué elementos parecían utilizables y qué ocurrió? "
    )
    datos["interacciones_calle"] = preguntar_entero(
        "Número de respuestas contextuales distintas observadas en calle: "
    )

    datos["respuesta_casa"] = preguntar(
        "Casa: ¿qué objetos usaste y qué cambios notaste? "
    )
    datos["interacciones_casa"] = preguntar_entero(
        "Número de microinteracciones distintas que respondieron en casa: "
    )

    datos["respuesta_sueno"] = preguntar(
        "Sueño: ¿qué reaccionó a tu presencia o interacción? "
    )
    datos["interacciones_sueno"] = preguntar_entero(
        "Número de respuestas ambientales/oníricas distintas observadas: "
    )
    datos["respuesta_general"] = preguntar(
        "En conjunto, ¿los escenarios parecían reaccionar a ti o funcionar como decorado? "
    )

    print("\n--- Checks del facilitador ---")
    datos["feedback_inmediato"] = preguntar_si_no(
        "¿Las interacciones probadas dieron feedback inmediato y comprensible?"
    )
    datos["affordances_enganosas"] = preguntar_si_no(
        "¿Hubo objetos relevantes que prometieran claramente interacción pero quedaran inertes?"
    )
    datos["ayuda_directa"] = preguntar_si_no(
        "¿Tuviste que señalar interactuables concretos para alcanzar los mínimos?"
    )
    datos["incidencia_reproducible"] = preguntar_si_no(
        "¿Queda una incidencia reproducible que invalide la lectura/reactividad del pase?"
    )
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia humana del gate transversal #400."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-400-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-400-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
