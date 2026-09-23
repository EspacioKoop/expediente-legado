## Segundo consumidor del mismo insight conversacional (#1180).
##
## Devuelve contexto histórico/literario para una superficie externa. El
## movimiento describe la conversación; nunca se proyecta sobre el jugador.
class_name LiteraturaMovimientoContexto
extends RefCounted


static func resolver(
	registro: Dictionary,
	id_dialogo: String,
	ruta: String = LiteraturaDialogo.RUTA,
) -> Dictionary:
	var evento := LiteraturaDialogo.insight_de_dialogo(registro, id_dialogo)
	if evento.is_empty():
		return {
			"consumidor": "contexto_movimiento",
			"disponible": false,
			"movimiento_id": "",
			"texto": "",
			"insight_id": "",
			"fuente": "",
		}

	var metadatos: Dictionary = evento.get("metadatos", {})
	var dialogo := LiteraturaDialogo.obtener(id_dialogo, ruta)
	var movimiento: Dictionary = dialogo.get("movimiento", {})
	if movimiento.is_empty():
		return {
			"consumidor": "contexto_movimiento",
			"disponible": false,
			"movimiento_id": "",
			"texto": "",
			"insight_id": "",
			"fuente": "",
		}

	return {
		"consumidor": "contexto_movimiento",
		"disponible": true,
		"movimiento_id": String(movimiento.get("id", "")),
		"texto": String(movimiento.get("contexto", "")),
		"insight_id": String(metadatos.get("insight_id", "")),
		"fuente": String(evento.get("fuente", "")),
	}
