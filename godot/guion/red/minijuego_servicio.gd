class_name MinijuegoServicio
extends RefCounted

## Fachada reutilizable de sala privada para minijuegos sociales (#383).
## No resuelve gameplay: solo abre/cierra la sala y mueve acciones validadas
## por el contrato común de MinijuegoSesionDatos.

const EventoOnline = preload("res://guion/red/evento_online.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

var _transporte: RefCounted
var _activa := false
var _scene_key := ""
var _room_id := ""
var _session_id := ""
var _minigame_id := ""
var _rules_version := 0
var _actor_public_id := ""
var _vistos: Dictionary = {}


func _init(transporte: RefCounted = null) -> void:
	_transporte = TransporteNulo.new() if transporte == null else transporte


func abrir_sala(
	scene_key: String,
	room_id: String,
	session_id: String,
	minigame_id: String,
	rules_version: int,
	actor_public_id: String,
) -> Dictionary:
	var razon := _validar_contexto(
		scene_key,
		room_id,
		session_id,
		minigame_id,
		rules_version,
		actor_public_id,
	)
	if not razon.is_empty():
		return {"ok": false, "status": razon}

	var resultado = (
		_transporte
		. call(
			"abrir_sala",
			scene_key,
			{
				"room_id": room_id,
				"actor_public_id": actor_public_id,
			},
		)
	)
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	if not bool(resultado.get("ok", false)):
		return resultado

	_scene_key = scene_key
	_room_id = room_id
	_session_id = session_id
	_minigame_id = minigame_id
	_rules_version = rules_version
	_actor_public_id = actor_public_id
	_vistos.clear()
	_activa = true

	var salida: Dictionary = resultado.duplicate(true)
	salida["room_id"] = room_id
	salida["session_id"] = session_id
	salida["minigame_id"] = minigame_id
	salida["rules_version"] = rules_version
	salida["actor_public_id"] = actor_public_id
	return salida


func procesar(delta: float) -> void:
	if not _activa:
		return
	if _transporte != null and _transporte.has_method("procesar"):
		_transporte.call("procesar", maxf(delta, 0.0))


func publicar_accion(
	game_build: String,
	sequence: int,
	turn: int,
	action: Dictionary,
	ahora_unix: int = -1,
	event_id: String = "",
) -> Dictionary:
	if not _activa:
		return {"ok": false, "status": "not_in_room"}

	var ahora := _ahora(ahora_unix)
	var creado := (
		MinijuegoSesionDatos
		. crear_accion(
			_scene_key,
			game_build,
			_actor_public_id,
			_room_id,
			_session_id,
			_minigame_id,
			_rules_version,
			sequence,
			turn,
			action,
			ahora,
			event_id,
		)
	)
	if not creado["ok"]:
		return {"ok": false, "status": "invalid_action", "reason": creado["reason"]}

	var resultado = _transporte.call("publicar_evento", creado["event"], ahora)
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	resultado = resultado.duplicate(true)
	resultado["event"] = creado["event"]
	return resultado


func consultar_acciones(ahora_unix: int = -1) -> Dictionary:
	if not _activa:
		return {"ok": true, "status": "inactive", "actions": [], "discarded": 0}

	var ahora := _ahora(ahora_unix)
	var consulta = (
		_transporte
		. call(
			"consultar_eventos",
			_scene_key,
			MinijuegoSesionDatos.KIND,
			ahora,
		)
	)
	if typeof(consulta) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"status": "invalid_transport_result",
			"actions": [],
			"discarded": 0,
		}
	if not bool(consulta.get("ok", false)):
		return {
			"ok": false,
			"status": String(consulta.get("status", "transport_error")),
			"actions": [],
			"discarded": 0,
		}

	var acciones: Array = []
	var descartados := 0
	for crudo in consulta.get("events", []):
		var filtrado := _filtrar_evento(crudo, ahora)
		if not filtrado["ok"]:
			descartados += 1
			continue
		var evento: Dictionary = filtrado["event"]
		var huella := EventoOnline.huella(evento)
		if _vistos.has(huella):
			continue
		_vistos[huella] = true
		acciones.append(evento)

	acciones.sort_custom(_ordenar_secuencia)
	return {
		"ok": true,
		"status": String(consulta.get("status", "ok")),
		"actions": acciones,
		"discarded": descartados,
	}


func comprobar_version(remota: int) -> Dictionary:
	if remota <= 0:
		return {"ok": false, "status": "invalid_rules_version"}
	if remota != _rules_version:
		return {
			"ok": false,
			"status": "incompatible_rules",
			"local": _rules_version,
			"remote": remota,
		}
	return {"ok": true, "status": "compatible", "rules_version": _rules_version}


func cerrar_sala() -> Dictionary:
	var resultado = _transporte.call("cerrar_sala")
	_limpiar()
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	return resultado


func activa() -> bool:
	return _activa


func contexto() -> Dictionary:
	return {
		"activa": _activa,
		"scene_key": _scene_key,
		"room_id": _room_id,
		"session_id": _session_id,
		"minigame_id": _minigame_id,
		"rules_version": _rules_version,
		"actor_public_id": _actor_public_id,
	}


func estado_transporte() -> Dictionary:
	if _transporte == null or not _transporte.has_method("health"):
		return {"ok": false, "status": "transport_unavailable"}
	var resultado = _transporte.call("health")
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	return resultado


func _filtrar_evento(evento: Variant, ahora: int) -> Dictionary:
	var validacion := MinijuegoSesionDatos.validar_evento(evento, ahora)
	if not validacion["ok"]:
		return {"ok": false, "event": {}}

	var normalizado: Dictionary = validacion["event"]
	var payload: Dictionary = normalizado["payload"]
	var coincide := String(payload["room_id"]) == _room_id
	coincide = coincide and String(payload["session_id"]) == _session_id
	coincide = coincide and String(payload["minigame_id"]) == _minigame_id
	coincide = coincide and int(payload["rules_version"]) == _rules_version
	if not coincide:
		return {"ok": false, "event": {}}
	return {"ok": true, "event": normalizado}


func _validar_contexto(
	scene_key: String,
	room_id: String,
	session_id: String,
	minigame_id: String,
	rules_version: int,
	actor_public_id: String,
) -> String:
	if scene_key.is_empty() or scene_key.length() > EventoOnline.MAX_SCENE_KEY:
		return "invalid_scene_key"
	if actor_public_id.is_empty() or actor_public_id.length() > EventoOnline.MAX_ACTOR_ID:
		return "invalid_actor_id"

	var prueba := (
		MinijuegoSesionDatos
		. validar_payload(
			{
				"room_id": room_id,
				"session_id": session_id,
				"minigame_id": minigame_id,
				"rules_version": rules_version,
				"sequence": 0,
				"turn": 0,
				"action": {"type": "context_probe"},
			}
		)
	)
	if not prueba["ok"]:
		return String(prueba["reason"])
	return ""


func _ordenar_secuencia(a: Dictionary, b: Dictionary) -> bool:
	var pa: Dictionary = a["payload"]
	var pb: Dictionary = b["payload"]
	var sa := int(pa["sequence"])
	var sb := int(pb["sequence"])
	if sa == sb:
		return String(a.get("actor_public_id", "")) < String(b.get("actor_public_id", ""))
	return sa < sb


func _limpiar() -> void:
	_activa = false
	_scene_key = ""
	_room_id = ""
	_session_id = ""
	_minigame_id = ""
	_rules_version = 0
	_actor_public_id = ""
	_vistos.clear()


func _ahora(valor: int) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())
