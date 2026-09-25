extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var hoyo: GolfHoyoApp = load("res://escenas/golf_hoyo_standalone.tscn").instantiate()
	root.add_child(hoyo)
	await process_frame

	_comprobar(hoyo.estado_bola.get("posicion") == GolfHoyoApp.INICIO, "parte del tee")
	_comprobar(GolfBola.detenida(hoyo.estado_bola), "la bola parte quieta")

	var potencia_inicial := hoyo.potencia
	hoyo._ajustar_potencia(0.1)
	_comprobar(hoyo.potencia > potencia_inicial, "permite elegir potencia")
	hoyo._ajustar_angulo(10.0)
	_comprobar(is_equal_approx(hoyo.angulo_grados, 10.0), "permite apuntar")

	hoyo._golpear()
	_comprobar(hoyo.golpes == 1, "registra exactamente un golpe")
	_comprobar(not GolfBola.detenida(hoyo.estado_bola), "el golpe inicia movimiento")
	GolfBola.simular_hasta_detener(hoyo.estado_bola)
	hoyo._sincronizar_bola_visual()
	hoyo._resolver_reposo()
	var posicion: Vector2 = hoyo.estado_bola.get("posicion")
	_comprobar(
		is_finite(posicion.x) and is_finite(posicion.y), "el tiro termina en posición finita"
	)
	_comprobar(GolfBola.detenida(hoyo.estado_bola), "el tiro siempre termina")

	hoyo.estado_bola["posicion"] = GolfHoyoApp.OBJETIVO
	hoyo._resolver_reposo()
	_comprobar(hoyo.terminada, "detecta el objetivo al detenerse")

	hoyo.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO GolfHoyo: " + nombre)
