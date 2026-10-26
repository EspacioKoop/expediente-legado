extends SceneTree

const MODELOS := preload("res://guion/modelos.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var material_original := StandardMaterial3D.new()
	material_original.albedo_color = Color(0.64, 0.57, 0.48)
	material_original.roughness = 0.23
	material_original.metallic = 0.42

	var malla_compartida := BoxMesh.new()
	malla_compartida.material = material_original

	var pieza_realista := Node3D.new()
	var malla_realista := MeshInstance3D.new()
	malla_realista.mesh = malla_compartida
	pieza_realista.add_child(malla_realista)

	var pieza_legacy := Node3D.new()
	var malla_legacy := MeshInstance3D.new()
	malla_legacy.mesh = malla_compartida
	pieza_legacy.add_child(malla_legacy)

	_comprobar(MODELOS._tiene_materiales_importados(pieza_realista), "reconoce material importado")
	MODELOS._acabado_mueble(pieza_realista, "desk", Color.RED, true)
	_comprobar(
		malla_realista.get_active_material(0) == material_original,
		"opt-in conserva instancia material importado"
	)
	_comprobar(malla_realista.material_override == null, "no impone shader PSX al opt-in")
	_comprobar(
		(
			is_equal_approx(material_original.roughness, 0.23)
			and is_equal_approx(material_original.metallic, 0.42)
		),
		"conserva roughness y metal originales"
	)

	MODELOS._acabado_mueble(pieza_legacy, "desk", Color.BLUE, false)
	_comprobar(
		malla_legacy.material_override is ShaderMaterial,
		"el acabado legado sigue aplicando su shader"
	)
	_comprobar(
		malla_realista.get_active_material(0) == material_original,
		"el material importado no se modifica al pintar otra instancia"
	)

	var pieza_sin_material := Node3D.new()
	var malla_sin_material := MeshInstance3D.new()
	malla_sin_material.mesh = BoxMesh.new()
	pieza_sin_material.add_child(malla_sin_material)
	_comprobar(
		not MODELOS._tiene_materiales_importados(pieza_sin_material),
		"detecta un asset sin materiales"
	)
	MODELOS._acabado_mueble(pieza_sin_material, "desk", Color.GRAY, true)
	_comprobar(
		malla_sin_material.material_override is ShaderMaterial,
		"opt-in incompleto vuelve al shader comun"
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO materiales importados 2519: " + nombre)
