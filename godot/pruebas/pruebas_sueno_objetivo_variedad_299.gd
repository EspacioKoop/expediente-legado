extends SceneTree

var _pasadas := 0
var _fallos := 0
var _completados: Array[String] = []
var _rumbos: Array[Vector3] = []


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_politica()
	await _probar_secuencia()
	await _probar_retorno()
	await _probar_permanencia()
	print("Sueño variedad objetivos 299: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_politica() -> void:
	var dia_uno := SuenoObjetivosVariedad.tipos_para(1, "montana")
	var dia_dos := SuenoObjetivosVariedad.tipos_para(2, "montana")
	_comprobar("cada noche ofrece tres objetivos", dia_uno.size(), 3)
	var unicos := {}
	for tipo in dia_uno:
		unicos[tipo] = true
	_comprobar("los tres objetivos de una noche son distintos", unicos.size(), 3)
	_comprobar("otra semilla rota el repertorio", dia_dos == dia_uno, false)
	_comprobar(
		"retorno declara ida y vuelta",
		SuenoObjetivosVariedad.condicion(SuenoObjetivosVariedad.TIPO_RETORNO),
		"ida_y_vuelta",
	)


func _actor(posicion: Vector3) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	# La transformación inicial debe llegar al PhysicsServer antes de entrar al
	# árbol. Añadirlo en ZERO y moverlo en el mismo frame puede producir un
	# body_entered fantasma en el primer checkpoint del smoke.
	actor.position = posicion
	var colision := CollisionShape3D.new()
	var forma := CapsuleShape3D.new()
	forma.radius = 0.35
	forma.height = 1.5
	colision.shape = forma
	actor.add_child(colision)
	root.add_child(actor)
	return actor


func _controlador() -> SuenoObjetivoVariedad3D:
	var controlador := SuenoObjetivoVariedad3D.new()
	root.add_child(controlador)
	controlador.completado.connect(_al_completar)
	controlador.rumbo_cambiado.connect(_al_rumbo)
	return controlador


func _probar_secuencia() -> void:
	_completados.clear()
	_rumbos.clear()
	var actor := _actor(Vector3(8.0, 0.0, 0.0))
	var controlador := _controlador()
	var puntos := [Vector3.ZERO, Vector3(4.0, 0.0, 0.0)]
	_comprobar(
		"secuencia se configura",
		(
			controlador
			. configurar(
				"escena:secuencia",
				SuenoObjetivoVariedad3D.TIPO_SECUENCIA,
				actor,
				puntos,
			)
		),
		true,
	)
	await physics_frame
	actor.position = puntos[1]
	await physics_frame
	await physics_frame
	_comprobar("saltar al segundo paso no completa", _completados.size(), 0)

	actor.position = puntos[0]
	await physics_frame
	await physics_frame
	_comprobar("primer paso cambia el rumbo", _rumbos.size(), 1)
	_comprobar("rumbo apunta al segundo paso", _rumbos[0], puntos[1])

	actor.position = Vector3(8.0, 0.0, 0.0)
	await physics_frame
	actor.position = puntos[1]
	await physics_frame
	await physics_frame
	_comprobar("segundo paso completa una vez", _completados, ["escena:secuencia"])
	_comprobar("controlador queda terminal", controlador.terminado(), true)
	controlador.queue_free()
	actor.queue_free()
	await process_frame


func _probar_retorno() -> void:
	_completados.clear()
	_rumbos.clear()
	var actor := _actor(Vector3(10.0, 0.0, 0.0))
	var origen := Vector3(6.0, 0.0, 0.0)
	var foco := Vector3.ZERO
	var controlador := _controlador()
	_comprobar(
		"retorno se configura",
		(
			controlador
			. configurar(
				"escena:retorno",
				SuenoObjetivoVariedad3D.TIPO_RETORNO,
				actor,
				[foco, origen],
			)
		),
		true,
	)
	await physics_frame
	actor.position = foco
	await physics_frame
	await physics_frame
	_comprobar("llegar al foco aún no completa retorno", _completados.size(), 0)
	_comprobar("retorno reorienta hacia el origen", _rumbos, [origen])
	actor.position = Vector3(10.0, 0.0, 0.0)
	await physics_frame
	actor.position = origen
	await physics_frame
	await physics_frame
	_comprobar("volver al origen completa", _completados, ["escena:retorno"])
	controlador.queue_free()
	actor.queue_free()
	await process_frame


func _probar_permanencia() -> void:
	_completados.clear()
	_rumbos.clear()
	var actor := _actor(Vector3(5.0, 0.0, 0.0))
	var controlador := _controlador()
	_comprobar(
		"permanencia se configura",
		(
			controlador
			. configurar(
				"escena:permanencia",
				SuenoObjetivoVariedad3D.TIPO_PERMANENCIA,
				actor,
				[Vector3.ZERO],
			)
		),
		true,
	)
	await physics_frame
	actor.position = Vector3.ZERO
	await physics_frame
	await physics_frame
	controlador._physics_process(SuenoObjetivoVariedad3D.TIEMPO_PERMANENCIA * 0.6)
	_comprobar("medio intervalo no completa", _completados.size(), 0)
	actor.position = Vector3(5.0, 0.0, 0.0)
	await physics_frame
	await physics_frame
	actor.position = Vector3.ZERO
	await physics_frame
	await physics_frame
	controlador._physics_process(SuenoObjetivoVariedad3D.TIEMPO_PERMANENCIA + 0.01)
	_comprobar("salir reinicia y volver permite completar", _completados, ["escena:permanencia"])
	controlador._physics_process(SuenoObjetivoVariedad3D.TIEMPO_PERMANENCIA + 1.0)
	_comprobar("permanencia terminal no duplica", _completados.size(), 1)
	controlador.queue_free()
	actor.queue_free()
	await process_frame


func _al_completar(objetivo_id: String) -> void:
	_completados.append(objetivo_id)


func _al_rumbo(posicion: Vector3) -> void:
	_rumbos.append(posicion)


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO variedad #299: %s (obtenido=%s esperado=%s)" % [nombre, obtenido, esperado])
