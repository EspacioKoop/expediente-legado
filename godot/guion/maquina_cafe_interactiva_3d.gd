## Microinteracción local para la máquina de café de la oficina (#400).
##
## La máquina física ya existe como bulto en el catálogo. Este nodo no la
## sustituye ni inventa economía: añade un volumen enfocable y una respuesta
## visible. Cada uso alterna una taza bajo el surtidor y el piloto frontal.
class_name MaquinaCafeInteractiva3D
extends Interactuable3D

const COLOR_PILOTO_APAGADO := Color(0.20, 0.10, 0.08)
const COLOR_PILOTO_ENCENDIDO := Color(0.78, 0.18, 0.08)
const COLOR_TAZA := Color(0.78, 0.75, 0.66)

var _taza_visible := false
var _taza: MeshInstance3D
var _piloto_material: StandardMaterial3D


func configurar() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "máquina de café"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.0, 1.55, 0.90)
	colision.shape = forma
	add_child(colision)

	_taza = MeshInstance3D.new()
	_taza.name = "TazaServida"
	var cuerpo_taza := CylinderMesh.new()
	cuerpo_taza.top_radius = 0.105
	cuerpo_taza.bottom_radius = 0.09
	cuerpo_taza.height = 0.22
	_taza.mesh = cuerpo_taza
	_taza.position = Vector3(0.18, -0.40, -0.45)
	var material_taza := StandardMaterial3D.new()
	material_taza.albedo_color = COLOR_TAZA
	material_taza.roughness = 1.0
	_taza.material_override = material_taza
	_taza.visible = false
	add_child(_taza)

	var piloto := MeshInstance3D.new()
	piloto.name = "PilotoCafe"
	var malla_piloto := BoxMesh.new()
	malla_piloto.size = Vector3(0.14, 0.10, 0.035)
	piloto.mesh = malla_piloto
	piloto.position = Vector3(-0.24, 0.28, -0.47)
	_piloto_material = StandardMaterial3D.new()
	_piloto_material.albedo_color = COLOR_PILOTO_APAGADO
	_piloto_material.roughness = 0.85
	piloto.material_override = _piloto_material
	add_child(piloto)

	activado.connect(_usar)


func taza_visible() -> bool:
	return _taza_visible


func _usar(_actor: Node) -> void:
	_taza_visible = not _taza_visible
	_taza.visible = _taza_visible
	_piloto_material.albedo_color = (
		COLOR_PILOTO_ENCENDIDO if _taza_visible else COLOR_PILOTO_APAGADO
	)
	_piloto_material.emission_enabled = _taza_visible
	_piloto_material.emission = COLOR_PILOTO_ENCENDIDO
	_piloto_material.emission_energy_multiplier = 0.65
