## Regresión ejecutable del trigger de La Fuerza (#1029).
##
##     godot4 --headless --path godot --script pruebas/pruebas_tarot_dificultad_1029.gd
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_cambio_explicito()
	_probar_idempotencia_y_clamp()
	_probar_reinicio_dificil()
	_probar_estado_sin_evento()
	print("tarot_dificultad_1029: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_cambio_explicito() -> void:
	var estado := Partida.nueva()
	_comprobar(estado["dificultad"], "normal", "la partida empieza en normal")
	_comprobar(_recogida(estado, "la-fuerza"), false, "normal no regala La Fuerza")

	var nuevas := Acusacion.cambiar_dificultad(estado, "dificil")
	_comprobar(estado["dificultad"], "dificil", "el cambio queda en el estado canónico")
	_comprobar(estado["vida"], 2, "difícil recorta las vidas al máximo legado")
	_comprobar(nuevas, ["la-fuerza"], "elegir difícil emite La Fuerza")
	_comprobar(_recogida(estado, "la-fuerza"), true, "La Fuerza queda recogida")
	_comprobar(
		estado.get("cartas_conocidas", []).has("la-fuerza"),
		true,
		"La Fuerza entra en memoria fantasma",
	)


func _probar_idempotencia_y_clamp() -> void:
	var estado := Partida.nueva()
	Acusacion.cambiar_dificultad(estado, "dificil")
	_comprobar(
		Acusacion.cambiar_dificultad(estado, "dificil"),
		[],
		"repetir difícil no duplica la adquisición",
	)

	estado["vida"] = 1
	Acusacion.cambiar_dificultad(estado, "facil")
	_comprobar(estado["vida"], 1, "subir el máximo no devuelve vidas perdidas")
	_comprobar(estado["dificultad"], "facil", "el cambio a fácil sí persiste")

	var anterior := estado.duplicate(true)
	_comprobar(
		Acusacion.cambiar_dificultad(estado, "inventada"),
		[],
		"una dificultad desconocida se rechaza",
	)
	_comprobar(estado, anterior, "rechazar una dificultad no muta la partida")


func _probar_reinicio_dificil() -> void:
	var estado := Partida.nueva()
	Acusacion.cambiar_dificultad(estado, "dificil")
	_carta(estado, "la-fuerza")["recogida"] = false
	Prometeo.reiniciar_vuelta(estado, Acusacion.DIFICULTADES["dificil"]["vidas"])
	_comprobar(estado["dificultad"], "dificil", "el despido conserva la dificultad")
	_comprobar(
		_recogida(estado, "la-fuerza"),
		true,
		"una nueva vuelta difícil vuelve a adquirir La Fuerza",
	)


func _probar_estado_sin_evento() -> void:
	var estado := Partida.nueva()
	estado["dificultad"] = "dificil"
	_comprobar(
		_recogida(estado, "la-fuerza"),
		false,
		"tener difícil en el estado no concede nada sin un evento real",
	)


func _carta(estado: Dictionary, carta_id: String) -> Dictionary:
	for carta in estado.get("tarot", []):
		if String(carta.get("id", "")) == carta_id:
			return carta
	return {}


func _recogida(estado: Dictionary, carta_id: String) -> bool:
	return bool(_carta(estado, carta_id).get("recogida", false))


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #1029: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
