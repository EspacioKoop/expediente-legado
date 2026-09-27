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

	var sesion := MinijuegoSesionDatos.nueva_sesion(
		session_id,
		MINIGAME_ID,
		RULES_VERSION,
		players,
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

	var validacion := MinijuegoSesionDatos.validar_evento(evento, ahora_unix)
	if not validacion["ok"]:
		return _rechazo("invalid_event", validacion["reason"])

	var normalizado: Dictionary = validacion["event"]
	var payload: Dictionary = normalizado["payload"]
	if String(payload["room_id"]) != _room_id:
		return _rechazo("wrong_room")
	if String(payload["session_id"]) != String(_sesion["session_id"]):
		return _rechazo("wrong_session")
	if String(payload["minigame_id"]) != MINIGAME_ID:
		return _rechazo("wrong_minigame")
	if int(payload["rules_version"]) != RULES_VERSION:
		return _rechazo("incompatible_rules")

	var sequence := int(payload["sequence"])
	var esperado := int(_sesion["sequence"])
	if sequence < esperado:
		return _rechazo("late_or_duplicate")
	if sequence > esperado:
		return _rechazo("out_of_order")
	if int(payload["turn"]) != int(_sesion["turn"]):
		return _rechazo("wrong_turn")

	var actor := String(normalizado["actor_public_id"])
	if actor != Golf.jugador_actual(_golf):
		return _rechazo("not_actor_turn")

	var validacion_tiro := _validar_tiro(payload["action"])
	if not validacion_tiro["ok"]:
		return _rechazo("invalid_action", validacion_tiro["reason"])

	var hoyo_antes := int(_golf["hoyo"])
	var resultado_tiro := _ejecutar_tiro(actor, validacion_tiro["direction"], validacion_tiro["power"])
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
	var esperadas := ["type", "direction", "power"]
	if action.size() != esperadas.size():
		return {"ok": false, "reason": "unexpected_shot_fields"}
	for campo in esperadas:
		if not action.has(campo):
			return {"ok": false, "reason": "missing_%s" % campo}
	if String(action["type"]) != TIPO_TIRO:
		return {"ok": false, "reason": "wrong_action_type"}

	var direccion = action["direction"]
	if typeof(direccion) != TYPE_ARRAY or direccion.size() != 2:
		return {"ok": false, "reason": "invalid_direction"}
	if not _numero(direccion[0]) or not _numero(direccion[1]):
		return {"ok": false, "reason": "invalid_direction"}
	var x := float(direccion[0])
	var y := float(direccion[1])
	if is_nan(x) or is_inf(x) or is_nan(y) or is_inf(y):
		return {"ok": false, "reason": "invalid_direction"}
	var vector := Vector2(x, y)
	if vector.length_squared() <= 0.000001:
		return {"ok": false, "reason": "zero_direction"}

	if not _numero(action["power"]):
		return {"ok": false, "reason": "invalid_power"}
	var potencia := float(action["power"])
	if is_nan(potencia) or is_inf(potencia) or potencia <= 0.0 or potencia > 1.0:
		return {"ok": false, "reason": "invalid_power"}

	return {"ok": true, "reason": "", "direction": vector, "power": potencia}


func _normalizar_configuraciones(configuraciones: Array) -> Array:
	var salida: Array = []
	for valor in configuraciones:
		if typeof(valor) != TYPE_DICTIONARY:
			return []
		var config: Dictionary = valor
		var inicio = config.get("inicio")
		var objetivo = config.get("objetivo")
		if typeof(inicio) != TYPE_VECTOR2 or typeof(objetivo) != TYPE_VECTOR2:
			return []

		var limite = config.get("limite", GolfBola.LIMITES_POR_DEFECTO)
		if typeof(limite) != TYPE_RECT2:
			return []
		var recta: Rect2 = limite
		if recta.size.x <= GolfBola.RADIO_BOLA * 2.0:
			return []
		if recta.size.y <= GolfBola.RADIO_BOLA * 2.0:
			return []

		var radio := float(config.get("radio_objetivo", 0.12))
		if radio < GolfBola.RADIO_BOLA * 1.5 or radio > 0.35:
			return []

		var obstaculos = config.get("obstaculos", [])
		if typeof(obstaculos) != TYPE_ARRAY:
			return []
		var obstaculos_validos: Array = []
		for obstaculo in obstaculos:
			if typeof(obstaculo) != TYPE_RECT2:
				return []
			var caja: Rect2 = obstaculo
			if caja.size.x <= 0.0 or caja.size.y <= 0.0:
				return []
			obstaculos_validos.append(caja)

		salida.append(
			{
				"inicio": inicio,
				"objetivo": objetivo,
				"limite": recta,
				"radio_objetivo": radio,
				"obstaculos": obstaculos_validos,
			}
		)
	return salida


func _reiniciar_bolas() -> void:
	_bolas.clear()
	if bool(_golf.get("terminada", false)):
		return
	var config := _configuracion(int(_golf["hoyo"]))
	for player in _golf.get("jugadores", []):
		_bolas[String(player)] = GolfBola.nueva(
			config["inicio"],
			config["limite"],
			config["obstaculos"],
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
