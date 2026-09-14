extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	TranslationServer.set_locale("es")
	var dia: Node = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	for frame in 8:
		await process_frame
	var mundo: Node3D = dia._mundo
	var importados := mundo.find_children("AssetCc0", "Node3D", true, false)
	_comprobar(importados.size() >= 25, "muebles y periféricos sustituidos en escena real")
	for pieza in importados:
		var caja := Modelos._limites(pieza)
		_comprobar(caja.size.length() > 0.01, "modelo tiene geometría real")
		for malla in Modelos._mallas(pieza):
			_comprobar(malla.is_visible_in_tree() and malla.layers != 0, "sustituto visible")
			for i in malla.mesh.get_surface_count():
				var material: ShaderMaterial = malla.get_active_material(i)
				_comprobar(material != null, "usa material PSX")
				_comprobar(
					material.get_shader_parameter("usar_uv") == true, "conserva UV de origen"
				)
	var colisiones := mundo.find_children("*", "CollisionShape3D", true, false).size()
	OficinaAssetsCc0.montar(mundo)
	_comprobar(
		mundo.find_children("AssetCc0", "Node3D", true, false).size() == importados.size(),
		"idempotente"
	)
	_comprobar(
		mundo.find_children("*", "CollisionShape3D", true, false).size() == colisiones,
		"colisiones intactas"
	)
	var vacio := Node3D.new()
	root.add_child(vacio)
	_comprobar(not AssetCc0.sustituir(vacio, "ausente_qa", Vector3.ONE), "fallback sin recurso")
	_comprobar(vacio.get_child_count() == 0, "fallback no deja nodos parciales")
	vacio.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	dia.queue_free()
	await process_frame
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO OficinaAssetsCc0: " + nombre)
