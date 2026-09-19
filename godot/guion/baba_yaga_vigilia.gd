## Contraparte de vigilia para Baba Yaga (#652 / #442).
##
## Un libro doméstico de cuentos no activa la semilla por estar en la estantería:
## hay que leer dos fragmentos, abrir el desplegable y comparar dos versiones de
## la cabaña. La familia entra en el sueño solo tras esa interacción sostenida.
class_name BabaYagaVigilia
extends Interactuable3D

const FUENTE := "libro:cuentos_eslavos_98"
const LECTURAS_MINIMAS := 2

const COLOR_PAPEL := Color(0.73, 0.68, 0.55)
const COLOR_TINTA := Color(0.24, 0.22, 0.18)
const COLOR_BOSQUE := Color(0.26, 0.37, 0.24)
const COLOR_ACTIVO := Color(0.72, 0.58, 0.28)

var _jornada: Dictionary = {}
var _libro: Node3D
var _detalle: MeshInstance3D
var _lecturas := 0
var _abierto := false
var _comparo_versiones := false
var _activada := false


func _ready() -> void:
	_configurar_prompt()
	if _libro == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _libro == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func lecturas() -> int:
	return _lecturas


func esta_abierto() -> bool:
	return _abierto


func comparo_versiones() -> bool:
	return _comparo_versiones


func esta_activada() -> bool:
	return _activada


## 1-2: leer dos fragmentos; 3: abrir el desplegable; 4: comparar las dos
## representaciones de la cabaña. La mera presencia del libro no cuenta.
func examinar() -> bool:
	if _lecturas < LECTURAS_MINIMAS:
		_lecturas += 1
	elif not _abierto:
		_abierto = true
	else:
		_comparo_versiones = true
	_actualizar_feedback()
	return _intentar_activar()


func _al_examinar(_actor: Node) -> void:
	examinar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = (
		SuenoBabaYaga
		. registrar_semilla(
			_jornada,
			_lecturas,
			_abierto,
			_comparo_versiones,
			FUENTE,
			2,
		)
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "libro de cuentos del este de Europa"


func _montar() -> void:
	_libro = Node3D.new()
	_libro.name = "LibroBabaYaga"
	add_child(_libro)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionLibroBabaYaga"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.8, 1.2, 0.22)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.60, 0.0)
	add_child(colision)

	_agregar_caja(
		_libro,
		"Cubierta",
		Vector3(1.8, 1.15, 0.12),
		Vector3(0.0, 0.60, 0.0),
		COLOR_PAPEL,
	)
	_agregar_caja(
		_libro,
		"Lomo",
		Vector3(0.14, 1.10, 0.16),
		Vector3(-0.82, 0.60, 0.0),
		COLOR_TINTA,
	)
	_agregar_caja(
		_libro,
		"Bosque",
		Vector3(0.58, 0.48, 0.04),
		Vector3(-0.30, 0.68, -0.08),
		COLOR_BOSQUE,
	)
	_detalle = _agregar_caja(
		_libro,
		"CabanaComparada",
		Vector3(0.58, 0.48, 0.04),
		Vector3(0.40, 0.48, -0.08),
		COLOR_TINTA,
	)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _detalle == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_ACTIVO if _activada else COLOR_TINTA
	material.roughness = 0.80
	material.emission_enabled = _abierto
	if material.emission_enabled:
		material.emission = COLOR_ACTIVO
		material.emission_energy_multiplier = 0.95 if _comparo_versiones else 0.30
	_detalle.material_override = material
	_detalle.scale = Vector3.ONE * (1.14 if _comparo_versiones else 1.0)
	_libro.scale.x = 1.10 if _abierto else 1.0


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
