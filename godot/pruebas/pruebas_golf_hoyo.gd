extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	await _probar_hoyo_standalone()
	_probar_rebote_obstaculo()
	await _probar_partida_tres_hoyos()
	await _probar_abandono()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_hoyo_standalone() -> void:
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

	hoyo.estado_bola["posicion"] = hoyo.objetivo
	hoyo._resolver_reposo()
	_comprobar(hoyo.terminada, "detecta el objetivo al detenerse")

	hoyo.queue_free()
	await process_frame


func _probar_rebote_obstaculo() -> void:
	var obstaculo := Rect2(-0.05, -0.20, 0.10, 0.40)
	var bola := GolfBola.nueva(
		Vector2(-0.25, 0.0),
		Rect2(-1.0, -1.0, 2.0, 2.0),
		[obstaculo],
	)
	GolfBola.golpear(bola, Vector2.RIGHT, 0.65)
	var reboto := false
	for _i in range(90):
		GolfBola.avanzar(bola, GolfBola.PASO_FIJO)
		var velocidad: Vector2 = bola.get("velocidad", Vector2.ZERO)
		if velocidad.x < 0.0:
			reboto = true
			break
	_comprobar(reboto, "los obstáculos rectangulares rebotan en el integrador determinista")
	_comprobar(bola.get("obstaculos", []).size() == 1, "el estado conserva obstáculos válidos")


func _probar_partida_tres_hoyos() -> void:
	var partida: GolfPartidaApp = load("res://escenas/golf_partida_standalone.tscn").instantiate()
	root.add_child(partida)
	await process_frame

	_comprobar(
		GolfPartidaApp.CONFIGURACIONES.size() == Golf.HOYOS,
		"la partida declara exactamente los tres hoyos del núcleo",
	)
	_comprobar(partida.hoyo_actual.numero_hoyo == 1, "la partida abre el hoyo uno")
	_comprobar(
		not partida.hoyo_actual.obstaculos.is_empty(), "el hoyo jugable monta obstáculos simples"
	)

	partida._al_completar_hoyo(2)
	await process_frame
	_comprobar(int(partida.estado.get("hoyo", -1)) == 1, "completar uno avanza al segundo")
	_comprobar(partida.hoyo_actual.numero_hoyo == 2, "el segundo hoyo reemplaza al primero")

	partida._al_completar_hoyo(2)
	await process_frame
	_comprobar(int(partida.estado.get("hoyo", -1)) == 2, "completar dos avanza al tercero")
	_comprobar(partida.hoyo_actual.numero_hoyo == 3, "el tercer hoyo usa el mismo slice")

	partida._al_completar_hoyo(2)
	await process_frame
	_comprobar(bool(partida.estado.get("terminada", false)), "el tercer hoyo termina la partida")
	_comprobar(bool(partida.resultado_final.get("completa", false)), "el resultado queda completo")
	_comprobar(
		int(partida.resultado_final.get("totales", {}).get("jugador", 0)) == 6,
		"la tarjeta suma los golpes de los tres hoyos",
	)
	_comprobar(partida.hoyo_actual == null, "al terminar no queda otro hoyo activo")

	partida.queue_free()
	await process_frame


func _probar_abandono() -> void:
	var partida: GolfPartidaApp = load("res://escenas/golf_partida_standalone.tscn").instantiate()
	root.add_child(partida)
	await process_frame
	partida._al_abandonar_hoyo()
	await process_frame
	_comprobar(bool(partida.resultado_final.get("abandonada", false)), "abandonar produce resultado válido")
	_comprobar(not bool(partida.resultado_final.get("completa", true)), "abandonar no cuenta como partida completa")
	partida.queue_free()
	await process_frame


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO GolfHoyo: " + nombre)
