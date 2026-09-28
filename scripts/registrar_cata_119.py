#!/usr/bin/env python3
"""Registra la cata auditiva humana pendiente de #119.

El artifact de #1026 prepara las fuentes y métricas. Este script conserva la
decisión humana por fuente sin asumir que CI pueda evaluar calidad auditiva.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


FUENTES = (
    ("fluorescente_archivo", "Fluorescente / archivo"),
    ("teclado_oficina", "Teclado de oficina"),
    ("calle_nocturna", "Calle nocturna"),
    ("sueno_onirico", "Sueño / onírico"),
)
DECISIONES = {"promover", "iterar", "descartar"}


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


def preguntar_decision(nombre: str) -> str:
    while True:
        valor = input(
            f"{nombre} — decisión [promover/iterar/descartar]: "
        ).strip().lower()
        if valor in DECISIONES:
            return valor
        print("Usa promover, iterar o descartar.")


def evaluar_fuente(datos: dict[str, object]) -> dict[str, object]:
    decision = str(datos.get("decision", "")).strip().lower()
    decision_valida = decision in DECISIONES
    checks = all(
        bool(datos.get(clave, False))
        for clave in ("nivel_adecuado", "loop_limpio", "fatiga_aceptable", "legibilidad")
    )
    promover_listo = decision == "promover" and checks
    requiere_iteracion = decision == "iterar" or (decision == "promover" and not checks)
    return {
        "decision_valida": decision_valida,
        "promover_listo": promover_listo,
        "requiere_iteracion": requiere_iteracion,
        "descartada": decision == "descartar",
    }


def evaluar_cata(datos: dict[str, object]) -> dict[str, object]:
    fuentes = datos.get("fuentes", {})
    resultados = {
        clave: evaluar_fuente(dict(fuentes.get(clave, {})))
        for clave, _ in FUENTES
    }
    completa = all(resultado["decision_valida"] for resultado in resultados.values())
    promover = [
        clave for clave, resultado in resultados.items() if resultado["promover_listo"]
    ]
    iterar = [
        clave for clave, resultado in resultados.items() if resultado["requiere_iteracion"]
    ]
    descartar = [
        clave for clave, resultado in resultados.items() if resultado["descartada"]
    ]
    return {
        "cata_completa": completa,
        "promover": promover,
        "iterar": iterar,
        "descartar": descartar,
        "resultados": resultados,
    }


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def render_markdown(datos: dict[str, object]) -> str:
    evaluacion = evaluar_cata(datos)
    lineas = [
        "# Registro de cata auditiva · ambiente #119",
        "",
        f"- fecha: {datos['fecha']}",
        f"- participante: {datos['participante']}",
        f"- plataforma/sistema de escucha: {datos['plataforma']}",
        f"- artifact/run: {datos['artifact']}",
        f"- build/ref: `{datos['build_ref']}`",
        "",
        "## Decisiones por fuente",
        "",
    ]
    fuentes = dict(datos["fuentes"])
    for clave, nombre in FUENTES:
        fuente = dict(fuentes[clave])
        resultado = evaluacion["resultados"][clave]
        lineas.extend(
            [
                f"### {nombre}",
                "",
                f"- decisión: **{fuente['decision']}**",
                f"- nivel relativo adecuado: {_si_no(bool(fuente['nivel_adecuado']))}",
                f"- loop/transición limpia: {_si_no(bool(fuente['loop_limpio']))}",
                f"- fatiga aceptable: {_si_no(bool(fuente['fatiga_aceptable']))}",
                f"- deja legibles efectos/diálogo: {_si_no(bool(fuente['legibilidad']))}",
                f"- lista para promover: {_si_no(bool(resultado['promover_listo']))}",
                f"- observación: {fuente.get('observacion', '') or '—'}",
                "",
            ]
        )
    lineas.extend(
        [
            "## Resumen accionable",
            "",
            f"- cata completa: **{'SÍ' if evaluacion['cata_completa'] else 'NO'}**",
            f"- promover: {', '.join(evaluacion['promover']) or 'ninguna'}",
            f"- iterar: {', '.join(evaluacion['iterar']) or 'ninguna'}",
            f"- descartar: {', '.join(evaluacion['descartar']) or 'ninguna'}",
            "",
            "Una fuente marcada «promover» solo pasa a esa lista si nivel, loop, fatiga y "
            "legibilidad fueron validados. La promoción a runtime, procedencia/hash y la "
            "escucha del recorrido completo siguen siendo un corte posterior.",
            "",
            "CI no sustituye esta escucha humana.",
            "",
        ]
    )
    return "\n".join(lineas)


def recoger_datos() -> dict[str, object]:
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del oyente: "),
        "plataforma": preguntar("Plataforma / auriculares-altavoces: "),
        "artifact": preguntar("Artifact o run de Cata ambientes 119: "),
        "build_ref": preguntar("SHA/ref del artifact: "),
        "fuentes": {},
    }
    for clave, nombre in FUENTES:
        print(f"\n--- {nombre} ---")
        decision = preguntar_decision(nombre)
        datos["fuentes"][clave] = {
            "decision": decision,
            "nivel_adecuado": preguntar_si_no("¿El nivel relativo es adecuado?"),
            "loop_limpio": preguntar_si_no("¿El loop/transición es limpia?"),
            "fatiga_aceptable": preguntar_si_no("¿La fatiga tras escucha repetida es aceptable?"),
            "legibilidad": preguntar_si_no("¿Deja legibles efectos y diálogo?"),
            "observacion": input("Observación (opcional): ").strip(),
        }
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Registra la cata humana de #119.")
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: cata-119-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"cata-119-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
