## Portátil original de 1998 para la casa (#124/#133/#800).
##
## La carcasa es propia y no copia logos ni assets propietarios. Al usarla abre
## una superficie aislada que puede ejecutar ROMs compatibles mediante Siga98GB.
class_name ConsolaPortatil98
extends Interactuable3D

var _encendida := false
var _material_pantalla: StandardMaterial3D
var _roms_detectadas: Array[Dictionary] = []
var _roms_desbloqueadas: Array = []
var _app: EmuladorPortatilApp = null
var _link_cable := LinkCablePortatil.new()
var _conector_link_cable: MeshInstance3D = null
var _puerto_ir := PuertoIRPortatil.new()
var _material_ir: StandardMaterial3D = null
var _pulso_ir_visual := 0
var _impresora_termica: ImpresoraTermicaPortatil = null


func establecer_impresora_termica(impresora: ImpresoraTermicaPortatil) -> void:
	_impresora_termica = impresora


func configurar() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "consola portátil"
	_montar_colision()
	_montar_carcasa()
	_montar_link_cable()
	_link_cable.estado_cambiado.connect(_al_cambiar_link_cable)
	_montar_puerto_ir()
	_puerto_ir.pulso_emitido.connect(_al_pulso_ir)
	activado.connect(_alternar)


func esta_encendida() -> bool:
	return _encendida


func carpeta_roms() -> String:
	return CatalogoRomsUsuario.ruta_absoluta()


func roms_disponibles() -> Array[Dictionary]:
	_roms_detectadas = CatalogoRomsUsuario.listar()
	return _roms_detectadas.duplicate(true)


## Canal genérico para contenidos que se obtienen fuera de tienda. La consola
## conserva ids, pero no conoce literatura, mitología ni ningún motivo narrativo.
func desbloquear_rom(id_rom: String) -> bool:
	var id := id_rom.strip_edges()
	if id.is_empty() or _roms_desbloqueadas.has(id):
		return false
	_roms_desbloqueadas.append(id)
	return true


func roms_desbloqueadas() -> Array:
	return _roms_desbloqueadas.duplicate()


## Consulta genérica para capas externas que necesiten observar una ROM propia
## sin recibir el objeto emulador ni acoplar la consola a estado de campaña.
func titulo_rom_activa() -> String:
	var emulador := _emulador_activo()
	if emulador == null or not bool(emulador.call("is_loaded")):
		return ""
	return String(emulador.call("rom_title"))


## Lee un byte mediante el contrato seguro de Siga98GB. La dirección pertenece
## a quien consume esta API; la consola no conoce handshakes ni recompensas.
func leer_memoria_rom_u8(direccion: int) -> int:
	var emulador := _emulador_activo()
	if emulador == null:
		return -1
	return int(emulador.call("read_memory_u8", direccion))


func _emulador_activo() -> Object:
	if _app == null:
		return null
	var emulador = _app.get("_emulador")
	return emulador if emulador is Object else null


func _alternar(_actor: Node) -> void:
	if _encendida:
		return
	_encendida = true
	CatalogoRomsUsuario.asegurar_carpeta()
	_roms_detectadas = CatalogoRomsUsuario.listar()
	_actualizar_pantalla()

	_app = EmuladorPortatilAudioApp.new()
	_app.roms_compradas = _roms_compradas()
	_app.roms_desbloqueadas = _roms_desbloqueadas.duplicate()
	_app.set("link_cable", _link_cable)
	_app.set("puerto_ir", _puerto_ir)
	_app.set("impresora_termica", _impresora_termica)
	_app.cerrado.connect(_al_cerrar_app)
	get_tree().root.add_child(_app)
	_app.abrir()
	SelectorCartuchos3D.instalar(_app)


## PerfilRoms es la autoridad desde #800. Si la consola está montada dentro de
## un día antiguo, la jornada se pasa una vez como fuente de migración.
func _roms_compradas() -> Array:
	var actual := get_parent()
	while actual != null:
		var jornada = actual.get("jornada")
		if jornada is Dictionary:
			return TiendaVideojuegos.compras(jornada)
		actual = actual.get_parent()
	return TiendaVideojuegos.compras({})


