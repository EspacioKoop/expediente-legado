class_name TransporteWebSocket
extends "res://guion/red/transporte_online.gd"

## Transporte WebSocket para la capa online offline-first (#375/#379).
##
## La conexión es no bloqueante: procesar() bombea el socket, reintenta tras
## cortes y conserva una cola pequeña. Para presencia solo mantiene el snapshot
## pendiente más reciente por actor/sala, evitando una ráfaga de estados viejos
## al reconectar.

const REINTENTO_SEGUNDOS := 0.25
const MAX_COLA_SALIENTE := 16
const MAX_ENTRANTES := 64

var endpoint_url := ""

var _socket: WebSocketPeer
var _scene_key := ""
var _room_id := ""
var _actor_public_id := ""
var _estado := "idle"
var _ultimo_error := ""
var _reintento_restante := 0.0
var _cerrado_voluntario := true
var _join_enviado := false
var _unido := false
var _cola_saliente: Array[Dictionary] = []
var _entrantes: Array[Dictionary] = []
var _descartados := 0


func _init(url: String = "") -> void:
	configurar(url)


func configurar(url: String) -> void:
	endpoint_url = url.strip_edges().trim_suffix("/")


func procesar(delta: float) -> void:
	if _cerrado_voluntario:
		return
	if endpoint_url.is_empty():
		_estado = "unconfigured"
		return

	if _socket == null:
		_reintento_restante = maxf(_reintento_restante - maxf(delta, 0.0), 0.0)
		if _reintento_restante <= 0.0:
			_conectar()
		return

	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			_estado = "connecting"
		WebSocketPeer.STATE_OPEN:
			if not _join_enviado:
				if not _enviar(_mensaje_join()):
					_marcar_reconexion("join_send_failed")
					return
				_join_enviado = true
				_estado = "joining"
			_leer_paquetes()
			if _unido:
				_vaciar_cola()
		WebSocketPeer.STATE_CLOSING:
			_estado = "closing"
		WebSocketPeer.STATE_CLOSED:
			_marcar_reconexion("socket_closed")


func publicar_evento(evento: Dictionary, ahora_unix: int = -1) -> Dictionary:
	if _cerrado_voluntario:
		return _resultado(false, "not_in_room", {"delivered": false})
	var validacion := EventoOnline.validar(evento, _ahora(ahora_unix))
	if not validacion["ok"]:
		return _resultado(
			false,
			"invalid_event",
			{"reason": validacion["reason"], "delivered": false},
		)

	var mensaje := {"op": "publish", "event": validacion["event"]}
	procesar(0.0)
	if _unido and _enviar(mensaje):
		return _resultado(true, "ok", {"delivered": true, "queued": false})

	_encolar_publicacion(mensaje)
	return _resultado(
		true,
		_estado,
		{"delivered": false, "queued": true, "queue_size": _cola_saliente.size()},
	)


func consultar_eventos(scene_key: String, kind: String = "", ahora_unix: int = -1) -> Dictionary:
	if _cerrado_voluntario:
		return _resultado(true, "inactive", {"events": []})

	procesar(0.0)
	var ahora := _ahora(ahora_unix)
	var salida: Array = []
	var restantes: Array[Dictionary] = []
	for crudo in _entrantes:
		var validacion := EventoOnline.validar(crudo, ahora)
		if not validacion["ok"]:
			_descartados += 1
			continue
		var evento: Dictionary = validacion["event"]
		if String(evento["scene_key"]) != scene_key:
			restantes.append(evento)
			continue
		if not kind.is_empty() and String(evento["kind"]) != kind:
			restantes.append(evento)
			continue
		salida.append(evento)
	_entrantes = restantes
	return _resultado(true, _estado, {"events": salida})


func abrir_sala(scene_key: String, opciones: Dictionary = {}) -> Dictionary:
	if endpoint_url.is_empty():
		return _resultado(false, "unconfigured", {"opened": false})
	if not endpoint_url.begins_with("ws://") and not endpoint_url.begins_with("wss://"):
		return _resultado(false, "invalid_endpoint", {"opened": false})

	var room_id := String(opciones.get("room_id", "")).strip_edges()
	var actor_public_id := String(opciones.get("actor_public_id", "")).strip_edges()
	if scene_key.is_empty() or room_id.is_empty() or actor_public_id.is_empty():
		return _resultado(false, "invalid_room_context", {"opened": false})

	if not _cerrado_voluntario:
		cerrar_sala()
	_reset_sesion()
	_scene_key = scene_key
	_room_id = room_id
	_actor_public_id = actor_public_id
	_cerrado_voluntario = false
	_estado = "connecting"
	_conectar()
	return _resultado(true, _estado, {"opened": false})


func cerrar_sala() -> Dictionary:
	if _cerrado_voluntario:
		return _resultado(true, "inactive", {"closed": true})

	if _socket != null and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_enviar(
			{
				"op": "leave",
				"scene_key": _scene_key,
				"room_id": _room_id,
				"actor_public_id": _actor_public_id,
			}
		)
		_socket.poll()
		_socket.close(-1)

	_cerrado_voluntario = true
	_socket = null
	_reset_sesion()
	_estado = "closed"
	return _resultado(true, "closed", {"closed": true})


