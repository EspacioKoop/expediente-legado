## Contraparte de vigilia del sueño del Minotauro (#437 / #442).
##
## El objeto puede estar presente durante todo el día, pero la semilla solo se
## activa al abrir la reproducción y completar una marca de ruta. Pasar cerca
## o mirar el objeto sin manipularlo no contamina el sueño.
class_name MinotauroVigilia
extends Interactuable3D

const ID_MITO := "minotauro"
const FUENTE := "rom:ariadna_labertinto_98"
const INTERACCIONES_REQUERIDAS := 2

var _jornada: Dictionary = {}
var _interacciones := 0
var _activada := false
var _objeto: Node3D


func _ready() -> void:
	_configurar_prompt()
	_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _objeto == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func interacciones_deliberadas() -> int:
	return _interacciones


func esta_activada() -> bool:
	return _activada


## Cada examen es una acción explícita: primero se abre la ROM y después se
## confirma una ruta. La misma fuente queda registrada de forma idempotente.
func _al_examinar(_actor: Node) -> void:
	_interacciones = mini(_interacciones + 1, INTERACCIONES_REQUERIDAS)
	_actualizar_feedback()
	_intentar_activar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	if _interacciones < INTERACCIONES_REQUERIDAS:
		return false
	_activada = SemillasOniricas.activar_semilla_onirica(_jornada, ID_MITO, FUENTE, 2)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "cartucho ARIADNA"


func _montar() -> void:
	_objeto = Node3D.new()
	_objeto.name = "CartuchoAriadna"
	add_child(_objeto)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.6, 0.35, 1.0)
	colision.shape = forma
	add_child(colision)
	var malla := BoxMesh.new()
	malla.size = Vector3(1.5, 0.28, 0.9)
	var visual := MeshInstance3D.new()
	visual.name = "EtiquetaLaberinto"
	visual.mesh = malla
	_objeto.add_child(visual)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _objeto == null or _objeto.get_child_count() == 0:
		return
	var visual := _objeto.get_child(0) as MeshInstance3D
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.46, 0.16, 0.10) if _activada else Color(0.18, 0.22, 0.26)
	material.roughness = 0.7
	visual.material_override = material
