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
			var colision: CollisionShape3D = (
				pieza.find_children("*", "CollisionShape3D", true, false)[0]
			)
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
	var armario := lote.get_node_or_null("ArmarioHogar") as Node3D
	_comprobar(armario != null, "el armario CC0 sigue montado")
	var examinar_armario: Interactuable3D = null
	if armario != null:
		examinar_armario = armario.get_node_or_null("ExaminarArmarioHogar") as Interactuable3D
	_comprobar(examinar_armario != null, "el armario CC0 es examinable")
	if examinar_armario != null:
		_comprobar(examinar_armario.texto_accion() == "Examinar armario", "el prompt nombra el original")
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
