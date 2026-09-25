extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	for especie in ["paloma", "gorrion", "perro", "cuervo", "polilla", "ciervo"]:
		await _probar_especie(especie)
	_probar_partes_especificas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_especie(especie: String) -> void:
	var animal := _animal(especie)
	var cuerpo := animal.get_node_or_null("Visual/Cuerpo") as MeshInstance3D
	_comprobar(cuerpo != null, "#1407: " + especie + " conserva cuerpo principal")
	_comprobar(
		cuerpo != null and (cuerpo.mesh is SphereMesh or cuerpo.mesh is CapsuleMesh),
		"#1407: " + especie + " usa volumen redondeado en el cuerpo",
	)
	var material := cuerpo.material_override as StandardMaterial3D if cuerpo != null else null
	_comprobar(
		material != null,
		"#1407: " + especie + " usa StandardMaterial3D",
	)
	_comprobar(
		material != null and material.roughness >= 0.70 and material.roughness <= 0.95,
		"#1407: " + especie + " mantiene rugosidad orgánica",
	)
	_comprobar(
		cuerpo != null
		and cuerpo.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
		"#1407: " + especie + " proyecta sombra solo desde masa principal",
	)

	var tiene_caja := false
	for nodo in animal.find_children("*", "MeshInstance3D", true, false):
		var parte := nodo as MeshInstance3D
		if parte != null and parte.mesh is BoxMesh:
			tiene_caja = true
	_comprobar(not tiene_caja, "#1407: " + especie + " elimina BoxMesh visual")

	animal.queue_free()
	await process_frame


func _probar_partes_especificas() -> void:
	var ave := _animal("paloma")
	_comprobar(
		(ave.get_node_or_null("Visual/AlaI") as MeshInstance3D).mesh is SphereMesh,
		"#1407: ala de ave es volumen redondeado",
	)
	_comprobar(
		(ave.get_node_or_null("Visual/Pico") as MeshInstance3D).mesh is CylinderMesh,
		"#1407: pico usa cono ligero",
	)
	var ojo := ave.get_node_or_null("Visual/OjoI") as MeshInstance3D
	_comprobar(
		ojo != null and ojo.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"#1407: ojos no gastan sombra",
	)

	var perro := _animal("perro")
	_comprobar(
		(perro.get_node_or_null("Visual/Pata") as MeshInstance3D).mesh is CapsuleMesh,
		"#1407: patas del perro son cápsulas",
	)
	_comprobar(
		perro.get_node_or_null("Visual/Cola") != null,
		"#1407: se conserva Cola para microgestos",
	)
	_comprobar(
		perro.get_node_or_null("Visual/Cabeza") != null,
		"#1407: se conserva Cabeza para orientación",
	)

	var polilla := _animal("polilla")
	_comprobar(
		(polilla.get_node_or_null("Visual/AlaI") as MeshInstance3D).mesh is SphereMesh,
		"#1407: alas de polilla son volúmenes redondeados",
	)
	_comprobar(
		polilla.get_node_or_null("Visual/AlaD") != null,
		"#1407: se conserva AlaD para batido",
	)

	var ciervo := _animal("ciervo")
	_comprobar(
		(ciervo.get_node_or_null("Visual/AstaI") as MeshInstance3D).mesh is CylinderMesh,
		"#1407: astas usan cilindros de pocos segmentos",
	)
	_comprobar(
		(ciervo.get_node_or_null("Visual/Pata") as MeshInstance3D).mesh is CapsuleMesh,
		"#1407: patas del ciervo son cápsulas",
	)
	_comprobar(
		ciervo.get_node_or_null("Visual/Cabeza") != null,
		"#1407: ciervo conserva Cabeza animable",
	)

	for animal in [ave, perro, polilla, ciervo]:
		_comprobar(
			animal.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"#1407: mejora visual no introduce física",
		)
		animal.queue_free()


func _animal(especie: String) -> AnimalAmbiental3D:
	var animal := AnimalAmbiental3D.new()
	root.add_child(animal)
	animal.configurar(_dato_especie(especie), null, false)
	return animal


func _dato_especie(especie: String) -> Dictionary:
	var espacio := {
		"entrada": Vector3(0, 0, 4),
		"salidas": [{"pos": Vector3(0, 1.1, -12)}],
	}
	var planes: Array = FaunaAmbiental.plan("trayecto", {}, 4, 12345)
	planes.append_array(FaunaAmbiental.plan("sueño", espacio, 4, 12345, "crucero"))
	for dato in planes:
		if String((dato as Dictionary).get("especie", "")) == especie:
			return (dato as Dictionary).duplicate(true)
	return {}


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO FaunaVisual: " + nombre)
