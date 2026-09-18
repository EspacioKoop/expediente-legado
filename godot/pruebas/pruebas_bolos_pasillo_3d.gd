extends SceneTree

const Controller := preload("res://guion/dia_bolos_pasillo_app.gd")


class DiaFalso:
	extends Node3D
	var jornada := {"fase": "archivo", "dia": 2}
	var partida := Partida.new()
	var guardados := 0
	var _mundo: Node3D
	var _caminante: Node3D
	var _hud_prioridades: CanvasLayer
	var _pantalla: Control

	func _init() -> void:
		partida.estado = Partida.nueva()

	func _guardar_o_avisar(_destino: String) -> bool:
		guardados += 1
		return true


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	PreferenciasSiga.aplicar(PreferenciasSiga.nuevas())
	var escena: BolosPasillo3D = load("res://escenas/bolos_pasillo.tscn").instantiate()
	root.add_child(escena)
	await process_frame

	_comprobar(escena.estado.get("lanzadores", []).size() == 4, "jugador y tres compañeros")
	_comprobar(escena.total_bolos_en_pie() == 10, "la pista monta diez bolos")
	_probar_variantes()
	_comprobar(escena._companeros_visual.size() == 3, "los tres compañeros son visibles")
	_comprobar(escena._idles_companeros.size() == 3, "los compañeros reutilizan idle de oficina")
	var todos_fuera := true
	for cuerpo in escena._companeros_visual:
		if absf(cuerpo.position.x) <= escena.CARRIL_ANCHO * 0.5:
			todos_fuera = false
	_comprobar(todos_fuera, "los compañeros quedan fuera de la física del carril")
	_comprobar(
		escena._idles_companeros[0].actividad_brazos,
		"un compañero reutiliza el gesto de espera de la oficina",
	)
	_comprobar(
		escena._idles_companeros.all(func(idle): return idle.objetivo in escena._companeros_visual),
		"cada idle anima su figura de bolos",
	)
	_comprobar(escena.lanzar(0.0, 1.0), "un tiro recto puede comenzar")
	var pasos_recto := escena.simular_hasta_reposo()
	_comprobar(pasos_recto > 0, "el tiro avanza con paso fijo")
	_comprobar(not escena.lanzamiento_activo(), "el tiro termina siempre")
	_comprobar(int(escena.estado.get("lanzamiento", 0)) == 1, "primer tiro consume un lanzamiento")
	_comprobar(int(escena.estado.get("puntuaciones", [0])[0]) > 0, "el tiro recto derriba")

	escena.reiniciar()
	_comprobar(escena.lanzar(1.0, 0.45), "se puede apuntar lateralmente")
	escena.simular_hasta_reposo()
	_comprobar(int(escena.estado.get("puntuaciones", [1])[0]) == 0, "un tiro lateral puede fallar")
	_comprobar(int(escena.estado.get("lanzamiento", 0)) == 1, "fallar no bloquea el turno")
	_comprobar(escena.lanzar(-1.0, 0.45), "segundo tiro puede comenzar")
	escena.simular_hasta_reposo()
	var resultado := escena.resultado_actual()
	_comprobar(bool(resultado.get("completa", false)), "dos tiros cierran jugador y compañeros")
	_comprobar(resultado.get("puntuaciones", []).size() == 4, "resultado incluye los cuatro turnos")

	escena.reiniciar()
	var abandonada := escena.abandonar()
	_comprobar(bool(abandonada.get("abandonada", false)), "abandonar devuelve resultado válido")
	_comprobar(not bool(abandonada.get("completa", true)), "abandonar no finge partida completa")

	escena.reiniciar()
	_comprobar(int(escena.estado.get("puntuaciones", [1])[0]) == 0, "repetir empieza desde cero")
	_comprobar(escena.total_bolos_en_pie() == 10, "repetir restaura los bolos")

	escena.queue_free()
	await process_frame
	await _probar_integracion_oficina()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_variantes() -> void:
	var dias := [2, 5, 8, 11, 14]
	for indice in dias.size():
		_comprobar(
			Controller.variante_para_dia({"fase": "archivo", "dia": dias[indice]})
			== BolosPasillo3D.VARIANTES[indice],
			"los días elegibles rotan variantes sin azar",
		)
	_comprobar(
		Controller.variante_para_dia({"fase": "archivo", "dia": 17})
		== BolosPasillo3D.VARIANTE_ESTRECHO,
		"la rotación de variantes vuelve al inicio",
	)
	_comprobar(
		BolosPasillo3D.ancho_de(BolosPasillo3D.VARIANTE_ESTRECHO) < BolosPasillo3D.CARRIL_ANCHO,
		"la variante estrecha reduce el ancho jugable",
	)
	var posiciones_absurdas := BolosPasillo3D.posiciones_de(BolosPasillo3D.VARIANTE_ABSURDO)
	_comprobar(
		absf(posiciones_absurdas[-1].x) > 0.9,
		"el cuñado desplaza un bolo a una posición absurda",
	)
	_comprobar(
		BolosPasillo3D.energia_luz_de(BolosPasillo3D.VARIANTE_NOCTURNO) < 0.5,
		"la ronda nocturna reduce la iluminación",
	)

	var mesa := BolosPasillo3D.new()
	mesa.configurar_variante(BolosPasillo3D.VARIANTE_MESA)
	mesa._bola_posicion = mesa._obstaculo_variante["posicion"]
	mesa._bola_velocidad = Vector3(0.2, 0.0, -3.0)
	mesa._resolver_obstaculo_variante()
	_comprobar(mesa._bola_velocidad == Vector3.ZERO, "la mesa bloquea un lanzamiento")
	mesa.free()

	var rebote := BolosPasillo3D.new()
	rebote.configurar_variante(BolosPasillo3D.VARIANTE_REBOTE)
	rebote._bola_posicion = rebote._obstaculo_variante["posicion"]
	rebote._bola_velocidad = Vector3(1.0, 0.0, -3.0)
	rebote._resolver_obstaculo_variante()
	_comprobar(rebote._bola_velocidad.x < 0.0, "el archivador devuelve la bola")
	rebote.free()


