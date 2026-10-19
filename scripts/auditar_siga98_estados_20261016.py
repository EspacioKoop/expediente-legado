#!/usr/bin/env python3
"""Auditoría estática conservadora de expedientes SIGA-98 versionados.

Recorre ficheros JSON con la forma {"casos": [...], "conceptos": [...]} (el
formato de godot/datos/casos.json) y señala, con criterios puramente
textuales y sin deducir nada de código dinámico:

- estado_desconocido: el caso declara un estado fuera del catálogo conocido.
- pista_registro_ausente: registroOrigen/registroOrigen2 no resuelve con
  ningún registro del mismo caso.
- pista_gatillo_no_resuelto: la fraseGatillo no aparece, de forma literal,
  en el contenido de ninguno de sus registros de origen; con el texto
  versionado, la transición oculto→descubierta no puede producirse.
- objetivo_sin_instruccion: pista sin fraseGatillo visible para el jugador
  (severidad media: con doble origen puede ser combinable).
- concepto_pista_ausente: conceptos[].pistas[] cita un id de pista inexistente.
- enlace_sin_destino: un enlace [[nombre]] del resumen de un concepto no
  coincide con el nombre de ningún concepto del mismo fichero.
- id_duplicado: ids repetidos en el mismo ámbito, que dejan las referencias
  ambiguas.
- estructura_no_reconocida: el fichero no expone una lista "casos".

Todo offline: solo biblioteca estándar, sin red ni lecturas fuera de las
rutas indicadas. El informe JSON es determinista y enlaza cada hallazgo con
archivo y línea (exacta en JSON expandido con una clave por línea; una
ausencia de estado declarado no se marca: solo se auditan referencias
explícitas).
"""

import argparse
import json
import re
import sys
from pathlib import Path

RUTA_SCRIPT = Path(__file__).resolve()
RAIZ_REPO = RUTA_SCRIPT.parents[1]
ENTRADA_POR_DEFECTO = RAIZ_REPO / "godot" / "datos" / "casos.json"
ESTADOS_VALIDOS = ("ABIERTO", "CERRADO")

SEVERIDAD_ALTA = "alta"
SEVERIDAD_MEDIA = "media"

RE_ID = re.compile(r'^\s*"id"\s*:\s*"([^"]+)"')
RE_ESTADO = re.compile(r'^\s*"estado"\s*:\s*"([^"]+)"')
RE_ORIGEN = re.compile(r'^\s*"(registroOrigen2?)"\s*:\s*"([^"]+)"')
RE_FRASE = re.compile(r'^\s*"fraseGatillo"')
RE_CADENA_SUELTA = re.compile(r'^\s*"([^"]+)"\s*,?\s*$')
RE_ENLACE = re.compile(r"\[\[([^\[\]]+)\]\]")


def _como_lista(valor):
    return valor if isinstance(valor, list) else []


def _texto_o_nada(valor):
    return valor if isinstance(valor, str) else None


def _mapear_lineas(texto):
    """Localiza en el texto crudo las líneas que enlazan cada hallazgo.

    Registra la última clave "id" vista como dueña de las claves siguientes,
    que es como quedan emparejadas en el JSON expandido del repositorio.
    """
    mapa = {"ids": {}, "estado": [], "origen": [], "frase": [], "sueltas": []}
    dueno = None
    for numero, linea in enumerate(texto.splitlines(), start=1):
        coincidencia = RE_ID.match(linea)
        if coincidencia is not None:
            dueno = coincidencia.group(1)
            mapa["ids"].setdefault(dueno, numero)
            continue
        coincidencia = RE_ESTADO.match(linea)
        if coincidencia is not None:
            mapa["estado"].append(
                {"linea": numero, "valor": coincidencia.group(1), "dueno": dueno}
            )
            continue
        coincidencia = RE_ORIGEN.match(linea)
        if coincidencia is not None:
            mapa["origen"].append(
                {
                    "linea": numero,
                    "clave": coincidencia.group(1),
                    "valor": coincidencia.group(2),
                    "dueno": dueno,
                }
            )
            continue
        if RE_FRASE.match(linea) is not None:
            mapa["frase"].append({"linea": numero, "dueno": dueno})
            continue
        coincidencia = RE_CADENA_SUELTA.match(linea)
        if coincidencia is not None:
            mapa["sueltas"].append(
                {"linea": numero, "valor": coincidencia.group(1), "dueno": dueno}
            )
    return mapa


