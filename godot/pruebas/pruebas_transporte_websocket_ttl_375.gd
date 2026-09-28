extends SceneTree

const TransporteWebSocket = preload("res://guion/red/transporte_websocket.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_expirado_se_descarta()
	_probar_fresco_permanece_si_no_hay_socket()
	_probar_control_no_se_trata_como_evento()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _evento(creado: int, expira: int, version: int = EventoOnline.PROTOCOL_VERSION) -> Dictionary:
	return {
		"protocol_version": version,
		"kind": "signal",
		"game_build": "test-375",
		"scene_key": "trayecto",
		"created_at": creado,
		"expires_at": expira,
		"actor_public_id": "anon-test",
		"payload": {"anchor_id": "portal"},
	}


func _probar_expirado_se_descarta() -> void:
	var transporte := TransporteWebSocket.new()
	transporte._unido = true
	transporte._cola_saliente.append({"op": "publish", "event": _evento(100, 110)})
	transporte._vaciar_cola(111)
	var salud := transporte.health()
	_comprobar(int(salud["queued"]) == 0, "un evento expirado sale de la cola")
	_comprobar(int(salud["discarded"]) == 1, "el descarte queda contabilizado")
	_comprobar(transporte._unido, "descartar por TTL no fuerza una reconexión")


func _probar_fresco_permanece_si_no_hay_socket() -> void:
	var transporte := TransporteWebSocket.new()
	transporte._unido = true
	transporte._cola_saliente.append({"op": "publish", "event": _evento(100, 200)})
	transporte._vaciar_cola(150)
	var salud := transporte.health()
	_comprobar(int(salud["queued"]) == 1, "un evento fresco no se descarta por TTL")
	_comprobar(int(salud["discarded"]) == 0, "fallar el envío no cuenta como TTL inválido")


func _probar_control_no_se_trata_como_evento() -> void:
	var transporte := TransporteWebSocket.new()
	transporte._unido = true
	transporte._cola_saliente.append({"op": "hide", "event_id": "evt-1"})
	transporte._vaciar_cola(999)
	var salud := transporte.health()
	_comprobar(int(salud["queued"]) == 1, "un control sin TTL permanece pendiente")
	_comprobar(int(salud["discarded"]) == 0, "un control no se valida como publicación")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO transporte WebSocket #375: " + nombre)
