class_name MinijuegoSesionDatos
extends RefCounted

## Contrato común de sesiones de minijuegos sociales (#383).
## La red transporta acciones pequeñas; nunca puntuaciones ni estado de Partida.

const EventoOnline = preload("res://guion/red/evento_online.gd")

const KIND := "minigame_action"
const TTL_SEGUNDOS := 25
const MAX_ROOM_ID := 32
const MAX_SESSION_ID := 48
const MAX_MINIGAME_ID := 48
const MAX_ACTION_TYPE := 32
const MAX_ACTION_FIELDS := 16
const MAX_PLAYERS := 4
const MIN_PLAYERS := 2
const CAMPOS_PAYLOAD := [
	"room_id",
	"session_id",
	"minigame_id",
	"rules_version",
	"sequence",
	"turn",
	"action",
]
const CLAVES_RESULTADO_PROHIBIDAS := [
	"score",
	"scores",
	"result",
	"resultado",
	"puntuacion",
	"puntos",
	"golpes",
	"winner",
	"ganador",
]


static func nueva_sesion(
	session_id: String,
	minigame_id: String,
	rules_version: int,
	players: Array,
) -> Dictionary:
	if not _id_valido(session_id, MAX_SESSION_ID):
		return {}
	if not _id_valido(minigame_id, MAX_MINIGAME_ID):
		return {}
	if rules_version <= 0:
		return {}
	if players.size() < MIN_PLAYERS or players.size() > MAX_PLAYERS:
		return {}

	var normalizados: Array[String] = []
	for valor in players:
		var player := String(valor)
		if not _id_valido(player, EventoOnline.MAX_ACTOR_ID):
			return {}
		if normalizados.has(player):
			return {}
		normalizados.append(player)

	return {
		"session_id": session_id,
		"minigame_id": minigame_id,
		"rules_version": rules_version,
		"players": normalizados,
		"phase": "playing",
		"turn": 0,
		"sequence": 0,
		"state": {},
		"allowed_actions": [],
		"result": {},
	}


static func crear_accion(
	scene_key: String,
	game_build: String,
	actor_public_id: String,
	room_id: String,
	session_id: String,
	minigame_id: String,
	rules_version: int,
	sequence: int,
	turn: int,
	action: Dictionary,
	ahora_unix: int,
	event_id: String = "",
) -> Dictionary:
	var payload := {
		"room_id": room_id,
		"session_id": session_id,
		"minigame_id": minigame_id,
		"rules_version": rules_version,
		"sequence": sequence,
		"turn": turn,
		"action": action.duplicate(true),
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
	var session_id := String(payload["session_id"])
	var minigame_id := String(payload["minigame_id"])
	if not _id_valido(room_id, MAX_ROOM_ID):
		return _invalido("invalid_room_id")
	if not _id_valido(session_id, MAX_SESSION_ID):
		return _invalido("invalid_session_id")
	if not _id_valido(minigame_id, MAX_MINIGAME_ID):
		return _invalido("invalid_minigame_id")

	var rules_version := _entero_json(payload["rules_version"])
	if rules_version <= 0:
		return _invalido("invalid_rules_version")
	var sequence := _entero_json(payload["sequence"])
	if sequence < 0:
		return _invalido("invalid_sequence")
	var turn := _entero_json(payload["turn"])
	if turn < 0:
		return _invalido("invalid_turn")

	var action = payload["action"]
	var validacion_action := _validar_action(action)
	if not validacion_action["ok"]:
		return _invalido(validacion_action["reason"])

	return {
		"ok": true,
		"reason": "",
		"payload":
		{
			"room_id": room_id,
			"session_id": session_id,
			"minigame_id": minigame_id,
			"rules_version": rules_version,
			"sequence": sequence,
			"turn": turn,
			"action": validacion_action["action"],
		},
	}


static func _validar_action(action: Variant) -> Dictionary:
	if typeof(action) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "action_not_dictionary", "action": {}}
	if action.is_empty() or action.size() > MAX_ACTION_FIELDS:
		return {"ok": false, "reason": "invalid_action_size", "action": {}}
	if not action.has("type"):
		return {"ok": false, "reason": "missing_action_type", "action": {}}

	var tipo := String(action["type"])
	if tipo.is_empty() or tipo.length() > MAX_ACTION_TYPE:
		return {"ok": false, "reason": "invalid_action_type", "action": {}}

	for clave in action.keys():
		if typeof(clave) != TYPE_STRING:
			return {"ok": false, "reason": "non_string_action_key", "action": {}}
		var normalizada := String(clave).to_lower()
		if CLAVES_RESULTADO_PROHIBIDAS.has(normalizada):
			return {"ok": false, "reason": "forbidden_result_field", "action": {}}

	return {"ok": true, "reason": "", "action": action.duplicate(true)}


static func _entero_json(valor: Variant) -> int:
	if typeof(valor) == TYPE_INT:
		return int(valor)
	if typeof(valor) != TYPE_FLOAT or not is_finite(float(valor)):
		return -1
	var numero := float(valor)
	if numero != floor(numero):
		return -1
	return int(numero)


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
