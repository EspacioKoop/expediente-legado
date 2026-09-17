## Detector común de interacción en primera persona (#283).
##
## Se monta como hijo de la cámara. Solo considera `Interactuable3D`, respeta
## su estado habilitado y usa la acción semántica `interactuar` de #113.
class_name DetectorInteraccion3D
extends RayCast3D

signal objetivo_cambiado(objetivo: Interactuable3D, texto: String)
signal objetivo_perdido

@export var alcance := 2.4

var _objetivo: Interactuable3D
var _texto_objetivo := ""


func _ready() -> void:
	target_position = Vector3(0.0, 0.0, -alcance)
	collide_with_areas = true
	collide_with_bodies = false


func _physics_process(_delta: float) -> void:
	var siguiente := _resolver_objetivo()
	if siguiente == _objetivo:
		_refrescar_texto()
		return
	_objetivo = siguiente
	if _objetivo == null:
		_texto_objetivo = ""
		objetivo_perdido.emit()
	else:
		_refrescar_texto(true)


func _unhandled_input(evento: InputEvent) -> void:
	if _objetivo == null or not evento.is_action_pressed("interactuar"):
		return
	if _objetivo.interactuar(get_parent()):
		_refrescar_texto(true)
		get_viewport().set_input_as_handled()


func objetivo_actual() -> Interactuable3D:
	return _objetivo


func _refrescar_texto(forzar := false) -> void:
	if _objetivo == null:
		return
	var texto := _objetivo.texto_accion()
	if not forzar and texto == _texto_objetivo:
		return
	_texto_objetivo = texto
	objetivo_cambiado.emit(_objetivo, texto)


func _resolver_objetivo() -> Interactuable3D:
	if not is_colliding():
		return null
	var colision := get_collider()
	if colision is Interactuable3D and colision.habilitado:
		return colision
	return null
