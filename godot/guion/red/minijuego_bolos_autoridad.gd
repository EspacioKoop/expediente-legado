class_name MinijuegoBolosAutoridad
extends RefCounted

## Autoridad host de bolos para #383.
## El cliente solo propone apuntado + potencia. La autoridad reutiliza la
## simulación determinista real de BolosPasillo3D y el tanteo puro de Bolos.

const Bolos = preload("res://guion/bolos.gd")
const BolosPasillo3D = preload("res://guion/bolos_pasillo_3d.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")

const MINIGAME_ID := "bolos_pasillo"
const RULES_VERSION := 1
const TIPO_LANZAMIENTO := "roll"
const CAMPOS_ACCION := ["type", "aim", "power"]

var _room_id := ""
var _sesion: Dictionary = {}
var _bolos: Dictionary = {}
var _bolos_en_pie: Array[bool] = []
var _variante := BolosPasillo3D.VARIANTE_ESTRECHO
var _valida := false


func _init(
	room_id: String,
	session_id: String,
	players: Array,
	variante: String = BolosPasillo3D.VARIANTE_ESTRECHO,
) -> void:
	if not BolosPasillo3D.VARIANTES.has(variante):
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
	_bolos = Bolos.nueva(players)
	_variante = variante
	_bolos_en_pie = _rack_nuevo()
	_valida = true
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
	if bool(_bolos.get("terminada", false)) or bool(_bolos.get("abandonada", false)):
		return _rechazo("session_finished")

	var contexto := _validar_contexto_evento(evento, ahora_unix)
	if not contexto["ok"]:
		return _rechazo(contexto["status"], contexto["reason"])

	var normalizado: Dictionary = contexto["event"]
	var payload: Dictionary = normalizado["payload"]
	var validacion_accion := _validar_lanzamiento(payload["action"])
	if not validacion_accion["ok"]:
		return _rechazo("invalid_action", validacion_accion["reason"])

	var simulacion := _simular(
		validacion_accion["aim"],
		validacion_accion["power"],
	)
	if not simulacion["ok"]:
		return _rechazo("simulation_failed", simulacion["reason"])

	var turno_anterior := int(_bolos["turno"])
	var pines_despues: Array = simulacion["pins_standing"]
	Bolos.derribar(_bolos, int(simulacion["knocked"]))
	var terminada := bool(_bolos.get("terminada", false))
	var cambio_turno := int(_bolos.get("turno", 0)) != turno_anterior
	if cambio_turno and not terminada:
		_bolos_en_pie = _rack_nuevo()
	else:
		_bolos_en_pie = _copiar_pines(pines_despues)

	_sesion["sequence"] = int(_sesion["sequence"]) + 1
	_refrescar_snapshot()
	return {
		"ok": true,
		"status": "accepted",
		"roll":
		{
			"actor": String(normalizado["actor_public_id"]),
			"aim": validacion_accion["aim"],
			"power": validacion_accion["power"],
			"knocked": int(simulacion["knocked"]),
			"pins_standing": pines_despues.duplicate(),
			"steps": int(simulacion["steps"]),
		},
		"snapshot": _sesion.duplicate(true),
	}


func abandonar() -> Dictionary:
	if not _valida:
		return _rechazo("invalid_session")
	Bolos.abandonar(_bolos)
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
		razon = "unexpected_roll_fields"
	else:
		for campo in CAMPOS_ACCION:
			if not action.has(campo):
				razon = "missing_%s" % campo
				break

	var apuntado := 0.0
	var potencia := 0.0
	if razon.is_empty():
		if String(action["type"]) != TIPO_LANZAMIENTO:
			razon = "wrong_action_type"
		elif not _es_numero_finito(action["aim"]) or not _es_numero_finito(action["power"]):
			razon = "invalid_roll_number"
		else:
			apuntado = float(action["aim"])
			potencia = float(action["power"])
			if apuntado < -1.0 or apuntado > 1.0:
				razon = "aim_out_of_range"
			elif potencia <= 0.0 or potencia > 1.0:
				razon = "power_out_of_range"

	if not razon.is_empty():
		return {"ok": false, "reason": razon}
	return {
		"ok": true,
		"reason": "",
		"aim": apuntado,
		"power": potencia,
	}


func _simular(apuntado: float, potencia: float) -> Dictionary:
	var simulador := BolosPasillo3D.new()
	simulador.configurar_variante(_variante)
	var resultado := simulador.simular_lanzamiento_autoritativo(
		apuntado,
		potencia,
		_bolos_en_pie,
	)
	simulador.free()
	return resultado


func _refrescar_snapshot() -> void:
	if not _valida:
		return

	var finalizada := (
		bool(_bolos.get("terminada", false)) or bool(_bolos.get("abandonada", false))
	)
	_sesion["phase"] = "finished" if finalizada else "playing"
	_sesion["turn"] = int(_bolos.get("turno", 0))
	_sesion["allowed_actions"] = [] if finalizada else [TIPO_LANZAMIENTO]
	_sesion["result"] = Bolos.resultado(_bolos) if finalizada else {}
	_sesion["state"] = {
		"variant": _variante,
		"current_player": _jugador_actual(),
		"roll": int(_bolos.get("lanzamiento", 0)),
		"scores": _bolos.get("puntuaciones", []).duplicate(),
		"pins_standing": _bolos_en_pie.duplicate(),
		"abandoned": bool(_bolos.get("abandonada", false)),
	}


func _jugador_actual() -> String:
	if bool(_bolos.get("terminada", false)) or bool(_bolos.get("abandonada", false)):
		return ""
	var lanzadores: Array = _bolos.get("lanzadores", [])
	var turno := int(_bolos.get("turno", 0))
	if turno < 0 or turno >= lanzadores.size():
		return ""
	return String(lanzadores[turno])


func _rack_nuevo() -> Array[bool]:
	var salida: Array[bool] = []
	for _indice in Bolos.BOLOS_POR_TURNO:
		salida.append(true)
	return salida


func _copiar_pines(valores: Array) -> Array[bool]:
	var salida: Array[bool] = []
	for valor in valores:
		salida.append(bool(valor))
	return salida


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
