## Persiana doméstica bloqueada por un imprevisto (#93/#680).
##
## La consecuencia sigue perteneciendo a Imprevistos. Este nodo solo traduce
## una herramienta del inventario con uso semántico `forzar` a la reparación
## física; no consume el objeto ni crea una economía paralela.
class_name PersianaAtascada3D
extends Interactuable3D

signal reparada(herramienta_id: String)

const CONSECUENCIA := "casa_persiana_atascada"
const USO_REQUERIDO := "forzar"

var _jornada: Dictionary = {}
var _inventario: Dictionary = {}


func _ready() -> void:
	if get_node_or_null("VolumenInteraccion") == null:
		_montar_volumen()


func configurar(jornada: Dictionary, inventario: Dictionary) -> void:
	_jornada = jornada
	_inventario = inventario
	verbo = Verbo.USAR
	nombre_objeto = "persiana atascada"
	sonido = "abrir"
	set_meta("uso_requerido", USO_REQUERIDO)
	if get_node_or_null("VolumenInteraccion") == null:
		_montar_volumen()


func herramienta_disponible() -> Dictionary:
	if _inventario.is_empty():
		return {}
	for objeto in Inventario.visibles(_inventario, true):
		if typeof(objeto) != TYPE_DICTIONARY:
			continue
		var usos = objeto.get("usos", [])
		if typeof(usos) != TYPE_ARRAY or not usos.has(USO_REQUERIDO):
			continue
		return objeto.duplicate(true)
	return {}


func interactuar(actor: Node) -> bool:
	if not habilitado:
		return false
	var herramienta := herramienta_disponible()
	if herramienta.is_empty():
		set_meta("ultimo_resultado", "falta_herramienta")
		return false
	if not Imprevistos.reparar_consecuencia(_jornada, CONSECUENCIA):
		set_meta("ultimo_resultado", "sin_consecuencia")
		return false

	var herramienta_id := String(herramienta.get("id", ""))
	set_meta("ultimo_resultado", "reparada")
	set_meta("herramienta_usada", herramienta_id)
	if not super.interactuar(actor):
		return false
	habilitado = false
	reparada.emit(herramienta_id)
	return true


func _montar_volumen() -> void:
	var colision := CollisionShape3D.new()
	colision.name = "VolumenInteraccion"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.75, 1.15, 0.32)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.02, 0.0)
	add_child(colision)
