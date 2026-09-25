## Gestos del Juicio: un gesto se ve entero y a su velocidad aunque la figura
## viniera andando, andar no lo pisa mientras dura, al acabar se vuelve a
## andar, y el gesto final del combate se ve antes de que la ventanilla cierre
## la arena (salvo al abandonar, que es inmediato).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	await _probar_ciclo_gesto_locomocion()
	await _probar_gesto_final()
	await _probar_abandonar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_ciclo_gesto_locomocion() -> void:
	var padre := Node3D.new()
	root.add_child(padre)
	var cuerpo := JuicioCombateEscenografia3D.cuerpo_jugador(padre, {})
	await process_frame
	var reproductor := Modelos._reproductor(cuerpo.figura())
	_comprobar(reproductor != null, "el cuerpo del Juicio tiene reproductor")
	if reproductor == null:
		padre.free()
		return
	_comprobar(not cuerpo.auto_animar, "en la arena no se anima solo")

	JuicioCombateEscenografia3D.andar(cuerpo, true)
	var andando := reproductor.current_animation
	_comprobar(cuerpo.estado == "andar", "empieza andando")
	# Andar deja su propia velocidad de reproducción; el gesto no la hereda.
	reproductor.speed_scale = 1.7

	var segundos := JuicioCombateEscenografia3D.gesto(cuerpo, "discutir")
	var del_gesto := reproductor.current_animation
	_comprobar(segundos > 0.0, "el gesto dura algo (%.2f s)" % segundos)
	_comprobar(del_gesto != andando, "el gesto sustituye a andar")
	_comprobar(is_equal_approx(reproductor.speed_scale, 1.0), "el gesto va a su velocidad")
	_comprobar(
		absf(segundos - reproductor.current_animation_length) < 0.01,
		(
			"la duración es la del clip a la velocidad real (%.2f frente a %.2f)"
			% [segundos, reproductor.current_animation_length]
		)
	)

	# Mientras dura, ni andar ni el propio cuerpo lo pisan.
	JuicioCombateEscenografia3D.andar(cuerpo, true)
	JuicioCombateEscenografia3D.andar(cuerpo, false)
	for i in 5:
		await process_frame
	_comprobar(
		reproductor.current_animation == del_gesto,
		"durante el gesto sigue el gesto (%s)" % reproductor.current_animation
	)

	# Al acabar, el siguiente paso vuelve a andar.
	cuerpo.set_meta("gesto_hasta", Time.get_ticks_msec() - 1)
	JuicioCombateEscenografia3D.andar(cuerpo, true)
	_comprobar(cuerpo.estado == "andar", "tras el gesto vuelve a andar")
	_comprobar(
		reproductor.current_animation != del_gesto,
		"tras el gesto ya no está el gesto (%s)" % reproductor.current_animation
	)
	_comprobar(not cuerpo.has_meta("gesto_hasta"), "el gesto no deja rastro")

	# Y un gesto sobre alguien quieto vuelve a reposo, no se queda congelado.
	JuicioCombateEscenografia3D.gesto(cuerpo, "encajar")
	cuerpo.set_meta("gesto_hasta", Time.get_ticks_msec() - 1)
	JuicioCombateEscenografia3D.andar(cuerpo, false)
	_comprobar(cuerpo.estado == "reposo", "tras el gesto, quieto respira")
	padre.free()


func _combate() -> JuicioCombate3D:
	var combate := JuicioCombate3D.new()
	combate.configurar({"id": "gestos", "nombre": "gestos"}, 0, true)
	root.add_child(combate)
	return combate


func _probar_gesto_final() -> void:
	var combate := _combate()
	await process_frame
	var resultado := []
	combate.terminado.connect(func(gano: bool): resultado.append(gano))
	var inicio := Time.get_ticks_msec()
	combate._terminar(true)
	await process_frame
	_comprobar(resultado.is_empty(), "el final no cierra en el mismo fotograma")
	while resultado.is_empty() and Time.get_ticks_msec() - inicio < 5000:
		await process_frame
	var espera := (Time.get_ticks_msec() - inicio) / 1000.0
	_comprobar(resultado == [true], "al acabar el gesto avisa de la victoria")
	_comprobar(
		espera > 0.3 and espera <= JuicioCombate3D.PAUSA_FINAL_MAX + 0.5,
		"el gesto final se ve y no retiene de más (%.2f s)" % espera
	)
	combate.free()


func _probar_abandonar() -> void:
	var combate := _combate()
	await process_frame
	var resultado := []
	combate.terminado.connect(func(gano: bool): resultado.append(gano))
	combate.abandonar()
	_comprobar(resultado == [false], "abandonar cierra al momento")
	combate.free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + mensaje)
