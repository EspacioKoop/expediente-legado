#!/usr/bin/env python3
"""Registra el playtest visual reproducible del gate documental #513.

El script no decide si una interpretación narrativa es correcta. Conserva checks
explícitos del facilitador y genera un Markdown trazable a una build concreta.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


FOLIOS = (
    ("F-1999-00231", "Factura"),
    ("MEMO-1999-088", "Memorándum"),
    ("EMP-0456", "Ficha de personal"),
    ("ACTA-1999-014", "Acta de Contraloría"),
)
FOLIO_IDS = frozenset(folio for folio, _tipo in FOLIOS)


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


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def _tiene_evidencia(registro: object) -> bool:
    return isinstance(registro, dict) and bool(str(registro.get("captura", "")).strip())


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    folios = datos["folios"]
    assert isinstance(folios, dict)

    conjunto_completo = set(folios) == FOLIO_IDS
    folios_ok = conjunto_completo and all(
        isinstance(folios.get(folio), dict)
        and all(
            bool(folios[folio][clave])
            for clave in (
                "cabecera_visible",
                "lectura_completa",
                "sin_recorte",
                "desplazamiento_ok",
            )
        )
        for folio, _tipo in FOLIOS
    )
    evidencias_ok = conjunto_completo and all(
        _tiene_evidencia(folios.get(folio)) for folio, _tipo in FOLIOS
    )

    gatillos_ok = bool(datos["gatillo_memo_ok"]) and bool(datos["gatillo_ficha_ok"])
    semantica_ok = bool(datos["peritaje_no_conclusion"]) and bool(
        datos["acta_no_conclusion"]
    )
    economia_ok = bool(datos["relectura_sin_coste"])
    relaciones_ok = bool(datos["relaciones_no_automaticas"])

    return {
        "folios_ok": folios_ok,
        "evidencias_ok": evidencias_ok,
        "gatillos_ok": gatillos_ok,
        "semantica_ok": semantica_ok,
        "economia_ok": economia_ok,
        "relaciones_ok": relaciones_ok,
        "listo_para_cerrar": all(
            (
                folios_ok,
                evidencias_ok,
                gatillos_ok,
                semantica_ok,
                economia_ok,
                relaciones_ok,
            )
        ),
    }


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    folios = datos["folios"]
    assert isinstance(folios, dict)

    bloques: list[str] = []
    for folio, tipo in FOLIOS:
        registro = folios[folio]
        captura = str(registro.get("captura", "")).strip() or "PENDIENTE: no indicada."
        notas = str(registro.get("notas", "")).strip() or "Sin observaciones."
        bloques.append(
            f"""### {folio} · {tipo}

- cabecera visible: {_si_no(bool(registro['cabecera_visible']))}
- lectura completa: {_si_no(bool(registro['lectura_completa']))}
- sin recorte fuera del panel: {_si_no(bool(registro['sin_recorte']))}
- desplazamiento correcto cuando procede: {_si_no(bool(registro['desplazamiento_ok']))}
- captura/evidencia: {captura}
- notas: {notas}
"""
        )

    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest visual · #513

- fecha: {datos['fecha']}
- tester/facilitador: {datos['tester']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- viewport: `1920×1080`

## Folios

{''.join(bloques)}
## Comprobaciones cruzadas

- `MEMO-1999-088`: `sin revisión previa` sigue siendo interactuable: {_si_no(bool(datos['gatillo_memo_ok']))}
- `EMP-0456`: `cuatro días después del cierre de caja` sigue siendo interactuable: {_si_no(bool(datos['gatillo_ficha_ok']))}
- el peritaje de tinta no se presenta como conclusión automática: {_si_no(bool(datos['peritaje_no_conclusion']))}
- el acta no convierte cinco minutos en prueba automática de negligencia/dolo: {_si_no(bool(datos['acta_no_conclusion']))}
- releer un folio ya leído no consume otra lectura: {_si_no(bool(datos['relectura_sin_coste']))}
- las conclusiones de dos documentos siguen requiriendo relacionarlos: {_si_no(bool(datos['relaciones_no_automaticas']))}

## Resumen del gate

- cuatro folios legibles y recorribles: **{_estado(gate['folios_ok'])}**
- evidencia visual adjunta para los cuatro folios: **{_estado(gate['evidencias_ok'])}**
- frases gatillo conservadas: **{_estado(gate['gatillos_ok'])}**
- semántica editorial no concluyente: **{_estado(gate['semantica_ok'])}**
- relectura sin coste adicional: **{_estado(gate['economia_ok'])}**
- relaciones no automáticas: **{_estado(gate['relaciones_ok'])}**
- listo para valorar cierre de #513: **{'SÍ' if gate['listo_para_cerrar'] else 'NO'}**

El resultado deriva únicamente de los checks introducidos durante el playtest; no sustituye revisión humana de narrativa ni gameplay.

## Incidencias

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest visual #513 — ejecutar a 1920×1080 sobre una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "tester": preguntar("Tester/facilitador: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA: "),
        "folios": {},
    }

    folios: dict[str, dict[str, object]] = {}
    for folio, tipo in FOLIOS:
        print(f"\n--- {folio} · {tipo} ---")
        registro: dict[str, object] = {
            "cabecera_visible": preguntar_si_no("¿Se ven folio, tipo y fecha en la cabecera?"),
            "lectura_completa": preguntar_si_no("¿Se puede leer el cuerpo completo hasta el final?"),
            "sin_recorte": preguntar_si_no("¿El texto permanece dentro del panel sin recorte?"),
            "desplazamiento_ok": preguntar_si_no(
                "¿El scroll/desplazamiento funciona correctamente cuando el cuerpo lo requiere?"
            ),
            "captura": preguntar("Captura/evidencia (ruta o URL, obligatoria): "),
            "notas": input("Notas del folio (opcional): ").strip(),
        }
        folios[folio] = registro
    datos["folios"] = folios

    print("\n--- Comprobaciones cruzadas ---")
    datos["gatillo_memo_ok"] = preguntar_si_no(
        "¿`sin revisión previa` sigue funcionando como frase gatillo?"
    )
    datos["gatillo_ficha_ok"] = preguntar_si_no(
        "¿`cuatro días después del cierre de caja` sigue funcionando como frase gatillo?"
    )
    datos["peritaje_no_conclusion"] = preguntar_si_no(
        "¿El peritaje de tinta permanece como evidencia cruzada y no como conclusión automática?"
    )
    datos["acta_no_conclusion"] = preguntar_si_no(
        "¿El intervalo de cinco minutos se presenta como indicio cuestionable y no como prueba automática?"
    )
    datos["relectura_sin_coste"] = preguntar_si_no(
        "¿Releer un folio ya leído evita consumir otra lectura?"
    )
    datos["relaciones_no_automaticas"] = preguntar_si_no(
        "¿Las conclusiones de dos folios siguen requiriendo el sistema de relación?"
    )

    print("\n--- Cierre ---")
    datos["incidencia"] = input("Incidencias reproducibles (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia del playtest visual pendiente de #513."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-513-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-513-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
