class_name GhostDatos
extends RefCounted

## Contrato cerrado para ecos asíncronos de trayectorias (#376).
## Solo contiene pose y gesto visual; nunca inputs, texto libre ni estado de Partida.

const EventoOnline = preload("res://guion/red/evento_online.gd")

const KIND := "ghost"
const TTL_SEGUNDOS := 900
const MIN_SAMPLE_RATE := 5.0
const MAX_SAMPLE_RATE := 10.0
const MAX_FRAMES := 48
const MAX_DURACION := 8.0
const MAX_COORDENADA_ABS := 10_000.0
const MAX_YAW_ABS := TAU * 4.0
const MAX_REVISION := 64
const MAX_ANCHOR := 64

const ESPACIOS := ["scene", "anchor"]
const GESTOS := ["", "detenerse", "mirar_escaparate", "saludo", "asentir"]
const CAMPOS_PAYLOAD := ["scene_revision", "sample_rate", "space", "anchor_key", "frames"]
const CAMPOS_FRAME := ["t", "position", "yaw", "gesture"]


static func crear_evento(
	scene_key: String,
	scene_revision: String,
	game_build: String,
	actor_public_id: String,
	frames: Array,
	sample_rate: float,
	ahora_unix: int,
	event_id: String = "",
	space: String = "scene",
	anchor_key: String = ""
) -> Dictionary:
	var payload := {
		"scene_revision": scene_revision,
		"sample_rate": sample_rate,
		"space": space,
		"anchor_key": anchor_key,
		"frames": frames,
	}
	var validacion_payload := validar_payload(payload, scene_key)
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
	var validacion_payload := validar_payload(
		normalizado["payload"], String(normalizado["scene_key"])
	)
	if not validacion_payload["ok"]:
		return _invalido(validacion_payload["reason"])
	normalizado["payload"] = validacion_payload["payload"]
	return {"ok": true, "reason": "", "event": normalizado}


static func validar_payload(payload: Variant, scene_key: String = "") -> Dictionary:
	if typeof(payload) != TYPE_DICTIONARY:
		return _invalido("payload_not_dictionary")
	for campo in ["scene_revision", "sample_rate", "frames"]:
		if not payload.has(campo):
			return _invalido("missing_%s" % campo)
	for clave in payload.keys():
		if not CAMPOS_PAYLOAD.has(String(clave)):
			return _invalido("unexpected_%s" % String(clave))

	var revision := String(payload.get("scene_revision", ""))
	if revision.is_empty() or revision.length() > MAX_REVISION:
		return _invalido("invalid_scene_revision")

	var sample_raw = payload.get("sample_rate")
	if typeof(sample_raw) != TYPE_INT and typeof(sample_raw) != TYPE_FLOAT:
		return _invalido("invalid_sample_rate")
	var sample_rate := float(sample_raw)
	if not is_finite(sample_rate) or sample_rate < MIN_SAMPLE_RATE or sample_rate > MAX_SAMPLE_RATE:
		return _invalido("invalid_sample_rate")

	var space := String(payload.get("space", "scene"))
	if not ESPACIOS.has(space):
		return _invalido("invalid_space")
	var anchor_key := String(payload.get("anchor_key", ""))
	if anchor_key.length() > MAX_ANCHOR:
		return _invalido("invalid_anchor")
	if space == "anchor" and anchor_key.is_empty():
		return _invalido("missing_anchor")
	if space == "scene" and not anchor_key.is_empty():
		return _invalido("unexpected_anchor")
	if scene_key.begins_with("sueno") and space != "anchor":
		return _invalido("dream_requires_anchor")

	var frames_raw = payload.get("frames")
	if typeof(frames_raw) != TYPE_ARRAY:
		return _invalido("frames_not_array")
	var frames: Array = frames_raw
	if frames.size() < 2 or frames.size() > MAX_FRAMES:
		return _invalido("invalid_frame_count")

	var normalizados: Array = []
	var tiempo_anterior := -1.0
	for frame_raw in frames:
		var validacion_frame := _validar_frame(frame_raw, tiempo_anterior)
		if not validacion_frame["ok"]:
			return _invalido(validacion_frame["reason"])
		var frame: Dictionary = validacion_frame["frame"]
		tiempo_anterior = float(frame["t"])
		normalizados.append(frame)
	if tiempo_anterior > MAX_DURACION:
		return _invalido("duration_too_large")

	return {
		"ok": true,
		"reason": "",
		"payload":
		{
			"scene_revision": revision,
			"sample_rate": sample_rate,
			"space": space,
			"anchor_key": anchor_key,
			"frames": normalizados,
		},
	}


static func _validar_frame(frame_raw: Variant, tiempo_anterior: float) -> Dictionary:
	if typeof(frame_raw) != TYPE_DICTIONARY:
		return _frame_invalido("frame_not_dictionary")
	var frame: Dictionary = frame_raw
	for campo in CAMPOS_FRAME:
		if not frame.has(campo):
			return _frame_invalido("missing_frame_%s" % campo)
	for clave in frame.keys():
		if not CAMPOS_FRAME.has(String(clave)):
			return _frame_invalido("unexpected_frame_%s" % String(clave))

	var t_raw = frame.get("t")
	if typeof(t_raw) != TYPE_INT and typeof(t_raw) != TYPE_FLOAT:
		return _frame_invalido("invalid_frame_time")
	var t := float(t_raw)
	if not is_finite(t) or t < 0.0 or t <= tiempo_anterior or t > MAX_DURACION:
		return _frame_invalido("invalid_frame_time")

	var posicion = frame.get("position")
	if typeof(posicion) != TYPE_ARRAY or posicion.size() != 3:
		return _frame_invalido("invalid_frame_position")
	var posicion_normalizada: Array[float] = []
	for valor in posicion:
		if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
			return _frame_invalido("invalid_frame_position")
		var numero := float(valor)
		if not is_finite(numero) or absf(numero) > MAX_COORDENADA_ABS:
			return _frame_invalido("invalid_frame_position")
		posicion_normalizada.append(numero)

	var yaw_raw = frame.get("yaw")
	if typeof(yaw_raw) != TYPE_INT and typeof(yaw_raw) != TYPE_FLOAT:
		return _frame_invalido("invalid_frame_yaw")
	var yaw := float(yaw_raw)
	if not is_finite(yaw) or absf(yaw) > MAX_YAW_ABS:
		return _frame_invalido("invalid_frame_yaw")

	var gesture := String(frame.get("gesture", ""))
	if not GESTOS.has(gesture):
		return _frame_invalido("invalid_frame_gesture")

	return {
		"ok": true,
		"reason": "",
		"frame":
		{
			"t": t,
			"position": posicion_normalizada,
			"yaw": yaw,
			"gesture": gesture,
		},
	}


static func _frame_invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "frame": {}}


static func _invalido(razon: String) -> Dictionary:
	return {"ok": false, "reason": razon, "event": {}, "payload": {}}
