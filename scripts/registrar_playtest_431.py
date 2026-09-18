#!/usr/bin/env python3
"""Registra el playtest humano de profundidad SIGA (#431 / #286).

El script no juega, no interpreta capturas y no sustituye juicio humano.
Solo conserva respuestas del tester y calcula gates objetivos a partir de ellas.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


IMPRESIONES = {
    "lectura": "pantalla de lectura + decisión inmediata",
    "ligera": "investigación ligera pero real",
    "friccion": "demasiada fricción",
    "otra": "otra impresión",
}

CAPAS = (
    ("relacion", "relación manual entre folios"),
    ("marcador", "marcador personal"),
    ("metadatos", "comparación de metadatos"),
    ("anexo", "anexo documental"),
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


def preguntar_impresion() -> str:
    opciones = ", ".join(f"{clave}={texto}" for clave, texto in IMPRESIONES.items())
    while True:
        valor = input(f"Impresión final ({opciones}): ").strip().lower()
        if valor in IMPRESIONES:
            return valor
        print("Usa una de las claves indicadas.")


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def _capas_espontaneas(datos: dict[str, object]) -> set[str]:
    capas = datos["capas"]
    assert isinstance(capas, dict)
    return {
        clave
        for clave, _descripcion in CAPAS
        if bool(capas.get(clave)) and bool(capas.get(f"{clave}_sin_ayuda"))
    }


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    casos = datos["casos"]
    assert isinstance(casos, list)

    dos_casos_ok = len(casos) >= 2 and all(
        int(caso["folios_abiertos"]) >= 2 for caso in casos[:2]
    )
    capas_ok = len(_capas_espontaneas(datos)) >= 2

    relacion_ok = bool(datos["relacion_valida"]) and bool(
        datos["relacion_invalida_prudente"]
    ) and bool(datos["feedback_pareja_entendido"])

    persistencia_ok = all(
        bool(datos[clave])
        for clave in (
            "persisten_lecturas",
            "persisten_marcadores",
            "persisten_relaciones",
        )
    )
    careo_ok = bool(datos["contexto_careo_visible"]) and bool(
        datos["careo_no_automatizado"]
    )
    paridad_ok = bool(datos["sin_hueco_paridad_sin_issue"])
    experiencia_ok = str(datos["impresion"]) != "lectura"
    teclado_ok = bool(datos["teclado_real"])

    return {
        "dos_casos_ok": dos_casos_ok,
        "capas_ok": capas_ok,
        "relacion_ok": relacion_ok,
        "persistencia_ok": persistencia_ok,
        "careo_ok": careo_ok,
        "paridad_ok": paridad_ok,
        "experiencia_ok": experiencia_ok,
        "teclado_ok": teclado_ok,
        "listo_para_valorar_cierre": all(
            (
                dos_casos_ok,
                capas_ok,
                relacion_ok,
                persistencia_ok,
                careo_ok,
                paridad_ok,
                experiencia_ok,
                teclado_ok,
            )
        ),
    }


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    casos = datos["casos"]
    assert isinstance(casos, list)

    filas = []
    for caso in casos:
        filas.append(
            "| {nombre} | {folios} | {relectura} | {intentos} | {marcador} | "
            "{anexo} | {nota} |".format(
                nombre=caso["nombre"],
                folios=caso["folios_abiertos"],
                relectura=_si_no(bool(caso["relectura_voluntaria"])),
                intentos=caso["intentos_relacion"],
                marcador=_si_no(bool(caso["marcador_usado"])),
                anexo=_si_no(bool(caso["anexo_usado"])),
                nota=str(caso["nota"]).replace("|", "\\|") or "—",
            )
        )

    capas = datos["capas"]
    assert isinstance(capas, dict)
    lineas_capas = []
    for clave, descripcion in CAPAS:
        lineas_capas.append(
            f"- {descripcion}: usada={_si_no(bool(capas.get(clave)))}; "
            f"sin instrucciones={_si_no(bool(capas.get(f'{clave}_sin_ayuda')))}"
        )

    impresion = IMPRESIONES.get(str(datos["impresion"]), str(datos["impresion"]))
    incidencias = str(datos.get("incidencias", "")).strip() or "Ninguna anotada."
    evidencia = str(datos.get("evidencia", "")).strip() or "No indicada."
    mando = (
        f"sí ({datos['mando_modelo']})"
        if bool(datos["mando_fisico"])
        else "no"
    )

    return f"""# Registro de playtest SIGA · #431 / #286

