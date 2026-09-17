class_name SenalVocabulario
extends RefCounted

## Catálogo cerrado para señales asíncronas (#377).
## La red solo transporta IDs; el texto se reconstruye localmente.

const MAX_GESTO := 16

const PLANTILLAS := {
	"cuidado_con": {
		"clave": "signal.template.cuidado_con",
		"texto": "Cuidado con {token0}",
		"categorias": [["peligros", "objetos"]],
	},
	"mira": {
		"clave": "signal.template.mira",
		"texto": "Mira {token0}",
		"categorias": [["objetos", "lugares", "direcciones"]],
	},
	"sigue": {
		"clave": "signal.template.sigue",
		"texto": "Sigue {token0}",
		"categorias": [["direcciones", "lugares"]],
	},
}

const TOKENS := {
	"trampa": {
		"clave": "signal.token.trampa",
		"texto": "trampa",
		"categoria": "peligros",
		"conocimiento": "",
	},
	"alarma": {
		"clave": "signal.token.alarma",
		"texto": "alarma",
		"categoria": "peligros",
		"conocimiento": "",
	},
	"llave": {
		"clave": "signal.token.llave",
		"texto": "llave",
		"categoria": "objetos",
		"conocimiento": "",
	},
	"sobre": {
		"clave": "signal.token.sobre",
		"texto": "sobre",
		"categoria": "objetos",
		"conocimiento": "",
	},
	"norte": {
		"clave": "signal.token.norte",
		"texto": "norte",
		"categoria": "direcciones",
		"conocimiento": "",
	},
	"derecha": {
		"clave": "signal.token.derecha",
		"texto": "derecha",
		"categoria": "direcciones",
		"conocimiento": "",
	},
	"portal": {
		"clave": "signal.token.portal",
		"texto": "portal",
		"categoria": "lugares",
		"conocimiento": "",
	},
	"simbolo_amarillo": {
		"clave": "signal.token.simbolo_amarillo",
		"texto": "símbolo amarillo",
		"categoria": "peligros",
		"conocimiento": "simbolo_amarillo",
	},
}

const ANCHORS := {
	"calle_escaparate": {
		"scene_key": "calle",
		"categorias": ["peligros", "objetos"],
	},
	"calle_portal": {
		"scene_key": "calle",
		"categorias": ["direcciones", "lugares"],
	},
}


static func validar_payload(payload: Variant, conocimiento: Array = []) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _invalido("not_dictionary")
	var datos: Dictionary = payload
	for campo in ["anchor_id", "plantilla_id", "tokens"]:
		if not datos.has(campo):
			return _invalido("missing_%s" % campo)

	if typeof(datos["anchor_id"]) != TYPE_STRING:
		return _invalido("invalid_anchor")
	if typeof(datos["plantilla_id"]) != TYPE_STRING:
		return _invalido("invalid_template")
	if typeof(datos["tokens"]) != TYPE_ARRAY:
		return _invalido("invalid_tokens")

	var anchor_id: String = datos["anchor_id"]
	var plantilla_id: String = datos["plantilla_id"]
	var tokens: Array = datos["tokens"]
	if not ANCHORS.has(anchor_id):
		return _invalido("unknown_anchor")
	if not PLANTILLAS.has(plantilla_id):
		return _invalido("unknown_template")

	var anchor: Dictionary = ANCHORS[anchor_id]
	var plantilla: Dictionary = PLANTILLAS[plantilla_id]
	var categorias_anchor: Array = anchor["categorias"]
	var categorias_slots: Array = plantilla["categorias"]
	if tokens.size() != categorias_slots.size():
		return _invalido("wrong_token_count")

	var normalizados: Array[String] = []
	for i in range(tokens.size()):
		if typeof(tokens[i]) != TYPE_STRING:
			return _invalido("invalid_token")
		var token_id: String = tokens[i]
		if not TOKENS.has(token_id):
			return _invalido("unknown_token")
		var token: Dictionary = TOKENS[token_id]
		var categoria := String(token["categoria"])
		var categorias_slot: Array = categorias_slots[i]
		if not categorias_slot.has(categoria):
			return _invalido("token_not_allowed_for_template")
		if not categorias_anchor.has(categoria):
			return _invalido("token_not_allowed_for_anchor")
		var requisito := String(token.get("conocimiento", ""))
		if not requisito.is_empty() and not conocimiento.has(requisito):
			return _invalido("locked_token")
		normalizados.append(token_id)

	var normalizado := {
		"anchor_id": anchor_id,
		"plantilla_id": plantilla_id,
		"tokens": normalizados,
	}
	if datos.has("gesto"):
		if typeof(datos["gesto"]) != TYPE_INT:
			return _invalido("invalid_gesture")
		var gesto: int = datos["gesto"]
		if gesto < 0 or gesto > MAX_GESTO:
			return _invalido("invalid_gesture")
		normalizado["gesto"] = gesto
	return {"ok": true, "reason": "", "payload": normalizado}


static func scene_key_para_anchor(anchor_id: String) -> String:
	if not ANCHORS.has(anchor_id):
		return ""
	var anchor: Dictionary = ANCHORS[anchor_id]
	return String(anchor["scene_key"])


static func tokens_para_anchor(anchor_id: String, conocimiento: Array = []) -> Array[String]:
	var salida: Array[String] = []
	if not ANCHORS.has(anchor_id):
		return salida
	var anchor: Dictionary = ANCHORS[anchor_id]
	var categorias: Array = anchor["categorias"]
	for token_id in TOKENS:
		var token: Dictionary = TOKENS[token_id]
		if not categorias.has(String(token["categoria"])):
			continue
		var requisito := String(token.get("conocimiento", ""))
		if not requisito.is_empty() and not conocimiento.has(requisito):
			continue
		salida.append(String(token_id))
	salida.sort()
	return salida


static func renderizar(payload: Variant, conocimiento: Array = []) -> Dictionary:
	var validacion := validar_payload(payload, conocimiento)
	if not validacion["ok"]:
		return {"ok": false, "reason": validacion["reason"], "text": ""}
	var datos: Dictionary = validacion["payload"]
	var plantilla: Dictionary = PLANTILLAS[datos["plantilla_id"]]
	var texto := _traducir(String(plantilla["clave"]), String(plantilla["texto"]))
	var tokens: Array = datos["tokens"]
	for i in range(tokens.size()):
		var token: Dictionary = TOKENS[tokens[i]]
		var texto_token := _traducir(String(token["clave"]), String(token["texto"]))
		texto = texto.replace("{token%d}" % i, texto_token)
	return {"ok": true, "reason": "", "text": texto}


static func _traducir(clave: String, fallback: String) -> String:
	var traducido := TranslationServer.translate(clave)
	if traducido == clave:
		return fallback
	return traducido


static func _invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "payload": {}}
