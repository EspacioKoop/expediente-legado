## Contrato puro de la vertical literaria (#1175/#1176).
##
## Mantiene separados hechos que no son equivalentes: conocer una obra no
## significa poseerla; obtener insight no activa por sí solo un ritual o efecto.
## El módulo no persiste en Partida ni aplica efectos de gameplay.
class_name LiteraturaEventos
extends RefCounted

const CANAL_CONOCIMIENTO := "conocimiento"
const CANAL_POSESION := "posesion"
const CANAL_INSIGHT := "insight"
const CANAL_RITUAL := "ritual"
const CANALES := [
	CANAL_CONOCIMIENTO,
	CANAL_POSESION,
	CANAL_INSIGHT,
	CANAL_RITUAL,
]


static func nuevo() -> Dictionary:
	return {
		CANAL_CONOCIMIENTO: [],
		CANAL_POSESION: [],
		CANAL_INSIGHT: [],
		CANAL_RITUAL: [],
	}


static func crear_evento(
	id_evento: String,
	canal: String,
	obra_id: String,
	fuente: String,
	contexto: String = "",
	jornada: int = 0,
	etiquetas: Array = [],
	metadatos: Dictionary = {}
) -> Dictionary:
	var id := id_evento.strip_edges()
	var obra := obra_id.strip_edges()
	var origen := fuente.strip_edges()
	if id.is_empty() or obra.is_empty() or origen.is_empty() or not CANALES.has(canal):
		return {}

	return {
		"id": id,
		"canal": canal,
		"obra_id": obra,
		"fuente": origen,
		"contexto": contexto.strip_edges(),
		"jornada": maxi(0, jornada),
		"etiquetas": _normalizar_lista(etiquetas),
		"metadatos": metadatos.duplicate(true),
	}


## El id es único entre todos los canales: el mismo hecho no puede acabar
## contado como conocimiento y posesión por accidente.
static func registrar(registro: Dictionary, evento: Dictionary) -> bool:
	if not evento_valido(evento):
		return false

	var id := String(evento["id"])
	for canal in CANALES:
		for existente in _lista_canal(registro, canal):
			if typeof(existente) == TYPE_DICTIONARY and String(existente.get("id", "")) == id:
				return false

	var canal := String(evento["canal"])
	var destino := _lista_canal(registro, canal)
	destino.append(evento.duplicate(true))
	registro[canal] = destino
	return true


static func eventos(registro: Dictionary, canal: String) -> Array:
	if not CANALES.has(canal):
		return []
	return _lista_canal(registro, canal)


static func obra_conocida(registro: Dictionary, obra_id: String) -> bool:
	return _canal_contiene_obra(registro, CANAL_CONOCIMIENTO, obra_id)


static func obra_poseida(registro: Dictionary, obra_id: String) -> bool:
	return _canal_contiene_obra(registro, CANAL_POSESION, obra_id)


static func evento_valido(evento: Dictionary) -> bool:
	if String(evento.get("id", "")).strip_edges().is_empty():
		return false
	if String(evento.get("obra_id", "")).strip_edges().is_empty():
		return false
	if String(evento.get("fuente", "")).strip_edges().is_empty():
		return false
	if not CANALES.has(String(evento.get("canal", ""))):
		return false
	if evento.has("etiquetas") and typeof(evento["etiquetas"]) != TYPE_ARRAY:
		return false
	if evento.has("metadatos") and typeof(evento["metadatos"]) != TYPE_DICTIONARY:
		return false
	return true


static func _canal_contiene_obra(registro: Dictionary, canal: String, obra_id: String) -> bool:
	var buscada := obra_id.strip_edges()
	if buscada.is_empty():
		return false
	for evento_bruto in _lista_canal(registro, canal):
		if typeof(evento_bruto) == TYPE_DICTIONARY:
			var evento: Dictionary = evento_bruto
			if String(evento.get("obra_id", "")) == buscada:
				return true
	return false


static func _lista_canal(registro: Dictionary, canal: String) -> Array:
	var valor = registro.get(canal, [])
	return valor.duplicate(true) if typeof(valor) == TYPE_ARRAY else []


static func _normalizar_lista(valores: Array) -> Array:
	var resultado := []
	for valor in valores:
		var texto := String(valor).strip_edges()
		if not texto.is_empty() and not resultado.has(texto):
			resultado.append(texto)
	resultado.sort()
	return resultado
