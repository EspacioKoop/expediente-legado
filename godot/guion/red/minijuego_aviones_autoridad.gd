class_name MinijuegoAvionesAutoridad
extends RefCounted

## Autoridad determinista de aviones de papel para el contrato común de #383.
## Reutiliza AvionesPapel (#160): el cliente solo propone parámetros de
## lanzamiento y la autoridad calcula trayectoria, puntuación, turno y final.

const AvionesPapel = preload("res://guion/aviones_papel.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")

const MINIGAME_ID := "aviones_papel"
const RULES_VERSION := 1
const TIPO_LANZAMIENTO := "launch"
const CAMPOS_ACCION := ["type", "model", "direction", "height", "power"]

var _room_id := ""
var _sesion: Dictionary = {}
var _aviones: Dictionary = {}
var _valida := false


func _init(
	room_id: String,
	session_id: String,
	players: Array,
	modalidad: String = "distancia",
) -> void:
	if room_id.is_empty():
		return
	var sesion := (
		MinijuegoSesionDatos
		. nueva_sesion(
			session_id,
			MINIGAME_ID,
			RULES_VERSION,
			players,
		)
	)
	if sesion.is_empty():
		return
	var contexto := (
		MinijuegoSesionDatos
		. validar_payload(
			{
				"room_id": room_id,
				"session_id": session_id,
				"minigame_id": MINIGAME_ID,
				"rules_version": RULES_VERSION,
				"sequence": 0,
				"turn": 0,
				"action": {"type": TIPO_LANZAMIENTO},
			}
		)
	)
	if not contexto["ok"]:
		return

	_room_id = room_id
	_sesion = sesion
	_aviones = AvionesPapel.nueva(players, modalidad)
	_valida = not bool(_aviones.get("terminada", true))
	_refrescar_snapshot()


func valida() -> bool:
	return _valida


func snapshot() -> Dictionary:
	if not _valida:
		return {}
	_refrescar_snapshot()
	return _sesion.duplicate(true)


func aplicar_evento(evento: Variant, ahora_unix: int) -> Dictionary:
	if not _valida:
		return _rechazo("invalid_session")
	if bool(_aviones.get("terminada", false)) or bool(_aviones.get("abandonada", false)):
		return _rechazo("session_finished")

	var contexto := _validar_contexto_evento(evento, ahora_unix)
	if not contexto["ok"]:
		return _rechazo(contexto["status"], contexto["reason"])

	var normalizado: Dictionary = contexto["event"]
	var payload: Dictionary = normalizado["payload"]
	var validacion_accion := _validar_lanzamiento(payload["action"])
	if not validacion_accion["ok"]:
		return _rechazo("invalid_action", validacion_accion["reason"])

	var actor := String(normalizado["actor_public_id"])
	var vuelos_actor: Array = _aviones["resultados"].get(actor, [])
	var cantidad_antes := vuelos_actor.size()
	(
		AvionesPapel
		. lanzar(
			_aviones,
			validacion_accion["model"],
			validacion_accion["direction"],
			validacion_accion["height"],
			validacion_accion["power"],
		)
	)
	var resultados_despues: Array = _aviones["resultados"].get(actor, [])
	if resultados_despues.size() <= cantidad_antes:
		return _rechazo("launch_not_applied")

	var vuelo: Dictionary = resultados_despues[-1]
	_sesion["sequence"] = int(_sesion["sequence"]) + 1
	_refrescar_snapshot()
	return {
		"ok": true,
		"status": "accepted",
		"flight": _serializar_vuelo(vuelo),
		"snapshot": _sesion.duplicate(true),
	}


func abandonar() -> Dictionary:
	if not _valida:
		return _rechazo("invalid_session")
	AvionesPapel.abandonar(_aviones)
	_refrescar_snapshot()
	return {"ok": true, "status": "abandoned", "snapshot": _sesion.duplicate(true)}


func _validar_contexto_evento(evento: Variant, ahora_unix: int) -> Dictionary:
	var validacion := MinijuegoSesionDatos.validar_evento(evento, ahora_unix)
	if not validacion["ok"]:
		return {
			"ok": false,
			"status": "invalid_event",
			"reason": validacion["reason"],
			"event": {},
		}

	var normalizado: Dictionary = validacion["event"]
	var payload: Dictionary = normalizado["payload"]
	var status := ""
	if String(payload["room_id"]) != _room_id:
		status = "wrong_room"
	elif String(payload["session_id"]) != String(_sesion["session_id"]):
		status = "wrong_session"
	elif String(payload["minigame_id"]) != MINIGAME_ID:
		status = "wrong_minigame"
	elif int(payload["rules_version"]) != RULES_VERSION:
		status = "incompatible_rules"
	else:
		var sequence := int(payload["sequence"])
		var esperado := int(_sesion["sequence"])
		if sequence < esperado:
			status = "late_or_duplicate"
		elif sequence > esperado:
			status = "out_of_order"
		elif int(payload["turn"]) != int(_sesion["turn"]):
			status = "wrong_turn"
		elif String(normalizado["actor_public_id"]) != _jugador_actual():
			status = "not_actor_turn"

	if not status.is_empty():
		return {"ok": false, "status": status, "reason": "", "event": {}}
	return {"ok": true, "status": "ok", "reason": "", "event": normalizado}


