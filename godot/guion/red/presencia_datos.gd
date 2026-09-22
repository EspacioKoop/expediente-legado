class_name PresenciaDatos
extends RefCounted

## Contrato de snapshot efímero para presencia coop (#379) sobre EventoOnline (#375).
## Solo transporta pose/estado visual. No conoce ni serializa Partida.

const EventoOnline = preload("res://guion/red/evento_online.gd")

const KIND := "presence"
const TTL_SEGUNDOS := 6
const MAX_ROOM_ID := 32
const MAX_SEQ := 2_147_483_647
const MAX_COORDENADA_ABS := 10_000.0
const MAX_YAW_ABS := TAU * 4.0

const MOVIMIENTOS := ["idle", "walk"]
const GESTOS := ["", "saludo", "senalar", "asentir"]
const CAMPOS_PAYLOAD := ["room_id", "seq", "position", "yaw", "motion", "gesture"]


static func crear_evento(
	scene_key: String,
	game_build: String,
	actor_public_id: String,
	room_id: String,
	seq: int,
	position: Vector3,
	yaw: float,
	motion: String,
	gesture: String,
	ahora_unix: int,
	event_id: String = ""
) -> Dictionary:
	var payload := {
		"room_id": room_id,
		"seq": seq,
		"position": [position.x, position.y, position.z],
		"yaw": yaw,
		"motion": motion,
		"gesture": gesture,
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
	if typeof(evento) != TYPE_DICTIONARY:
		return _invalido("not_dictionary")
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
	for campo in ["room_id", "seq", "position", "yaw", "motion"]:
		if not payload.has(campo):
			return _invalido("missing_%s" % campo)
	for clave in payload.keys():
		if not CAMPOS_PAYLOAD.has(String(clave)):
			return _invalido("unexpected_%s" % String(clave))

	var room_id := String(payload.get("room_id", ""))
	if not validar_room_id(room_id):
		return _invalido("invalid_room_id")

	var seq := int(payload.get("seq", -1))
	if seq < 0 or seq > MAX_SEQ:
		return _invalido("invalid_seq")

	var posicion = payload.get("position")
	if typeof(posicion) != TYPE_ARRAY or posicion.size() != 3:
		return _invalido("invalid_position")
	var normalizada: Array[float] = []
	for valor in posicion:
		if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
			return _invalido("invalid_position")
		var numero := float(valor)
		if not is_finite(numero) or absf(numero) > MAX_COORDENADA_ABS:
			return _invalido("invalid_position")
		normalizada.append(numero)

	var yaw_raw = payload.get("yaw")
	if typeof(yaw_raw) != TYPE_INT and typeof(yaw_raw) != TYPE_FLOAT:
		return _invalido("invalid_yaw")
	var yaw := float(yaw_raw)
	if not is_finite(yaw) or absf(yaw) > MAX_YAW_ABS:
		return _invalido("invalid_yaw")

	var motion := String(payload.get("motion", ""))
	if not MOVIMIENTOS.has(motion):
		return _invalido("invalid_motion")
	var gesture := String(payload.get("gesture", ""))
	if not GESTOS.has(gesture):
		return _invalido("invalid_gesture")

	return {
		"ok": true,
		"reason": "",
		"payload":
		{
			"room_id": room_id,
			"seq": seq,
			"position": normalizada,
			"yaw": yaw,
			"motion": motion,
			"gesture": gesture,
		},
	}


static func validar_room_id(room_id: String) -> bool:
	if room_id.is_empty() or room_id.length() > MAX_ROOM_ID:
		return false
	for i in range(room_id.length()):
		var codigo := room_id.unicode_at(i)
		var es_numero := codigo >= 48 and codigo <= 57
		var es_mayuscula := codigo >= 65 and codigo <= 90
		var es_minuscula := codigo >= 97 and codigo <= 122
		if (
			not es_numero
			and not es_mayuscula
			and not es_minuscula
			and codigo != 45
			and codigo != 95
		):
			return false
	return true


static func _invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "event": {}, "payload": {}}