def _linea_de_estado(mapa, caso_id, valor):
    for ocurrencia in mapa["estado"]:
        if ocurrencia["valor"] == valor and (
            caso_id is None or ocurrencia["dueno"] == caso_id
        ):
            return ocurrencia["linea"]
    return None


def _linea_de_origen(mapa, pista_id, clave, valor):
    for ocurrencia in mapa["origen"]:
        if ocurrencia["clave"] == clave and ocurrencia["valor"] == valor and (
            pista_id is None or ocurrencia["dueno"] == pista_id
        ):
            return ocurrencia["linea"]
    return None


def _linea_de_frase(mapa, pista_id):
    if pista_id is None:
        return None
    for ocurrencia in mapa["frase"]:
        if ocurrencia["dueno"] == pista_id:
            return ocurrencia["linea"]
    return None


def _linea_de_suelta(mapa, dueno, valor):
    for ocurrencia in mapa["sueltas"]:
        if ocurrencia["valor"] == valor and (
            dueno is None or ocurrencia["dueno"] == dueno
        ):
            return ocurrencia["linea"]
    return None


def _linea_de_id(mapa, elemento):
    if elemento is None:
        return None
    return mapa["ids"].get(elemento)


def _hallazgo(tipo, severidad, archivo, linea, caso, elemento, detalle):
    return {
        "tipo": tipo,
        "severidad": severidad,
        "archivo": archivo,
        "linea": linea,
        "caso": caso,
        "elemento": elemento,
        "detalle": detalle,
    }


def _ids_repetidos(elementos):
    contador = {}
    for elemento in elementos:
        if not isinstance(elemento, dict):
            continue
        elemento_id = _texto_o_nada(elemento.get("id"))
        if elemento_id is not None:
            contador[elemento_id] = contador.get(elemento_id, 0) + 1
    return {ident: total for ident, total in contador.items() if total > 1}


