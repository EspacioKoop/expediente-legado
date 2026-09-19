## Casa redistribuida por zonas con mobiliario CC0 (#227).
extends SceneTree

const Hogar := preload("res://guion/casa_hogar_cc0.gd")
const DIA := preload("res://escenas/dia.tscn")

## Volúmenes en planta (x, z) que deben quedar libres para jugar.
const ENTRADA := Rect2(0.05, 2.95, 0.9, 0.9)
const PASO_A_CAMA := Rect2(-0.45, -1.6, 0.9, 3.6)
const PIE_DE_CAMA := Rect2(-1.55, -1.6, 1.1, 0.7)

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	if OS.get_environment("LEGADO_PRUEBAS_AISLADAS") != "1":
		printerr("Ejecuta esta prueba desde unittest con datos aislados.")
		quit(1)
		return
	_probar.call_deferred()


func _probar() -> void:
	_comprobar(Hogar.montar(null) == null, "sin raíz no hay montaje")
	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	dia._entrar_en("casa")
	await process_frame
	var mundo: Node3D = dia._mundo
	var lote := mundo.get_node_or_null("CasaHogarCC0") as Node3D
	_comprobar(lote != null, "la casa monta el lote CC0")
	if lote == null:
		quit(1)
		return
	_comprobar(lote.get_child_count() == Hogar.PIEZAS.size(), "todas las piezas cargan su GLB")
	_comprobar(Hogar.montar(mundo) == lote, "montaje idempotente")

	# #133: la distribución doméstica y el acceso a la consola se validan sobre
	# la escena real, no solo buscando literales en los scripts.
	var habitaciones := mundo.get_node_or_null(Hogar.NOMBRE_HABITACIONES) as Node3D
	_comprobar(habitaciones != null, "la casa monta habitaciones físicas")
	if habitaciones != null:
		var frente := habitaciones.get_node_or_null("TabiqueDormitorioFrente") as StaticBody3D
		var lateral := habitaciones.get_node_or_null("TabiqueDormitorioLateral") as StaticBody3D
		var dintel := habitaciones.get_node_or_null("DintelDormitorio") as StaticBody3D
		_comprobar(frente != null, "tabique frontal del dormitorio presente")
		_comprobar(lateral != null, "tabique lateral del dormitorio presente")
		_comprobar(dintel != null, "dintel del dormitorio presente")
		if frente != null and lateral != null:
			var caja_frente := _caja_colision(frente)
			var caja_lateral := _caja_colision(lateral)
			var paso_util := caja_lateral.position.x - caja_frente.end.x
			_comprobar(paso_util >= 0.90, "la puerta conserva al menos 90 cm de paso físico")

	var transiciones := mundo.get_node_or_null(Hogar.NOMBRE_TRANSICIONES) as Node3D
	_comprobar(transiciones != null, "la casa monta transiciones domésticas")
	if transiciones != null:
		for nombre in [
			"JambaDormitorioIzquierda",
			"JambaDormitorioDerecha",
			"MarcoSuperiorDormitorio",
			"UmbralDormitorio",
			"AlfombraSalon",
		]:
			_comprobar(transiciones.has_node(nombre), "acabado doméstico presente: " + nombre)

	var consola := mundo.get_node_or_null("ConsolaSobremesa98") as ConsolaSobremesa98
	_comprobar(consola != null, "la consola de sobremesa sigue montada")
	if consola != null:
		_comprobar(
			consola.position.is_equal_approx(Vector3(-3.58, 0.54, 2.00)),
			"la consola conserva la posición despejada del rincón de TV",
		)
		_comprobar(
			is_equal_approx(consola.rotation_degrees.y, -90.0),
			"la consola mira hacia el interior del salón",
		)
		var enfoque: CollisionShape3D = null
		for hijo in consola.get_children():
			if hijo is CollisionShape3D:
				enfoque = hijo
				break
		_comprobar(enfoque != null, "la consola conserva volumen de foco")
		if enfoque != null and enfoque.shape is BoxShape3D:
			var caja_enfoque := enfoque.shape as BoxShape3D
			_comprobar(
				caja_enfoque.size.is_equal_approx(Vector3(0.68, 0.38, 0.52)),
				"el volumen de foco sigue ampliado para el playtest",
			)

		# Simula una mirada desde el espacio libre delante del rincón de TV con el
		# detector real del jugador. La distancia queda por debajo de sus 2,4 m.
		var observador := Node3D.new()
		observador.name = "ObservadorConsolaPrueba"
		observador.position = Vector3(-1.45, 1.55, 2.35)
		mundo.add_child(observador)
		observador.look_at(consola.global_position + Vector3(0.0, 0.20, 0.0), Vector3.UP)
		var detector := DetectorInteraccion3D.new()
		observador.add_child(detector)
		await physics_frame
		detector.force_raycast_update()
		_comprobar(detector.is_colliding(), "el detector real alcanza un objetivo desde el salón")
		_comprobar(detector.get_collider() == consola, "la consola se adquiere desde el salón")
		observador.queue_free()
	_comprobar(lote.find_children("*", "Light3D", true, false).is_empty(), "sin luces nuevas")
	_comprobar(lote.find_children("*", "RigidBody3D", true, false).is_empty(), "sin dinámica")

	# La planta sale del catálogo: desde #785 la casa crece hacia la cocina y la
	# entrada, así que los muros ya no son simétricos respecto al origen.
	var medidas: Vector2 = EspaciosCatalogo.CASA["suelo"]
	var centro: Vector2 = EspaciosCatalogo.CASA.get("centro_suelo", Vector2.ZERO)
	var interior := Rect2(centro - medidas * 0.5, medidas)
	var cajas := {}
	var triangulos := 0
	for pieza in lote.get_children():
		var caja := _caja_global(pieza)
		cajas[str(pieza.name)] = caja
		for malla in pieza.find_children("*", "MeshInstance3D", true, false):
			for i in malla.mesh.get_surface_count():
				triangulos += malla.mesh.surface_get_array_index_len(i) / 3
				var material := malla.get_active_material(i) as ShaderMaterial
				_comprobar(material != null, "shader PSX común: " + str(pieza.name))
				_comprobar(
					material != null and material.get_shader_parameter("con_textura"),
					"conserva la paleta del pack: " + str(pieza.name)
				)
		var nombre := str(pieza.name)
		_comprobar(caja.position.x > interior.position.x, "dentro de la casa: " + nombre)
		_comprobar(caja.end.x < interior.end.x, "dentro de la casa: " + nombre)
		_comprobar(caja.position.z > interior.position.y, "dentro de la casa: " + nombre)
		_comprobar(caja.end.z < interior.end.y, "dentro de la casa: " + nombre)
		var planta := Rect2(caja.position.x, caja.position.z, caja.size.x, caja.size.z)
		_comprobar(not planta.intersects(ENTRADA), "entrada despejada: " + nombre)
		_comprobar(not planta.intersects(PASO_A_CAMA), "paso hacia la cama libre: " + nombre)
		_comprobar(not planta.intersects(PIE_DE_CAMA), "acceso a la cama libre: " + nombre)
		if pieza is StaticBody3D:
			# Solo la colisión física DIRECTA del mueble. Un Area3D interactiva
			# puede tener su propia forma y no define el volumen sólido del prop.
			var colision: CollisionShape3D = null
			for hijo in pieza.get_children():
				if hijo is CollisionShape3D:
					colision = hijo
					break
			_comprobar(colision != null, "colisión física presente: " + nombre)
			if colision != null:
				var volumen: AABB = (
					colision.global_transform * AABB(-colision.shape.size / 2, colision.shape.size)
				)
				_comprobar(
					volumen.position.is_equal_approx(caja.position), "colisión alineada: " + nombre
				)
			_comprobar(absf(caja.position.y) < 0.01, "apoyado en el suelo: " + nombre)
	print("Casa CC0: %d piezas, %d triángulos" % [lote.get_child_count(), triangulos])
	_comprobar(triangulos <= 5000, "presupuesto geométrico acotado")

	# Sin solapes entre muebles con cuerpo físico.
	var solidos := []
	for pieza in lote.get_children():
		if pieza is StaticBody3D:
			solidos.append(str(pieza.name))
	for i in solidos.size():
		for j in range(i + 1, solidos.size()):
			var a: AABB = cajas[solidos[i]].grow(-0.02)
			var b: AABB = cajas[solidos[j]].grow(-0.02)
			_comprobar(not a.intersects(b), "sin solape %s/%s" % [solidos[i], solidos[j]])

	# Coherencia de zonas.
	var mesa: AABB = cajas["MesaComedorHogar"]
	var cigarro: Vector3 = EspaciosCatalogo.CASA["cigarros"][0]
	_comprobar(
		Rect2(mesa.position.x, mesa.position.z, mesa.size.x, mesa.size.z).has_point(
			Vector2(cigarro.x, cigarro.z)
		),
		"el cigarro sigue sobre la mesa"
	)
	_comprobar(absf(mesa.end.y - cigarro.y) < 0.05, "el cigarro apoya en el tablero")
	var mueble_tv: AABB = cajas["MuebleTVHogar"]
	var tele := mundo.get_node_or_null("TelevisorCasaInteractuable") as Node3D
	_comprobar(tele != null, "el televisor interactivo sigue montado")
	if tele != null:
		var base: float = tele.global_position.y - EspaciosCatalogo.CASA["bultos"][2]["tam"].y / 2.0
		_comprobar(absf(base - mueble_tv.end.y) < 0.05, "la tele descansa sobre su mueble")
		var cristal := tele.get_node_or_null("CristalPantallaTV") as MeshInstance3D
		var emision := tele.get_node_or_null("EmisionPantallaTV") as Node3D
		_comprobar(cristal != null, "la carcasa conserva una pantalla apagada distinguible")
		_comprobar(emision != null, "la tele monta una superficie encendida separada")
		if cristal != null and emision != null:
			_comprobar(cristal.visible, "la pantalla apagada se ve como cristal oscuro")
			_comprobar(not emision.visible, "la emisión permanece oculta con la tele apagada")
			var tele_interactiva := tele as TelevisionInteractiva3D
			tele_interactiva.alternar_desde_mando()
			_comprobar(not cristal.visible, "al encender se oculta el cristal apagado")
			_comprobar(emision.visible, "al encender aparece la superficie CRT")
			tele_interactiva.alternar_desde_mando()
	var armario := lote.get_node_or_null("ArmarioHogar") as Node3D
	_comprobar(armario != null, "el armario CC0 sigue montado")
	var examinar_armario: Interactuable3D = null
	if armario != null:
		examinar_armario = armario.get_node_or_null("ExaminarArmarioHogar") as Interactuable3D
	_comprobar(examinar_armario != null, "el armario CC0 es examinable")
	if examinar_armario != null:
		_comprobar(
			examinar_armario.texto_accion() == "Examinar armario", "el prompt nombra el original"
		)
		_comprobar(examinar_armario.interactuar(root), "examinar el armario acepta interacción")
		_comprobar(
			ObjetosOniricos.del_dia(dia.jornada).has(Hogar.ARMARIO_OBJETO_ONIRICO),
			"examinar el armario conserva su original para el sueño",
		)

	var sofa := mundo.get_node_or_null("SofaCasa") as Node3D
	_comprobar(sofa != null and sofa.has_node("VisualHogar"), "el sofá usa el modelo CC0")
	if sofa != null:
		var visibles := 0
		for malla in sofa.find_children("*", "MeshInstance3D", true, false):
			if malla.layers != 0:
				visibles += 1
		_comprobar(visibles > 0, "el sofá sigue visible")
		_comprobar(sofa.global_position.x > mueble_tv.end.x + 1.0, "el sofá mira a la tele")
	for horno in ["HornoHogar", "LavadoraHogar"]:
		_comprobar(cajas[horno].position.x > 2.8, horno + " contra el muro de la cocina")

	dia.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _caja_colision(cuerpo: StaticBody3D) -> AABB:
	for hijo in cuerpo.get_children():
		if hijo is CollisionShape3D and hijo.shape is BoxShape3D:
			var caja := hijo.shape as BoxShape3D
			return hijo.global_transform * AABB(-caja.size / 2.0, caja.size)
	return AABB()


func _caja_global(pieza: Node3D) -> AABB:
	var caja := AABB()
	for malla in pieza.find_children("*", "MeshInstance3D", true, false):
		var limites: AABB = malla.global_transform * malla.get_aabb()
		caja = limites if caja.size == Vector3.ZERO else caja.merge(limites)
	return caja


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO CasaHogarCC0: " + nombre)
