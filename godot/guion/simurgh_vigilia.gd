## Contraparte doméstica de Simurgh (#658 / #442).
##
## La lámina puede estar presente sin activar nada. El jugador debe examinarla
## varias veces y finalmente girarla para descubrir la relación pluma/nido.
class_name SimurghVigilia
extends Interactuable3D

const ID_MITO := "simurgh"
const FUENTE := "lamina:simurgh_98"
const INSPECCIONES_MINIMAS := 2

const COLOR_MARCO := Color(0.20, 0.15, 0.11)
const COLOR_PAPEL := Color(0.74, 0.68, 0.55)
const COLOR_TINTA := Color(0.34, 0.23, 0.15)
const COLOR_PLUMA := Color(0.72, 0.46, 0.20)
const COLOR_ACTIVO := Color(0.88, 0.66, 0.30)

var _jornada: Dictionary = {}
var _lamina: Node3D
var _pluma: MeshInstance3D
var _inspecciones := 0
var _girada := false
var _activada := false


func _ready() -> void:
	_configurar_prompt()
	if _lamina == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _lamina == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func inspecciones() -> int:
	return _inspecciones


func esta_girada() -> bool:
	return _girada


func esta_activada() -> bool:
	return _activada


## Dos activaciones sirven para observar detalles; la siguiente gira la lámina
## y completa la interacción deliberada. No hay mensaje de desbloqueo.
func examinar() -> bool:
	if _inspecciones < INSPECCIONES_MINIMAS:
		_inspecciones += 1
		_actualizar_feedback()
	else:
		_girada = true
		_actualizar_feedback()
	return _intentar_activar()


func _al_examinar(_actor: Node) -> void:
	examinar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = SuenoSimurgh.registrar_semilla(
		_jornada,
		_inspecciones,
		_girada,
		FUENTE,
		2,
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "lámina persa"


func _montar() -> void:
	_lamina = Node3D.new()
	_lamina.name = "LaminaSimurgh"
	add_child(_lamina)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionLaminaSimurgh"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.9, 1.35, 0.20)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.68, 0.0)
	add_child(colision)

	_agregar_caja(_lamina, "Marco", Vector3(2.0, 1.45, 0.12), Vector3(0.0, 0.72, 0.0), COLOR_MARCO)
	_agregar_caja(_lamina, "Papel", Vector3(1.74, 1.19, 0.05), Vector3(0.0, 0.72, -0.08), COLOR_PAPEL)
	_pluma = _agregar_caja(
		_lamina,
		"MotivoPluma",
		Vector3(1.18, 0.12, 0.035),
		Vector3(-0.08, 0.76, -0.13),
		COLOR_PLUMA,
	)
	for i in 4:
		_agregar_caja(
			_lamina,
			"Trazo%d" % (i + 1),
			Vector3(0.42, 0.055, 0.025),
			Vector3(-0.45 + i * 0.28, 0.40 + (i % 2) * 0.16, -0.14),
			COLOR_TINTA,
		)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _lamina == null:
		return
	_lamina.rotation_degrees.z = 180.0 if _girada else 0.0
	if _pluma == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_ACTIVO if _activada else COLOR_PLUMA
	material.roughness = 0.78
	material.emission_enabled = _inspecciones >= INSPECCIONES_MINIMAS
	if material.emission_enabled:
		material.emission = COLOR_PLUMA
		material.emission_energy_multiplier = 0.55 if not _activada else 1.1
	_pluma.material_override = material


func _agregar_caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
