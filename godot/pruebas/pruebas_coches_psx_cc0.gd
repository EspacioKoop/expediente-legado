## Integración del lote de coches PSX y del hook real de trayecto (#230).
extends SceneTree

const Coches := preload("res://guion/coches_psx_cc0.gd")
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
	_comprobar(Coches.montar(null) == null, "sin mundo no hay montaje")
	var mundo := Node3D.new()
	root.add_child(mundo)
	var lote := Coches.montar(mundo)
	_comprobar(lote.get_child_count() == 4, "tres aparcados y un coche de fondo")
	_comprobar(Coches.montar(mundo) == lote, "montaje idempotente")
	_comprobar(mundo.get_child_count() == 1, "sin duplicación al repetir")
	_comprobar(lote.find_children("*", "Light3D", true, false).is_empty(), "sin luces")
	_comprobar(lote.find_children("*", "Area3D", true, false).is_empty(), "sin interacción")
	_comprobar(lote.find_children("*", "VehicleBody3D", true, false).is_empty(), "sin vehículo")
	_comprobar(lote.find_children("*", "RigidBody3D", true, false).is_empty(), "sin dinámica")
	_comprobar(
		lote.find_children("*", "StaticBody3D", true, false).size() == 3,
		"solo los tres aparcados tienen caja",
	)
	var trafico := lote.get_node("TraficoFondo") as Node3D
	_comprobar(trafico != null, "tráfico lejano presente")
	_comprobar(
		trafico.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"tráfico lejano sin colisión",
	)
	var largos := {"RancheraSur": 4.60, "MonovolumenCentro": 4.30, "UtilitarioNorte": 4.00}
	var triangulos := 0
	for coche in lote.get_children():
		var caja := AABB()
		for malla in coche.find_children("*", "MeshInstance3D", true, false):
			var limites: AABB = malla.global_transform * malla.get_aabb()
			caja = limites if caja.size == Vector3.ZERO else caja.merge(limites)
			_comprobar(
				malla.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				"coches sin pasada de sombras",
			)
			for i in malla.mesh.get_surface_count():
				triangulos += malla.mesh.surface_get_array_index_len(i) / 3
				var mate: StandardMaterial3D = malla.get_active_material(i)
				var original: StandardMaterial3D = malla.mesh.surface_get_material(i)
				_comprobar(mate.albedo_texture != null, "textura original visible")
				_comprobar(
					mate.albedo_texture == original.albedo_texture, "UV y textura preservadas"
				)
				_comprobar(mate != original, "material original sin mutar")
				_comprobar(mate.roughness == 1.0 and mate.metallic == 0.0, "acabado mate")
				_comprobar(mate.specular_mode == BaseMaterial3D.SPECULAR_DISABLED, "sin brillo")
		var nombre := str(coche.name)
		_comprobar(absf(caja.position.y) < 0.001, "ruedas apoyadas en el asfalto: " + nombre)
		_comprobar(caja.size.y > 1.2 and caja.size.y < 2.2, "altura verosímil: " + nombre)
		if nombre == "TraficoFondo":
			_comprobar(
				absf(maxf(caja.size.x, caja.size.z) - 4.00) < 0.001,
				"largo normalizado del tráfico lejano",
			)
			_comprobar(caja.position.z > 14.0, "tráfico detrás del cierre jugable")
			_comprobar(caja.end.z < 19.0, "tráfico contenido en el fondo urbano")
			continue
		_comprobar(absf(caja.size.z - largos[nombre]) < 0.001, "largo normalizado: " + nombre)
		_comprobar(caja.end.x < -1.6 or caja.position.x > 1.6, "paso central libre: " + nombre)
		_comprobar(caja.position.x > -4.0 and caja.end.x < 4.0, "dentro de la calzada: " + nombre)
		_comprobar(caja.position.z > -14.0 and caja.end.z < 14.0, "lejos de entrada y portal")
		_comprobar(not _pisa_conos(caja), "no invade barrera ni conos: " + nombre)
		_comprobar(not _tapa_escaparate(caja), "no tapa el escaparate: " + nombre)
		var colision: CollisionShape3D = (
			coche.find_children("*", "CollisionShape3D", true, false)[0]
		)
		var volumen: AABB = (
			colision.global_transform * AABB(-colision.shape.size / 2, colision.shape.size)
		)
		_comprobar(volumen.position.is_equal_approx(caja.position), "colisión alineada: " + nombre)
		_comprobar(volumen.size.is_equal_approx(caja.size), "colisión del tamaño del coche")
	print("Lote: 4 instancias, %d triángulos" % triangulos)
	_comprobar(triangulos <= 1900, "presupuesto geométrico acotado")
	var x_inicial := trafico.position.x
	await create_timer(0.20).timeout
	_comprobar(trafico.position.x > x_inicial + 0.01, "tráfico lejano se mueve")
	mundo.free()

	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	for fase in ["archivo", "trayecto", "casa", "trayecto", "archivo"]:
		dia._entrar_en(fase)
		await process_frame
		var montado = dia._mundo.get_node_or_null("CochesPsxCC0")
		_comprobar((montado != null) == (fase == "trayecto"), "hook real de fase " + fase)
		if montado != null:
			_comprobar(montado.get_child_count() == 4, "lote completo al regresar")
			_comprobar(
				montado.get_node_or_null("TraficoFondo") != null,
				"tráfico lejano se reconstruye con trayecto",
			)
	dia.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


## Barrera y conos de TraficoVialCC0 ocupan el carril derecho entre z 4 y 8.
func _pisa_conos(caja: AABB) -> bool:
	return caja.intersects(AABB(Vector3(2.4, 0.0, 4.0), Vector3(1.6, 2.0, 4.0)))


## El escaparate de televisores está en la fachada izquierda entre z -5 y 2.
func _tapa_escaparate(caja: AABB) -> bool:
	return caja.intersects(AABB(Vector3(-4.0, 0.0, -5.5), Vector3(2.4, 3.0, 8.0)))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO CochesPsxCC0: " + nombre)