func _validar_lanzamiento(action: Dictionary) -> Dictionary:
	var razon := ""
	if action.size() != CAMPOS_ACCION.size():
		razon = "unexpected_launch_fields"
	else:
		for campo in CAMPOS_ACCION:
			if not action.has(campo):
				razon = "missing_%s" % campo
				break

	var modelo := ""
	var direccion := 0.0
	var altura := 0.0
	var potencia := 0.0
	if razon.is_empty():
		if String(action["type"]) != TIPO_LANZAMIENTO:
			razon = "wrong_action_type"
		else:
			modelo = String(action["model"])
			if not AvionesPapel.MODELOS.has(modelo):
				razon = "invalid_model"

	if razon.is_empty():
		var numeros := [action["direction"], action["height"], action["power"]]
		if not numeros.all(func(valor): return _es_numero_finito(valor)):
			razon = "invalid_launch_number"
		else:
			direccion = float(action["direction"])
			altura = float(action["height"])
			potencia = float(action["power"])
			if direccion < -1.0 or direccion > 1.0:
				razon = "direction_out_of_range"
			elif altura < -20.0 or altura > 55.0:
				razon = "height_out_of_range"
			elif potencia < 0.0 or potencia > 1.0:
				razon = "power_out_of_range"

	if not razon.is_empty():
		return {"ok": false, "reason": razon}
	return {
		"ok": true,
		"reason": "",
		"model": modelo,
		"direction": direccion,
		"height": altura,
		"power": potencia,
	}


func _refrescar_snapshot() -> void:
	if not _valida:
		return
	var finalizada := (
		bool(_aviones.get("terminada", false)) or bool(_aviones.get("abandonada", false))
	)
	_sesion["phase"] = "finished" if finalizada else "playing"
	_sesion["turn"] = int(_aviones.get("turno", 0))
	_sesion["allowed_actions"] = [] if finalizada else [TIPO_LANZAMIENTO]
	_sesion["result"] = AvionesPapel.resultado(_aviones) if finalizada else {}
	_sesion["state"] = {
		"mode": String(_aviones.get("modalidad", "distancia")),
		"current_player": _jugador_actual(),
		"launch": int(_aviones.get("lanzamiento", 0)),
		"scores": _puntuaciones_actuales(),
		"results": _serializar_resultados(),
		"abandoned": bool(_aviones.get("abandonada", false)),
	}


func _jugador_actual() -> String:
	if bool(_aviones.get("terminada", false)) or bool(_aviones.get("abandonada", false)):
		return ""
	var participantes: Array = _aviones.get("participantes", [])
	var turno := int(_aviones.get("turno", 0))
	if turno < 0 or turno >= participantes.size():
		return ""
	return String(participantes[turno])


func _puntuaciones_actuales() -> Dictionary:
	var totales := {}
	for actor in _aviones.get("resultados", {}):
		var puntos := 0.0
		for vuelo in _aviones["resultados"][actor]:
			puntos += float(vuelo.get("puntos", 0.0))
		totales[String(actor)] = puntos
	return totales


func _serializar_resultados() -> Dictionary:
	var salida := {}
	for actor in _aviones.get("resultados", {}):
		var vuelos: Array = []
		for vuelo in _aviones["resultados"][actor]:
			vuelos.append(_serializar_vuelo(vuelo))
		salida[String(actor)] = vuelos
	return salida


func _serializar_vuelo(vuelo: Dictionary) -> Dictionary:
	var posicion: Vector3 = vuelo.get("posicion", Vector3.ZERO)
	return {
		"model": String(vuelo.get("modelo", "")),
		"position": [posicion.x, posicion.y, posicion.z],
		"distance": float(vuelo.get("distancia", 0.0)),
		"precision": float(vuelo.get("precision", 0.0)),
		"zone": bool(vuelo.get("zona", false)),
		"time": float(vuelo.get("tiempo", 0.0)),
		"reason": String(vuelo.get("motivo", "")),
		"points": float(vuelo.get("puntos", 0.0)),
	}


func _es_numero_finito(valor: Variant) -> bool:
	if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
		return false
	var numero := float(valor)
	return not is_nan(numero) and not is_inf(numero)


func _rechazo(status: String, reason: String = "") -> Dictionary:
	return {
		"ok": false,
		"status": status,
		"reason": reason,
		"snapshot": snapshot(),
	}
