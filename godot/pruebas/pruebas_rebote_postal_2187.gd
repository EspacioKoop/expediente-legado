extends SceneTree

const REGLAS := preload("res://guion/rebote_postal.gd")
const APP := preload("res://guion/rebote_postal_app.gd")
const SELECTOR := preload("res://guion/turno_serpiente_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _comprobar(valor: bool, mensaje: String) -> void:
	if valor:
		_pasadas += 1
	else:
		_fallos += 1
		printerr(mensaje)


func _ejecutar() -> void:
	var juego := REGLAS.new()
	juego.nueva()
	_comprobar(
		juego.paquetes.size() == 18 and juego.vidas == 3, "Inicio con 18 paquetes y 3 pelotas"
	)
	juego.avanzar(1.0)
	_comprobar(juego.pelota == Vector2(480, 524), "Sin saque no se mueve la pelota")
	juego.avanzar(0.1, -1)
	_comprobar(
		is_equal_approx(juego.pelota.x, juego.pala) and juego.pala < 480, "Saque sigue la pala"
	)
	_comprobar(juego.sacar() and not juego.sacar(), "Un único saque")
	var posicion := juego.pelota
	juego.pausar()
	juego.avanzar(10.0, 1)
	_comprobar(juego.pelota == posicion and juego.fase == "pausa", "Pausa inmóvil")
	juego.pausar()
	juego.pelota = Vector2(9, 350)
	juego.velocidad = Vector2(-330, 0)
	juego.avanzar(REGLAS.PASO)
	_comprobar(juego.pelota.x >= REGLAS.RADIO and juego.velocidad.x > 0, "Pared devuelve pelota")
	juego.pelota = Vector2(juego.pala + 50, 530)
	juego.velocidad = Vector2(0, 330)
	juego.avanzar(REGLAS.PASO)
	_comprobar(juego.velocidad.y < 0 and juego.velocidad.x > 0, "Pala dirige rebote por impacto")
	var primero: Rect2 = juego.paquetes[0]
	juego.pelota = Vector2(primero.get_center().x, primero.end.y + REGLAS.RADIO + 1)
	juego.velocidad = Vector2(0, -330)
	var eventos := juego.avanzar(REGLAS.PASO)
	_comprobar(
		eventos.has("paquete") and juego.puntos == 100 and juego.paquetes.size() == 17,
		"Entrega puntúa una vez"
	)
	for restantes in [2, 1, 0]:
		juego.fase = "jugando"
		juego.pelota = Vector2(10, 607)
		juego.velocidad = Vector2(0, 330)
		juego.avanzar(REGLAS.PASO)
		_comprobar(juego.vidas == restantes, "Una pérdida por caída")
	_comprobar(juego.fase == "derrota" and juego.puntos == 100, "Derrota conserva marcador")
	juego.avanzar(10)
	_comprobar(juego.vidas == 0, "Derrota no pierde más pelotas")
	juego.nueva()
	_comprobar(juego.puntos == 0 and juego.nivel == 1 and juego.vidas == 3, "Revancha limpia")
	var rapido := juego.rapidez()
	juego.tranquilo = true
	_comprobar(juego.rapidez() < rapido, "Modo tranquilo real")
	juego.tranquilo = false
	_comprobar(_resolver(juego), "Partida completa real con piloto de pala")
	_comprobar(
		juego.fase == "victoria" and juego.puntos == 6200 and juego.nivel == 3,
		"62 paquetes hasta victoria"
	)
	_comprobar(not juego.siguiente(), "Victoria no abre cuarto nivel")
	var uno := REGLAS.new()
	var dos := REGLAS.new()
	uno.nueva()
	dos.nueva()
	uno.sacar()
	dos.sacar()
	for _i in range(60):
		uno.avanzar(REGLAS.PASO)
	for _i in range(30):
		dos.avanzar(REGLAS.PASO * 2)
	_comprobar(uno.pelota.distance_to(dos.pelota) < 0.001, "Paso fijo independiente de agrupación")
	await _probar_ui()
	print("Rebote Postal: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(0 if _fallos == 0 else 1)


func _resolver(juego: RefCounted) -> bool:
	for i in range(180000):
		if juego.fase == "victoria":
			return true
		if juego.fase == "derrota":
			return false
		if juego.fase == "nivel_completo":
			juego.siguiente()
		if juego.fase == "listo":
			juego.sacar()
		var objetivo: float = juego.pelota.x - sin(i * 0.017) * 45
		var eje := clampf((objetivo - juego.pala) / (650.0 * REGLAS.PASO), -1, 1)
		juego.avanzar(REGLAS.PASO, eje)
	return false


func _probar_ui() -> void:
	for accion in ["cancelar", "interactuar", "mover_izquierda", "mover_derecha"]:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
	var raton := Input.mouse_mode
	var selector := SELECTOR.new()
	selector.modo_consola = true
	root.add_child(selector)
	var elegidos := [0]
	selector.rebote_solicitado.connect(func(): elegidos[0] += 1)
	selector._menu_rebote.pressed.emit()
	_comprobar(elegidos[0] == 1 and not paused, "Selector entrega nuevo arcade y restaura")
	await process_frame
	var app := APP.new()
	app.modo_consola = true
	root.add_child(app)
	app.set_process(false)
	_comprobar(paused and app.juego.fase == "listo", "Arcade pausa el mundo")
	app._lento.button_pressed = true
	app._principal.pressed.emit()
	_comprobar(app.juego.fase == "jugando" and app.juego.tranquilo, "Saque por UI aplica ritmo")
	app._izquierda = true
	app._process(0.05)
	_comprobar(app.juego.pala < 480, "Botón de movimiento mantiene pala")
	var evento := InputEventAction.new()
	evento.action = "interactuar"
	evento.pressed = true
	app._input(evento)
	_comprobar(app.juego.fase == "pausa", "Pausa semántica")
	app._principal.pressed.emit()
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_comprobar(
		app.juego.fase == "pausa" and not app._izquierda, "Perder foco pausa y suelta dirección"
	)
	app._principal.pressed.emit()
	app.juego.vidas = 1
	app.juego.pelota = Vector2(10, 607)
	app.juego.velocidad = Vector2(0, 330)
	app._process(0.02)
	_comprobar(app.juego.fase == "derrota", "Derrota llega a UI por física")
	app._principal.pressed.emit()
	_comprobar(app.juego.vidas == 3 and app.juego.fase == "listo", "Revancha por UI")
	_comprobar(_resolver(app.juego), "Tres niveles completables desde sesión UI")
	app._refrescar()
	_comprobar(app._estado.text == app._texto("victoria"), "Final traducido visible")
	app._principal.pressed.emit()
	_comprobar(app.juego.fase == "listo" and app.juego.puntos == 0, "Revancha tras victoria")
	var vuelta := [0]
	app.menu_solicitado.connect(func(): vuelta[0] += 1)
	app._volver_menu()
	_comprobar(
		vuelta[0] == 1 and not paused and Input.mouse_mode == raton,
		"Retorno al selector restaura host"
	)
	await process_frame
	paused = true
	var segundo := APP.new()
	root.add_child(segundo)
	segundo.free()
	_comprobar(paused, "Salida inesperada conserva pausa previa")
	paused = false
	var tercero := APP.new()
	root.add_child(tercero)
	var cierres := [0]
	tercero.cerrado.connect(func(): cierres[0] += 1)
	evento.action = "cancelar"
	tercero._input(evento)
	tercero.cerrar()
	_comprobar(not paused and cierres[0] == 1, "Cancelación semántica e idempotente")
	await process_frame
