class_name Inventario
extends RefCounted

const CARRIED := "carried"
const HOME_STORAGE := "home_storage"


static func nuevo() -> Dictionary:
	return {
		CARRIED: [],
		HOME_STORAGE: [],
	}


static func completar(estado: Dictionary) -> Dictionary:
	if not estado.has(CARRIED) or typeof(estado[CARRIED]) != TYPE_ARRAY:
		estado[CARRIED] = []
	if not estado.has(HOME_STORAGE) or typeof(estado[HOME_STORAGE]) != TYPE_ARRAY:
		estado[HOME_STORAGE] = []
	return estado


static func recoger(estado: Dictionary, objeto: Dictionary) -> bool:
	completar(estado)
	if not _objeto_valido(objeto):
		return false
	var id := String(objeto["id"])
	if contiene(estado, id):
		return false
	estado[CARRIED].append(objeto.duplicate(true))
	return true


static func guardar_en_casa(estado: Dictionary, objeto_id: String) -> bool:
	return _mover(estado, objeto_id, CARRIED, HOME_STORAGE)


static func sacar_de_casa(estado: Dictionary, objeto_id: String) -> bool:
	return _mover(estado, objeto_id, HOME_STORAGE, CARRIED)


static func vender(estado: Dictionary, objeto_id: String) -> Dictionary:
	completar(estado)
	for ubicacion in [CARRIED, HOME_STORAGE]:
		var indice := _indice(estado[ubicacion], objeto_id)
		if indice < 0:
			continue
		var objeto: Dictionary = estado[ubicacion][indice]
		# La recompensa del sueño no puede convertirse en la economía despierta.
		# Aunque un objeto tenga precio por error de catálogo, su origen manda.
		if String(objeto.get("origen", "")) == "sueno":
			return {"vendido": false, "dinero": 0, "motivo": "onirico"}
		if not bool(objeto.get("vendible", false)):
			return {"vendido": false, "dinero": 0, "motivo": "no_vendible"}
		var precio := maxi(0, int(objeto.get("precio", 0)))
		estado[ubicacion].remove_at(indice)
		return {"vendido": true, "dinero": precio, "motivo": ""}
	return {"vendido": false, "dinero": 0, "motivo": "no_encontrado"}


static func perder_casa(estado: Dictionary) -> Array:
	completar(estado)
	var perdidos: Array = estado[HOME_STORAGE].duplicate(true)
	estado[HOME_STORAGE].clear()
	return perdidos


static func visibles(estado: Dictionary, en_casa: bool) -> Array:
	completar(estado)
	var resultado: Array = estado[CARRIED].duplicate(true)
	if en_casa:
		resultado.append_array(estado[HOME_STORAGE].duplicate(true))
	return resultado


static func contiene(estado: Dictionary, objeto_id: String) -> bool:
	completar(estado)
	return _indice(estado[CARRIED], objeto_id) >= 0 or _indice(estado[HOME_STORAGE], objeto_id) >= 0


static func _mover(estado: Dictionary, objeto_id: String, origen: String, destino: String) -> bool:
	completar(estado)
	var indice := _indice(estado[origen], objeto_id)
	if indice < 0:
		return false
	var objeto = estado[origen][indice]
	estado[origen].remove_at(indice)
	estado[destino].append(objeto)
	return true


static func _indice(lista: Array, objeto_id: String) -> int:
	for i in lista.size():
		var objeto = lista[i]
		if typeof(objeto) == TYPE_DICTIONARY and String(objeto.get("id", "")) == objeto_id:
			return i
	return -1


static func _objeto_valido(objeto: Dictionary) -> bool:
	return not String(objeto.get("id", "")).is_empty()
