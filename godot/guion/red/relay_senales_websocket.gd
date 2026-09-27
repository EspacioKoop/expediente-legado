class_name RelaySenalesWebSocket
extends RefCounted

## Relay de desarrollo para señales asíncronas (#377).
##
## Conserva señales válidas en memoria por scene_key + room_id hasta su TTL y
## las reenvía al entrar en la sala. No conoce Partida ni el conocimiento local
## del jugador: ese filtro permanece en SenalServicio/SenalVocabulario.

const EventoOnline = preload("res://guion/red/evento_online.gd")
const SenalDatos = preload("res://guion/red/senal_datos.gd")
const SenalServicio = preload("res://guion/red/senal_servicio.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")

const MAX_PEERS := 8
const MAX_MENSAJE_BYTES := 4096
const MAX_ROOM_ID := 32
const MAX_RETENIDAS_POR_SALA := 64

var _server := TCPServer.new()
var _peers: Dictionary = {}
var _retenidas: Dictionary = {}
var _ultima_publicacion: Dictionary = {}
var _siguiente_peer_id := 1
var _puerto := 0
var _rechazados := 0


func iniciar(puerto: int, bind_address: String = "127.0.0.1") -> Dictionary:
	if puerto <= 0 or puerto > 65535:
		return {"ok": false, "status": "invalid_port"}
	if _server.is_listening():
		detener()

	var error := _server.listen(puerto, bind_address)
	if error != OK:
		return {"ok": false, "status": "listen_failed", "error": error}
	_puerto = puerto
	return {"ok": true, "status": "listening", "port": puerto}


func iniciar_disponible(
	puerto_inicial: int = 19148, intentos: int = 20, bind_address: String = "127.0.0.1"
) -> Dictionary:
	for desplazamiento in range(maxi(intentos, 1)):
		var resultado := iniciar(puerto_inicial + desplazamiento, bind_address)
		if bool(resultado.get("ok", false)):
			return resultado
	return {"ok": false, "status": "no_port_available"}


func procesar() -> void:
	if not _server.is_listening():
		return

	while _server.is_connection_available():
		var stream := _server.take_connection()
		if stream == null:
			break
		if _peers.size() >= MAX_PEERS:
			stream.disconnect_from_host()
			continue

		var socket := WebSocketPeer.new()
		var error := socket.accept_stream(stream)
		if error != OK:
			stream.disconnect_from_host()
			continue
		var peer_id := _siguiente_peer_id
		_siguiente_peer_id += 1
		_peers[peer_id] = {
			"socket": socket,
			"scene_key": "",
			"room_id": "",
			"actor_public_id": "",
		}

	for peer_id in _peers.keys():
		if not _peers.has(peer_id):
			continue
		var peer: Dictionary = _peers[peer_id]
		var socket: WebSocketPeer = peer["socket"]
		socket.poll()
		match socket.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				while socket.get_available_packet_count() > 0:
					var paquete := socket.get_packet()
					if (
						not socket.was_string_packet()
						or paquete.size() <= 0
						or paquete.size() > MAX_MENSAJE_BYTES
					):
						_rechazar(peer_id, "invalid_frame")
						continue
					_procesar_mensaje(peer_id, paquete.get_string_from_utf8())
			WebSocketPeer.STATE_CLOSED:
				_peers.erase(peer_id)


func detener() -> void:
	for peer_id in _peers.keys():
		var peer: Dictionary = _peers[peer_id]
		var socket: WebSocketPeer = peer["socket"]
		if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
			socket.close(-1)
	_peers.clear()
	_retenidas.clear()
	_ultima_publicacion.clear()
	if _server.is_listening():
		_server.stop()
	_puerto = 0


func url() -> String:
	if _puerto <= 0:
		return ""
	return "ws://127.0.0.1:%d" % _puerto


func clientes_en_sala(room_id: String) -> int:
	var total := 0
	for peer in _peers.values():
		if String(peer.get("room_id", "")) == room_id:
			total += 1
	return total


