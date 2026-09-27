class_name MinijuegoGolfAutoridad
extends RefCounted

## Autoridad host del primer vertical de #383.
## Reutiliza Golf + GolfBola: el cliente solo propone un tiro y la autoridad
## calcula trayectoria, golpes, cambio de turno y resultado.

const Golf = preload("res://guion/golf.gd")
const GolfBola = preload("res://guion/golf_bola.gd")
const MinijuegoSesionDatos = preload("res://guion/red/minijuego_sesion_datos.gd")

const MINIGAME_ID := "golf_pasillo"
const RULES_VERSION := 1
const TIPO_TIRO := "shot"

var _room_id := ""
var _sesion: Dictionary = {}
var _golf: Dictionary = {}
var _bolas: Dictionary = {}
var _configuraciones: Array = []
var _valida := false


func _init(
	room_id: String,
	session_id: String,
	players: Array,
	configuraciones: Array,
) -> void:
	if room_id.is_empty():
		return
	if configuraciones.size() != Golf.HOYOS:
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

	var normalizadas := _normalizar_configuraciones(configuraciones)
	if normalizadas.size() != Golf.HOYOS:
		return

	_room_id = room_id
	_sesion = sesion
	_golf = Golf.nueva(players)
	_configuraciones = normalizadas
	_valida = true
	_reiniciar_bolas()
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
	if bool(_golf.get("terminada", false)):
		return _rechazo("session_finished")

	var contexto := _validar_contexto_evento(evento, ahora_unix)
	if not contexto["ok"]:
		return _rechazo(contexto["status"], contexto["reason"])

	var normalizado: Dictionary = contexto["event"]
	var payload: Dictionary = normalizado["payload"]
	var validacion_tiro := _validar_tiro(payload["action"])
	if not validacion_tiro["ok"]:
		return _rechazo("invalid_action", validacion_tiro["reason"])

	var esperado := int(_sesion["sequence"])
	var hoyo_antes := int(_golf["hoyo"])
	var resultado_tiro := _ejecutar_tiro(
		String(normalizado["actor_public_id"]),
		validacion_tiro["direction"],
		validacion_tiro["power"],
	)
	if not resultado_tiro["ok"]:
		return resultado_tiro

	_sesion["sequence"] = esperado + 1
	if int(_golf["hoyo"]) != hoyo_antes and not bool(_golf.get("terminada", false)):
		_reiniciar_bolas()
	_refrescar_snapshot()
	return {
		"ok": true,
		"status": "accepted",
		"shot": resultado_tiro["shot"],
		"snapshot": _sesion.duplicate(true),
	}


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
		elif String(normalizado["actor_public_id"]) != Golf.jugador_actual(_golf):
			status = "not_actor_turn"

	if not status.is_empty():
		return {"ok": false, "status": status, "reason": "", "event": {}}
	return {"ok": true, "status": "ok", "reason": "", "event": normalizado}


func abandonar() -> Dictionary:
	if not _valida:
		return _rechazo("invalid_session")
	Golf.abandonar(_golf)
	_refrescar_snapshot()
	return {"ok": true, "status": "abandoned", "snapshot": _sesion.duplicate(true)}


func _ejecutar_tiro(actor: String, direccion: Vector2, potencia: float) -> Dictionary:
	var bola: Dictionary = _bolas.get(actor, {})
	if bola.is_empty():
		return _rechazo("missing_ball")

	GolfBola.golpear(bola, direccion, potencia)
	if GolfBola.detenida(bola):
		return _rechazo("shot_not_started")
	GolfBola.simular_hasta_detener(bola)
	_bolas[actor] = bola

	var hoyo_antes := int(_golf["hoyo"])
	Golf.golpear(_golf, actor)

	var posicion: Vector2 = bola.get("posicion", Vector2.ZERO)
	var configuracion := _configuracion(hoyo_antes)
	var entro := false
	if int(_golf.get("hoyo", 0)) == hoyo_antes and Golf.jugador_actual(_golf) == actor:
		var objetivo: Vector2 = configuracion["objetivo"]
		var radio := float(configuracion["radio_objetivo"])
		if posicion.distance_to(objetivo) <= radio:
			entro = true
			Golf.terminar_hoyo(_golf, actor)

	return {
		"ok": true,
		"status": "accepted",
		"shot":
		{
			"actor": actor,
			"hole": hoyo_antes,
			"position": [posicion.x, posicion.y],
			"holed": entro,
		},
	}


