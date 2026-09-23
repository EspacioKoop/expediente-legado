## Productor de insight conversacional para la vertical literaria (#1180).
##
## La conversación registra un hecho observable y su procedencia. No escribe
## identidad, afiliación, reputación ni atributos globales del jugador.
class_name LiteraturaDialogo
extends RefCounted

const RUTA := "res://datos/literatura_dialogos.json"
const VERSION := 1


static func cargar(ruta: String = RUTA) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return {}
	var catalogo: Dictionary = datos
	if int(catalogo.get("version", 0)) != VERSION:
		return {}
	var dialogos = catalogo.get("dialogos", [])
	if typeof(dialogos) != TYPE_ARRAY or dialogos.is_empty():
		return {}

	var ids := {}
	for dialogo_bruto in dialogos:
		if typeof(dialogo_bruto) != TYPE_DICTIONARY:
			return {}
		var dialogo: Dictionary = dialogo_bruto
		if not _dialogo_valido(dialogo):
			return {}
		var id := String(dialogo["id"])
		if ids.has(id):
			return {}
		ids[id] = true
	return catalogo.duplicate(true)


static func obtener(id_dialogo: String, ruta: String = RUTA) -> Dictionary:
	var buscado := id_dialogo.strip_edges()
	if buscado.is_empty():
		return {}
	for dialogo_bruto in cargar(ruta).get("dialogos", []):
		if typeof(dialogo_bruto) != TYPE_DICTIONARY:
			continue
		var dialogo: Dictionary = dialogo_bruto
		if String(dialogo.get("id", "")) == buscado:
			return dialogo.duplicate(true)
	return {}


static func conversar(
	registro: Dictionary,
	id_dialogo: String,
	id_rama: String,
	fuente: String,
	jornada: int = 0,
	ruta: String = RUTA,
) -> Dictionary:
	var resultado := {
		"valida": false,
		"insight_nuevo": false,
		"motivo": "dialogo_invalido",
		"respuesta": "",
		"consecuencia_visible": "",
		"insight_id": "",
		"movimiento_id": "",
	}
	var dialogo := obtener(id_dialogo, ruta)
	var origen := fuente.strip_edges()
	if dialogo.is_empty() or origen.is_empty():
		return resultado

	var rama := _rama(dialogo, id_rama)
	if rama.is_empty():
		resultado["motivo"] = "rama_invalida"
		return resultado

	var npc: Dictionary = dialogo.get("npc", {})
	var movimiento: Dictionary = dialogo.get("movimiento", {})
	var insight_id := String(rama.get("insight_id", "")).strip_edges()
	var evento := (
		LiteraturaEventos
		. crear_evento(
			"insight:dialogo:%s:%s" % [String(dialogo["id"]), insight_id],
			LiteraturaEventos.CANAL_INSIGHT,
			String(dialogo["obra_id"]),
			origen,
			"dialogo:%s" % String(dialogo["id"]),
			jornada,
			rama.get("etiquetas", []),
			{
				"productor": "dialogo_literario",
				"dialogo_id": String(dialogo["id"]),
				"rama_id": String(rama["id"]),
				"insight_id": insight_id,
				"npc_id": String(npc.get("id", "")),
				"movimiento_id": String(movimiento.get("id", "")),
				"consecuencia_visible": String(rama.get("consecuencia_visible", "")),
			},
		)
	)
	var nuevo := LiteraturaEventos.registrar(registro, evento)
	resultado["valida"] = true
	resultado["insight_nuevo"] = nuevo
	resultado["motivo"] = "registrado" if nuevo else "ya_registrado"
	resultado["respuesta"] = String(rama.get("respuesta", ""))
	resultado["consecuencia_visible"] = String(rama.get("consecuencia_visible", ""))
	resultado["insight_id"] = insight_id
	resultado["movimiento_id"] = String(movimiento.get("id", ""))
	return resultado


static func insight_de_dialogo(registro: Dictionary, id_dialogo: String) -> Dictionary:
	var buscado := id_dialogo.strip_edges()
	if buscado.is_empty():
		return {}
	for evento_bruto in LiteraturaEventos.eventos(registro, LiteraturaEventos.CANAL_INSIGHT):
		if typeof(evento_bruto) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_bruto
		var metadatos = evento.get("metadatos", {})
		if typeof(metadatos) != TYPE_DICTIONARY:
			continue
		if String(metadatos.get("productor", "")) != "dialogo_literario":
			continue
		if String(metadatos.get("dialogo_id", "")) == buscado:
			return evento.duplicate(true)
	return {}


static func _rama(dialogo: Dictionary, id_rama: String) -> Dictionary:
	var buscada := id_rama.strip_edges()
	for rama_bruta in dialogo.get("ramas", []):
		if typeof(rama_bruta) != TYPE_DICTIONARY:
			continue
		var rama: Dictionary = rama_bruta
		if String(rama.get("id", "")) == buscada:
			return rama.duplicate(true)
	return {}


static func _dialogo_valido(dialogo: Dictionary) -> bool:
	for clave in ["id", "obra_id", "apertura"]:
		if String(dialogo.get(clave, "")).strip_edges().is_empty():
			return false

	var npc = dialogo.get("npc", {})
	if typeof(npc) != TYPE_DICTIONARY:
		return false
	for clave in ["id", "nombre", "rol"]:
		if String(npc.get(clave, "")).strip_edges().is_empty():
			return false

	var movimiento = dialogo.get("movimiento", {})
	if typeof(movimiento) != TYPE_DICTIONARY:
		return false
	for clave in ["id", "nombre", "contexto"]:
		if String(movimiento.get(clave, "")).strip_edges().is_empty():
			return false

	var ramas = dialogo.get("ramas", [])
	if typeof(ramas) != TYPE_ARRAY or ramas.size() < 2:
		return false
	var ids := {}
	for rama_bruta in ramas:
		if typeof(rama_bruta) != TYPE_DICTIONARY:
			return false
		var rama: Dictionary = rama_bruta
		for clave in [
			"id",
			"texto",
			"respuesta",
			"consecuencia_visible",
			"reentrada",
			"insight_id",
		]:
			if String(rama.get(clave, "")).strip_edges().is_empty():
				return false
		var id := String(rama["id"])
		if ids.has(id):
			return false
		ids[id] = true
		if typeof(rama.get("etiquetas", [])) != TYPE_ARRAY:
			return false
	return true