func _al_cerrar_app() -> void:
	_encendida = false
	_app = null
	_actualizar_pantalla()


func _montar_colision() -> void:
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.38, 0.46, 0.30)
	colision.position = Vector3(0, 0.18, 0)
	colision.shape = forma
	add_child(colision)


func _montar_carcasa() -> void:
	var carcasa := MeshInstance3D.new()
	carcasa.name = "CarcasaPortatilOriginal98"
	carcasa.mesh = load("res://assets/modelos/props_originales_98/consola_portatil_98.obj") as Mesh
	add_child(carcasa)

	# La pantalla dinámica se mantiene separada para reflejar encendido/apagado
	# sin mutar los materiales importados del resto de la carcasa.
	var pantalla := _agregar_caja(
		Vector3(0, 0.255, -0.052), Vector3(0.145, 0.105, 0.005), Color(0.20, 0.28, 0.22)
	)
	pantalla.name = "PantallaPortatil"
	_material_pantalla = pantalla.material_override as StandardMaterial3D
	_material_pantalla.emission_enabled = true
	_material_pantalla.emission = Color(0.08, 0.12, 0.09)
	_material_pantalla.emission_energy_multiplier = 0.15


func _montar_link_cable() -> void:
	var cable := MeshInstance3D.new()
	cable.name = "CableLinkPortatil"
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.006
	cilindro.bottom_radius = 0.006
	cilindro.height = 0.24
	cable.mesh = cilindro
	cable.position = Vector3(0.17, 0.13, 0.035)
	cable.rotation_degrees = Vector3(0.0, 0.0, -8.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.055, 0.055, 0.06)
	material.roughness = 0.82
	cable.material_override = material
	add_child(cable)

	_conector_link_cable = _agregar_caja(
		Vector3(0.17, 0.025, 0.028),
		Vector3(0.035, 0.022, 0.020),
		Color(0.10, 0.10, 0.11),
	)
	_conector_link_cable.name = "ConectorLinkCable"
	_actualizar_link_cable_3d(_link_cable.esta_conectado())


func _al_cambiar_link_cable(conectado: bool) -> void:
	_actualizar_link_cable_3d(conectado)


func _actualizar_link_cable_3d(conectado: bool) -> void:
	if _conector_link_cable == null:
		return
	if conectado:
		_conector_link_cable.position = Vector3(0.126, 0.205, 0.016)
		_conector_link_cable.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	else:
		_conector_link_cable.position = Vector3(0.17, 0.025, 0.028)
		_conector_link_cable.rotation_degrees = Vector3.ZERO


func _montar_puerto_ir() -> void:
	var lente := MeshInstance3D.new()
	lente.name = "LenteIRPortatil"
	var esfera := SphereMesh.new()
	esfera.radius = 0.010
	esfera.height = 0.020
	lente.mesh = esfera
	lente.position = Vector3(0.100, 0.356, -0.030)
	_material_ir = StandardMaterial3D.new()
	_material_ir.albedo_color = Color(0.11, 0.025, 0.025)
	_material_ir.roughness = 0.48
	_material_ir.emission_enabled = true
	_material_ir.emission = Color(0.10, 0.0, 0.0)
	_material_ir.emission_energy_multiplier = 0.18
	lente.material_override = _material_ir
	add_child(lente)


func _al_pulso_ir(secuencia: int) -> void:
	_pulso_ir_visual = secuencia
	if _material_ir == null:
		return
	_material_ir.emission = Color(0.85, 0.05, 0.03)
	_material_ir.emission_energy_multiplier = 1.8
	await get_tree().create_timer(0.12, true).timeout
	if secuencia != _pulso_ir_visual or _material_ir == null:
		return
	_material_ir.emission = Color(0.10, 0.0, 0.0)
	_material_ir.emission_energy_multiplier = 0.18


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
