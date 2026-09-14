extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var dia: Node = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	for frame in 8:
		await process_frame
	var mundo: Node3D = dia._mundo
	var conjunto := mundo.get_node_or_null("PostersOficina")
	_comprobar(conjunto != null, "la escena diaria monta los pósteres en archivo")
	if conjunto == null:
		quit(1)
		return
	_comprobar(conjunto.get_child_count() == 6, "seis diseños")
	PostersOficina.montar(mundo)
	_comprobar(conjunto.get_child_count() == 6, "montaje idempotente")
	var texturas := {}
	for hijo in conjunto.get_children():
		var lamina := hijo as MeshInstance3D
		var plano := lamina.mesh as QuadMesh
		var material := lamina.material_override as StandardMaterial3D
		var textura := material.albedo_texture
		texturas[textura.resource_path] = true
		_comprobar(textura.get_image().has_mipmaps(), "mipmaps importados para lectura a distancia")
		_comprobar(textura.get_width() > 300 and textura.get_height() > 700, "PNG real importado")
		_comprobar(
			is_equal_approx(
				plano.size.x / plano.size.y, float(textura.get_width()) / textura.get_height()
			),
			"proporción conservada"
		)
		_comprobar(plano.size.y >= 1.2 and plano.size.y <= 1.4, "escala de cartel mural")
		_comprobar(lamina.position.y - plano.size.y / 2.0 >= 1.15, "sobre mobiliario bajo")
		_comprobar(lamina.position.y + plano.size.y / 2.0 < Espacio3D.ALTURA_MURO, "bajo el techo")
		_comprobar(not material.emission_enabled, "papel sin emisión")
		_comprobar(not material.uv1_triplanar, "UV completas sin mosaico")
		_comprobar(lamina.basis.z.dot(-lamina.position) > 4.0, "cara visible hacia el interior")
	_comprobar(texturas.size() == 6, "sin diseños repetidos")
	_comprobar(
		conjunto.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"no altera navegación ni interacciones"
	)
	# Montar el controlador real en otro mundo verifica el filtro de fase y
	# el reingreso al archivo sin depender de la transición cinematográfica.
	var otro := Node3D.new()
	root.add_child(otro)
	var anterior: Node3D = dia._mundo
	dia._mundo = otro
	dia.jornada["fase"] = "casa"
	var controlador: Node = dia.get_node("OficinaUtileriaController")
	controlador._process(0.0)
	_comprobar(not otro.has_node("PostersOficina"), "no aparecen en casa")
	dia._mundo = anterior
	dia.jornada["fase"] = "archivo"
	controlador._process(0.0)
	_comprobar(conjunto.get_child_count() == 6, "reingreso sin duplicados")
	otro.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	dia.queue_free()
	await process_frame
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO PostersOficina: " + nombre)
