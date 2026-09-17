class_name SenalDatos
extends RefCounted

## Adaptador de #377 sobre el contrato offline-first de #375.

const EventoOnline = preload("res://guion/red/evento_online.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")
const KIND := "signal"
const TTL_SEGUNDOS := 900


static func crear_evento(
	scene_key: String,
	game_build: String,
	actor_public_id: String,
	anchor_id: String,
	plantilla_id: String,
	tokens: Array,
	ahora_unix: int,
	conocimiento: Array = [],
	gesto: int = -1,
	event_id: String = ""
) -> Dictionary:
	var payload := {
		"anchor_id": anchor_id,
		"plantilla_id": plantilla_id,
		"tokens": tokens.duplicate(),
	}
	if gesto >= 0:
		payload["gesto"] = gesto
	var validacion_payload := SenalVocabulario.validar_payload(payload, conocimiento)
	if not validacion_payload["ok"]:
		return _invalido(validacion_payload["reason"])
	if SenalVocabulario.scene_key_para_anchor(anchor_id) != scene_key:
		return _invalido("anchor_scene_mismatch")

	var evento := {
		"protocol_version": EventoOnline.PROTOCOL_VERSION,
		"kind": KIND,
		"game_build": game_build,
		"scene_key": scene_key,
		"created_at": ahora_unix,
		"expires_at": ahora_unix + TTL_SEGUNDOS,
		"actor_public_id": actor_public_id,
		"payload": validacion_payload["payload"],
	}
	if not event_id.is_empty():
		evento["event_id"] = event_id
	var validacion_evento := EventoOnline.validar(evento, ahora_unix)
	if not validacion_evento["ok"]:
		return _invalido(validacion_evento["reason"])
	return {"ok": true, "reason": "", "event": validacion_evento["event"]}


static func validar_evento(
	evento: Variant, ahora_unix: int, conocimiento: Array = []
) -> Dictionary:
	if typeof(evento) != TYPE_DICTIONARY:
		return _invalido("not_dictionary")
	var validacion_evento := EventoOnline.validar(evento, ahora_unix)
	if not validacion_evento["ok"]:
		return _invalido(validacion_evento["reason"])
	var normalizado: Dictionary = validacion_evento["event"]
	if normalizado["kind"] != KIND:
		return _invalido("wrong_kind")
	var validacion_payload := SenalVocabulario.validar_payload(normalizado["payload"], conocimiento)
	if not validacion_payload["ok"]:
		return _invalido(validacion_payload["reason"])
	var payload: Dictionary = validacion_payload["payload"]
	if SenalVocabulario.scene_key_para_anchor(payload["anchor_id"]) != normalizado["scene_key"]:
		return _invalido("anchor_scene_mismatch")
	normalizado["payload"] = payload
	return {"ok": true, "reason": "", "event": normalizado}


static func _invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "event": {}}
