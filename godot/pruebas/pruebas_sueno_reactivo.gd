extends SceneTree

const OBJETOS_TOCADOS := ["silla", "monitor", "archivador"]

var _pasadas := 0
var _fallos := 0
var _observaciones: Array = []


func _initialize() -> void:
	_probar_sin_objetos_tocados()
	_probar_todas_las_formas()
	_probar_gramatica_simbolica()
	_probar_armario_domestico_cc0()
	_probar_televisor_domestico()
	_probar_espacio_simbolico()
	_probar_reproducibilidad()
	_probar_tarot_no_filtra_pistas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_sin_objetos_tocados() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var creadas := SuenoUtileria.montar(mundo, "crucero", 7, 400)
	_comprobar(creadas.is_empty(), "sin objetos tocados no inventa anomalías")
	_comprobar(
		mundo.find_children("AnomaliaSueno*", "", true, false).is_empty(),
		"sin objetos tocados no monta interactuables de relleno",
	)
	_comprobar(
		mundo.find_child("EspacioSimbolico", false, false) == null,
		"sin original conocido tampoco inventa gramática espacial",
	)
	mundo.queue_free()


func _probar_todas_las_formas() -> void:
	for valor_id in SuenoFormas.ids():
		var id := String(valor_id)
		var mundo := Node3D.new()
		root.add_child(mundo)
		var creadas := SuenoUtileria.montar(mundo, id, 7, 400, [], OBJETOS_TOCADOS)
		_comprobar(creadas.size() == 3, "%s recibe tres anomalías tocadas" % id)
		_comprobar(
			mundo.find_children("AnomaliaSueno*", "", true, false).size() == 3,
			"%s monta tres interactuables tocados" % id,
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


func _probar_gramatica_simbolica() -> void:
	var motivos := {
		"silla": "umbral",
		"monitor": "doble",
		"archivador": "laberinto",
	}
	for objeto_id in motivos:
		var mundo := Node3D.new()
		root.add_child(mundo)
		var creadas := SuenoUtileria.montar(mundo, "crucero", 8, 888, [], [objeto_id])
		_comprobar(creadas.size() == 1, "#888: un original produce una anomalía simbólica")
		if creadas.size() == 1:
			var anomalia: AnomaliaSueno3D = creadas[0]
			var motivo := String(anomalia.get_meta("motivo_simbolico", ""))
			_comprobar(
				motivo == motivos[objeto_id],
				"#888: %s conserva su familia simbólica interna" % objeto_id,
			)
			var original := anomalia.find_child("FormaDeformada", false, false) as Node3D
			var eco := anomalia.find_child("EcoSimbolico", false, false) as Node3D
			_comprobar(eco != null, "#888: %s proyecta un eco geométrico" % objeto_id)
			if eco != null:
				_comprobar(
					String(eco.get_meta("motivo_simbolico", "")) == motivo,
					"#888: el eco comparte el motivo del original",
				)
				_comprobar(
					eco.find_children("*", "CollisionShape3D", true, false).is_empty(),
					"#888: el eco no añade colisión ni objetivo oculto",
				)
				_comprobar(
					original != null and eco.transform != original.transform,
					"#888: el eco deforma composición sin tapar el original",
				)
		mundo.queue_free()

	var desconocido := Node3D.new()
	root.add_child(desconocido)
	var inventadas := SuenoUtileria.montar(desconocido, "crucero", 8, 888, [], ["objeto-ajeno"])
	_comprobar(inventadas.is_empty(), "#888: la gramática no fabrica originales desconocidos")
	desconocido.queue_free()


func _probar_armario_domestico_cc0() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var creadas := SuenoUtileria.montar(mundo, "crucero", 8, 227, [], ["armario_hogar"])
	_comprobar(creadas.size() == 1, "#227: un armario examinado produce una sola anomalía")
	if creadas.size() == 1:
		var armario: AnomaliaSueno3D = creadas[0]
		_comprobar(
			armario.id_catalogo() == "armario-domestico-desencajado",
			"#227: el armario enlaza su entrada estable del catálogo",
		)
		_comprobar(
			String(armario.get_meta("objeto_origen", "")) == "armario_hogar",
			"#227: la deformación conserva el original doméstico tocado",
		)
		_comprobar(
			String(armario.get_meta("motivo_simbolico", "")) == "laberinto",
			"#227: el armario reutiliza la familia laberinto sin inventar otra gramática",
		)
		var visual := armario.find_child("FormaDeformada", false, false) as Node3D
		var asset: Node3D = null
		if visual != null:
			asset = visual.get_node_or_null("AssetCc0") as Node3D
		_comprobar(asset != null, "#227: el sueño reutiliza el GLB CC0 del armario")
		_comprobar(
			visual != null and visual.find_child("RespaldoGeometrico", true, false) == null,
			"#227: el armario no cae al cubo genérico",
		)
		var conserva_paleta := false
		if asset != null:
			for valor_malla in asset.find_children("*", "MeshInstance3D", true, false):
				var malla := valor_malla as MeshInstance3D
				for superficie in malla.mesh.get_surface_count():
					var material := malla.get_active_material(superficie) as ShaderMaterial
					if material != null and material.get_shader_parameter("con_textura"):
						conserva_paleta = true
		_comprobar(conserva_paleta, "#227: la copia onírica conserva la paleta PSX del pack")
	mundo.queue_free()


func _probar_televisor_domestico() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var creadas := SuenoUtileria.montar(mundo, "crucero", 8, 442, [], ["televisor_casa"])
	_comprobar(creadas.size() == 1, "#87: el televisor atendido produce una sola anomalía")
	if creadas.size() == 1:
		var televisor: AnomaliaSueno3D = creadas[0]
		_comprobar(
			televisor.id_catalogo() == "televisor-domestico-desfasado",
			"#87: el televisor enlaza su entrada estable del catálogo",
		)
		_comprobar(
			String(televisor.get_meta("objeto_origen", "")) == "televisor_casa",
			"#87: la deformación conserva el televisor real manipulado durante el día",
		)
		_comprobar(
			String(televisor.get_meta("motivo_simbolico", "")) == "doble",
			"#888: el televisor reutiliza la familia doble sin inventar simbología explícita",
		)
		var visual := televisor.find_child("FormaDeformada", false, false) as Node3D
		_comprobar(visual != null, "#87: el televisor monta una forma reconocible")
		_comprobar(
			visual != null and visual.find_child("RespaldoGeometrico", true, false) == null,
			"#87: el televisor no cae al cubo genérico",
		)
		_comprobar(
			televisor.find_child("EcoSimbolico", false, false) != null,
			"#888: el televisor puede proyectar su doble visual",
		)
	mundo.queue_free()


func _probar_espacio_simbolico() -> void:
	var motivos := {
		"silla": "umbral",
		"monitor": "doble",
		"archivador": "laberinto",
	}
	var mallas_esperadas := {
		"silla": 3,
		"monitor": 4,
		"archivador": 9,
	}
	for objeto_id in motivos:
		var mundo := Node3D.new()
		root.add_child(mundo)
		var creadas := SuenoUtileria.montar(mundo, "crucero", 8, 888, [], [objeto_id])
		var capa := mundo.find_child("EspacioSimbolico", false, false) as Node3D
		_comprobar(capa != null, "#888: %s extiende su motivo al espacio" % objeto_id)
		if capa != null:
			_comprobar(capa.get_child_count() == 1, "#888: un original crea una sola rima espacial")
			var rima := capa.get_child(0) as Node3D
			_comprobar(
				String(rima.get_meta("motivo_simbolico", "")) == motivos[objeto_id],
				"#888: la rima espacial conserva la familia de su original",
			)
			_comprobar(
				String(rima.get_meta("catalogo_origen", "")) == creadas[0].id_catalogo(),
				"#888: la rima espacial conserva el origen catalogado",
			)
			_comprobar(
				_cerca_xz(rima.position, creadas[0].position),
				"#888: la composición espacial nace alrededor del original",
			)
			_comprobar(
				rima.find_children("*", "CollisionShape3D", true, false).is_empty(),
				"#888: la capa espacial no modifica colisiones",
			)
			_comprobar(
				rima.find_children("*", "Control", true, false).is_empty(),
				"#888: la capa espacial no añade HUD ni rótulos",
			)
			var mallas := rima.find_children("*", "MeshInstance3D", true, false)
			_comprobar(
				mallas.size() == int(mallas_esperadas[objeto_id]),
				"#888: %s usa una composición espacial acotada" % objeto_id,
			)
			var distancia_max := 0.0
			for valor_malla in mallas:
				var malla := valor_malla as Node3D
				var delta := _posicion_relativa(malla, rima)
				distancia_max = maxf(distancia_max, Vector2(delta.x, delta.z).length())
			_comprobar(
				distancia_max > 0.75,
				"#888: el motivo modifica lectura del espacio, no solo el objeto",
			)
		mundo.queue_free()

	var desconocido := Node3D.new()
	root.add_child(desconocido)
	SuenoUtileria.montar(desconocido, "crucero", 8, 888, [], ["objeto-ajeno"])
	_comprobar(
		desconocido.find_child("EspacioSimbolico", false, false) == null,
		"#888: un original desconocido tampoco fabrica arquitectura simbólica",
	)
	desconocido.queue_free()


func _probar_reproducibilidad() -> void:
	var a := Node3D.new()
	var b := Node3D.new()
	root.add_child(a)
	root.add_child(b)
	var primera := SuenoUtileria.montar(a, "crucero", 9, 12345, [], OBJETOS_TOCADOS)
	var segunda := SuenoUtileria.montar(b, "crucero", 9, 12345, [], OBJETOS_TOCADOS)
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
		_comprobar(
			(
				primera[i].get_meta("motivo_simbolico", "")
				== segunda[i].get_meta("motivo_simbolico", "")
			),
			"motivo simbólico reproducible %d" % i,
		)
	var capa_a := a.find_child("EspacioSimbolico", false, false) as Node3D
	var capa_b := b.find_child("EspacioSimbolico", false, false) as Node3D
	_comprobar(capa_a != null and capa_b != null, "#888: ambas semillas montan capa espacial")
	if capa_a != null and capa_b != null:
		_comprobar(
			capa_a.get_child_count() == capa_b.get_child_count(),
			"#888: la cantidad de rimas espaciales es reproducible",
		)
		for i in range(capa_a.get_child_count()):
			var rima_a := capa_a.get_child(i) as Node3D
			var rima_b := capa_b.get_child(i) as Node3D
			_comprobar(
				rima_a.transform == rima_b.transform, "#888: rima espacial reproducible %d" % i
			)
	a.queue_free()
	b.queue_free()


func _probar_tarot_no_filtra_pistas() -> void:
	var folio_luna := "F-1996-00187"

	var sin_recoger := Node3D.new()
	root.add_child(sin_recoger)
	var ocultas := SuenoUtileria.montar(sin_recoger, "crucero", 4, 8700, [folio_luna], [], [])
	_comprobar(ocultas.is_empty(), "leer el folio sin recoger la carta no fabrica utilería")
	_comprobar(
		sin_recoger.find_child("EspacioSimbolico", false, false) == null,
		"#888: tarot no recogido tampoco deja huella espacial",
	)
	sin_recoger.queue_free()

	var recogida := Node3D.new()
	root.add_child(recogida)
	var visibles := SuenoUtileria.montar(
		recogida, "crucero", 4, 8700, [folio_luna], [], ["la-luna"]
	)
	_comprobar(visibles.size() == 1, "solo tarot válido produce una sola anomalía, sin relleno")
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
		_comprobar(
			String(tarot.get_meta("motivo_simbolico", "")) == "ciclo-centro",
			"#888: el tarot recogido usa ciclo/centro sin rotular el arcano",
		)
		_comprobar(
			tarot.find_child("EcoSimbolico", false, false) != null,
			"#888: el tarot conocido puede proyectar un eco estructural",
		)
		var capa_tarot := recogida.find_child("EspacioSimbolico", false, false) as Node3D
		_comprobar(capa_tarot != null, "#888: tarot conocido puede rimar con el espacio")
		if capa_tarot != null:
			var rima_tarot := capa_tarot.get_child(0) as Node3D
			_comprobar(
				String(rima_tarot.get_meta("motivo_simbolico", "")) == "ciclo-centro",
				"#888: la rima del tarot conserva ciclo/centro",
			)
			_comprobar(
				rima_tarot.find_children("*", "MeshInstance3D", true, false).size() == 8,
				"#888: ciclo/centro se expresa como ocho marcas radiales bajas",
			)
	recogida.queue_free()

	var con_objetos := Node3D.new()
	root.add_child(con_objetos)
	var mixtas := SuenoUtileria.montar(
		con_objetos, "crucero", 4, 8700, [folio_luna], OBJETOS_TOCADOS, ["la-luna"]
	)
	_comprobar(mixtas.size() == 3, "tarot y objetos tocados respetan el máximo de tres anomalías")
	_comprobar(
		_buscar_id(mixtas, "tarot-geometria-viva") != null,
		"el tarot válido no se pierde cuando hay otros originales del día",
	)
	var capa_mixta := con_objetos.find_child("EspacioSimbolico", false, false) as Node3D
	_comprobar(
		capa_mixta != null and capa_mixta.get_child_count() == 3,
		"#888: el límite de tres anomalías limita también sus tres rimas espaciales",
	)
	con_objetos.queue_free()

	var otro_folio := Node3D.new()
	root.add_child(otro_folio)
	var ajenas := SuenoUtileria.montar(
		otro_folio, "crucero", 4, 8700, ["ACTA-SIN-TAROT"], [], ["la-luna"]
	)
	_comprobar(
		ajenas.is_empty(),
		"una carta recogida no aparece si su documento no fue leído hoy",
	)
	_comprobar(
		otro_folio.find_child("EspacioSimbolico", false, false) == null,
		"#888: tarot ajeno a lo leído hoy no altera el espacio",
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


func _posicion_relativa(nodo: Node3D, ancestro: Node3D) -> Vector3:
	var acumulada := nodo.transform
	var padre := nodo.get_parent()
	while padre != null and padre != ancestro:
		if padre is Node3D:
			acumulada = (padre as Node3D).transform * acumulada
		padre = padre.get_parent()
	return acumulada.origin


func _cerca_xz(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)) < 0.01


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SuenoReactivo: " + nombre)
