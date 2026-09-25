class_name CombateCoopDatos
extends RefCounted

## Contrato mínimo de elección de ronda para #380.
## No admite campos de campaña, texto libre ni consecuencias persistentes.

const EventoOnline = preload("res://guion/red/evento_online.gd")

const KIND := "coop_combat"
const TTL_SEGUNDOS := 20
const MAX_ROOM_ID := 32
const MAX_ENCOUNTER_ID := 48
const MAX_RONDA := 2
const CAMPOS_PAYLOAD := ["room_id", "encounter_id", "round", "action"]


static func crear_eleccion(
	scene_key: String,
	game_build: String,
	actor_public_id: String,
	room_id: String,
	encounter_id: String,
	ronda: int,
	action: String,
	ahora_unix: int,
	event_id: String = ""
) -> Dictionary:
	var payload := {
		"room_id": room_id,
		"encounter_id": encounter_id,
		"round": ronda,
		"action": action,
	}
	var validacion_payload := validar_payload(payload)
	if not validacion_payload["ok"]:
		return _invalido(validacion_payload["reason"])

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


static func validar_evento(evento: Variant, ahora_unix: int) -> Dictionary:
	var validacion_evento := EventoOnline.validar(evento, ahora_unix)
	if not validacion_evento["ok"]:
		return _invalido(validacion_evento["reason"])
	var normalizado: Dictionary = validacion_evento["event"]
	if normalizado["kind"] != KIND:
		return _invalido("wrong_kind")
	var validacion_payload := validar_payload(normalizado["payload"])
	if not validacion_payload["ok"]:
		return _invalido(validacion_payload["reason"])
	normalizado["payload"] = validacion_payload["payload"]
	return {"ok": true, "reason": "", "event": normalizado}


static func validar_payload(payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _invalido("payload_not_dictionary")
	for campo in CAMPOS_PAYLOAD:
		if not payload.has(campo):
			return _invalido("missing_%s" % campo)
	for clave in payload.keys():
		if not CAMPOS_PAYLOAD.has(String(clave)):
			return _invalido("unexpected_%s" % String(clave))

	var room_id := String(payload["room_id"])
	if not _id_valido(room_id, MAX_ROOM_ID):
		return _invalido("invalid_room_id")
	var encounter_id := String(payload["encounter_id"])
	if not _id_valido(encounter_id, MAX_ENCOUNTER_ID):
		return _invalido("invalid_encounter_id")
	var ronda := int(payload["round"])
	if ronda < 0 or ronda > MAX_RONDA:
		return _invalido("invalid_round")
	var action := String(payload["action"])
	if not Combate.TIPOS.has(action):
		return _invalido("invalid_action")

	return {
		"ok": true,
		"reason": "",
		"payload": {
			"room_id": room_id,
			"encounter_id": encounter_id,
			"round": ronda,
			"action": action,
		},
	}


static func _id_valido(valor: String, maximo: int) -> bool:
	if valor.is_empty() or valor.length() > maximo:
		return false
	for i in range(valor.length()):
		var codigo := valor.unicode_at(i)
		var numero := codigo >= 48 and codigo <= 57
		var mayuscula := codigo >= 65 and codigo <= 90
		var minuscula := codigo >= 97 and codigo <= 122
		if not numero and not mayuscula and not minuscula and codigo != 45 and codigo != 95:
			return false
	return true


static func _invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "event": {}, "payload": {}}
