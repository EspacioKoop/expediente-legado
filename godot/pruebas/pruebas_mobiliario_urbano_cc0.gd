## Integración de basura urbana y aparatos de aire CC0 en el trayecto (#222).
extends SceneTree

const Urbano := preload("res://guion/mobiliario_urbano_cc0.gd")
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
	_comprobar(Urbano.montar(null) == null, "sin mundo no hay montaje")
	var mundo := Node3D.new()
	root.add_child(mundo)
	var lote := Urbano.montar(mundo)
	_comprobar(lote.get_child_count() == Urbano.PIEZAS.size(), "lote completo")
	_comprobar(Urbano.montar(mundo) == lote, "montaje idempotente")
	_comprobar(mundo.get_child_count() == 1, "sin duplicación al repetir")
	_comprobar(lote.find_children("*", "Light3D", true, false).is_empty(), "sin luces")
	_comprobar(lote.find_children("*", "Area3D", true, false).is_empty(), "sin interacción")
	_comprobar(lote.find_children("*", "RigidBody3D", true, false).is_empty(), "sin dinámica")
	_comprobar(
		lote.find_children("*", "StaticBody3D", true, false).size() == 2,
		"el contenedor y el bidón bloquean el paso"
	)
	var triangulos := 0
	for ficha in Urbano.PIEZAS:
		var pieza := lote.get_node(ficha[0]) as Node3D
		var nombre := str(ficha[0])
		var caja := AABB()
		for malla in pieza.find_children("*", "MeshInstance3D", true, false):
			var limites: AABB = malla.global_transform * malla.get_aabb()
			caja = limites if caja.size == Vector3.ZERO else caja.merge(limites)
			for i in malla.mesh.get_surface_count():
				triangulos += malla.mesh.surface_get_array_index_len(i) / 3
				var mate: StandardMaterial3D = malla.get_active_material(i)
				var original: StandardMaterial3D = malla.mesh.surface_get_material(i)
				_comprobar(mate.albedo_texture != null, "textura original visible: " + nombre)
				_comprobar(mate != original, "material original sin mutar: " + nombre)
				_comprobar(mate.roughness == 1.0 and mate.metallic == 0.0, "acabado mate")
				_comprobar(mate.cull_mode == BaseMaterial3D.CULL_DISABLED, "visible por dos caras")
		var medida: float = ficha[3]
		match ficha[1]:
			"Cardboard":
				# El AABB global crece con el giro: se mide en los ejes de la pieza.
				var local := AABB()
				for malla in pieza.find_children("*", "MeshInstance3D", true, false):
					var propia: AABB = (
						pieza.global_transform.affine_inverse()
						* malla.global_transform
						* malla.get_aabb()
					)
					local = propia if local.size == Vector3.ZERO else local.merge(propia)
				_comprobar(
					absf(maxf(local.size.x, local.size.z) - medida) < 0.01,
					"cartón a escala: " + nombre
				)
				_comprobar(absf(caja.position.y - ficha[2].y) < 0.01, "cartón sobre la acera")
			"Conditioner":
				_comprobar(absf(caja.size.y - medida) < 0.01, "aparato a escala: " + nombre)
				var pared: float = ficha[2].x
				var tocando := minf(absf(caja.position.x - pared), absf(caja.end.x - pared))
				_comprobar(tocando < 0.01, "apoyado en la fachada: " + nombre)
				_comprobar(
					caja.position.x >= pared - 0.01 if pared < 0 else caja.end.x <= pared + 0.01,
					"sobresale hacia la calle, no dentro del muro: " + nombre
				)
				_comprobar(caja.position.y > 2.2, "por encima de la cabeza: " + nombre)
			_:
				_comprobar(absf(caja.size.y - medida) < 0.01, "altura realista: " + nombre)
				_comprobar(absf(caja.position.y - ficha[2].y) < 0.01, "apoyado: " + nombre)
		_comprobar(caja.end.x < -1.6 or caja.position.x > 1.6, "paso central libre: " + nombre)
		_comprobar(caja.position.z > -14.0 and caja.end.z < 14.0, "lejos de entrada y portal")
		_comprobar(
			not caja.intersects(AABB(Vector3(2.4, 0.0, 4.0), Vector3(1.6, 2.0, 4.0))),
			"no invade barrera ni conos: " + nombre
		)
		_comprobar(
			not caja.intersects(AABB(Vector3(-4.0, 0.0, -5.5), Vector3(2.4, 3.0, 8.0))),
			"no tapa el escaparate: " + nombre
		)
		for coche in [Vector3(-3.0, 0, -11.0), Vector3(2.8, 0, -3.5), Vector3(-3.0, 0, 9.5)]:
			_comprobar(
				not caja.intersects(AABB(coche - Vector3(1.3, 0, 2.4), Vector3(2.6, 2.0, 4.8))),
				"no pisa coches aparcados: " + nombre
			)
	print("Lote: %d piezas, %d triángulos" % [lote.get_child_count(), triangulos])
	_comprobar(triangulos <= 3000, "presupuesto geométrico acotado")
	mundo.free()

	var dia = DIA.instantiate()
	root.add_child(dia)
	await process_frame
	for fase in ["archivo", "trayecto", "casa", "trayecto", "archivo"]:
		dia._entrar_en(fase)
		await process_frame
		var montado = dia._mundo.get_node_or_null("MobiliarioUrbanoCC0")
		_comprobar((montado != null) == (fase == "trayecto"), "hook real de fase " + fase)
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
		push_error("FALLO MobiliarioUrbanoCC0: " + nombre)
