## Catálogo data-driven de obras literarias (#1175/#1176).
class_name LiteraturaCatalogo
extends RefCounted

const RUTA := "res://datos/literatura_obras.json"
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
	var obras = catalogo.get("obras", [])
	if typeof(obras) != TYPE_ARRAY:
		return {}

	var ids := {}
	for obra_bruta in obras:
		if typeof(obra_bruta) != TYPE_DICTIONARY:
			return {}
		var obra: Dictionary = obra_bruta
		if not obra_valida(obra):
			return {}
		var id := String(obra["id"])
		if ids.has(id):
			return {}
		ids[id] = true
	return catalogo.duplicate(true)


static func todas(ruta: String = RUTA) -> Array:
	var catalogo := cargar(ruta)
	var obras = catalogo.get("obras", [])
	return obras.duplicate(true) if typeof(obras) == TYPE_ARRAY else []


static func obra(id_obra: String, ruta: String = RUTA) -> Dictionary:
	var buscada := id_obra.strip_edges()
	if buscada.is_empty():
		return {}
	for obra_bruta in todas(ruta):
		if typeof(obra_bruta) != TYPE_DICTIONARY:
			continue
		var candidata: Dictionary = obra_bruta
		if String(candidata.get("id", "")) == buscada:
			return candidata.duplicate(true)
	return {}


static func obra_valida(obra: Dictionary) -> bool:
	for clave in ["id", "titulo", "autor", "epoca", "fuente_documental"]:
		if String(obra.get(clave, "")).strip_edges().is_empty():
			return false

	var generos = obra.get("generos", [])
	if typeof(generos) != TYPE_ARRAY or generos.is_empty():
		return false

	var lectura = obra.get("lectura", {})
	if typeof(lectura) != TYPE_DICTIONARY:
		return false
	var umbral := float(lectura.get("umbral_conocimiento", -1.0))
	if umbral <= 0.0 or umbral > 1.0:
		return false
	if String(lectura.get("insight_id", "")).strip_edges().is_empty():
		return false

	var rom = obra.get("rom", {})
	if typeof(rom) != TYPE_DICTIONARY:
		return false
	for clave in ["id", "estado", "desbloqueo"]:
		if String(rom.get(clave, "")).strip_edges().is_empty():
			return false

	var efecto = obra.get("efecto_juego", {})
	if typeof(efecto) != TYPE_DICTIONARY:
		return false
	for clave in ["id", "tipo", "descripcion"]:
		if String(efecto.get(clave, "")).strip_edges().is_empty():
			return false
	var consumidores = efecto.get("consumidores", [])
	if typeof(consumidores) != TYPE_ARRAY or consumidores.is_empty():
		return false

	# #1182: la capa onirica es opcional y declarativa. El catalogo solo
	# describe motivos y modulacion visual segura; el consumidor decide si usa
	# el insight y nunca obtiene hechos de expedientes desde aqui.
	if obra.has("sueno"):
		var sueno = obra.get("sueno", {})
		if typeof(sueno) != TYPE_DICTIONARY:
			return false
		if String(sueno.get("consumidor", "")).strip_edges().is_empty():
			return false
		var motivos = sueno.get("motivos", [])
		if typeof(motivos) != TYPE_ARRAY or motivos.is_empty():
			return false
		for motivo in motivos:
			if String(motivo).strip_edges().is_empty():
				return false
		var presentacion = sueno.get("presentacion", {})
		if typeof(presentacion) != TYPE_DICTIONARY:
			return false
		var deformacion = presentacion.get("deformacion_textura", [1.0, 1.0, 1.0])
		if typeof(deformacion) != TYPE_ARRAY or deformacion.size() != 3:
			return false

	return true
