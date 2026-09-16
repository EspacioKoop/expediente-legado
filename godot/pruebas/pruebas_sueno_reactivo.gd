extends SceneTree

var _pasadas := 0
var _fallos := 0
var _observaciones: Array = []


func _initialize() -> void:
	_probar_todas_las_formas()
	_probar_reproducibilidad()
	_probar_tarot_no_filtra_pistas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_todas_las_formas() -> void:
	for valor_id in SuenoFormas.ids():
		var id := String(valor_id)
		var mundo := Node3D.new()
		root.add_child(mundo)
		var creadas := SuenoUtileria.montar(mundo, id, 7, 400)
		_comprobar(creadas.size() == 3, "%s recibe tres anomalías" % id)
		_comprobar(
			mundo.find_children("AnomaliaSueno*", "", true, false).size() == 3,
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
			_comprobar(
				_esta_en_planta(anomalia.position, bloques), "%s coloca dentro de planta" % id
			)
			_comprobar(
				anomalia.texto_accion().begins_with("Examinar "),
				"%s usa verbo semántico de examen" % id,
			)
			var catalogo_id: String = anomalia.id_catalogo()
			_comprobar(not catalogo_id.is_empty(), "%s declara id de catálogo" % id)
			_comprobar(
				not CatalogoAnomalias.ficha(catalogo_id).is_empty(),
				"%s enlaza una entrada real del catálogo" % id,
			)
			_observaciones.clear()
			anomalia.observada.connect(_capturar_observacion)
			_comprobar(not anomalia.reactiva(), "%s empieza en estado base" % id)
			_comprobar(not anomalia.luz_visible(), "%s empieza sin respuesta luminosa" % id)
			var escala_base: Vector3 = anomalia.escala_visual()
			_comprobar(anomalia.interactuar(root), "%s acepta interactuar" % id)
			_comprobar(anomalia.reactiva(), "%s cambia estado al examinar" % id)
			_comprobar(anomalia.luz_visible(), "%s responde con luz local" % id)
			_comprobar(
				anomalia.escala_visual() != escala_base,
				"%s cambia deformación visible" % id,
			)
			_comprobar(_observaciones.size() == 1, "%s emite una observación" % id)
			if _observaciones.size() == 1:
				_comprobar(
					_observaciones[0]["id"] == catalogo_id,
					"%s emite el id estable esperado" % id,
				)
				_comprobar(
					_observaciones[0]["actor"] == root,
					"%s conserva el actor que examinó" % id,
				)
			_comprobar(anomalia.interactuar(root), "%s acepta segundo examen" % id)
			_comprobar(not anomalia.reactiva(), "%s vuelve al estado base" % id)
			_comprobar(anomalia.escala_visual() == escala_base, "%s restaura su forma" % id)
			_comprobar(
				_observaciones.size() == 2,
				"%s notifica cada examen y deja la idempotencia al catálogo" % id,
			)
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
		_comprobar(
			primera[i].id_catalogo() == segunda[i].id_catalogo(),
			"id de catálogo reproducible %d" % i,
		)
	a.queue_free()
	b.queue_free()


func _probar_tarot_no_filtra_pistas() -> void:
	var folio_luna := "F-1996-00187"

	var sin_recoger := Node3D.new()
	root.add_child(sin_recoger)
	var ocultas := SuenoUtileria.montar(sin_recoger, "crucero", 4, 8700, [folio_luna], [])
	_comprobar(
		_buscar_id(ocultas, "tarot-geometria-viva") == null,
		"leer el folio sin recoger la carta no la filtra al sueño",
	)
	sin_recoger.queue_free()

	var recogida := Node3D.new()
	root.add_child(recogida)
	var visibles := SuenoUtileria.montar(recogida, "crucero", 4, 8700, [folio_luna], ["la-luna"])
	var tarot = _buscar_id(visibles, "tarot-geometria-viva")
	_comprobar(tarot != null, "una carta recogida desde un folio de hoy sí puede deformarse")
	if tarot != null:
		_comprobar(
			String(tarot.get_meta("documento_origen", "")) == folio_luna,
			"la deformación conserva el folio real que la originó",
		)
		_comprobar(
			String(tarot.get_meta("carta_origen", "")) == "la-luna",
			"la deformación conserva el id de la carta reconocida",
		)
		_comprobar(
			tarot.find_child("Carta", true, false) != null,
			"el tarot mantiene silueta propia en vez de caer al cubo genérico",
		)
	recogida.queue_free()

	var otro_folio := Node3D.new()
	root.add_child(otro_folio)
	var ajenas := SuenoUtileria.montar(
		otro_folio, "crucero", 4, 8700, ["ACTA-SIN-TAROT"], ["la-luna"]
	)
	_comprobar(
		_buscar_id(ajenas, "tarot-geometria-viva") == null,
		"una carta recogida no aparece si su documento no fue leído hoy",
	)
	otro_folio.queue_free()


func _buscar_id(anomalias: Array, id: String):
	for anomalia in anomalias:
		if anomalia.id_catalogo() == id:
			return anomalia
	return null


func _capturar_observacion(anomalia_id: String, actor: Node) -> void:
	_observaciones.append({"id": anomalia_id, "actor": actor})


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
