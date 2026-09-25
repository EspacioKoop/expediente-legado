## Integración del lote original y del hook real de trayecto con datos sintéticos.
extends SceneTree

const Vial := preload("res://guion/trafico_vial_cc0.gd")
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
	_comprobar(Vial.montar(null) == null, "sin mundo no hay montaje")
	var mundo := Node3D.new()
	root.add_child(mundo)
	var inicio := Time.get_ticks_usec()
	var lote := Vial.montar(mundo)
	print("Montaje inicial del lote: %d us" % (Time.get_ticks_usec() - inicio))
	_comprobar(lote.get_child_count() == 5, "cinco instancias del lote mínimo")
	_comprobar(Vial.montar(mundo) == lote, "montaje idempotente")
	_comprobar(mundo.get_child_count() == 1, "sin duplicación al repetir")
	_comprobar(lote.find_children("*", "Light3D", true, false).is_empty(), "sin luces")
	_comprobar(lote.find_children("*", "Area3D", true, false).is_empty(), "sin interacción")
	_comprobar(lote.find_children("*", "RigidBody3D", true, false).is_empty(), "sin dinámica")
	_comprobar(lote.find_children("*", "StaticBody3D", true, false).size() == 1, "una caja")
	var triangulos := 0
	for pieza in lote.get_children():
		var caja := AABB()
		for malla in pieza.find_children("*", "MeshInstance3D", true, false):
			var limites: AABB = malla.global_transform * malla.get_aabb()
			caja = limites if caja.size == Vector3.ZERO else caja.merge(limites)
			_comprobar(
				malla.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				"mobiliario vial sin pasada de sombras",
			)
			for i in malla.mesh.get_surface_count():
				triangulos += malla.mesh.surface_get_array_index_len(i) / 3
				var mate: StandardMaterial3D = malla.get_active_material(i)
				var original: StandardMaterial3D = malla.mesh.surface_get_material(i)
				_comprobar(mate.albedo_texture != null, "atlas original visible")
				_comprobar(mate.albedo_texture == original.albedo_texture, "UV y atlas preservados")
				_comprobar(mate != original, "material original sin mutar")
				_comprobar(mate.roughness == 1.0 and mate.metallic == 0.0, "acabado mate")
				_comprobar(mate.specular_mode == BaseMaterial3D.SPECULAR_DISABLED, "sin brillo")
		_comprobar(caja.end.x < -1.6 or caja.position.x > 1.6, "paso central libre")
		if str(pieza.name).begins_with("Tapa"):
			_comprobar(absf(caja.size.x - 0.70) < 0.001, "tapa a escala 70 cm")
			_comprobar(
				absf(caja.end.y - Vial.HOLGURA_TAPA) < 0.0005,
				"cara superior de tapa casi enrasada sin z-fighting",
			)
			_comprobar(caja.position.y < -0.02, "grosor de tapa empotrado en el asfalto")
		else:
			_comprobar(absf(caja.position.y - pieza.position.y) < 0.001, "base apoyada")
		else:
			var alto := 1.10 if pieza.name == &"Barrera" else 0.65
			_comprobar(absf(caja.size.y - alto) < 0.001, "altura de mobiliario realista")
	print("Lote: 5 instancias, %d triángulos" % triangulos)
	_comprobar(triangulos <= 1000, "presupuesto geométrico acotado")
	var colision: CollisionShape3D = lote.find_children("*", "CollisionShape3D", true, false)[0]
	var barrera: MeshInstance3D = (
		lote.get_node("Barrera").find_children("*", "MeshInstance3D", true, false)[0]
	)
	var volumen: AABB = (
		colision.global_transform * AABB(-colision.shape.size / 2, colision.shape.size)
	)
	var visual: AABB = barrera.global_transform * barrera.get_aabb()
	_comprobar(volumen.position.is_equal_approx(visual.position), "colisión alineada")
	_comprobar(volumen.size.is_equal_approx(visual.size), "colisión del tamaño de la barrera")
	mundo.free()

	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	for fase in ["archivo", "trayecto", "casa", "trayecto", "archivo"]:
		dia._entrar_en(fase)
		await process_frame
		var montado = dia._mundo.get_node_or_null("TraficoVialCC0")
		_comprobar((montado != null) == (fase == "trayecto"), "hook real de fase " + fase)
		if montado != null:
			_comprobar(montado.get_child_count() == 5, "lote completo al regresar")
	dia.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO TraficoVialCC0: " + nombre)