func _probar_integracion_oficina() -> void:
	_comprobar(
		not Controller.disponible({"fase": "archivo", "dia": 1}),
		"los bolos no aparecen todos los días",
	)
	_comprobar(
		Controller.disponible({"fase": "archivo", "dia": 2}),
		"el día elegible ofrece la pausa",
	)
	_comprobar(
		not Controller.disponible({"fase": "trayecto", "dia": 2}),
		"la actividad solo pertenece al archivo",
	)

	var dia := DiaFalso.new()
	dia._mundo = Node3D.new()
	dia._mundo.name = "MundoFalso"
	dia._caminante = Node3D.new()
	dia._caminante.name = "CaminanteFalso"
	dia._hud_prioridades = CanvasLayer.new()
	dia._hud_prioridades.name = "HUDFalso"
	root.add_child(dia)
	dia.add_child(dia._mundo)
	dia._mundo.add_child(dia._caminante)
	dia.add_child(dia._hud_prioridades)

	var camara_previa := Camera3D.new()
	camara_previa.name = "CamaraPrevia"
	dia._caminante.add_child(camara_previa)
	camara_previa.make_current()

	var controller: DiaBolosPasilloApp = Controller.new()
	dia.add_child(controller)
	controller._process(0.0)
	var oferta := dia._mundo.get_node_or_null("BolosPasilloOferta") as Interactuable3D
	_comprobar(oferta != null, "el controller monta una oferta interactuable")
	controller._process(0.0)
	_comprobar(
		dia._mundo.find_children("BolosPasilloOferta", "Area3D", true, false).size() == 1,
		"la oferta no se duplica",
	)

	var modo_previo := dia._caminante.process_mode
	var menu := root.get_node_or_null("MenuGlobal")
	var menu_previo := menu.is_processing_unhandled_input() if menu != null else true
	_comprobar(oferta.interactuar(camara_previa), "interactuar abre la actividad")
	_comprobar(is_instance_valid(controller._bolos), "se instancia la sesión de bolos")
	_comprobar(
		controller._bolos.variante == BolosPasillo3D.VARIANTE_ESTRECHO,
		"el día 2 abre la variante estrecha",
	)
	_comprobar(not dia._mundo.visible, "el mundo de oficina se oculta durante la partida")
	_comprobar(
		dia._caminante.process_mode == Node.PROCESS_MODE_DISABLED,
		"el caminante no se mueve durante la partida",
	)
	_comprobar(not dia._hud_prioridades.visible, "el HUD de jornada no compite con los bolos")
	_comprobar(
		menu == null or not menu.is_processing_unhandled_input(),
		"cancelar queda en manos del minijuego mientras está abierto",
	)

	controller._bolos.abandonar()
	await process_frame
	_comprobar(dia._mundo.visible, "abandonar restaura el mundo")
	_comprobar(dia._caminante.process_mode == modo_previo, "abandonar restaura el caminante")
	_comprobar(dia._hud_prioridades.visible, "abandonar restaura el HUD")
	_comprobar(
		menu == null or menu.is_processing_unhandled_input() == menu_previo,
		"abandonar restaura el menú global",
	)
	_comprobar(
		root.get_camera_3d() == camara_previa,
		"abandonar devuelve la cámara anterior",
	)
	var resultado_abandono: Dictionary = dia.get_meta("ultimo_resultado_bolos", {})
	_comprobar(
		bool(resultado_abandono.get("abandonada", false)), "el resultado efímero registra abandono"
	)
	_comprobar(
		not is_instance_valid(controller._marcador_resultado),
		"abandonar no muestra marcador final",
	)
	_comprobar(
		not Sellos.tiene_sello(dia.partida.estado, Controller.SELLO_RECOMPENSA),
		"abandonar no concede el sello",
	)
	_comprobar(dia.guardados == 0, "abandonar no fuerza guardado")

	_comprobar(oferta.interactuar(camara_previa), "la actividad se puede repetir")
	var sesion: BolosPasillo3D = controller._bolos
	_comprobar(sesion.lanzar(1.0, 0.45), "la repetición acepta el primer tiro")
	sesion.simular_hasta_reposo()
	_comprobar(sesion.lanzar(-1.0, 0.45), "la repetición acepta el segundo tiro")
	sesion.simular_hasta_reposo()
	await process_frame
	var resultado_completo: Dictionary = dia.get_meta("ultimo_resultado_bolos", {})
	_comprobar(bool(resultado_completo.get("completa", false)), "terminar deja resultado completo")
	_comprobar(not is_instance_valid(controller._bolos), "terminar cierra la sesión integrada")
	_comprobar(dia._mundo.visible, "terminar devuelve a la oficina")
	_comprobar(
		is_instance_valid(controller._marcador_resultado),
		"una partida completa muestra marcador final",
	)
	if is_instance_valid(controller._marcador_resultado):
		var etiquetas := controller._marcador_resultado.find_children(
			"Puntos*", "Label", true, false
		)
		var marcas := controller._marcador_resultado.find_children(
			"Marca*", "ColorRect", true, false
		)
		_comprobar(etiquetas.size() == 4, "el marcador enseña las cuatro puntuaciones")
		_comprobar(marcas.size() == 4, "el marcador distingue visualmente los cuatro turnos")
	_comprobar(
		dia._caminante.process_mode == modo_previo and dia._hud_prioridades.visible,
		"el marcador no bloquea la jornada restaurada",
	)
	_comprobar(
		Sellos.tiene_sello(dia.partida.estado, Controller.SELLO_RECOMPENSA),
		"completar concede el sello cosmético",
	)
	_comprobar(dia.guardados == 1, "la primera concesión pide guardado")
	controller._retirar_marcador_resultado()

	var ruta_guardado := "user://bolos-sello-prueba.json"
	if FileAccess.file_exists(ruta_guardado):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_guardado))
	_comprobar(dia.partida.guardar(ruta_guardado), "el sello se escribe en la partida")
	var recargada := Partida.new()
	var carga := recargada.cargar(ruta_guardado)
	_comprobar(String(carga.get("resultado", "")) == "cargada", "la partida con sello recarga")
	_comprobar(
		Sellos.tiene_sello(recargada.estado, Controller.SELLO_RECOMPENSA),
		"recargar conserva el sello",
	)
	Sellos.registrar_sello(recargada.estado, Controller.SELLO_RECOMPENSA)
	var sellos_recargados: Array = recargada.estado.get(Sellos.CLAVE_ESTADO, [])
	_comprobar(
		sellos_recargados.count(Controller.SELLO_RECOMPENSA) == 1,
		"registrar tras recargar no duplica el sello",
	)
	if FileAccess.file_exists(ruta_guardado):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_guardado))

	_comprobar(oferta.interactuar(camara_previa), "repetir tras premio vuelve a abrir")
	var sesion_repetida: BolosPasillo3D = controller._bolos
	_comprobar(sesion_repetida.lanzar(1.0, 0.45), "repetir acepta primer tiro")
	sesion_repetida.simular_hasta_reposo()
	_comprobar(sesion_repetida.lanzar(-1.0, 0.45), "repetir acepta segundo tiro")
	sesion_repetida.simular_hasta_reposo()
	await process_frame
	var sellos_repetidos: Array = dia.partida.estado.get(Sellos.CLAVE_ESTADO, [])
	_comprobar(
		sellos_repetidos.count(Controller.SELLO_RECOMPENSA) == 1,
		"repetir la actividad no duplica el sello",
	)
	_comprobar(dia.guardados == 2, "repetir conserva el camino de guardado idempotente")
	controller._retirar_marcador_resultado()

	dia.queue_free()
	await process_frame


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO BolosPasillo3D: " + nombre)
