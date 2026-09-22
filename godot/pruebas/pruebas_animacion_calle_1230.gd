## Animación ambiental sobre la calle real (#1230).
##
## Lo que aquí se comprueba no se puede comprobar leyendo el texto de un guion:
## que el lote animado se monta sobre las fachadas vivas de verdad, que sigue
## siendo UNA llamada de dibujo, que los árboles del trayecto están donde el
## viento los busca y que el reparto llega a registrar piezas.
extends SceneTree

const DIA := preload("res://escenas/dia.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Ejecuta esta prueba desde unittest con datos aislados.")
		quit(1)
		return
	_probar.call_deferred()


func _probar() -> void:
	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	dia._entrar_en("trayecto")
	await process_frame

	var calle := dia._mundo.get_node_or_null("CalleIdentidad") as Node3D
	_comprobar(calle != null, "el trayecto sigue montando la calle")
	if calle == null:
		_terminar(dia)
		return
	var vivas := calle.get_node_or_null("FachadasVivas") as Node3D
	_comprobar(vivas != null, "el trayecto sigue montando las fachadas vivas de #861")
	if vivas == null:
		_terminar(dia)
		return

	var lote := vivas.get_node_or_null(CalleVentanasVivas.NOMBRE_LOTE) as MultiMeshInstance3D
	_comprobar(lote != null, "se monta el lote de ventanas animadas")
	if lote == null:
		_terminar(dia)
		return

	var animadas := lote.multimesh.instance_count
	_comprobar(animadas > 0, "el lote anima al menos una ventana")
	_comprobar(
		animadas <= CalleVentanasVivas.MAX_VENTANAS, "el lote respeta su tope de ventanas animadas"
	)
	_comprobar(
		lote.multimesh.use_custom_data,
		"el lote lleva datos por instancia: es lo que distingue una ventana de otra"
	)
	_comprobar(
		(
			(
				vivas
				. find_children("*", "MultiMeshInstance3D", false, false)
				. filter(func(nodo): return nodo.name == CalleVentanasVivas.NOMBRE_LOTE)
				. size()
			)
			== 1
		),
		"todas las ventanas animadas caben en una sola llamada de dibujo"
	)
	_comprobar(
		lote.material_override is ShaderMaterial,
		"el parpadeo lo pone un shader y no una escritura por fotograma"
	)
	_comprobar(
		lote.visibility_range_end > 0.0, "el lote animado se apaga a distancia como el estático"
	)

	# Un MultiMesh no devuelve sus datos sin servidor de render, así que la
	# regresión lee la copia en CPU: es exactamente lo que se le mandó.
	var distintas := {}
	for indice in animadas:
		distintas[dia._ventanas_vivas.dato_de(indice).to_html()] = true
	_comprobar(distintas.size() > 1, "las ventanas no arrancan todas con la misma luz")

	var pisos := calle.get_node_or_null("PisosFachada") as Node3D
	var tapadas := 0
	for indice in animadas:
		if pisos == null:
			break
		var nombre: String = dia._ventanas_vivas.nombre_de(indice)
		var ventana := pisos.get_node_or_null(nombre) as Node3D
		if ventana == null:
			continue
		var animada: Vector3 = dia._ventanas_vivas.posicion_de(indice)
		# El plano animado tapa al fondo estático desde la calle: mismo hueco,
		# unos milímetros por delante.
		if (
			is_equal_approx(animada.y, ventana.position.y)
			and is_equal_approx(animada.z, ventana.position.z)
		):
			tapadas += 1
	_comprobar(tapadas == animadas, "cada plano animado ocupa el hueco de su ventana")

	# El arbolado CC0 lo monta su propio controlador desde `_process`, o sea un
	# fotograma más tarde que todo esto. Es justo el caso que el viento tiene
	# que sobrevivir sin que nadie encadene el orden de montaje.
	await process_frame
	var arboles: Array = dia._mundo.find_children("*", "MeshInstance3D", true, false).filter(
		func(nodo): return nodo.is_in_group(VientoAmbiental.GRUPO_FOLLAJE)
	)
	_comprobar(not arboles.is_empty(), "el follaje del trayecto entra en el grupo del viento")
	dia.animador_ambiental().avanzar(0.3)
	_comprobar(
		dia._viento != null and dia._viento.materiales() > 0,
		"el viento acaba encontrando el follaje del trayecto"
	)
	_comprobar(
		dia._viento == null or dia._viento.fuerza_actual() > 0.0,
		"con el clima del día el follaje se mece"
	)

	var animador: AnimadorAmbiental3D = dia.animador_ambiental()
	var estado: Dictionary = animador.estado()
	_comprobar(int(estado["piezas"]) >= animadas, "el animador reparte al menos las ventanas")
	_comprobar(
		int(estado["presupuesto"]) == AnimacionAmbiental.PRESUPUESTO,
		"el trayecto no se salta el presupuesto ambiental"
	)

	var cambiadas := 0
	var antes: Array[Color] = []
	for indice in animadas:
		antes.append(dia._ventanas_vivas.dato_de(indice))
	var sitio: Vector3 = dia._ventanas_vivas.posicion_de(0)
	animador.observar_desde(sitio + Vector3(3.0, 0.0, 0.0), Vector3(-1.0, 0.0, 0.0))
	for salto in 6:
		animador.avanzar(CalleVentanasVivas.CICLO)
	for indice in animadas:
		if not dia._ventanas_vivas.dato_de(indice).is_equal_approx(antes[indice]):
			cambiadas += 1
	_comprobar(cambiadas > 0, "al pasar el tiempo el barrio cambia de luz sin remontar nada")

	dia._entrar_en("casa")
	await process_frame
	_comprobar(
		int(dia.animador_ambiental().estado()["piezas"]) == 0,
		"al cambiar de fase no quedan piezas apuntando a un mundo que ya no existe"
	)

	_terminar(dia)


func _terminar(dia) -> void:
	dia.queue_free()
	await process_frame
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO AnimacionAmbiental: " + nombre)
