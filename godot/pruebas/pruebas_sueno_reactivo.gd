extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_todas_las_formas()
	_probar_reproducibilidad()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_todas_las_formas() -> void:
	for id in SuenoFormas.ids():
		var mundo := Node3D.new()
		root.add_child(mundo)
		var creadas := SuenoUtileria.montar(mundo, id, 7, 400)
		_comprobar(creadas.size() == 3, "%s recibe tres anomalías" % id)
		_comprobar(
			mundo.find_children("AnomaliaSueno*", "AnomaliaSueno3D", true, false).size() == 3,
			"%s monta tres interactuables" % id,
		)

		var forma := SuenoFormas.de(id)
		var bloques: Array = forma["bloques"]
		var entrada: Vector2i = forma["entrada"]
		var primera := Planta.a_la_vista(bloques, entrada, 3)
		var centro_primera := Planta.centro_en_metros(bloques, primera)
		_comprobar(
			_cerca_xz(creadas[0].position, centro_primera),
			"%s deja una anomalía a la vista al entrar" % id,
		)

		for anomalia in creadas:
			_comprobar(_esta_en_planta(anomalia.position, bloques), "%s coloca dentro de planta" % id)
			_comprobar(
				anomalia.texto_accion().begins_with("Examinar "),
				"%s usa verbo semántico de examen" % id,
			)
			_comprobar(not anomalia.reactiva(), "%s empieza en estado base" % id)
			_comprobar(not anomalia.luz_visible(), "%s empieza sin respuesta luminosa" % id)
			var escala_base := anomalia.escala_visual()
			_comprobar(anomalia.interactuar(root), "%s acepta interactuar" % id)
			_comprobar(anomalia.reactiva(), "%s cambia estado al examinar" % id)
			_comprobar(anomalia.luz_visible(), "%s responde con luz local" % id)
			_comprobar(
				anomalia.escala_visual() != escala_base,
				"%s cambia deformación visible" % id,
			)
			_comprobar(anomalia.interactuar(root), "%s acepta segundo examen" % id)
			_comprobar(not anomalia.reactiva(), "%s vuelve al estado base" % id)
			_comprobar(anomalia.escala_visual() == escala_base, "%s restaura su forma" % id)
		mundo.queue_free()


func _probar_reproducibilidad() -> void:
	var a := Node3D.new()
	var b := Node3D.new()
	root.add_child(a)
	root.add_child(b)
	var primera := SuenoUtileria.montar(a, "crucero", 9, 12345)
	var segunda := SuenoUtileria.montar(b, "crucero", 9, 12345)
	for i in range(3):
		_comprobar(primera[i].position == segunda[i].position, "posición reproducible %d" % i)
		_comprobar(
			primera[i].nombre_objeto == segunda[i].nombre_objeto,
			"orden reproducible %d" % i,
		)
	a.queue_free()
	b.queue_free()


func _esta_en_planta(posicion: Vector3, bloques: Array) -> bool:
	for celda in Planta.celdas(bloques).keys():
		if _cerca_xz(posicion, Planta.centro_en_metros(bloques, celda)):
			return true
	return false


func _cerca_xz(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)) < 0.01


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SuenoReactivo: " + nombre)
