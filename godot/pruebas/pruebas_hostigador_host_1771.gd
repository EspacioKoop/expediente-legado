## Regresión standalone del hostigador onírico (#1771) en JuicioCombate3D.
## Cubre distancia 5–8 m, rumbo congelado, disparo lineal único y ventana.
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const PASO := 1.0 / 60.0
const RAIZ := 11

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	await _probar_monta_linea_sin_guardia()
	await _probar_reposiciona_por_distancia()
	await _probar_rumbo_congelado()
	await _probar_disparo_unico_y_ventana()
	await _probar_salir_de_linea_evade()
	await _probar_reduccion_movimiento_no_cambia_reglas()
	await _probar_host_contextual_solo_sueno()
	await create_timer(0.5).timeout
	await process_frame
	print("hostigador_host_1771: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_monta_linea_sin_guardia() -> void:
	var juicio := await _nuevo(false)
	_comprobar(_estado(juicio), ARQUETIPOS.REPOSICIONAR, "empieza reposicionando")
	_comprobar(juicio._linea_hostigador != null, true, "monta aviso lineal")
	_comprobar(juicio._escudo_guardia == null, true, "no reutiliza la guardia")
	_comprobar(juicio._linea_hostigador.visible, false, "la línea empieza oculta")
	juicio.free()


func _probar_reposiciona_por_distancia() -> void:
	var cerca := await _nuevo()
	cerca._jugador.position = Vector3.ZERO
	cerca._rival.position = Vector3(0.0, 0.0, -2.0)
	var antes := cerca._rival.position.distance_to(cerca._jugador.position)
	cerca._avanzar_arquetipo(PASO)
	_comprobar(
		cerca._arquetipo.get("_intencion_runtime", ""), "alejarse", "a menos de 5 m decide alejarse"
	)
	cerca._mover_rival(PASO)
	_comprobar(
		cerca._rival.position.distance_to(cerca._jugador.position) > antes,
		true,
		"el host ejecuta el alejamiento",
	)
	cerca.free()

	var lejos := await _nuevo()
	lejos._jugador.position = Vector3(0.0, 0.0, 4.0)
	lejos._rival.position = Vector3(0.0, 0.0, -5.0)
	antes = lejos._rival.position.distance_to(lejos._jugador.position)
	lejos._avanzar_arquetipo(PASO)
	_comprobar(
		lejos._arquetipo.get("_intencion_runtime", ""), "acercarse", "a más de 8 m decide acercarse"
	)
	lejos._mover_rival(PASO)
	_comprobar(
		lejos._rival.position.distance_to(lejos._jugador.position) < antes,
		true,
		"el host ejecuta el acercamiento",
	)
	lejos.free()


func _probar_rumbo_congelado() -> void:
	var juicio := await _nuevo()
	_colocar_a_seis_metros(juicio)
	juicio._avanzar_arquetipo(PASO)
	_comprobar(_estado(juicio), ARQUETIPOS.TELEGRAFIAR, "entra en telegraph a distancia válida")
	_comprobar(juicio._linea_hostigador.visible, true, "el telegraph es visible")
	var rumbo := float(juicio._arquetipo["rumbo_bloqueado"])
	var rotacion_linea := juicio._linea_hostigador.rotation.y

	juicio._jugador.position = Vector3(3.0, 0.0, 0.0)
	juicio._avanzar_arquetipo(PASO)
	_comprobar(
		float(juicio._arquetipo["rumbo_bloqueado"]),
		rumbo,
		"moverse durante telegraph no corrige el rumbo",
	)
	_comprobar(
		juicio._linea_hostigador.rotation.y,
		rotacion_linea,
		"la geometría conserva el rumbo congelado",
	)
	juicio.free()


func _probar_disparo_unico_y_ventana() -> void:
	var juicio := await _nuevo()
	_colocar_a_seis_metros(juicio)
	var antes := juicio._determinacion_jugador
	juicio._avanzar_arquetipo(PASO)
	_avanzar_hasta(juicio, ARQUETIPOS.DISPARAR_LINEA, 90)
	_comprobar(
		juicio._determinacion_jugador,
		antes - 1,
		"la línea alineada aplica el impacto común una sola vez",
	)
	var tras_disparo := juicio._determinacion_jugador
	for _i in range(3):
		juicio._avanzar_arquetipo(PASO)
	_comprobar(
		juicio._determinacion_jugador,
		tras_disparo,
		"mantener DISPARAR_LINEA varios frames no repite daño",
	)
	_avanzar_hasta(juicio, ARQUETIPOS.VULNERABLE, 30)
	_comprobar(_estado(juicio), ARQUETIPOS.VULNERABLE, "tras disparar abre ventana vulnerable")
	_comprobar(juicio._linea_hostigador.visible, false, "la línea desaparece en la ventana")
	juicio.free()


func _probar_salir_de_linea_evade() -> void:
	var juicio := await _nuevo()
	_colocar_a_seis_metros(juicio)
	var antes := juicio._determinacion_jugador
	juicio._avanzar_arquetipo(PASO)
	juicio._jugador.position = Vector3(3.0, 0.0, 0.0)
	_avanzar_hasta(juicio, ARQUETIPOS.DISPARAR_LINEA, 90)
	_comprobar(
		juicio._determinacion_jugador,
		antes,
		"salir lateralmente de la línea evita el disparo",
	)
	juicio.free()


func _probar_reduccion_movimiento_no_cambia_reglas() -> void:
	var animado := await _nuevo(false)
	var reducido := await _nuevo(true)
	_colocar_a_seis_metros(animado)
	_colocar_a_seis_metros(reducido)
	var iguales := true
	for _i in range(55):
		animado._avanzar_arquetipo(PASO)
		reducido._avanzar_arquetipo(PASO)
		if _estado(animado) != _estado(reducido):
			iguales = false
		if animado._linea_hostigador.visible != reducido._linea_hostigador.visible:
			iguales = false
	_comprobar(iguales, true, "reducción de movimiento conserva timings y línea")
	animado.free()
	reducido.free()


func _probar_host_contextual_solo_sueno() -> void:
	var id := ""
	for indice in range(100):
		var candidato := "figura-hostigador-%d" % indice
		if HOST.elegir(candidato, RAIZ, CombateContextual.PLANO_SUENO) == ARQUETIPOS.HOSTIGADOR:
			id = candidato
			break
	_comprobar(id.is_empty(), false, "la selección estable incluye hostigadores")

	var sueno := _abrir_contextual(id, CombateContextual.PLANO_SUENO)
	_comprobar(
		sueno._combate.arquetipo_onirico,
		ARQUETIPOS.HOSTIGADOR,
		"el sueño pasa el hostigador al duelo",
	)
	_comprobar(sueno._combate._linea_hostigador != null, true, "y monta su línea")
	sueno.free()

	var realidad := _abrir_contextual(id, CombateContextual.PLANO_REALIDAD)
	_comprobar(realidad._combate.arquetipo_onirico, "", "la realidad conserva duelo clásico")
	_comprobar(realidad._combate._arquetipo.is_empty(), true, "sin política fuera del sueño")
	realidad.free()
	await process_frame


func _colocar_a_seis_metros(juicio: JuicioCombate3D) -> void:
	juicio._rival.position = Vector3(0.0, 0.0, -3.0)
	juicio._jugador.position = Vector3(0.0, 0.0, 3.0)
	juicio._rival.rotation.y = 0.0


func _avanzar_hasta(juicio: JuicioCombate3D, esperado: String, max_pasos: int) -> void:
	for _i in range(max_pasos):
		if _estado(juicio) == esperado:
			return
		juicio._avanzar_arquetipo(PASO)
	_comprobar(_estado(juicio), esperado, "alcanza estado %s" % esperado)


func _abrir_contextual(id: String, plano: String) -> DiaCombateContextualApp:
	var app := DiaCombateContextualApp.new()
	get_root().add_child(app)
	var caminante := CharacterBody3D.new()
	var mundo := Node3D.new()
	var hud := CanvasLayer.new()
	for nodo in [caminante, mundo, hud]:
		app.add_child(nodo)
	var abierto := (
		app
		. abrir(
			{"id": id, "nombre": "HOSTIGADOR"},
			{"permitido": true, "plano": plano},
			null,
			caminante,
			mundo,
			hud,
			Environment.new(),
			Partida.new(),
			{},
			RAIZ,
		)
	)
	_comprobar(abierto, true, "el host contextual abre (%s)" % plano)
	app._combate.set_process(false)
	return app


func _nuevo(reducir: bool = true) -> JuicioCombate3D:
	var juicio := JuicioCombate3D.new()
	juicio.configurar({"id": "hostigador-1771", "nombre": "HOSTIGADOR"}, 0, reducir, RAIZ)
	juicio.arquetipo_onirico = ARQUETIPOS.HOSTIGADOR
	get_root().add_child(juicio)
	juicio.set_process(false)
	await process_frame
	return juicio


func _estado(juicio: JuicioCombate3D) -> String:
	return String(juicio._arquetipo.get("estado", ""))


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #1771 hostigador: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