def auditar_expediente(datos, archivo, mapa, estados_validos):
    """Devuelve (hallazgos, recuento) de un expediente ya parseado."""
    hallazgos = []
    casos = datos.get("casos") if isinstance(datos, dict) else None
    if not isinstance(casos, list):
        hallazgos.append(
            _hallazgo(
                "estructura_no_reconocida",
                SEVERIDAD_ALTA,
                archivo,
                None,
                None,
                None,
                "el fichero no expone una lista 'casos'",
            )
        )
        return hallazgos, {"archivo": archivo}

    conceptos = _como_lista(datos.get("conceptos"))
    nombres_concepto = {
        concepto["nombre"]
        for concepto in conceptos
        if isinstance(concepto, dict) and isinstance(concepto.get("nombre"), str)
    }
    ids_pista_versionadas = set()

    total_registros = 0
    total_pistas = 0
    total_sospechosos = 0

    for caso in casos:
        if not isinstance(caso, dict):
            hallazgos.append(
                _hallazgo(
                    "estructura_no_reconocida",
                    SEVERIDAD_ALTA,
                    archivo,
                    None,
                    None,
                    None,
                    "un elemento de 'casos' no es un objeto",
                )
            )
            continue
        caso_id = _texto_o_nada(caso.get("id"))
        registros = _como_lista(caso.get("registros"))
        pistas = _como_lista(caso.get("pistas"))
        sospechosos = _como_lista(caso.get("sospechosos"))
        total_registros += len(registros)
        total_pistas += len(pistas)
        total_sospechosos += len(sospechosos)

        for ambito, elementos in (
            ("registros", registros),
            ("pistas", pistas),
            ("sospechosos", sospechosos),
        ):
            for elemento_id, total in sorted(_ids_repetidos(elementos).items()):
                hallazgos.append(
                    _hallazgo(
                        "id_duplicado",
                        SEVERIDAD_ALTA,
                        archivo,
                        _linea_de_id(mapa, elemento_id),
                        caso_id,
                        elemento_id,
                        "id repetido %d veces entre los %s del caso" % (total, ambito),
                    )
                )

        contenidos_por_id = {}
        for registro in registros:
            if not isinstance(registro, dict):
                continue
            registro_id = _texto_o_nada(registro.get("id"))
            if registro_id is not None:
                contenidos_por_id.setdefault(registro_id, []).append(
                    registro.get("contenido")
                )

        estado = _texto_o_nada(caso.get("estado"))
        if estado is not None and estado not in estados_validos:
            hallazgos.append(
                _hallazgo(
                    "estado_desconocido",
                    SEVERIDAD_ALTA,
                    archivo,
                    _linea_de_estado(mapa, caso_id, estado)
                    or _linea_de_id(mapa, caso_id),
                    caso_id,
                    estado,
                    "estado '%s' fuera del catálogo %s" % (estado, list(estados_validos)),
                )
            )

        for pista in pistas:
            if not isinstance(pista, dict):
                continue
            pista_id = _texto_o_nada(pista.get("id"))
            if pista_id is not None:
                ids_pista_versionadas.add(pista_id)
            origenes = []
            for clave in ("registroOrigen", "registroOrigen2"):
                destino = _texto_o_nada(pista.get(clave))
                if destino is None:
                    continue
                origenes.append(destino)
                if destino in contenidos_por_id:
                    continue
                hallazgos.append(
                    _hallazgo(
                        "pista_registro_ausente",
                        SEVERIDAD_ALTA,
                        archivo,
                        _linea_de_origen(mapa, pista_id, clave, destino)
                        or _linea_de_id(mapa, pista_id),
                        caso_id,
                        pista_id,
                        "%s '%s' no resuelve con ningún registro del caso"
                        % (clave, destino),
                    )
                )

            frase = _texto_o_nada(pista.get("fraseGatillo"))
            if frase is not None and frase.strip():
                contenidos = [
                    contenido
                    for destino in origenes
                    for contenido in contenidos_por_id.get(destino, [])
                    if isinstance(contenido, str)
                ]
                if not any(frase in contenido for contenido in contenidos):
                    fragmento = frase if len(frase) <= 60 else frase[:57] + "..."
                    detalle = (
                        "fraseGatillo «%s» sin coincidencia literal en el contenido "
                        "de sus registros de origen" % fragmento
                    )
                    if not origenes:
                        detalle += " (sin registroOrigen declarado)"
                    hallazgos.append(
                        _hallazgo(
                            "pista_gatillo_no_resuelto",
                            SEVERIDAD_ALTA,
                            archivo,
                            _linea_de_frase(mapa, pista_id)
                            or _linea_de_id(mapa, pista_id),
                            caso_id,
                            pista_id,
                            detalle,
                        )
                    )
            elif pista_id is not None:
                detalle = "pista sin fraseGatillo visible para el jugador"
                if len(origenes) > 1:
                    detalle += " (doble origen; puede ser combinable)"
                hallazgos.append(
                    _hallazgo(
                        "objetivo_sin_instruccion",
                        SEVERIDAD_MEDIA,
                        archivo,
                        _linea_de_id(mapa, pista_id),
                        caso_id,
                        pista_id,
                        detalle,
                    )
                )

    recuento = {
        "archivo": archivo,
        "casos": len(casos),
        "registros": total_registros,
        "pistas": total_pistas,
        "sospechosos": total_sospechosos,
        "conceptos": len(conceptos),
    }

    for elemento_id, total in sorted(_ids_repetidos(conceptos).items()):
        hallazgos.append(
            _hallazgo(
                "id_duplicado",
                SEVERIDAD_ALTA,
                archivo,
                _linea_de_id(mapa, elemento_id),
                None,
                elemento_id,
                "id repetido %d veces entre los conceptos del fichero" % total,
            )
        )

    for concepto in conceptos:
        if not isinstance(concepto, dict):
            continue
        concepto_id = _texto_o_nada(concepto.get("id"))
        for referencia in _como_lista(concepto.get("pistas")):
            if not isinstance(referencia, str) or referencia in ids_pista_versionadas:
                continue
            hallazgos.append(
                _hallazgo(
                    "concepto_pista_ausente",
                    SEVERIDAD_ALTA,
                    archivo,
                    _linea_de_suelta(mapa, concepto_id, referencia)
                    or _linea_de_id(mapa, concepto_id),
                    None,
                    concepto_id,
                    "la referencia a la pista '%s' no resuelve con ninguna pista "
                    "del fichero" % referencia,
                )
            )
        resumen = _texto_o_nada(concepto.get("resumen"))
        if resumen is None:
            continue
        for destino_bruto in RE_ENLACE.findall(resumen):
            destino = destino_bruto.strip()
            if destino in nombres_concepto:
                continue
            hallazgos.append(
                _hallazgo(
                    "enlace_sin_destino",
                    SEVERIDAD_ALTA,
                    archivo,
                    _linea_de_id(mapa, concepto_id),
                    None,
                    concepto_id,
                    "el enlace [[%s]] no coincide con el nombre de ningún "
                    "concepto" % destino,
                )
            )

    return hallazgos, recuento