func reportar_evento(event_id: String) -> Dictionary:
	return _control_evento("report", event_id)


func ocultar_evento(event_id: String) -> Dictionary:
	return _control_evento("hide", event_id)


func health() -> Dictionary:
	return _resultado(
		not endpoint_url.is_empty(),
		_estado,
		{
			"online": _unido,
			"transport": "websocket",
			"protocol_version": EventoOnline.PROTOCOL_VERSION,
			"queued": _cola_saliente.size(),
			"discarded": _descartados,
			"last_error": _ultimo_error,
		},
	)


func _conectar() -> void:
	if _cerrado_voluntario or endpoint_url.is_empty():
		return

	var socket := WebSocketPeer.new()
	socket.heartbeat_interval = 5.0
	var error := socket.connect_to_url(endpoint_url)
	if error != OK:
		_socket = null
		_estado = "reconnecting"
		_ultimo_error = "connect_%d" % error
		_reintento_restante = REINTENTO_SEGUNDOS
		return

	_socket = socket
	_join_enviado = false
	_unido = false
	_estado = "connecting"
	_ultimo_error = ""


func _marcar_reconexion(motivo: String) -> void:
	if _cerrado_voluntario:
		return
	_socket = null
	_join_enviado = false
	_unido = false
	_estado = "reconnecting"
	_ultimo_error = motivo
	_reintento_restante = REINTENTO_SEGUNDOS


func _mensaje_join() -> Dictionary:
	return {
		"op": "join",
		"protocol_version": EventoOnline.PROTOCOL_VERSION,
		"scene_key": _scene_key,
		"room_id": _room_id,
		"actor_public_id": _actor_public_id,
	}


func _enviar(mensaje: Dictionary) -> bool:
	if _socket == null or _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	var error := _socket.send_text(JSON.stringify(mensaje))
	if error == OK:
		return true
	_ultimo_error = "send_%d" % error
	return false


func _leer_paquetes() -> void:
	if _socket == null:
		return
	while _socket.get_available_packet_count() > 0:
		var paquete := _socket.get_packet()
		if not _socket.was_string_packet():
			_descartados += 1
			continue
		var datos = JSON.parse_string(paquete.get_string_from_utf8())
		if typeof(datos) != TYPE_DICTIONARY:
			_descartados += 1
			continue

		match String(datos.get("op", "")):
			"joined":
				if (
					String(datos.get("scene_key", "")) == _scene_key
					and String(datos.get("room_id", "")) == _room_id
				):
					_unido = true
					_estado = "online"
			"event":
				var evento = datos.get("event")
				if typeof(evento) != TYPE_DICTIONARY:
					_descartados += 1
					continue
				if _entrantes.size() >= MAX_ENTRANTES:
					_entrantes.pop_front()
					_descartados += 1
				_entrantes.append(evento.duplicate(true))
			"error":
				_ultimo_error = String(datos.get("reason", "relay_error"))
				_estado = "relay_error"
			_:
				_descartados += 1


func _encolar_publicacion(mensaje: Dictionary) -> void:
	var evento: Dictionary = mensaje.get("event", {})
	if String(evento.get("kind", "")) == "presence":
		for indice in range(_cola_saliente.size() - 1, -1, -1):
			var anterior: Dictionary = _cola_saliente[indice]
			if String(anterior.get("op", "")) != "publish":
				continue
			var evento_anterior: Dictionary = anterior.get("event", {})
			if (
				String(evento_anterior.get("kind", "")) == "presence"
				and (
					String(evento_anterior.get("actor_public_id", ""))
					== String(evento.get("actor_public_id", ""))
				)
				and (
					String(evento_anterior.get("scene_key", ""))
					== String(evento.get("scene_key", ""))
				)
			):
				_cola_saliente.remove_at(indice)
				break

	_cola_saliente.append(mensaje.duplicate(true))
	while _cola_saliente.size() > MAX_COLA_SALIENTE:
		_cola_saliente.pop_front()
		_descartados += 1


func _vaciar_cola() -> void:
	while _unido and not _cola_saliente.is_empty():
		var mensaje: Dictionary = _cola_saliente[0]
		if not _enviar(mensaje):
			_marcar_reconexion("queue_send_failed")
			return
		_cola_saliente.pop_front()


func _control_evento(op: String, event_id: String) -> Dictionary:
	if _cerrado_voluntario:
		return _resultado(false, "not_in_room", {"delivered": false})
	if event_id.is_empty():
		return _resultado(false, "invalid_event_id", {"delivered": false})
	var mensaje := {"op": op, "event_id": event_id}
	procesar(0.0)
	if _unido and _enviar(mensaje):
		return _resultado(true, "ok", {"delivered": true})
	if _cola_saliente.size() >= MAX_COLA_SALIENTE:
		_cola_saliente.pop_front()
		_descartados += 1
	_cola_saliente.append(mensaje)
	return _resultado(true, _estado, {"delivered": false, "queued": true})


func _reset_sesion() -> void:
	_scene_key = ""
	_room_id = ""
	_actor_public_id = ""
	_join_enviado = false
	_unido = false
	_reintento_restante = 0.0
	_cola_saliente.clear()
	_entrantes.clear()
