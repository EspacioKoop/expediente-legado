class_name AyudaServicio
extends RefCounted

## Fachada offline-first para ayudas/resonancias (#378).
## No conoce Partida, objetivos, pistas, economía, vidas ni veredictos.

const AyudaDatos = preload("res://guion/red/ayuda_datos.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const MAX_ACTIVAS_POR_ACTOR_ESCENA := 4
const MAX_VISIBLES_POR_ANCHOR := 2
const INTERVALO_MINIMO_SEGUNDOS := 10

var _transporte: RefCounted
var _publicaciones: Dictionary = {}
var _ocultos: Dictionary = {}
var _ayudas_visibles := true


func _init(transporte: RefCounted = null) -> void:
	if transporte == null:
		_transporte = TransporteNulo.new()
	else:
		_transporte = transporte


func set_ayudas_visibles(activas: bool) -> void:
	_ayudas_visibles = activas


func ayudas_visibles() -> bool:
	return _ayudas_visibles


func publicar(
	scene_key: String,
	game_build: String,
	actor_public_id: String,
	anchor_id: String,
	help_type: String,
	strength: String,
	ahora_unix: int = -1,
	conocimiento: Array = [],
	event_id: String = ""
) -> Dictionary:
	var ahora := _ahora(ahora_unix)
	var limite := _comprobar_limite(actor_public_id, scene_key, ahora)
	if not limite["ok"]:
		return limite
	var creado := AyudaDatos.crear_evento(
		scene_key,
		game_build,
		actor_public_id,
		anchor_id,
		help_type,
		strength,
		ahora,
		conocimiento,
		event_id
	)
	if not creado["ok"]:
		return {"ok": false, "status": "invalid_help", "reason": creado["reason"]}
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
	if not _ayudas_visibles:
		return {"ok": true, "status": "disabled_local", "helps": []}
	var ahora := _ahora(ahora_unix)
	var consulta = _transporte.call("consultar_eventos", scene_key, AyudaDatos.KIND, ahora)
	if typeof(consulta) != TYPE_DICTIONARY:
		return {"ok": false, "status": "invalid_transport_result", "helps": []}
	if not bool(consulta.get("ok", false)):
		return {
			"ok": false,
			"status": String(consulta.get("status", "transport_error")),
			"helps": [],
		}
	var salida: Array = []
	var por_anchor: Dictionary = {}
	for evento in consulta.get("events", []):
		var validacion := AyudaDatos.validar_evento(evento, ahora, conocimiento)
		if not validacion["ok"]:
			continue
		var normalizado: Dictionary = validacion["event"]
		var event_id := String(normalizado.get("event_id", ""))
		if not event_id.is_empty() and _ocultos.has(event_id):
			continue
		var anchor_id := String(normalizado["payload"]["anchor_id"])
		var visibles := int(por_anchor.get(anchor_id, 0))
		if visibles >= MAX_VISIBLES_POR_ANCHOR:
			continue
		por_anchor[anchor_id] = visibles + 1
		salida.append(normalizado)
	return {
		"ok": true,
		"status": String(consulta.get("status", "ok")),
		"helps": salida,
	}


func ocultar_evento(event_id: String) -> Dictionary:
	if event_id.is_empty():
		return {"ok": false, "status": "invalid_event_id"}
	_ocultos[event_id] = true
	var remoto = _transporte.call("ocultar_evento", event_id)
	return {"ok": true, "status": "hidden_local", "remote": remoto}


func _comprobar_limite(actor_public_id: String, scene_key: String, ahora: int) -> Dictionary:
	var clave := "%s|%s" % [actor_public_id, scene_key]
	var anteriores: Array = _publicaciones.get(clave, [])
	var vigentes: Array[int] = []
	for timestamp in anteriores:
		if ahora - int(timestamp) < AyudaDatos.TTL_SEGUNDOS:
			vigentes.append(int(timestamp))
	_publicaciones[clave] = vigentes
	if not vigentes.is_empty():
		var transcurrido: int = ahora - int(vigentes.back())
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