func retenidas(room_id: String, ahora_unix: int = -1) -> int:
	var ahora := _ahora(ahora_unix)
	var total := 0
	for clave in _retenidas.keys():
		if not String(clave).ends_with("|%s" % room_id):
			continue
		_limpiar_sala(String(clave), ahora)
		total += (_retenidas.get(clave, []) as Array).size()
	return total


func rechazados() -> int:
	return _rechazados


func _procesar_mensaje(peer_id: int, texto: String) -> void:
	var datos = JSON.parse_string(texto)
	if typeof(datos) != TYPE_DICTIONARY:
		_rechazar(peer_id, "invalid_json")
		return

	match String(datos.get("op", "")):
		"join":
			_unir(peer_id, datos)
		"publish":
			_publicar(peer_id, datos)
		"leave":
			_dejar(peer_id)
		"report", "hide":
			_confirmar_control(peer_id, String(datos.get("op", "")))
		_:
			_rechazar(peer_id, "unknown_op")


func _unir(peer_id: int, datos: Dictionary) -> void:
	if int(datos.get("protocol_version", -1)) != EventoOnline.PROTOCOL_VERSION:
		_rechazar(peer_id, "unsupported_version")
		return

	var scene_key := String(datos.get("scene_key", "")).strip_edges()
	var room_id := String(datos.get("room_id", "")).strip_edges()
	var actor_public_id := String(datos.get("actor_public_id", "")).strip_edges()
	if (
		scene_key.is_empty()
		or scene_key.length() > EventoOnline.MAX_SCENE_KEY
		or not _room_id_valido(room_id)
		or actor_public_id.is_empty()
		or actor_public_id.length() > EventoOnline.MAX_ACTOR_ID
	):
		_rechazar(peer_id, "invalid_membership")
		return

	var peer: Dictionary = _peers.get(peer_id, {})
	if peer.is_empty():
		return
	peer["scene_key"] = scene_key
	peer["room_id"] = room_id
	peer["actor_public_id"] = actor_public_id
	_peers[peer_id] = peer
	_enviar(
		peer_id,
		{
			"op": "joined",
			"scene_key": scene_key,
			"room_id": room_id,
		},
	)
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
	if _activas_actor(clave_sala, String(peer["actor_public_id"])) >= SenalServicio.MAX_ACTIVAS_POR_ACTOR_ESCENA:
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


func _dejar(peer_id: int) -> void:
	var peer: Dictionary = _peers.get(peer_id, {})
	if peer.is_empty():
		return
	peer["scene_key"] = ""
	peer["room_id"] = ""
	peer["actor_public_id"] = ""
	_peers[peer_id] = peer


func _confirmar_control(peer_id: int, op: String) -> void:
	_enviar(peer_id, {"op": "ack", "for": op})


func _rechazar(peer_id: int, razon: String) -> void:
	_rechazados += 1
	_enviar(peer_id, {"op": "error", "reason": razon})


func _enviar(peer_id: int, mensaje: Dictionary) -> void:
	var peer: Dictionary = _peers.get(peer_id, {})
	if peer.is_empty():
		return
	var socket: WebSocketPeer = peer["socket"]
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	socket.send_text(JSON.stringify(mensaje))


func _conocimiento_catalogo() -> Array:
	var conocimiento: Array = []
	for token in SenalVocabulario.TOKENS.values():
		var requisito := String((token as Dictionary).get("conocimiento", ""))
		if not requisito.is_empty() and not conocimiento.has(requisito):
			conocimiento.append(requisito)
	return conocimiento


func _clave_sala(scene_key: String, room_id: String) -> String:
	return "%s|%s" % [scene_key, room_id]


func _room_id_valido(room_id: String) -> bool:
	if room_id.is_empty() or room_id.length() > MAX_ROOM_ID:
		return false
	for indice in range(room_id.length()):
		var codigo := room_id.unicode_at(indice)
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


func _ahora(valor: int = -1) -> int:
	if valor >= 0:
		return valor
	return int(Time.get_unix_time_from_system())