def auditar(rutas, estados_validos=ESTADOS_VALIDOS):
    """Produce el informe completo; solo lee las rutas indicadas."""
    ficheros = []
    hallazgos = []
    for ruta in rutas:
        texto = Path(ruta).read_text(encoding="utf-8")
        datos = json.loads(texto)
        mapa = _mapear_lineas(texto)
        hallazgos_fichero, recuento = auditar_expediente(
            datos, str(ruta), mapa, estados_validos
        )
        recuento["hallazgos"] = len(hallazgos_fichero)
        ficheros.append(recuento)
        hallazgos.extend(hallazgos_fichero)
    hallazgos.sort(
        key=lambda hallazgo: (
            hallazgo["archivo"],
            hallazgo["linea"] is None,
            hallazgo["linea"] or 0,
            hallazgo["tipo"],
            hallazgo["elemento"] or "",
            hallazgo["caso"] or "",
            hallazgo["detalle"],
        )
    )
    por_severidad = {}
    por_tipo = {}
    for hallazgo in hallazgos:
        por_severidad[hallazgo["severidad"]] = (
            por_severidad.get(hallazgo["severidad"], 0) + 1
        )
        por_tipo[hallazgo["tipo"]] = por_tipo.get(hallazgo["tipo"], 0) + 1
    return {
        "esquema": 1,
        "auditor": RUTA_SCRIPT.name,
        "parametros": {
            "entradas": [str(ruta) for ruta in rutas],
            "estados_validos": list(estados_validos),
        },
        "ficheros": ficheros,
        "hallazgos": hallazgos,
        "resumen": {
            "total": len(hallazgos),
            "por_severidad": por_severidad,
            "por_tipo": por_tipo,
        },
    }


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Auditoría estática conservadora de expedientes SIGA-98 "
        "versionados."
    )
    parser.add_argument(
        "--entrada",
        nargs="+",
        default=[str(ENTRADA_POR_DEFECTO)],
        help="ficheros JSON de expedientes a auditar "
        "(por omisión: godot/datos/casos.json)",
    )
    parser.add_argument(
        "--salida",
        default=None,
        help="escribe el informe JSON en este fichero en lugar de stdout",
    )
    parser.add_argument(
        "--estados",
        nargs="+",
        default=list(ESTADOS_VALIDOS),
        help="catálogo de estados de caso admitidos",
    )
    parser.add_argument(
        "--estricto",
        action="store_true",
        help="termina con código 1 si el informe contiene algún hallazgo",
    )
    argumentos = parser.parse_args(argv)
    try:
        informe = auditar(
            [Path(ruta) for ruta in argumentos.entrada], tuple(argumentos.estados)
        )
    except (OSError, ValueError) as error:
        print("error: %s" % error, file=sys.stderr)
        return 2
    texto = json.dumps(informe, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if argumentos.salida:
        Path(argumentos.salida).write_text(texto, encoding="utf-8")
    else:
        sys.stdout.write(texto)
    if argumentos.estricto and informe["resumen"]["total"] > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
