extends SceneTree

const Controller := preload("res://guion/dia_bolos_pasillo_app.gd")


class DiaFalso:
	extends Node3D
	var jornada := {"fase": "archivo", "dia": 2}
	var _mundo: Node3D
	var _caminante: Node3D
	var _hud_prioridades: CanvasLayer
	var _pantalla: Control


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
	var menu_previo := MenuGlobal.is_processing_unhandled_input()
	_comprobar(oferta.interactuar(camara_previa), "interactuar abre la actividad")
	_comprobar(is_instance_valid(controller._bolos), "se instancia la sesión de bolos")
	_comprobar(not dia._mundo.visible, "el mundo de oficina se oculta durante la partida")
	_comprobar(
		dia._caminante.process_mode == Node.PROCESS_MODE_DISABLED,
		"el caminante no se mueve durante la partida",
	)
	_comprobar(not dia._hud_prioridades.visible, "el HUD de jornada no compite con los bolos")
	_comprobar(
		not MenuGlobal.is_processing_unhandled_input(),
		"cancelar queda en manos del minijuego mientras está abierto",
	)

	controller._bolos.abandonar()
	await process_frame
	_comprobar(dia._mundo.visible, "abandonar restaura el mundo")
	_comprobar(dia._caminante.process_mode == modo_previo, "abandonar restaura el caminante")
	_comprobar(dia._hud_prioridades.visible, "abandonar restaura el HUD")
	_comprobar(
		MenuGlobal.is_processing_unhandled_input() == menu_previo,
		"abandonar restaura el menú global",
	)
	_comprobar(
		get_viewport().get_camera_3d() == camara_previa,
		"abandonar devuelve la cámara anterior",
	)
	var resultado_abandono: Dictionary = dia.get_meta("ultimo_resultado_bolos", {})
	_comprobar(bool(resultado_abandono.get("abandonada", false)), "el resultado efímero registra abandono")

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

	dia.queue_free()
	await process_frame


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO BolosPasillo3D: " + nombre)
