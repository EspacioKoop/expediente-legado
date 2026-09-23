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
	var evento := LiteraturaDialogo.insight_de_dialogo(registro, id_dialogo)
	if evento.is_empty():
		return {
			"consumidor": "dialogo_reentrada",
			"disponible": false,
		"texto": "",
			"insight_id": "",
			"fuente": "",
		}

	var metadatos: Dictionary = evento.get("metadatos", {})
	var dialogo := LiteraturaDialogo.obtener(id_dialogo, ruta)
	var rama := _rama(dialogo, String(metadatos.get("rama_id", "")))
	if rama.is_empty():
		return {
			"consumidor": "dialogo_reentrada",
			"disponible": false,
			"texto": "",
			"insight_id": "",
			"fuente": "",
		}

	return {
		"consumidor": "dialogo_reentrada",
		"disponible": true,
		"texto": String(rama.get("reentrada", "")),
		"insight_id": String(metadatos.get("insight_id", "")),
		"fuente": String(evento.get("fuente", "")),
	}


static func _rama(dialogo: Dictionary, id_rama: String) -> Dictionary:
	for rama_bruta in dialogo.get("ramas", []):
		if typeof(rama_bruta) != TYPE_DICTIONARY:
			continue
		var rama: Dictionary = rama_bruta
		if String(rama.get("id", "")) == id_rama:
			return rama.duplicate(true)
	return {}
