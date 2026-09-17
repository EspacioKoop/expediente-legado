extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	await _probar_golpes_y_resumen()
	await _probar_esquiva_reducida_e_impacto()
	await _probar_interrupcion_solar()
	await _probar_contraataque_duat()
	await _probar_retorno_hidra()
	print("playtest_juicio_telemetria_912: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_golpes_y_resumen() -> void:
	var juicio := await _nuevo({}, false)
	_acercar(juicio)
	juicio._recarga_jugador = 0.0
	juicio._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	juicio._recarga_jugador = 0.0
	juicio._atacar(2, JuicioCombate3D.ALCANCE_FUERTE, JuicioCombate3D.RECARGA_FUERTE, true)

	juicio._rival.position = Vector3(0.0, 0.0, -4.5)
	juicio._jugador.position = Vector3.ZERO
	juicio._recarga_jugador = 0.0
	juicio._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	var resumen := juicio.resumen_playtest()
	_comprobar(int(resumen["ligeros_conectados"]) == 1, "solo cuenta el ligero conectado")
	_comprobar(int(resumen["fuertes_conectados"]) == 1, "cuenta el fuerte conectado")
	_comprobar(float(resumen["duracion_segundos"]) >= 0.0, "expone duración de sesión")
	_comprobar(String(resumen["ritual_id"]) == "base", "identifica el combate base")
	resumen["ligeros_conectados"] = 99
	_comprobar(
		int(juicio.resumen_playtest()["ligeros_conectados"]) == 1,
		"el resumen es una copia y no muta contadores internos",
	)
	juicio.abandonar()
	_comprobar(
		String(juicio.resumen_playtest()["resultado"]) == "abandono",
		"distingue abandono de derrota",
	)
	juicio.queue_free()


func _probar_esquiva_reducida_e_impacto() -> void:
	var juicio := await _nuevo({}, true)
	_acercar(juicio)
	juicio._esquiva = 0.34
	juicio._ataque_rival_pendiente = true
	juicio._resolver_ataque_rival()
	var resumen := juicio.resumen_playtest()
	_comprobar(int(resumen["esquivas_utiles"]) == 1, "cuenta esquiva resuelta")
	_comprobar(
		int(resumen["determinacion_perdida"]) == 0,
		"reducción de movimiento no altera la esquiva útil",
	)

	juicio._esquiva = 0.0
	juicio._ataque_rival_pendiente = true
	juicio._resolver_ataque_rival()
	resumen = juicio.resumen_playtest()
	_comprobar(int(resumen["determinacion_perdida"]) == 1, "cuenta determinación perdida")
	juicio.queue_free()


func _probar_interrupcion_solar() -> void:
	var ritual := JuicioSimbolico.ritual_para({"id": "el-sol"}, "maui_tamanuitera")
	var juicio := await _nuevo(ritual, false)
	_acercar(juicio)
	juicio._ataque_rival_pendiente = true
	juicio._recarga_jugador = 0.0
	juicio._atacar(2, JuicioCombate3D.ALCANCE_FUERTE, juicio._recarga_fuerte, true)
	var resumen := juicio.resumen_playtest()
	_comprobar(int(resumen["interrupciones"]) == 1, "cuenta la interrupción solar")
	_comprobar(int(resumen["fuertes_conectados"]) == 1, "interrupción también cuenta fuerte")
	_comprobar(String(resumen["ritual_id"]) == "robo_del_sol", "expone el ritual activo")
	juicio.queue_free()


func _probar_contraataque_duat() -> void:
	var ritual := JuicioSimbolico.ritual_para({"id": "la-justicia"}, "duat")
	var juicio := await _nuevo(ritual, false)
	_acercar(juicio)
	juicio._contraataque = 1
	juicio._recarga_jugador = 0.0
	juicio._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	_comprobar(
		int(juicio.resumen_playtest()["contraataques"]) == 1,
		"cuenta la conversión de CONTRA en golpe",
	)
	juicio.queue_free()


func _probar_retorno_hidra() -> void:
	var ritual := JuicioSimbolico.ritual_para({"id": "la-muerte"}, "hidra")
	var juicio := await _nuevo(ritual, false)
	_acercar(juicio)
	juicio._determinacion_rival = 1
	juicio._recarga_jugador = 0.0
	juicio._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)
	var resumen := juicio.resumen_playtest()
	_comprobar(int(resumen["retornos"]) == 1, "cuenta el retorno de la Hidra")
	_comprobar(int(resumen["determinacion_rival_final"]) == 2, "observa la segunda fase")

	juicio._recarga_jugador = 0.0
	juicio._atacar(2, JuicioCombate3D.ALCANCE_FUERTE, JuicioCombate3D.RECARGA_FUERTE, true)
	_comprobar(
		String(juicio.resumen_playtest()["resultado"]) == "victoria",
		"registra el resultado final tras agotar retornos",
	)
	juicio.queue_free()


func _nuevo(ritual: Dictionary, reducir: bool) -> JuicioCombatePlaytest912:
	var juicio := JuicioCombatePlaytest912.new()
	juicio.configurar({"id": "prueba_912", "nombre": "PRUEBA #912"}, 0, reducir)
	juicio._ritual = ritual.duplicate(true)
	juicio._aplicar_configuracion_ritual()
	root.add_child(juicio)
	await process_frame
	return juicio


func _acercar(juicio: JuicioCombatePlaytest912) -> void:
	juicio._jugador.position = Vector3.ZERO
	juicio._rival.position = Vector3(0.0, 0.0, -1.0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #912 telemetría: %s" % nombre)
