class_name SenalServicio
extends RefCounted

## Fachada offline-first para publicar y consultar señales (#377).
## Por defecto usa TransporteNulo: jugar sin red nunca bloquea la partida.

const SenalDatos = preload("res://guion/red/senal_datos.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const MAX_ACTIVAS_POR_ACTOR_ESCENA := 10
const INTERVALO_MINIMO_SEGUNDOS := 2

var _transporte: RefCounted
var _publicaciones: Dictionary = {}
var _ocultos: Dictionary = {}


func _init(transporte: RefCounted = null) -> void:
	if transporte == null:
		_transporte = TransporteNulo.new()
	else:
		_transporte = transporte


func publicar(
	scene_key: String,
	game_build: String,
	actor_public_id: String,
	anchor_id: String,
	plantilla_id: String,
	tokens: Array,
	ahora_unix: int = -1,
	conocimiento: Array = [],
	gesto: int = -1,
	event_id: String = ""
) -> Dictionary:
	var ahora := _ahora(ahora_unix)
	var limite := _comprobar_limite(actor_public_id, scene_key, ahora)
	if not limite["ok"]:
		return limite
	var creado := SenalDatos.crear_evento(
		scene_key,
		game_build,
		actor_public_id,
		anchor_id,
		plantilla_id,
		tokens,
		ahora,
		conocimiento,
		gesto,
		event_id
	)
	if not creado["ok"]:
		return {"ok": false, "status": "invalid_signal", "reason": creado["reason"]}
	var resultado = _transporte.call("publicar_evento", creado["event"], ahora)
	if typeof(resultado) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result"}
	if bool(resultado.get("ok", false)):
		_registrar_publicacion(actor_public_id, scene_key, ahora)
		resultado["event"] = creado["event"]
	return resultado


func consultar(
	scene_key: String, conocimiento: Array = [], ahora_unix: int = -1
) -> Dictionary:
	var ahora := _ahora(ahora_unix)
	var consulta = _transporte.call("consultar_eventos", scene_key, SenalDatos.KIND, ahora)
	if typeof(consulta) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result", "signals": []}
	if not bool(consulta.get("ok", false)):
		return {
			"ok": false,
			"status": String(consulta.get("status", "transport_error")),
			"signals": [],
		}
	var salida: Array = []
	for evento in consulta.get("events", []):
		var validacion := SenalDatos.validar_evento(evento, ahora, conocimiento)
		if not validacion["ok"]:
			continue
		var normalizado: Dictionary = validacion["event"]
		var event_id := String(normalizado.get("event_id", ""))
		if not event_id.is_empty() and _ocultos.has(event_id):
			continue
		salida.append(normalizado)
	return {
		"ok": true,
		"status": String(consulta.get("status", "ok")),
		"signals": salida,
	}


func ocultar_evento(event_id: String) -> Dictionary:
	if event_id.is_empty():
		return {"ok": false, "status": "invalid_event_id"}
	_ocultos[event_id] = true
	var remoto = _transporte.call("ocultar_evento", event_id)
	return {"ok": true, "status": "hidden_local", "remote": remoto}


func reportar_evento(event_id: String) -> Dictionary:
	if event_id.is_empty():
		return {"ok": false, "status": "invalid_event_id"}
	var remoto = _transporte.call("reportar_evento", event_id)
	return {"ok": true, "status": "reported", "remote": remoto}


func _comprobar_limite(actor_public_id: String, scene_key: String, ahora: int) -> Dictionary:
	var clave := "%s|%s" % [actor_public_id, scene_key]
	var anteriores: Array = _publicaciones.get(clave, [])
	var vigentes: Array[int] = []
	for timestamp in anteriores:
		if ahora - int(timestamp) < SenalDatos.TTL_SEGUNDOS:
			vigentes.append(int(timestamp))
	_publicaciones[clave] = vigentes
	if not vigentes.is_empty():
		var transcurrido := ahora - vigentes.back()
		if transcurrido < INTERVALO_MINIMO_SEGUNDOS:
			return {
				"ok": false,
				"status": "rate_limited",
				"retry_after": INTERVALO_MINIMO_SEGUNDOS - transcurrido,
			}
	if vigentes.size() >= MAX_ACTIVAS_POR_ACTOR_ESCENA:
		return {"ok": false, "status": "active_limit"}
	return {"ok": true, "status": "ok"}


func _registrar_publicacion(actor_public_id: String, scene_key: String, ahora: int) -> void:
	var clave := "%s|%s" % [actor_public_id, scene_key]
	var publicaciones: Array = _publicaciones.get(clave, [])
	publicaciones.append(ahora)
	_publicaciones[clave] = publicaciones


func _ahora(valor: int) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())
