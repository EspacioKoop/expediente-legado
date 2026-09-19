## Contraparte doméstica del Popol Wuj (#655 / #442).
##
## El libro puede estar presente sin activar nada. La semilla solo aparece al
## examinar dos páginas y comparar deliberadamente una pareja visual entre ellas.
## No hay pregunta cultural ni respuesta correcta.
class_name PopolWujVigilia
extends Interactuable3D

const FUENTE := "libro:popol_wuj_98"
const INSPECCIONES_MINIMAS := 2

const COLOR_CUBIERTA := Color(0.22, 0.15, 0.11)
const COLOR_PAPEL := Color(0.72, 0.66, 0.50)
const COLOR_TINTA := Color(0.25, 0.22, 0.17)
const COLOR_PAREJA := Color(0.56, 0.40, 0.20)
const COLOR_ACTIVO := Color(0.76, 0.61, 0.28)

var _jornada: Dictionary = {}
var _libro: Node3D
var _marca_izquierda: MeshInstance3D
var _marca_derecha: MeshInstance3D
var _inspecciones := 0
var _pareja_comparada := false
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


func inspecciones() -> int:
	return _inspecciones


func pareja_comparada() -> bool:
	return _pareja_comparada


func esta_activada() -> bool:
	return _activada


func examinar() -> bool:
	if _inspecciones < INSPECCIONES_MINIMAS:
		_inspecciones += 1
	else:
		_pareja_comparada = true
	_actualizar_feedback()
	return _intentar_activar()


func _al_examinar(_actor: Node) -> void:
	examinar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = (
		SuenoPopolWuj
		. registrar_semilla(
			_jornada,
			_inspecciones,
			_pareja_comparada,
			FUENTE,
			2,
		)
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "libro cultural ilustrado"


func _montar() -> void:
	_libro = Node3D.new()
	_libro.name = "LibroPopolWuj"
	add_child(_libro)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionLibroPopolWuj"
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.1, 0.22, 1.45)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.16, 0.0)
	add_child(colision)

	_agregar_caja(
		_libro, "Cubierta", Vector3(2.15, 0.12, 1.50), Vector3(0.0, 0.06, 0.0), COLOR_CUBIERTA
	)
	_agregar_caja(
		_libro, "PaginaIzquierda", Vector3(0.98, 0.06, 1.34), Vector3(-0.52, 0.15, 0.0), COLOR_PAPEL
	)
	_agregar_caja(
		_libro, "PaginaDerecha", Vector3(0.98, 0.06, 1.34), Vector3(0.52, 0.15, 0.0), COLOR_PAPEL
	)
	_marca_izquierda = _agregar_caja(
		_libro,
		"MarcaParejaIzquierda",
		Vector3(0.34, 0.08, 0.34),
		Vector3(-0.52, 0.21, 0.0),
		COLOR_PAREJA
	)
	_marca_derecha = _agregar_caja(
		_libro,
		"MarcaParejaDerecha",
		Vector3(0.34, 0.08, 0.34),
		Vector3(0.52, 0.21, 0.0),
		COLOR_PAREJA
	)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _marca_izquierda == null or _marca_derecha == null:
		return
	var escala := 1.12 if _pareja_comparada else 1.0
	_marca_izquierda.scale = Vector3.ONE * escala
	_marca_derecha.scale = Vector3.ONE * escala
	for marca in [_marca_izquierda, _marca_derecha]:
		var material := StandardMaterial3D.new()
		material.albedo_color = COLOR_ACTIVO if _activada else COLOR_PAREJA
		material.roughness = 0.78
		material.emission_enabled = _inspecciones >= INSPECCIONES_MINIMAS
		if material.emission_enabled:
			material.emission = COLOR_PAREJA
			material.emission_energy_multiplier = 0.35 if not _pareja_comparada else 0.70
		marca.material_override = material


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
