## Consumidor de reentrada para diálogos literarios (#1180).
##
## Reacciona al evento conversacional registrado, no a una barra cultural.
class_name LiteraturaDialogoReentrada
extends RefCounted


static func resolver(
	registro: Dictionary,
	id_dialogo: String,
	ruta: String = LiteraturaDialogo.RUTA,
) -> Dictionary:
	var id_limpio := id_dialogo.strip_edges()
	if id_limpio.is_empty() or typeof(registro) != TYPE_DICTIONARY:
		return _no_disponible()

	var evento := LiteraturaDialogo.insight_de_dialogo(registro, id_limpio)
	if typeof(evento) != TYPE_DICTIONARY or evento.is_empty():
		return _no_disponible()

	var metadatos_raw = evento.get("metadatos", {})
	if typeof(metadatos_raw) != TYPE_DICTIONARY:
		return _no_disponible()

	var metadatos: Dictionary = metadatos_raw
	var rama_id := String(metadatos.get("rama_id", "")).strip_edges()
	if rama_id.is_empty():
		return _no_disponible()

	var dialogo := LiteraturaDialogo.obtener(id_limpio, ruta)
	if typeof(dialogo) != TYPE_DICTIONARY or dialogo.is_empty():
		return _no_disponible()

	var rama := _rama(dialogo, rama_id)
	if typeof(rama) != TYPE_DICTIONARY or rama.is_empty():
		return _no_disponible()

	var reentrada_texto := String(rama.get("reentrada", ""))
	if reentrada_texto.strip_edges().is_empty():
		return _no_disponible()

	var insight_id := String(metadatos.get("insight_id", rama.get("insight_id", ""))).strip_edges()
	var fuente := String(evento.get("fuente", "")).strip_edges()

	return {
		"consumidor": "dialogo_reentrada",
		"disponible": true,
		"texto": reentrada_texto,
		"insight_id": insight_id,
		"fuente": fuente,
	}


static func _rama(dialogo: Dictionary, id_rama: String) -> Dictionary:
	var buscada := id_rama.strip_edges()
	if buscada.is_empty():
		return {}

	var ramas_raw = dialogo.get("ramas", [])
	if typeof(ramas_raw) != TYPE_ARRAY:
		return {}

	for rama_bruta in ramas_raw:
		if typeof(rama_bruta) != TYPE_DICTIONARY:
			continue
		var rama: Dictionary = rama_bruta
		if String(rama.get("id", "")).strip_edges() == buscada:
			return rama.duplicate(true)
	return {}


static func _no_disponible() -> Dictionary:
	return {
		"consumidor": "dialogo_reentrada",
		"disponible": false,
		"texto": "",
		"insight_id": "",
		"fuente": "",
	}
