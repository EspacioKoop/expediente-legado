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


func _ready() -> void:
	target_position = Vector3(0.0, 0.0, -alcance)
	collide_with_areas = true
	collide_with_bodies = false


func _physics_process(_delta: float) -> void:
	var siguiente := _resolver_objetivo()
	if siguiente == _objetivo:
		return
	_objetivo = siguiente
	if _objetivo == null:
		objetivo_perdido.emit()
	else:
		objetivo_cambiado.emit(_objetivo, _objetivo.texto_accion())


func _unhandled_input(evento: InputEvent) -> void:
	if _objetivo == null or not evento.is_action_pressed("interactuar"):
		return
	if _objetivo.interactuar(get_parent()):
		get_viewport().set_input_as_handled()


func objetivo_actual() -> Interactuable3D:
	return _objetivo


func _resolver_objetivo() -> Interactuable3D:
	if not is_colliding():
		return null
	var colision := get_collider()
	if colision is Interactuable3D and colision.habilitado:
		return colision
	return null