func _validar_tiro(action: Dictionary) -> Dictionary:
	var razon := ""
	var direccion = []
	var vector := Vector2.ZERO
	var potencia := 0.0
	var esperadas := ["type", "direction", "power"]

	if action.size() != esperadas.size():
		razon = "unexpected_shot_fields"
	else:
		for campo in esperadas:
			if not action.has(campo):
				razon = "missing_%s" % campo
				break

	if razon.is_empty() and String(action["type"]) != TIPO_TIRO:
		razon = "wrong_action_type"

	if razon.is_empty():
		direccion = action["direction"]
		if typeof(direccion) != TYPE_ARRAY or direccion.size() != 2:
			razon = "invalid_direction"
		elif not _numero(direccion[0]) or not _numero(direccion[1]):
			razon = "invalid_direction"

	if razon.is_empty():
		var x := float(direccion[0])
		var y := float(direccion[1])
		if is_nan(x) or is_inf(x) or is_nan(y) or is_inf(y):
			razon = "invalid_direction"
		else:
			vector = Vector2(x, y)
			if vector.length_squared() <= 0.000001:
				razon = "zero_direction"

	if razon.is_empty():
		if not _numero(action["power"]):
			razon = "invalid_power"
		else:
			potencia = float(action["power"])
			if is_nan(potencia) or is_inf(potencia) or potencia <= 0.0 or potencia > 1.0:
				razon = "invalid_power"

	if not razon.is_empty():
		return {"ok": false, "reason": razon}
	return {"ok": true, "reason": "", "direction": vector, "power": potencia}


func _normalizar_configuraciones(configuraciones: Array) -> Array:
	var salida: Array = []
	for valor in configuraciones:
		var normalizada := _normalizar_configuracion(valor)
		if normalizada.is_empty():
			return []
		salida.append(normalizada)
	return salida


func _normalizar_configuracion(valor: Variant) -> Dictionary:
	if typeof(valor) != TYPE_DICTIONARY:
		return {}

	var config: Dictionary = valor
	var inicio = config.get("inicio")
	var objetivo = config.get("objetivo")
	var limite = config.get("limite", GolfBola.LIMITES_POR_DEFECTO)
	var obstaculos = config.get("obstaculos", [])
	var valido := typeof(inicio) == TYPE_VECTOR2 and typeof(objetivo) == TYPE_VECTOR2
	valido = valido and typeof(limite) == TYPE_RECT2 and typeof(obstaculos) == TYPE_ARRAY

	var recta := Rect2()
	var radio := float(config.get("radio_objetivo", 0.12))
	var obstaculos_validos: Array = []
	if valido:
		recta = limite
		valido = recta.size.x > GolfBola.RADIO_BOLA * 2.0
		valido = valido and recta.size.y > GolfBola.RADIO_BOLA * 2.0
		valido = valido and radio >= GolfBola.RADIO_BOLA * 1.5 and radio <= 0.35

	if valido:
		for obstaculo in obstaculos:
			if typeof(obstaculo) != TYPE_RECT2:
				valido = false
				break
			var caja: Rect2 = obstaculo
			if caja.size.x <= 0.0 or caja.size.y <= 0.0:
				valido = false
				break
			obstaculos_validos.append(caja)

	if not valido:
		return {}
	return {
		"inicio": inicio,
		"objetivo": objetivo,
		"limite": recta,
		"radio_objetivo": radio,
		"obstaculos": obstaculos_validos,
	}


func _reiniciar_bolas() -> void:
	_bolas.clear()
	if bool(_golf.get("terminada", false)):
		return
	var config := _configuracion(int(_golf["hoyo"]))
	for player in _golf.get("jugadores", []):
		_bolas[String(player)] = (
			GolfBola
			. nueva(
				config["inicio"],
				config["limite"],
				config["obstaculos"],
			)
		)


func _configuracion(indice: int) -> Dictionary:
	if indice < 0 or indice >= _configuraciones.size():
		return {}
	return _configuraciones[indice]


func _refrescar_snapshot() -> void:
	if not _valida:
		return

	var terminada := bool(_golf.get("terminada", false))
	_sesion["phase"] = "finished" if terminada else "playing"
	_sesion["turn"] = int(_golf.get("turno", 0))
	_sesion["allowed_actions"] = [] if terminada else [TIPO_TIRO]
	_sesion["result"] = Golf.resultado(_golf) if terminada else {}

	var posiciones := {}
	for player in _bolas:
		var posicion: Vector2 = _bolas[player].get("posicion", Vector2.ZERO)
		posiciones[player] = [posicion.x, posicion.y]

	_sesion["state"] = {
		"hole": int(_golf.get("hoyo", 0)),
		"current_player": Golf.jugador_actual(_golf),
		"cards": _golf.get("tarjetas", {}).duplicate(true),
		"strokes_current": _golf.get("golpes_hoyo", {}).duplicate(true),
		"ball_positions": posiciones,
		"abandoned": bool(_golf.get("abandonada", false)),
	}


func _numero(valor: Variant) -> bool:
	return typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT


func _rechazo(status: String, reason: String = "") -> Dictionary:
	return {
		"ok": false,
		"status": status,
		"reason": reason,
		"snapshot": snapshot(),
	}
