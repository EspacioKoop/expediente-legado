## Estado del corcho físico de conceptos (#101).
##
## El grafo lógico sigue viviendo en los conceptos y sus referencias [[...]].
## Este módulo guarda únicamente la interpretación manual del jugador: qué
## fichas han llegado a su tablón y qué pares decidió unir con hilo.
class_name Corcho
extends RefCounted

const CLAVE := "corcho"
const COLUMNAS_INICIALES := 5
const PASO_INICIAL := Vector2(0.48, 0.32)
const ORIGEN_INICIAL := Vector2(-0.96, 0.48)


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
		var columna := indice % COLUMNAS_INICIALES
		var fila := int(indice / COLUMNAS_INICIALES)
		fichas[id] = {
			"pos":
			[
				ORIGEN_INICIAL.x + float(columna) * PASO_INICIAL.x,
				ORIGEN_INICIAL.y - float(fila) * PASO_INICIAL.y,
			]
		}
		cambio = true
	return cambio


## Sanea posiciones persistidas contra el área útil que le entrega la vista 3D.
## No reordena la interpretación del jugador: solo impide que una ficha quede
## físicamente fuera del tablón por datos antiguos o por crecimiento del grafo.
static func limitar_posiciones(jornada: Dictionary, limite: Vector2) -> bool:
	var tablero := estado(jornada)
	var fichas: Dictionary = tablero["fichas"]
	var max_x := maxf(0.0, limite.x)
	var max_y := maxf(0.0, limite.y)
	var cambio := false

	for id in fichas.keys():
		var datos_invalidos := typeof(fichas[id]) != TYPE_DICTIONARY
		var datos: Dictionary = {}
		if not datos_invalidos:
			datos = fichas[id]
		var pos = datos.get("pos", [0.0, 0.0])
		var x := 0.0
		var y := 0.0
		if typeof(pos) == TYPE_ARRAY and pos.size() >= 2:
			x = float(pos[0])
			y = float(pos[1])
		var nueva_x := clampf(x, -max_x, max_x)
		var nueva_y := clampf(y, -max_y, max_y)
		var pos_invalida := typeof(pos) != TYPE_ARRAY or pos.size() < 2
		if (
			datos_invalidos
			or pos_invalida
			or not is_equal_approx(x, nueva_x)
			or not is_equal_approx(y, nueva_y)
		):
			datos["pos"] = [nueva_x, nueva_y]
			fichas[id] = datos
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
