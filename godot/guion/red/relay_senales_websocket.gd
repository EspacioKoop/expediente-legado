class_name RelaySenalesWebSocket
extends "res://guion/red/relay_presencia_websocket.gd"

## Especialización del relay WebSocket existente para señales asíncronas (#377).
##
## Reutiliza conexión, membresía y framing de #379. Solo cambia el contrato de
## publicación y añade retención en memoria + replay por sala hasta el TTL.
## El relay no conoce el progreso local: acepta cualquier token catalogado y el
## receptor aplica su filtro de conocimiento al reconstruir la señal.

const SenalDatos = preload("res://guion/red/senal_datos.gd")
const SenalServicio = preload("res://guion/red/senal_servicio.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")

const MAX_RETENIDAS_POR_SALA := 64

var _retenidas: Dictionary = {}
var _ultima_publicacion: Dictionary = {}


func detener() -> void:
	super.detener()
	_retenidas.clear()
	_ultima_publicacion.clear()


func retenidas(room_id: String, ahora_unix: int = -1) -> int:
	var ahora := _ahora(ahora_unix)
	var total := 0
	for clave in _retenidas.keys():
		if not String(clave).ends_with("|%s" % room_id):
			continue
		_limpiar_sala(String(clave), ahora)
		total += (_retenidas.get(clave, []) as Array).size()
	return total


func _unir(peer_id: int, datos: Dictionary) -> void:
	super._unir(peer_id, datos)
	var peer: Dictionary = _peers.get(peer_id, {})
	if peer.is_empty() or String(peer.get("room_id", "")).is_empty():
		return
	_replay(peer_id)


func _publicar(peer_id: int, datos: Dictionary) -> void:
	var peer: Dictionary = _peers.get(peer_id, {})
	if peer.is_empty() or String(peer.get("room_id", "")).is_empty():
		_rechazar(peer_id, "not_joined")
		return

	var evento = datos.get("event")
	if typeof(evento) != TYPE_DICTIONARY:
		_rechazar(peer_id, "invalid_event")
		return

	var ahora := _ahora()
	var validacion := SenalDatos.validar_evento(evento, ahora, _conocimiento_catalogo())
	if not validacion["ok"]:
		_rechazar(peer_id, "invalid_signal")
		return
	var normalizado: Dictionary = validacion["event"]
	if (
		String(normalizado["scene_key"]) != String(peer["scene_key"])
		or String(normalizado["actor_public_id"]) != String(peer["actor_public_id"])
	):
		_rechazar(peer_id, "membership_mismatch")
		return

	var clave_sala := _clave_sala(String(peer["scene_key"]), String(peer["room_id"]))
	_limpiar_sala(clave_sala, ahora)
	if not _permite_publicar(clave_sala, String(peer["actor_public_id"]), ahora):
		_rechazar(peer_id, "rate_limited")
		return
	if (
		_activas_actor(clave_sala, String(peer["actor_public_id"]))
		>= SenalServicio.MAX_ACTIVAS_POR_ACTOR_ESCENA
	):
		_rechazar(peer_id, "active_limit")
		return

	_retener(clave_sala, normalizado)
	_ultima_publicacion["%s|%s" % [clave_sala, String(peer["actor_public_id"])]] = ahora
	_emitir_sala(String(peer["scene_key"]), String(peer["room_id"]), normalizado)


func _replay(peer_id: int) -> void:
	var peer: Dictionary = _peers.get(peer_id, {})
	if peer.is_empty():
		return
	var clave := _clave_sala(String(peer["scene_key"]), String(peer["room_id"]))
	_limpiar_sala(clave, _ahora())
	for evento in _retenidas.get(clave, []):
		_enviar(peer_id, {"op": "event", "event": evento})


func _retener(clave_sala: String, evento: Dictionary) -> void:
	var eventos: Array = _retenidas.get(clave_sala, [])
	var huella := EventoOnline.huella(evento)
	for existente in eventos:
		if EventoOnline.huella(existente) == huella:
			return
	eventos.append(evento.duplicate(true))
	while eventos.size() > MAX_RETENIDAS_POR_SALA:
		eventos.pop_front()
	_retenidas[clave_sala] = eventos


func _limpiar_sala(clave_sala: String, ahora: int) -> void:
	var vigentes: Array = []
	for evento in _retenidas.get(clave_sala, []):
		if int(evento.get("expires_at", 0)) > ahora:
			vigentes.append(evento)
	if vigentes.is_empty():
		_retenidas.erase(clave_sala)
	else:
		_retenidas[clave_sala] = vigentes


func _permite_publicar(clave_sala: String, actor_public_id: String, ahora: int) -> bool:
	var clave := "%s|%s" % [clave_sala, actor_public_id]
	if not _ultima_publicacion.has(clave):
		return true
	return (
		ahora - int(_ultima_publicacion[clave])
		>= SenalServicio.INTERVALO_MINIMO_SEGUNDOS
	)


func _activas_actor(clave_sala: String, actor_public_id: String) -> int:
	var total := 0
	for evento in _retenidas.get(clave_sala, []):
		if String(evento.get("actor_public_id", "")) == actor_public_id:
			total += 1
	return total


func _emitir_sala(scene_key: String, room_id: String, evento: Dictionary) -> void:
	for destino_id in _peers.keys():
		var destino: Dictionary = _peers[destino_id]
		if (
			String(destino.get("scene_key", "")) != scene_key
			or String(destino.get("room_id", "")) != room_id
		):
			continue
		_enviar(destino_id, {"op": "event", "event": evento})


func _conocimiento_catalogo() -> Array:
	var conocimiento: Array = []
	for token in SenalVocabulario.TOKENS.values():
		var requisito := String((token as Dictionary).get("conocimiento", ""))
		if not requisito.is_empty() and not conocimiento.has(requisito):
			conocimiento.append(requisito)
	return conocimiento


func _clave_sala(scene_key: String, room_id: String) -> String:
	return "%s|%s" % [scene_key, room_id]


func _ahora(valor: int = -1) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())
