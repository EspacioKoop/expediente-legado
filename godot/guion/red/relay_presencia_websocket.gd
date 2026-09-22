class_name RelayPresenciaWebSocket
extends RefCounted

## Relay mínimo de desarrollo para #379.
##
## No conoce Partida ni gameplay. Solo mantiene membresía efímera por sala,
## valida EventoOnline/PresenciaDatos y reenvía snapshots entre participantes
## de la misma scene_key + room_id.

const EventoOnline = preload("res://guion/red/evento_online.gd")
const PresenciaDatos = preload("res://guion/red/presencia_datos.gd")

const MAX_PEERS := 8
const MAX_MENSAJE_BYTES := 4096

var _server := TCPServer.new()
var _peers: Dictionary = {}
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
	puerto_inicial: int = 19098, intentos: int = 20, bind_address: String = "127.0.0.1"
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
	if _server.is_listening():
		_server.stop()
	_puerto = 0


func cortar_actor(actor_public_id: String) -> bool:
	for peer_id in _peers.keys():
		var peer: Dictionary = _peers[peer_id]
		if String(peer.get("actor_public_id", "")) != actor_public_id:
			continue
		var socket: WebSocketPeer = peer["socket"]
		socket.close(-1)
		_peers.erase(peer_id)
		return true
	return false


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
		or not PresenciaDatos.validar_room_id(room_id)
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


func _publicar(peer_id: int, datos: Dictionary) -> void:
	var peer: Dictionary = _peers.get(peer_id, {})
	if peer.is_empty() or String(peer.get("room_id", "")).is_empty():
		_rechazar(peer_id, "not_joined")
		return

	var evento = datos.get("event")
	if typeof(evento) != TYPE_DICTIONARY:
		_rechazar(peer_id, "invalid_event")
		return

	var ahora := int(Time.get_unix_time_from_system())
	var validacion := PresenciaDatos.validar_evento(evento, ahora)
	if not validacion["ok"]:
		_rechazar(peer_id, "invalid_presence")
		return
	var normalizado: Dictionary = validacion["event"]
	var payload: Dictionary = normalizado["payload"]
	if (
		String(normalizado["scene_key"]) != String(peer["scene_key"])
		or String(normalizado["actor_public_id"]) != String(peer["actor_public_id"])
		or String(payload["room_id"]) != String(peer["room_id"])
	):
		_rechazar(peer_id, "membership_mismatch")
		return

	for destino_id in _peers.keys():
		if destino_id == peer_id:
			continue
		var destino: Dictionary = _peers[destino_id]
		if (
			String(destino.get("scene_key", "")) != String(peer["scene_key"])
			or String(destino.get("room_id", "")) != String(peer["room_id"])
		):
			continue
		_enviar(destino_id, {"op": "event", "event": normalizado})


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
