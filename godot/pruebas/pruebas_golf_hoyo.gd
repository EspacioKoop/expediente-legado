extends SceneTree

const HOYO_SCENE: PackedScene = preload("res://escenas/golf_hoyo_standalone.tscn")
const PARTIDA_SCENE: PackedScene = preload("res://escenas/golf_partida_standalone.tscn")

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
	var hoyo: GolfHoyoApp = HOYO_SCENE.instantiate()
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
	var bola := (
		GolfBola
		. nueva(
			Vector2(-0.25, 0.0),
			Rect2(-1.0, -1.0, 2.0, 2.0),
			[obstaculo],
		)
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
	var partida: GolfPartidaApp = PARTIDA_SCENE.instantiate()
	root.add_child(partida)
	await process_frame

	_comprobar(
		GolfPartidaApp.CONFIGURACIONES.size() == Golf.HOYOS,
		"la partida declara exactamente los tres hoyos del núcleo",
	)
	_comprobar(partida.hoyo_actual.numero_hoyo == 1, "la partida abre el hoyo uno")
	_comprobar(
		partida.estado.get("jugadores", []) == GolfPartidaApp.LANZADORES,
		"la partida incluye jugador y tres perfiles de compañeros",
	)
	_comprobar(
		not partida.hoyo_actual.obstaculos.is_empty(), "el hoyo jugable monta obstáculos simples"
	)
	for perfil in ["prudente", "agresiva", "absurda"]:
		var cuerpo := partida.find_child("CompaneroGolf_%s" % perfil, true, false) as Node3D
		_comprobar(cuerpo != null, "%s aparece físicamente junto al hoyo" % perfil)
		if cuerpo == null:
			continue
		_comprobar(
			String(cuerpo.get_meta("perfil_golf", "")) == perfil,
			"%s conserva su perfil visual sin estado paralelo" % perfil,
		)
		_comprobar(
			absf(cuerpo.position.x) > GolfHoyoApp.LIMITE.size.x * 0.5,
			"%s queda fuera del rectángulo jugable" % perfil,
		)
		_comprobar(
			_buscar_colision(cuerpo) == null,
			"%s no añade colisión a la física del golf" % perfil,
		)

	partida._al_completar_hoyo(2)
	await process_frame
	_comprobar(int(partida.estado.get("hoyo", -1)) == 1, "completar uno avanza al segundo")
	_comprobar(partida.hoyo_actual.numero_hoyo == 2, "el segundo hoyo reemplaza al primero")
	_comprobar(
		partida.estado["tarjetas"]["prudente"] == [4],
		"el perfil prudente termina su turno con plan conservador",
	)
	_comprobar(
		partida.estado["tarjetas"]["agresiva"] == [3],
		"el perfil agresivo arriesga menos golpes en el primer hoyo",
	)
	_comprobar(
		partida.estado["tarjetas"]["absurda"] == [7],
		"el perfil absurdo conserva un plan propio y finito",
	)

	partida._al_completar_hoyo(2)
	await process_frame
	_comprobar(int(partida.estado.get("hoyo", -1)) == 2, "completar dos avanza al tercero")
	_comprobar(partida.hoyo_actual.numero_hoyo == 3, "el tercer hoyo usa el mismo slice")

	partida._al_completar_hoyo(2)
	await process_frame
	_comprobar(bool(partida.estado.get("terminada", false)), "el tercer hoyo termina la partida")
	_comprobar(bool(partida.resultado_final.get("completa", false)), "el resultado queda completo")
	var totales: Dictionary = partida.resultado_final.get("totales", {})
	_comprobar(int(totales.get("jugador", 0)) == 6, "la tarjeta suma los golpes del jugador")
	_comprobar(int(totales.get("prudente", 0)) == 12, "prudente completa los tres hoyos")
	_comprobar(int(totales.get("agresiva", 0)) == 11, "agresiva completa los tres hoyos")
	_comprobar(int(totales.get("absurda", 0)) == 21, "absurda completa los tres hoyos")
	_comprobar(
		partida.resultado_final.get("ranking", []).size() == 4,
		"el resultado final ordena las cuatro tarjetas",
	)
	_comprobar(partida.hoyo_actual == null, "al terminar no queda otro hoyo activo")

	partida.queue_free()
	await process_frame


func _probar_abandono() -> void:
	var partida: GolfPartidaApp = PARTIDA_SCENE.instantiate()
	root.add_child(partida)
	await process_frame
	partida._al_abandonar_hoyo()
	await process_frame
	_comprobar(
		bool(partida.resultado_final.get("abandonada", false)), "abandonar produce resultado válido"
	)
	_comprobar(
		not bool(partida.resultado_final.get("completa", true)),
		"abandonar no cuenta como partida completa"
	)
	partida.queue_free()
	await process_frame


func _buscar_colision(nodo: Node) -> CollisionObject3D:
	if nodo is CollisionObject3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrada := _buscar_colision(hijo)
		if encontrada != null:
			return encontrada
	return null


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO GolfHoyo: " + nombre)
