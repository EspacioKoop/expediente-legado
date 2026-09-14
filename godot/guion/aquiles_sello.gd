## Sello diegético para resolver el sueño de Aquiles (#438).
##
## Permanece inerte hasta que el reflector revela el talón. La interacción no
## representa un ataque: comunica una acción administrativa de sellado.
class_name AquilesSello
extends Interactuable3D

signal sellado(actor: Node)

const COLOR_MANGO := Color(0.29, 0.20, 0.14)
const COLOR_SELLO := Color(0.52, 0.16, 0.12)
const COLOR_ACTIVO := Color(0.80, 0.34, 0.19)

var _cabeza: MeshInstance3D


func _ready() -> void:
	configurar()


func configurar() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "sello del talón"
	habilitado = false
	if _cabeza == null:
		_montar()
	if not activado.is_connected(_al_activar):
		activado.connect(_al_activar)
	_actualizar_feedback()


func habilitar(valor: bool) -> void:
	habilitado = valor
	_actualizar_feedback()


func esta_habilitado() -> bool:
	return habilitado


func _al_activar(actor: Node) -> void:
	sellado.emit(actor)


func _montar() -> void:
	var colision := CollisionShape3D.new()
	colision.name = "ColisionSello"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.72, 0.82, 0.72)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.42, 0.0)
	add_child(colision)

	var mango_malla := CylinderMesh.new()
	mango_malla.top_radius = 0.10
	mango_malla.bottom_radius = 0.14
	mango_malla.height = 0.58
	var mango := MeshInstance3D.new()
	mango.name = "MangoSello"
	mango.mesh = mango_malla
	mango.position = Vector3(0.0, 0.52, 0.0)
	mango.material_override = _material(COLOR_MANGO)
	add_child(mango)

	var cabeza_malla := CylinderMesh.new()
	cabeza_malla.top_radius = 0.32
	cabeza_malla.bottom_radius = 0.32
	cabeza_malla.height = 0.12
	_cabeza = MeshInstance3D.new()
	_cabeza.name = "CabezaSello"
	_cabeza.mesh = cabeza_malla
	_cabeza.position = Vector3(0.0, 0.17, 0.0)
	add_child(_cabeza)


func _actualizar_feedback() -> void:
	if _cabeza == null:
		return
	_cabeza.material_override = _material(
		COLOR_ACTIVO if habilitado else COLOR_SELLO,
		habilitado,
	)


func _material(color: Color, emision: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.68
	if emision:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2
	return material
