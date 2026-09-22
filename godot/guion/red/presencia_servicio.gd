class_name PresenciaServicio
extends RefCounted

## Fachada de sesión para presencia coop (#379).
## Mantiene la campaña fuera del contrato: solo publica/lee EventoOnline(kind="presence").

const PresenciaDatos = preload("res://guion/red/presencia_datos.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

var _transporte: RefCounted
var _activa := false
var _scene_key := ""
var _room_id := ""
var _actor_public_id := ""
var _seq_local := -1
var _ultimo_seq_remoto: Dictionary = {}
var _ocultos: Dictionary = {}


func _init(transporte: RefCounted = null) -> void:
	_transporte = TransporteNulo.new() if transporte == null else transporte


func abrir_sala(scene_key: String, room_id: String, actor_public_id: String) -> Dictionary:
	if scene_key.is_empty() or scene_key.length() > 96:
		return {"ok": false, "status": "invalid_scene_key"}
	if not PresenciaDatos.validar_room_id(room_id):
		return {"ok": false, "status": "invalid_room_id"}
	if actor_public_id.is_empty() or actor_public_id.length() > 96:
		return {"ok": false, "status": "invalid_actor_id"}

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
	_actor_public_id = actor_public_id
	_seq_local = -1
	_ultimo_seq_remoto.clear()
	_ocultos.clear()
	_activa = true

	var salida: Dictionary = resultado.duplicate(true)
	salida["room_id"] = room_id
	salida["actor_public_id"] = actor_public_id
	return salida


func procesar(delta: float) -> void:
	if not _activa:
		return
	if _transporte != null and _transporte.has_method("procesar"):
		_transporte.call("procesar", maxf(delta, 0.0))


func publicar_snapshot(
	game_build: String,
	position: Vector3,
	yaw: float,
	motion: String,
	gesture: String = "",
	ahora_unix: int = -1,
	event_id: String = ""
) -> Dictionary:
	if not _activa:
		return {"ok": false, "status": "not_in_room"}
	var ahora := _ahora(ahora_unix)
	_seq_local += 1
	var creado := PresenciaDatos.crear_evento(
		_scene_key,
		game_build,
		_actor_public_id,
		_room_id,
		_seq_local,
		position,
		yaw,
		motion,
		gesture,
		ahora,
		event_id
	)
	if not creado["ok"]:
		return {"ok": false, "status": "invalid_presence", "reason": creado["reason"]}
	var resultado = _transporte.call("publicar_evento", creado["event"], ahora)
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	resultado = resultado.duplicate(true)
	resultado["event"] = creado["event"]
	return resultado


func consultar(ahora_unix: int = -1) -> Dictionary:
	if not _activa:
		return {"ok": true, "status": "inactive", "participants": []}
	var ahora := _ahora(ahora_unix)
	var consulta = _transporte.call("consultar_eventos", _scene_key, PresenciaDatos.KIND, ahora)
	if typeof(consulta) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result", "participants": []}
	if not bool(consulta.get("ok", false)):
		return {
			"ok": false,
			"status": String(consulta.get("status", "transport_error")),
			"participants": [],
		}

	var mas_reciente: Dictionary = {}
	for crudo in consulta.get("events", []):
		var validacion := PresenciaDatos.validar_evento(crudo, ahora)
		if not validacion["ok"]:
			continue
		var evento: Dictionary = validacion["event"]
		var actor_id := String(evento["actor_public_id"])
		if actor_id == _actor_public_id or _ocultos.has(actor_id):
			continue
		var payload: Dictionary = evento["payload"]
		if String(payload["room_id"]) != _room_id:
			continue
		var seq := int(payload["seq"])
		if seq <= int(_ultimo_seq_remoto.get(actor_id, -1)):
			continue
		if mas_reciente.has(actor_id):
			var anterior: Dictionary = mas_reciente[actor_id]
			if seq <= int(anterior["payload"]["seq"]):
				continue
		mas_reciente[actor_id] = evento

	var actores := mas_reciente.keys()
	actores.sort()
	var participantes: Array = []
	for actor_id in actores:
		var evento: Dictionary = mas_reciente[actor_id]
		_ultimo_seq_remoto[actor_id] = int(evento["payload"]["seq"])
		participantes.append(evento)

	return {
		"ok": true,
		"status": String(consulta.get("status", "ok")),
		"participants": participantes,
	}


func ocultar_participante(actor_public_id: String) -> bool:
	if actor_public_id.is_empty() or actor_public_id == _actor_public_id:
		return false
	_ocultos[actor_public_id] = true
	return true


func mostrar_participante(actor_public_id: String) -> void:
	_ocultos.erase(actor_public_id)


func cerrar_sala() -> Dictionary:
	var resultado = _transporte.call("cerrar_sala")
	_activa = false
	_scene_key = ""
	_room_id = ""
	_actor_public_id = ""
	_seq_local = -1
	_ultimo_seq_remoto.clear()
	_ocultos.clear()
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
		"actor_public_id": _actor_public_id,
	}


func estado_transporte() -> Dictionary:
	if _transporte == null or not _transporte.has_method("health"):
		return {"ok": false, "status": "transport_unavailable"}
	var resultado = _transporte.call("health")
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	return resultado


func _ahora(valor: int) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())
