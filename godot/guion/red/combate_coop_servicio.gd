class_name CombateCoopServicio
extends RefCounted

## Transporte de elecciones efímeras de #380.
## La resolución vive en CombateCoop y nunca escribe progreso canónico.

const CombateCoopDatos = preload("res://guion/red/combate_coop_datos.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

var _transporte: RefCounted
var _scene_key := ""
var _room_id := ""
var _encounter_id := ""
var _actor_id := ""
var _activa := false


func _init(transporte: RefCounted = null) -> void:
	_transporte = TransporteNulo.new() if transporte == null else transporte


func abrir(
	scene_key: String, room_id: String, encounter_id: String, actor_public_id: String
) -> Dictionary:
	var apertura = _transporte.call(
		"abrir_sala",
		scene_key,
		{
			"room_id": room_id,
			"actor_public_id": actor_public_id,
		},
	)
	if typeof(apertura) != TYPE_DICTIONARY or not bool(apertura.get("ok", false)):
		return {"ok": false, "status": "transport_error"}
	_scene_key = scene_key
	_room_id = room_id
	_encounter_id = encounter_id
	_actor_id = actor_public_id
	_activa = true
	return apertura


func publicar_eleccion(
	ronda: int, action: String, game_build: String, ahora_unix: int, event_id: String = ""
) -> Dictionary:
	if not _activa:
		return {"ok": false, "status": "not_in_room"}
	var creada := CombateCoopDatos.crear_eleccion(
		_scene_key,
		game_build,
		_actor_id,
		_room_id,
		_encounter_id,
		ronda,
		action,
		ahora_unix,
		event_id
	)
	if not creada["ok"]:
		return {"ok": false, "status": "invalid_choice", "reason": creada["reason"]}
	var resultado = _transporte.call("publicar_evento", creada["event"], ahora_unix)
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	resultado = resultado.duplicate(true)
	resultado["event"] = creada["event"]
	return resultado


func consultar_elecciones(ronda: int, ahora_unix: int) -> Dictionary:
	if not _activa:
		return {"ok": true, "status": "inactive", "choices": []}
	var consulta = _transporte.call(
		"consultar_eventos", _scene_key, CombateCoopDatos.KIND, ahora_unix
	)
	if typeof(consulta) != TYPE_DICTIONARY or not bool(consulta.get("ok", false)):
		return {"ok": false, "status": "transport_error", "choices": []}
	var por_actor: Dictionary = {}
	for crudo in consulta.get("events", []):
		var validacion := CombateCoopDatos.validar_evento(crudo, ahora_unix)
		if not validacion["ok"]:
			continue
		var evento: Dictionary = validacion["event"]
		var payload: Dictionary = evento["payload"]
		if String(payload["room_id"]) != _room_id:
			continue
		if String(payload["encounter_id"]) != _encounter_id:
			continue
		if int(payload["round"]) != ronda:
			continue
		var actor := String(evento["actor_public_id"])
		if not por_actor.has(actor):
			por_actor[actor] = evento

	var actores := por_actor.keys()
	actores.sort()
	var elecciones: Array = []
	for actor in actores:
		elecciones.append(por_actor[actor])
	return {"ok": true, "status": "ok", "choices": elecciones}


func cerrar() -> Dictionary:
	var resultado = _transporte.call("cerrar_sala")
	_activa = false
	_scene_key = ""
	_room_id = ""
	_encounter_id = ""
	_actor_id = ""
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	return resultado
