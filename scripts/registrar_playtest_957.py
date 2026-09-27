#!/usr/bin/env python3
"""Registra el playtest humano de marcadores diegéticos (#957).

El script no juega, no analiza capturas y no sustituye juicio humano. Conserva
respuestas del tester y calcula únicamente si los criterios declarados del gate
quedan cubiertos.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CRITERIOS = (
    ("dos_zonas", "se probaron al menos dos zonas"),
    ("suelo_y_pared", "se probaron marcas sobre suelo y pared"),
    ("tipos_por_forma", "los tipos se distinguen sin depender solo del color"),
    ("texto_local", "el texto se lee cerca sin dominar la sala"),
    ("densidad_legible", "cinco marcas siguen siendo visualmente manejables"),
    ("limite_correcto", "la sexta marca se rechaza al alcanzar el límite"),
    ("borrado_correcto", "borrar una marca no deja residuo interactivo"),
    ("limpieza_aislada", "limpiar una zona no borra las demás"),
    ("persistencia_real", "guardar/cerrar/reabrir conserva las marcas"),
    ("sin_colisiones", "las marcas no bloquean ni alteran navegación"),
    ("opcional", "ignorar los marcadores no bloquea progresión"),
    ("estres_legible", "el estrés no vuelve irreconocibles las marcas"),
    ("sin_tapar_critico", "ninguna marca tapa información crítica"),
    ("estetica_coherente", "el conjunto encaja con el tratamiento visual del juego"),
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


def preguntar_entero(prompt: str, minimo: int = 0) -> int:
    while True:
        valor = input(prompt).strip()
        try:
            numero = int(valor)
        except ValueError:
            print("Introduce un número entero.")
            continue
        if numero >= minimo:
            return numero
        print(f"El valor mínimo es {minimo}.")


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    zonas = int(datos["zonas_probadas"])
    criterios = datos["criterios"]
    assert isinstance(criterios, dict)

    resultados = {
        clave: bool(criterios.get(clave))
        for clave, _descripcion in CRITERIOS
    }
    resultados["dos_zonas"] = zonas >= 2 and resultados["dos_zonas"]
    resultados["zonas_identificadas"] = bool(str(datos.get("zonas", "")).strip())
    resultados["evidencia_trazable"] = bool(str(datos.get("evidencia", "")).strip())
    resultados["listo_para_valorar_cierre"] = all(resultados.values())
    return resultados


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    criterios = datos["criterios"]
    assert isinstance(criterios, dict)

    filas = []
    for clave, descripcion in CRITERIOS:
        filas.append(
            f"| {descripcion} | {_si_no(bool(criterios.get(clave)))} | "
            f"**{_estado(gate[clave])}** |"
        )

    evidencia = str(datos.get("evidencia", "")).strip() or "No indicada."
    incidencias = str(datos.get("incidencias", "")).strip() or "Ninguna anotada."
    zonas = str(datos.get("zonas", "")).strip() or "No detalladas."

    return f"""# Registro de playtest · marcadores en mundo #957

- fecha: {datos['fecha']}
- tester/facilitador: {datos['tester']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- zonas probadas: {datos['zonas_probadas']}
- zonas/recorrido: {zonas}

## Gate humano

| Criterio | Respuesta humana | Estado |
| --- | --- | --- |
{chr(10).join(filas)}

## Resultado

- listo para valorar cierre de #957: **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Este resultado deriva únicamente de respuestas introducidas durante un pase
humano. CI, capturas automáticas o este script por sí solos no validan la
experiencia ni la coherencia estética.

## Evidencia

{evidencia}

## Incidencias derivadas

{incidencias}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest de marcadores #957 — usar una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "tester": preguntar("Tester/facilitador: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA: "),
        "zonas_probadas": preguntar_entero("Número de zonas probadas: ", 0),
        "zonas": preguntar("Zonas/recorrido: "),
    }

    print("\n--- Criterios ---")
    criterios: dict[str, bool] = {}
    for clave, descripcion in CRITERIOS:
        criterios[clave] = preguntar_si_no(f"¿{descripcion.capitalize()}?")
    datos["criterios"] = criterios

    datos["evidencia"] = preguntar(
        "Capturas/vídeo/logs o rutas de evidencia: "
    )
    datos["incidencias"] = input(
        "Issues derivados o incidencias reproducibles (opcional): "
    ).strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia del playtest humano pendiente de #957."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-957-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-957-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
