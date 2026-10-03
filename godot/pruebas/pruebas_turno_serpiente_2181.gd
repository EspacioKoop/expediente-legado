extends SceneTree

const REGLAS := preload("res://guion/turno_serpiente.gd")
const APP := preload("res://guion/turno_serpiente_app.gd")

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
	_comprobar(juego.avanzar() == "quieto", "El título no mueve la cola")
	juego.iniciar()
	_comprobar(not juego.girar(Vector2i.LEFT), "No admite marcha atrás")
	_comprobar(juego.girar(Vector2i.UP), "Primer giro aceptado")
	_comprobar(not juego.girar(Vector2i.LEFT), "Bloquea segundo giro en el mismo tick")
	juego.avanzar()
	_comprobar(juego.cuerpo[0] == Vector2i(5, 6), "Aplica un único giro")
	juego.pausar()
	var cabeza: Vector2i = juego.cuerpo[0]
	_comprobar(juego.avanzar() == "quieto" and juego.cuerpo[0] == cabeza, "Pausa inmóvil")
	juego.pausar()
	juego.cuerpo.assign([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	juego.direccion = Vector2i.LEFT
	juego.pendiente = Vector2i.LEFT
	_comprobar(juego.avanzar() == "choque" and juego.fase == "derrota", "Borde da derrota")
	juego.nueva()
	juego.iniciar()
	juego.cuerpo.assign([Vector2i(5, 5), Vector2i(5, 6), Vector2i(4, 6), Vector2i(4, 5)])
	juego.direccion = Vector2i.LEFT
	juego.pendiente = Vector2i.LEFT
	juego.sello = Vector2i(15, 10)
	_comprobar(juego.avanzar() == "paso", "Permite entrar en la cola que se vacía")
	juego.cuerpo.assign([Vector2i(5, 5), Vector2i(4, 5), Vector2i(4, 6), Vector2i(5, 6)])
	juego.direccion = Vector2i.LEFT
	juego.pendiente = Vector2i.LEFT
	_comprobar(juego.avanzar() == "choque", "El cuerpo sólido da derrota")
	juego.nueva()
	var otro := REGLAS.new()
	otro.nueva()
	_comprobar(juego.sello == otro.sello, "Semilla repetible")
	_comprobar(_resolver(juego), "Partida real completa de tres turnos con BFS")
	_comprobar(juego.puntos == 3600 and juego.fase == "victoria", "Victoria y puntuación exactas")
	_comprobar(not juego.siguiente(), "No existe cuarto turno")
	juego.nueva()
	_comprobar(juego.puntos == 0 and juego.nivel == 1, "Revancha limpia")
	# Obstáculos se verifican en una nueva preparación del segundo turno.
	juego.nueva()
	juego.fase = "nivel_completo"
	juego.siguiente()
	juego.iniciar()
	juego.cuerpo.assign([Vector2i(9, 3), Vector2i(8, 3), Vector2i(7, 3)])
	_comprobar(juego.avanzar() == "choque", "Archivador sólido da derrota")
	_comprobar(juego.intervalo(true) > juego.intervalo(false), "Ritmo tranquilo ralentiza")
	await _probar_ui()
	print("Turno Serpiente: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(0 if _fallos == 0 else 1)


func _resolver(juego: RefCounted) -> bool:
	for _tick in range(2000):
		if juego.fase == "victoria":
			return true
		if juego.fase == "nivel_completo":
			juego.siguiente()
		if juego.fase == "preparado":
			juego.iniciar()
		if juego.fase != "jugando":
			return false
		if juego.cuerpo.has(juego.sello) or juego.paredes.has(juego.sello):
			return false
		var ruta := _ruta(juego)
		if ruta.is_empty():
			return false
		juego.girar(ruta[0] - juego.cuerpo[0])
		juego.avanzar()
	return false


func _ruta(juego: RefCounted) -> Array[Vector2i]:
	var cola: Array[Vector2i] = [juego.cuerpo[0]]
	var previo: Dictionary = {juego.cuerpo[0]: juego.cuerpo[0]}
	while not cola.is_empty():
		var actual: Vector2i = cola.pop_front()
		if actual == juego.sello:
			var ruta: Array[Vector2i] = []
			while actual != juego.cuerpo[0]:
				ruta.push_front(actual)
				actual = previo[actual]
			return ruta
		for paso in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var vecino: Vector2i = actual + paso
			if not Rect2i(Vector2i.ZERO, REGLAS.TAMANO).has_point(vecino):
				continue
			if previo.has(vecino) or juego.paredes.has(vecino) or juego.cuerpo.has(vecino):
				continue
			previo[vecino] = actual
			cola.append(vecino)
	return []


func _probar_ui() -> void:
	for accion in ["interactuar", "cancelar"] + APP.DIRECCIONES.keys():
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
	var raton := Input.mouse_mode
	var app := APP.new()
	app.modo_consola = true
	root.add_child(app)
	app.set_process(false)
	_comprobar(paused and app._menu_rom.visible, "La consola pausa y ofrece ROMs")
	app._principal.pressed.emit()
	_comprobar(app.juego.fase == "jugando", "Botón empieza la partida")
	var evento := InputEventAction.new()
	evento.action = "mover_adelante"
	evento.pressed = true
	app._input(evento)
	app._process(0.3)
	_comprobar(app.juego.cuerpo[0] == Vector2i(5, 6), "Input semántico mueve la cabeza")
	evento.action = "interactuar"
	app._input(evento)
	var cabeza: Vector2i = app.juego.cuerpo[0]
	app._process(10.0)
	_comprobar(
		app.juego.fase == "pausa" and app.juego.cuerpo[0] == cabeza, "Pausa UI detiene ticks"
	)
	app._principal.pressed.emit()
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_comprobar(app.juego.fase == "pausa", "Perder foco pausa automáticamente")
	app._principal.pressed.emit()
	app.juego.cuerpo.assign([Vector2i(19, 7), Vector2i(18, 7), Vector2i(17, 7)])
	app.juego.direccion = Vector2i.RIGHT
	app.juego.pendiente = Vector2i.RIGHT
	app._process(0.3)
	_comprobar(app.juego.fase == "derrota", "Choque real llega a resultado UI")
	app._principal.pressed.emit()
	_comprobar(app.juego.fase == "preparado" and app.juego.puntos == 0, "Revancha UI")
	_comprobar(_resolver(app.juego), "Victoria completa en la sesión UI")
	app._refrescar()
	_comprobar(app._estado.text == app._texto("victoria"), "Muestra final traducido")
	app._principal.pressed.emit()
	_comprobar(app.juego.fase == "preparado", "Revancha después de victoria")
	var emitidos := [0]
	app.cerrado.connect(func(): emitidos[0] += 1)
	evento.action = "cancelar"
	app._input(evento)
	app.cerrar()
	_comprobar(
		not paused and Input.mouse_mode == raton and emitidos[0] == 1,
		"Salir restaura y es idempotente"
	)
	await process_frame
	paused = true
	var segundo := APP.new()
	segundo.modo_consola = true
	root.add_child(segundo)
	var roms := [0]
	segundo.rom_solicitada.connect(func(): roms[0] += 1)
	segundo._menu_rom.pressed.emit()
	_comprobar(paused and roms[0] == 1, "ROM handoff conserva pausa previa")
	await process_frame
	paused = false
	var tercero := APP.new()
	root.add_child(tercero)
	tercero.free()
	_comprobar(not paused, "Retirada inesperada restaura mundo")
