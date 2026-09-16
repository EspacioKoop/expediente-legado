## Una microinteracción doméstica reversible para #675.
##
## Conserva el contrato semántico de Interactuable3D: teclado y mando llegan
## por la acción común `interactuar`. Esta clase solo alterna un booleano de
## CasaRutinas y mueve/rota una pieza visual. Con reducción de movimiento el
## mismo estado final se aplica en corte, sin tween ni reglas diferentes.
class_name CasaRutinaInteractiva3D
extends Interactuable3D

const DURACION := 0.16

var _jornada: Dictionary = {}
var _clave := ""
var _activo := false
var _reduccion_movimiento := false
var _visual: Node3D
var _pos_inactiva := Vector3.ZERO
var _pos_activa := Vector3.ZERO
var _rot_inactiva := Vector3.ZERO
var _rot_activa := Vector3.ZERO
var _texto_inactivo := "Usar"
var _texto_activo := "Usar"
var _sonido_inactivo := ""
var _sonido_activo := ""
var _verbo_inactivo := Verbo.USAR
var _verbo_activo := Verbo.USAR
var _tween: Tween


## `inactivo` y `activo` describen cada extremo del estado con las claves
## `pos`, `rot` (Vector3), `texto`, `sonido` (String) y `verbo` (Verbo).
func configurar(
	jornada: Dictionary,
	clave: String,
	visual: Node3D,
	tamano_colision: Vector3,
	inactivo: Dictionary,
	activo: Dictionary,
	estado_inicial: bool,
	reduccion_movimiento: bool = false,
) -> void:
	_jornada = jornada
	_clave = clave
	_visual = visual if visual != null else self
	_pos_inactiva = inactivo.get("pos", Vector3.ZERO)
	_pos_activa = activo.get("pos", Vector3.ZERO)
	_rot_inactiva = inactivo.get("rot", Vector3.ZERO)
	_rot_activa = activo.get("rot", Vector3.ZERO)
	_texto_inactivo = inactivo.get("texto", "Usar")
	_texto_activo = activo.get("texto", "Usar")
	_sonido_inactivo = inactivo.get("sonido", "")
	_sonido_activo = activo.get("sonido", "")
	_verbo_inactivo = inactivo.get("verbo", Verbo.USAR)
	_verbo_activo = activo.get("verbo", Verbo.USAR)
	_reduccion_movimiento = reduccion_movimiento
	_activo = estado_inicial

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamano_colision
	colision.shape = forma
	add_child(colision)

	_refrescar_verbo()
	_aplicar_visual(false)


func esta_activa() -> bool:
	return _activo


func visual_objetivo() -> Node3D:
	return _visual


func texto_accion() -> String:
	return _texto_activo if _activo else _texto_inactivo


func interactuar(actor: Node) -> bool:
	if not habilitado or _clave.is_empty():
		return false
	var sonido_actual := _sonido_activo if _activo else _sonido_inactivo
	_activo = CasaRutinas.alternar(_jornada, _clave)
	_aplicar_visual(true)
	_refrescar_verbo()
	activado.emit(actor)
	Sonido.sonar_en(self, sonido_actual)
	return true


func _refrescar_verbo() -> void:
	verbo = _verbo_activo if _activo else _verbo_inactivo


func _aplicar_visual(animar: bool) -> void:
	if _visual == null:
		return
	var destino_pos := _pos_activa if _activo else _pos_inactiva
	var destino_rot := _rot_activa if _activo else _rot_inactiva
	if not animar or _reduccion_movimiento or not is_inside_tree():
		_visual.position = destino_pos
		_visual.rotation_degrees = destino_rot
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_visual, "position", destino_pos, DURACION)
	_tween.tween_property(_visual, "rotation_degrees", destino_rot, DURACION)
