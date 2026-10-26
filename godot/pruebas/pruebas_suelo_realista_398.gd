extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	Espacio3D._suelo(
		mundo, Vector2(14, 10), Color(0.30, 0.29, 0.27), "linoleo", Vector2.ZERO, true
	)
	var cuerpo := mundo.get_child(0) as StaticBody3D
	_comprobar(cuerpo != null, "el suelo continúa teniendo cuerpo físico")
	var malla := Espacio3D._malla_de(cuerpo)
	var material := malla.material_override as StandardMaterial3D
	_comprobar(material != null, "el suelo usa material físico y no el shader PSX")
	if material != null:
		_comprobar(material.albedo_texture != null, "reutiliza albedo del linóleo")
		_comprobar(material.uv1_triplanar, "escala de textura triplanar")
		_comprobar(material.uv1_world_triplanar, "mantiene texelado en metros del mundo")
		_comprobar(
			is_equal_approx(material.roughness, 0.85),
			"rugosidad de superficie administrativa mate"
		)
	_comprobar(
		cuerpo.find_children("*", "CollisionShape3D", true, false).size() == 1,
		"la colisión conserva una sola caja"
	)
	mundo.free()

	var legado := Node3D.new()
	root.add_child(legado)
	Espacio3D._suelo(legado, Vector2(4, 4), Color.GRAY, "linoleo")
	var antiguo := legado.get_child(0) as StaticBody3D
	_comprobar(
		Espacio3D._malla_de(antiguo).material_override is ShaderMaterial,
		"sin opt-in el shader retro sigue siendo el valor por defecto"
	)
	legado.free()

	_comprobar(
		bool(EspaciosCatalogo.OFICINA.get("suelo_material_fisico", false)),
		"solo la oficina activa la nueva materia"
	)
	_comprobar(
		not bool(EspaciosCatalogo.CASA.get("suelo_material_fisico", false)),
		"la casa mantiene sus superficies"
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO suelo realista 398: " + nombre)
