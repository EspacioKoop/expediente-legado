## Reflector manipulable del sueño de Aquiles (#438).
##
## La vulnerabilidad no se descubre por proximidad: el jugador gira este objeto
## en pasos deliberados hasta que el ángulo de reflexión coincide con el talón.
class_name AquilesReflector
extends Interactuable3D

signal alineacion_cambiada(alineado: bool)

const PASO_GRADOS := -15.0
const ANGULO_OBJETIVO := -45.0
const TOLERANCIA := 1.0

const COLOR_BRONCE := Color(0.42, 0.30, 0.17)
const COLOR_REFLEJO := Color(0.86, 0.74, 0.48)
const COLOR_APAGADO := Color(0.26, 0.21, 0.16)

var _angulo := 0.0
var _disco: Node3D
var _indicador: MeshInstance3D
var _haz: SpotLight3D


func _ready() -> void:
	configurar()


func configurar() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "reflector de bronce"
	if _disco == null:
		_montar()
	if not activado.is_connected(_al_activar):
		activado.connect(_al_activar)
	_actualizar_feedback()


func angulo_actual() -> float:
	return _angulo


func esta_alineado() -> bool:
	var diferencia := wrapf(_angulo - ANGULO_OBJETIVO, -180.0, 180.0)
	return absf(diferencia) <= TOLERANCIA


func girar_paso() -> bool:
	_angulo = wrapf(_angulo + PASO_GRADOS, -180.0, 180.0)
	if _disco != null:
		_disco.rotation_degrees.y = _angulo
	var alineado := esta_alineado()
	_actualizar_feedback()
	alineacion_cambiada.emit(alineado)
	return alineado


func _al_activar(_actor: Node) -> void:
	girar_paso()


func _montar() -> void:
	_disco = Node3D.new()
	_disco.name = "DiscoReflector"
	add_child(_disco)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionReflector"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.25, 1.55, 0.28)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.78, 0.0)
	add_child(colision)

	var pie_malla := BoxMesh.new()
	pie_malla.size = Vector3(0.42, 1.55, 0.42)
	var pie := MeshInstance3D.new()
	pie.name = "PieReflector"
	pie.mesh = pie_malla
	pie.position = Vector3(0.0, 0.78, 0.0)
	pie.material_override = _material(COLOR_BRONCE)
	add_child(pie)

	var disco_malla := CylinderMesh.new()
	disco_malla.top_radius = 0.62
	disco_malla.bottom_radius = 0.62
	disco_malla.height = 0.10
	disco_malla.radial_segments = 20
	var disco_visual := MeshInstance3D.new()
	disco_visual.name = "SuperficieReflectora"
	disco_visual.mesh = disco_malla
	disco_visual.position = Vector3(0.0, 1.56, 0.0)
	disco_visual.rotation_degrees.x = 90.0
	disco_visual.material_override = _material(COLOR_REFLEJO, true)
	_disco.add_child(disco_visual)

	var indicador_malla := SphereMesh.new()
	indicador_malla.radius = 0.09
	indicador_malla.height = 0.18
	_indicador = MeshInstance3D.new()
	_indicador.name = "IndicadorAlineacion"
	_indicador.mesh = indicador_malla
	_indicador.position = Vector3(0.0, 1.56, -0.12)
	_disco.add_child(_indicador)

	_haz = SpotLight3D.new()
	_haz.name = "HazReflejado"
	_haz.position = Vector3(0.0, 1.56, -0.18)
	_haz.light_color = COLOR_REFLEJO
	_haz.spot_range = 12.0
	_haz.spot_angle = 18.0
	_haz.rotation_degrees.x = -12.0
	_disco.add_child(_haz)


func _actualizar_feedback() -> void:
	if _indicador == null or _haz == null:
		return
	var alineado := esta_alineado()
	_indicador.material_override = _material(
		COLOR_REFLEJO if alineado else COLOR_APAGADO,
		alineado,
	)
	_haz.light_energy = 5.0 if alineado else 0.35


func _material(color: Color, emision: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.72
	material.roughness = 0.22
	if emision:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.4
	return material
