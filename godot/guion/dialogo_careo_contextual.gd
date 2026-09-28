## Ramificación ligera previa al duelo de careo (#1672).
##
## Conserva como máximo un enfoque por folio dentro de Jornada. No calcula
## afinidad, reputación ni ventaja de combate: solo recuerda cómo se planteó la
## conversación para que una reentrada no repita el selector desde cero.
class_name DialogoCareoContextual
extends RefCounted

const CAMPO := "dialogos_careo"

const RAMAS := {
	"pragmatica":
	{
		"texto": "DIALOGO_CAREO_OPCION_PRAGMATICA",
		"respuesta": "DIALOGO_CAREO_PRAGMATICA_RESPUESTA",
		"reentrada": "DIALOGO_CAREO_PRAGMATICA_REENTRADA",
	},
	"version":
	{
		"texto": "DIALOGO_CAREO_OPCION_VERSION",
		"respuesta": "DIALOGO_CAREO_VERSION_RESPUESTA",
		"reentrada": "DIALOGO_CAREO_VERSION_REENTRADA",
	},
	"contraste":
	{
		"texto": "DIALOGO_CAREO_OPCION_CONTRASTE",
		"respuesta": "DIALOGO_CAREO_CONTRASTE_RESPUESTA",
		"reentrada": "DIALOGO_CAREO_CONTRASTE_REENTRADA",
	},
}


static func opciones(tiene_contexto_documental: bool) -> Array[Dictionary]:
	var ids := ["pragmatica", "version"]
	if tiene_contexto_documental:
		ids.append("contraste")

	var salida: Array[Dictionary] = []
	for id_rama in ids:
		var rama: Dictionary = RAMAS[id_rama]
		salida.append(
			{
				"id": id_rama,
				"texto": String(rama.get("texto", "")),
			}
		)
	return salida


## Primera escritura gana. Reabrir el mismo folio no reinterpreta la primera
## conversación aunque el callback se dispare dos veces.
static func registrar(jornada: Dictionary, folio: String, id_rama: String) -> Dictionary:
	var folio_id := folio.strip_edges()
	var rama := _rama(id_rama)
	if folio_id.is_empty() or rama.is_empty():
		return {"valida": false}

	var memorias := _memorias(jornada)
	var previa = memorias.get(folio_id, {})
	if typeof(previa) == TYPE_DICTIONARY and not previa.is_empty():
		var anterior := _rama(String(previa.get("rama", "")))
		if anterior.is_empty():
			return {"valida": false}
		return {
			"valida": true,
			"nueva": false,
			"respuesta": String(anterior.get("reentrada", "")),
		}

	memorias[folio_id] = {
		"rama": id_rama,
		"dia": maxi(1, int(jornada.get("dia", 1))),
	}
	jornada[CAMPO] = memorias
	return {
		"valida": true,
		"nueva": true,
		"respuesta": String(rama.get("respuesta", "")),
	}


static func reentrada(jornada: Dictionary, folio: String) -> String:
	var memoria = _memorias(jornada).get(folio.strip_edges(), {})
	if typeof(memoria) != TYPE_DICTIONARY:
		return ""
	var rama := _rama(String(memoria.get("rama", "")))
	return String(rama.get("reentrada", "")) if not rama.is_empty() else ""


static func claves() -> Array[String]:
	var salida: Array[String] = ["DIALOGO_CAREO_APERTURA"]
	for rama_bruta in RAMAS.values():
		if typeof(rama_bruta) != TYPE_DICTIONARY:
			continue
		var rama: Dictionary = rama_bruta
		for campo in ["texto", "respuesta", "reentrada"]:
			var clave := String(rama.get(campo, ""))
			if not clave.is_empty() and not salida.has(clave):
				salida.append(clave)
	return salida


static func _rama(id_rama: String) -> Dictionary:
	var rama = RAMAS.get(id_rama, {})
	return rama if typeof(rama) == TYPE_DICTIONARY else {}


static func _memorias(jornada: Dictionary) -> Dictionary:
	var actual = jornada.get(CAMPO, {})
	return actual.duplicate(true) if typeof(actual) == TYPE_DICTIONARY else {}
