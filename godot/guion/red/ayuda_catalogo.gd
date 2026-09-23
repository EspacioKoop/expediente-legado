class_name AyudaCatalogo
extends RefCounted

## Catálogo cerrado de ayudas/resonancias asíncronas (#378).
## La red solo transporta IDs declarativos; nunca texto, scripts ni recursos.

const HELP_TYPES := {
	"resonancia": {
		"visual": "pulso_luz",
		"audio": "eco_breve",
	},
}

const STRENGTHS := ["leve", "media"]

const ANCHORS := {
	"suenio_umbral": {
		"scene_key": "suenio/primera_noche",
		"knowledge_gate": "",
	},
	"suenio_figura": {
		"scene_key": "suenio/primera_noche",
		"knowledge_gate": "figura_onirica",
	},
}


static func validar_payload(payload: Variant, conocimiento: Array = []) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _invalido("not_dictionary")
	var datos: Dictionary = payload
	for campo in ["anchor_id", "help_type", "strength"]:
		if not datos.has(campo):
			return _invalido("missing_%s" % campo)
	for campo in datos:
		if not ["anchor_id", "help_type", "strength", "knowledge_gate"].has(String(campo)):
			return _invalido("unexpected_field")

	if typeof(datos["anchor_id"]) != TYPE_STRING:
		return _invalido("invalid_anchor")
	if typeof(datos["help_type"]) != TYPE_STRING:
		return _invalido("invalid_help_type")
	if typeof(datos["strength"]) != TYPE_STRING:
		return _invalido("invalid_strength")

	var anchor_id: String = datos["anchor_id"]
	var help_type: String = datos["help_type"]
	var strength: String = datos["strength"]
	if not ANCHORS.has(anchor_id):
		return _invalido("unknown_anchor")
	if not HELP_TYPES.has(help_type):
		return _invalido("unknown_help_type")
	if not STRENGTHS.has(strength):
		return _invalido("unknown_strength")

	var anchor: Dictionary = ANCHORS[anchor_id]
	var gate := String(anchor.get("knowledge_gate", ""))
	if datos.has("knowledge_gate"):
		if typeof(datos["knowledge_gate"]) != TYPE_STRING:
			return _invalido("invalid_knowledge_gate")
		if String(datos["knowledge_gate"]) != gate:
			return _invalido("knowledge_gate_mismatch")
	if not gate.is_empty() and not conocimiento.has(gate):
		return _invalido("locked_knowledge")

	var normalizado := {
		"anchor_id": anchor_id,
		"help_type": help_type,
		"strength": strength,
	}
	if not gate.is_empty():
		normalizado["knowledge_gate"] = gate
	return {"ok": true, "reason": "", "payload": normalizado}


static func scene_key_para_anchor(anchor_id: String) -> String:
	if not ANCHORS.has(anchor_id):
		return ""
	var anchor: Dictionary = ANCHORS[anchor_id]
	return String(anchor["scene_key"])


static func feedback_para(payload: Variant, conocimiento: Array = []) -> Dictionary:
	var validacion := validar_payload(payload, conocimiento)
	if not validacion["ok"]:
		return {"ok": false, "reason": validacion["reason"], "feedback": {}}
	var datos: Dictionary = validacion["payload"]
	var tipo: Dictionary = HELP_TYPES[datos["help_type"]]
	return {
		"ok": true,
		"reason": "",
		"feedback":
		{
			"visual": String(tipo["visual"]),
			"audio": String(tipo["audio"]),
			"strength": String(datos["strength"]),
		},
	}


static func _invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "payload": {}}
