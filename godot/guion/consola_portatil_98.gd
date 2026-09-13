## Portátil original de 1998 para la casa (#124/#133).
##
## Se inspira en las consolas portátiles de la época sin copiar logos, marcas ni
## assets propietarios. Este corte aporta carcasa, pantalla, cruceta, botones y
## el punto de integración con `CatalogoRomsUsuario`; todavía no emula ROMs.
class_name ConsolaPortatil98
extends Interactuable3D

var _encendida := false
var _material_pantalla: StandardMaterial3D
var _roms_detectadas: Array[Dictionary] = []


func configurar() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "consola portátil"
	_montar_colision()
	_montar_carcasa()
	activado.connect(_alternar)


func esta_encendida() -> bool:
	return _encendida


func carpeta_roms() -> String:
	return CatalogoRomsUsuario.ruta_absoluta()


func roms_disponibles() -> Array[Dictionary]:
	_roms_detectadas = CatalogoRomsUsuario.listar()
	return _roms_detectadas.duplicate(true)


func _alternar(_actor: Node) -> void:
	_encendida = not _encendida
	if _encendida:
		CatalogoRomsUsuario.asegurar_carpeta()
		_roms_detectadas = CatalogoRomsUsuario.listar()
	_actualizar_pantalla()


func _montar_colision() -> void:
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.38, 0.46, 0.30)
	colision.position = Vector3(0, 0.18, 0)
	colision.shape = forma
	add_child(colision)


func _montar_carcasa() -> void:
	_agregar_caja(
		Vector3(0, 0.18, 0),
		Vector3(0.24, 0.36, 0.065),
		Color(0.16, 0.38, 0.46),
	)
	_agregar_caja(
		Vector3(0, 0.255, -0.037),
		Vector3(0.19, 0.145, 0.012),
		Color(0.08, 0.10, 0.11),
	)
	var pantalla := _agregar_caja(
		Vector3(0, 0.255, -0.045), Vector3(0.145, 0.105, 0.008), Color(0.20, 0.28, 0.22)
	)
	_material_pantalla = pantalla.material_override as StandardMaterial3D
	_material_pantalla.emission_enabled = true
	_material_pantalla.emission = Color(0.08, 0.12, 0.09)
	_material_pantalla.emission_energy_multiplier = 0.15

	# Cruceta simple y deliberadamente genérica.
	_agregar_caja(
		Vector3(-0.065, 0.105, -0.047),
		Vector3(0.065, 0.020, 0.012),
		Color(0.07, 0.07, 0.08),
	)
	_agregar_caja(
		Vector3(-0.065, 0.105, -0.047),
		Vector3(0.020, 0.065, 0.012),
		Color(0.07, 0.07, 0.08),
	)

	# Dos botones de acción sin letras ni iconografía propietaria.
	_agregar_boton(Vector3(0.063, 0.115, -0.050), Color(0.58, 0.16, 0.31))
	_agregar_boton(Vector3(0.090, 0.085, -0.050), Color(0.76, 0.49, 0.13))

	# Select/start como dos barras pequeñas.
	_agregar_caja(
		Vector3(-0.020, 0.052, -0.047),
		Vector3(0.040, 0.010, 0.010),
		Color(0.12, 0.12, 0.13),
	)
	_agregar_caja(
		Vector3(0.030, 0.052, -0.047),
		Vector3(0.040, 0.010, 0.010),
		Color(0.12, 0.12, 0.13),
	)

	# Ranura de cartucho: solo geometría, sin marca ni ROM física incluida.
	_agregar_caja(
		Vector3(0, 0.355, 0.005),
		Vector3(0.13, 0.018, 0.045),
		Color(0.07, 0.09, 0.10),
	)


func _actualizar_pantalla() -> void:
	if _material_pantalla == null:
		return
	if _encendida:
		_material_pantalla.albedo_color = Color(0.36, 0.55, 0.40)
		_material_pantalla.emission = Color(0.24, 0.42, 0.28)
		_material_pantalla.emission_energy_multiplier = 0.65
	else:
		_material_pantalla.albedo_color = Color(0.20, 0.28, 0.22)
		_material_pantalla.emission = Color(0.08, 0.12, 0.09)
		_material_pantalla.emission_energy_multiplier = 0.15


func _agregar_caja(pos: Vector3, tam: Vector3, color: Color) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	malla.material_override = material
	add_child(malla)
	return malla


func _agregar_boton(pos: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.018
	cilindro.bottom_radius = 0.018
	cilindro.height = 0.012
	malla.mesh = cilindro
	malla.position = pos
	malla.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	malla.material_override = material
	add_child(malla)