- fecha: {datos['fecha']}
- tester/facilitador: {datos['tester']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- teclado real: {_si_no(bool(datos['teclado_real']))}
- mando físico: {mando}

## Expedientes

| Expediente | Folios abiertos | Relectura voluntaria | Intentos de relación | Marcador | Anexo | Nota |
| --- | ---: | --- | ---: | --- | --- | --- |
{chr(10).join(filas)}

## Capas usadas sin instrucciones de desarrollador

{chr(10).join(lineas_capas)}

## Relaciones y persistencia

- se encontró al menos una relación válida: {_si_no(bool(datos['relacion_valida']))}
- una pareja inválida mantuvo feedback prudente: {_si_no(bool(datos['relacion_invalida_prudente']))}
- se entendió qué dos documentos produjeron el hallazgo: {_si_no(bool(datos['feedback_pareja_entendido']))}
- lecturas persisten tras guardar/cerrar/reabrir: {_si_no(bool(datos['persisten_lecturas']))}
- marcadores persisten tras guardar/cerrar/reabrir: {_si_no(bool(datos['persisten_marcadores']))}
- relaciones/conclusiones persisten tras guardar/cerrar/reabrir: {_si_no(bool(datos['persisten_relaciones']))}

## Careo y paridad

- el contexto investigado aparece al llegar al careo: {_si_no(bool(datos['contexto_careo_visible']))}
- ese contexto no automatiza acusado, tiradas, vida, veredicto ni ganador: {_si_no(bool(datos['careo_no_automatizado']))}
- no apareció ningún hueco de paridad relevante sin issue propio: {_si_no(bool(datos['sin_hueco_paridad_sin_issue']))}

## Impresión final

**{impresion}**

## Resumen del gate

- al menos dos expedientes con varios folios: **{_estado(gate['dos_casos_ok'])}**
- al menos dos capas distintas usadas espontáneamente: **{_estado(gate['capas_ok'])}**
- relación válida + negativa prudente + feedback entendido: **{_estado(gate['relacion_ok'])}**
- persistencia de lecturas, marcadores y relaciones: **{_estado(gate['persistencia_ok'])}**
- investigación llega al careo sin automatizarlo: **{_estado(gate['careo_ok'])}**
- paridad relevante sin huecos huérfanos: **{_estado(gate['paridad_ok'])}**
- ya no se describe como lectura + decisión inmediata: **{_estado(gate['experiencia_ok'])}**
- recorrido realizado con teclado real: **{_estado(gate['teclado_ok'])}**
- listo para valorar cierre de #286: **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Este resumen deriva únicamente de respuestas introducidas durante un pase humano.
CI, capturas automáticas o este script por sí solos no validan la experiencia.

## Evidencia

{evidencia}

## Incidencias derivadas

{incidencias}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest SIGA #431/#286 — usar una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "tester": preguntar("Tester/facilitador: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA: "),
        "teclado_real": preguntar_si_no("¿Se ha probado el recorrido con teclado real?"),
        "mando_fisico": preguntar_si_no("¿Se ha probado también con mando físico?"),
    }
    datos["mando_modelo"] = (
        preguntar("Modelo de mando: ") if datos["mando_fisico"] else "no probado"
    )

    casos = []
    print("\n--- Dos expedientes mínimos ---")
    for indice in range(2):
        print(f"\nExpediente {indice + 1}")
        casos.append(
            {
                "nombre": preguntar("Nombre/ID del expediente: "),
                "folios_abiertos": preguntar_entero("Folios abiertos antes de firmar: ", 0),
                "relectura_voluntaria": preguntar_si_no(
                    "¿Se volvió voluntariamente a algún folio ya leído?"
                ),
                "intentos_relacion": preguntar_entero(
                    "Intentos de relación antes de una válida: ", 0
                ),
                "marcador_usado": preguntar_si_no("¿Se usó marcador personal?"),
                "anexo_usado": preguntar_si_no(
                    "¿Se abrió/cerró un anexo cuando el caso lo ofrecía?"
                ),
                "nota": input("Nota breve del expediente (opcional): ").strip(),
            }
        )
    datos["casos"] = casos

    print("\n--- Capas ---")
    capas: dict[str, bool] = {}
    for clave, descripcion in CAPAS:
        capas[clave] = preguntar_si_no(f"¿Se usó {descripcion}?")
        capas[f"{clave}_sin_ayuda"] = (
            preguntar_si_no("¿Se usó sin instrucciones del desarrollador?")
            if capas[clave]
            else False
        )
    datos["capas"] = capas

    print("\n--- Relaciones ---")
    datos["relacion_valida"] = preguntar_si_no(
        "¿Se encontró al menos una relación válida por lectura/comparación?"
    )
    datos["relacion_invalida_prudente"] = preguntar_si_no(
        "¿Una pareja inválida evitó afirmar que no existe relación narrativa?"
    )
    datos["feedback_pareja_entendido"] = preguntar_si_no(
        "¿Se entendió qué dos documentos produjeron el hallazgo?"
    )

    print("\n--- Persistencia ---")
    datos["persisten_lecturas"] = preguntar_si_no(
        "¿Las lecturas persistieron tras guardar/cerrar/reabrir?"
    )
    datos["persisten_marcadores"] = preguntar_si_no(
        "¿Los marcadores persistieron tras guardar/cerrar/reabrir?"
    )
    datos["persisten_relaciones"] = preguntar_si_no(
        "¿Las relaciones/conclusiones persistieron tras guardar/cerrar/reabrir?"
    )

    print("\n--- Careo y cierre ---")
    datos["contexto_careo_visible"] = preguntar_si_no(
        "¿El contexto documental investigado apareció al llegar al careo?"
    )
    datos["careo_no_automatizado"] = preguntar_si_no(
        "¿El contexto dejó intactos acusado, tiradas, vida, veredicto y ganador?"
    )
    datos["sin_hueco_paridad_sin_issue"] = preguntar_si_no(
        "¿Todo hueco de paridad relevante observado ya tiene issue propio?"
    )
    datos["impresion"] = preguntar_impresion()
    datos["evidencia"] = input(
        "Capturas/vídeo/logs o rutas de evidencia (opcional): "
    ).strip()
    datos["incidencias"] = input(
        "Issues derivados o incidencias reproducibles (opcional): "
    ).strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia del playtest humano pendiente de #431/#286."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-431-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-431-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
