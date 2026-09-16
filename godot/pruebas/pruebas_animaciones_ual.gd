extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	_probar_clips_sobre_persona()
	_probar_escala_de_cadera()
	_probar_cache_compartida()
	_probar_entradas_invalidas()
	_probar_companero_al_telefono()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_clips_sobre_persona() -> void:
	var cuerpo := _persona()
	var reproductor := Modelos._reproductor(cuerpo)
	var esqueleto := Modelos._esqueleto(cuerpo)
	for clip in AnimacionesUAL.CLIPS:
		_comprobar(AnimacionesUAL.reproducir(cuerpo, clip, 0.25), "%s se reproduce" % clip)
		_comprobar(
			reproductor.current_animation == "ual/%s" % clip, "%s es el clip en curso" % clip
		)
		var animacion := reproductor.get_animation("ual/%s" % clip)
		_comprobar(animacion.get_track_count() > 20, "%s conserva el cuerpo entero" % clip)
		_comprobar(animacion.loop_mode == Animation.LOOP_LINEAR, "%s va en bucle" % clip)
		var huerfanas := []
		for pista in animacion.get_track_count():
			var hueso := String(animacion.track_get_path(pista).get_concatenated_subnames())
			if esqueleto.find_bone(hueso) < 0:
				huerfanas.append(hueso)
		_comprobar(huerfanas.is_empty(), "%s solo mueve huesos de persona.fbx" % clip)
	_comprobar(esqueleto.motion_scale == 1.0, "no se toca la escala de movimiento del esqueleto")

	# `Modelos._animar` busca por sufijo: añadir la biblioteca UAL no debe
	# cambiar qué clip recibe quien pide `idle` o `work`.
	Modelos._animar(cuerpo, "idle")
	_comprobar(
		not String(reproductor.current_animation).begins_with("ual/"),
		"idle sigue siendo el de persona.fbx"
	)
	cuerpo.free()


func _probar_escala_de_cadera() -> void:
	var fuente := Animation.new()
	var pista := fuente.add_track(Animation.TYPE_POSITION_3D)
	fuente.track_set_path(pista, NodePath("Armature/Skeleton3D:Hips"))
	fuente.track_insert_key(pista, 0.0, Vector3(0.0, 1.0, 0.1))
	var ajena := fuente.add_track(Animation.TYPE_POSITION_3D)
	fuente.track_set_path(ajena, NodePath("Armature/Skeleton3D:LeftHand"))
	fuente.track_insert_key(ajena, 0.0, Vector3.ONE)
	var sin_mapa := fuente.add_track(Animation.TYPE_ROTATION_3D)
	fuente.track_set_path(sin_mapa, NodePath("Armature/Skeleton3D:LeftRingProximal"))
	fuente.track_insert_key(sin_mapa, 0.0, Quaternion.IDENTITY)

	var convertida := AnimacionesUAL.convertir(fuente, "Figura/Skeleton3D", 0.5)
	_comprobar(convertida.get_track_count() == 1, "solo la cadera conserva posición")
	_comprobar(
		convertida.track_get_path(0) == NodePath("Figura/Skeleton3D:Hips"),
		"la pista apunta al esqueleto de la figura"
	)
	_comprobar(
		convertida.track_get_key_value(0, 0).is_equal_approx(Vector3(0.0, 0.5, 0.05)),
		"la cadera vuelve a la altura de la figura"
	)


func _probar_cache_compartida() -> void:
	var uno := _persona()
	var otro := _persona()
	AnimacionesUAL.reproducir(uno, "sentado")
	AnimacionesUAL.reproducir(otro, "sentado")
	_comprobar(
		(
			Modelos._reproductor(uno).get_animation("ual/sentado")
			== Modelos._reproductor(otro).get_animation("ual/sentado")
		),
		"dos figuras comparten la animación convertida"
	)
	uno.free()
	otro.free()


func _probar_entradas_invalidas() -> void:
	var cuerpo := _persona()
	_comprobar(not AnimacionesUAL.reproducir(cuerpo, "bailar"), "un clip desconocido no suena")
	cuerpo.free()
	var vacio := Node3D.new()
	root.add_child(vacio)
	_comprobar(not AnimacionesUAL.reproducir(vacio, "telefono"), "sin esqueleto no hay clip")
	vacio.free()


func _probar_companero_al_telefono() -> void:
	var cuerpo := _persona()
	var idle := CompaneroIdle3D.new()
	root.add_child(idle)
	idle.configurar(cuerpo, 134, true, false)
	_comprobar(
		Modelos._reproductor(cuerpo).current_animation == "ual/telefono",
		"el compañero del teléfono habla por teléfono"
	)
	idle.free()
	_comprobar(
		not String(Modelos._reproductor(cuerpo).current_animation).begins_with("ual/"),
		"al desmontarse vuelve al idle propio"
	)
	cuerpo.free()


func _persona() -> Node3D:
	var cuerpo := Node3D.new()
	root.add_child(cuerpo)
	Modelos.persona(cuerpo, "persona", Color.GRAY)
	return cuerpo


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
