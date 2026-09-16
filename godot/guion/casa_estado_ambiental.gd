## Contrato ambiental puro para #96.
##
## La casa no mantiene una segunda estadística estética. Este módulo traduce
## hechos que ya existen en el guardado a señales discretas que una escena puede
## materializar más tarde: qué objetos siguen realmente en casa, cómo está el
## gato, qué rutinas domésticas quedaron físicamente y qué vuelta se está viviendo.
##
## No crea nodos, no toca escenas y no muta jornada ni inventario.
extends RefCounted

const GATO_AUSENTE := "ausente"
const GATO_ALIMENTADO := "alimentado"
const GATO_SIN_COMER := "sin_comer"


static func derivar(jornada: Dictionary, inventario: Dictionary = {}) -> Dictionary:
	var objetos_casa := _objetos_de_casa(inventario)
	return {
		"gato_estado": _estado_gato(jornada),
		"objetos_casa": objetos_casa,
		"objetos_casa_ids": _ids(objetos_casa),
		"rutinas_casa": CasaRutinas.estado(jornada),
		"vuelta": maxi(1, int(jornada.get("vuelta", 1))),
	}


static func _objetos_de_casa(inventario: Dictionary) -> Array:
	var almacen = inventario.get(Inventario.HOME_STORAGE, [])
	if typeof(almacen) != TYPE_ARRAY:
		return []
	# Copia profunda: quien materialice la escena puede ordenar o enriquecer la
	# señal sin alterar accidentalmente el guardado.
	return almacen.duplicate(true)


static func _ids(objetos: Array) -> Array[String]:
	var ids: Array[String] = []
	for objeto in objetos:
		if typeof(objeto) != TYPE_DICTIONARY:
			continue
		var id := String(objeto.get("id", ""))
		if not id.is_empty():
			ids.append(id)
	return ids


static func _estado_gato(jornada: Dictionary) -> String:
	var gato = jornada.get("gato", {})
	if typeof(gato) != TYPE_DICTIONARY or not bool(gato.get("presente", false)):
		return GATO_AUSENTE
	if int(gato.get("dias_sin_comer", 0)) > 0:
		return GATO_SIN_COMER
	return GATO_ALIMENTADO
