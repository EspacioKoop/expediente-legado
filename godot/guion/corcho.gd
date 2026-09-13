## Estado del corcho físico de conceptos (#101).
##
## El grafo lógico sigue viviendo en los conceptos y sus referencias [[...]].
## Este módulo guarda únicamente la interpretación manual del jugador: qué
## fichas han llegado a su tablón y qué pares decidió unir con hilo.
class_name Corcho
extends RefCounted

const CLAVE := "corcho"


static func estado(jornada: Dictionary) -> Dictionary:
	if typeof(jornada.get(CLAVE)) != TYPE_DICTIONARY:
		jornada[CLAVE] = {"fichas": {}, "enlaces": []}
	var tablero: Dictionary = jornada[CLAVE]
	if typeof(tablero.get("fichas")) != TYPE_DICTIONARY:
		tablero["fichas"] = {}
	if typeof(tablero.get("enlaces")) != TYPE_ARRAY:
		tablero["enlaces"] = []
	return tablero


## Incorpora los conceptos ya descubiertos sin fabricar relaciones. La posición
## inicial es determinista para que una ficha nueva no salte al recargar.
static func sincronizar(jornada: Dictionary, conceptos: Array) -> bool:
	var tablero := estado(jornada)
	var fichas: Dictionary = tablero["fichas"]
	var cambio := false
	for concepto in conceptos:
		var id := String(concepto.get("id", ""))
		if id.is_empty() or fichas.has(id):
			continue
		var indice := fichas.size()
		var columna := indice % 4
		var fila := indice / 4
		fichas[id] = {
			"pos": [float(columna) * 0.82 - 1.23, 0.55 - float(fila) * 0.58]
		}
		cambio = true
	return cambio


## Dos pulsaciones sobre fichas alternan el hilo entre ellas. El orden no crea
## enlaces distintos y nunca se acepta una ficha que no esté físicamente allí.
static func alternar_enlace(jornada: Dictionary, a: String, b: String) -> bool:
	var tablero := estado(jornada)
	var fichas: Dictionary = tablero["fichas"]
	if a == b or not fichas.has(a) or not fichas.has(b):
		return false
	var par := [a, b]
	par.sort()
	var enlaces: Array = tablero["enlaces"]
	for indice in range(enlaces.size()):
		if enlaces[indice] == par:
			enlaces.remove_at(indice)
			return true
	enlaces.append(par)
	return true


## El conocimiento del expediente puede sobrevivir; el montaje doméstico no.
static func perder_casa(jornada: Dictionary) -> void:
	jornada[CLAVE] = {"fichas": {}, "enlaces": []}
