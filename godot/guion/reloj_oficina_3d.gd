## Reloj mural analógico de la oficina (#963).
##
## No contiene temporizador: representa la hora que le entrega Jornada. Cambiar
## la hora del sistema, esperar delante de él o bajar los FPS no mueve las
## agujas. Esa separación es el límite entre feedback diegético y contrarreloj.
class_name RelojOficina3D
extends Node3D

const RADIO := 0.42
const PROFUNDIDAD := 0.08
const LARGO_HORA := 0.20
const LARGO_MINUTO := 0.29

var _pivote_hora: Node3D
var _pivote_minuto: Node3D
var _construido := false


func _ready() -> void:
	_construir()


## Coloca las agujas en una hora de Jornada, expresada en minutos desde medianoche.
func poner_hora(minutos: int) -> void:
	_construir()
	var normalizados := posmod(minutos, 24 * 60)
	var vuelta_hora := float(posmod(normalizados, 12 * 60)) / float(12 * 60)
	var vuelta_minuto := float(posmod(normalizados, 60)) / 60.0
	_pivote_hora.rotation.z = -TAU * vuelta_hora
	_pivote_minuto.rotation.z = -TAU * vuelta_minuto
	set_meta("hora_minutos", normalizados)


func _construir() -> void:
	if _construido:
		return
	_construido = true

	var marco := MeshInstance3D.new()
	marco.name = "Marco"
	var malla_marco := CylinderMesh.new()
	malla_marco.top_radius = RADIO
	malla_marco.bottom_radius = RADIO
	malla_marco.height = PROFUNDIDAD
	malla_marco.radial_segments = 24
	marco.mesh = malla_marco
	marco.material_override = _material(Color(0.10, 0.09, 0.07), 0.42)
	marco.rotation_degrees.x = 90.0
	add_child(marco)

	var esfera := MeshInstance3D.new()
	esfera.name = "Esfera"
	var malla_esfera := CylinderMesh.new()
	malla_esfera.top_radius = RADIO * 0.88
	malla_esfera.bottom_radius = RADIO * 0.88
	malla_esfera.height = 0.025
	malla_esfera.radial_segments = 24
	esfera.mesh = malla_esfera
	esfera.material_override = _material(Color(0.77, 0.75, 0.66), 0.76)
	esfera.position.z = 0.055
	esfera.rotation_degrees.x = 90.0
	add_child(esfera)

	for indice in 12:
		var pivote := Node3D.new()
		pivote.rotation.z = -TAU * float(indice) / 12.0
		add_child(pivote)
		var marca := MeshInstance3D.new()
		marca.name = "Marca%02d" % indice
		var malla_marca := BoxMesh.new()
		malla_marca.size = Vector3(0.025, 0.065, 0.018)
		marca.mesh = malla_marca
		marca.material_override = _material(Color(0.12, 0.115, 0.10), 0.58)
		marca.position = Vector3(0.0, RADIO * 0.72, 0.082)
		pivote.add_child(marca)

	_pivote_hora = _aguja("PivoteHora", LARGO_HORA, 0.045, 0.095)
	_pivote_minuto = _aguja("PivoteMinuto", LARGO_MINUTO, 0.03, 0.105)

	var eje := MeshInstance3D.new()
	eje.name = "Eje"
	var malla_eje := CylinderMesh.new()
	malla_eje.top_radius = 0.035
	malla_eje.bottom_radius = 0.035
	malla_eje.height = 0.035
	malla_eje.radial_segments = 12
	eje.mesh = malla_eje
	eje.material_override = _material(Color(0.08, 0.075, 0.065), 0.38)
	eje.position.z = 0.12
	eje.rotation_degrees.x = 90.0
	add_child(eje)


func _aguja(nombre: String, largo: float, ancho: float, z: float) -> Node3D:
	var pivote := Node3D.new()
	pivote.name = nombre
	add_child(pivote)

	var aguja := MeshInstance3D.new()
	aguja.name = "Aguja"
	var malla := BoxMesh.new()
	malla.size = Vector3(ancho, largo, 0.022)
	aguja.mesh = malla
	aguja.material_override = _material(Color(0.055, 0.05, 0.045), 0.34)
	aguja.position = Vector3(0.0, largo * 0.5, z)
	pivote.add_child(aguja)
	return pivote


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rugosidad
	return material
