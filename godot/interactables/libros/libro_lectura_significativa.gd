extends Area3D

signal progreso_cambiado(obra_id: String, progreso: float)
signal lectura_completada(obra_id: String)

@export var obra_id: String = "vida_es_sueno_1635"
@export var fuente_documental: String = "biblioteca:edicion_1998:vida_es_sueno"
@export_range(1, 8, 1) var pasos_para_completar: int = 2

var pasos_realizados: int = 0

@onready var label: Label = get_node_or_null("InteractionLabel")


func _ready() -> void:
	if label != null:
		label.visible = false
		_actualizar_label()


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("jugador") and label != null:
		label.visible = true


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("jugador") and label != null:
		label.visible = false


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		avanzar_lectura()
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		avanzar_lectura()


func avanzar_lectura(jornada: int = 0) -> Dictionary:
	pasos_realizados = mini(pasos_para_completar, pasos_realizados + 1)
	var progreso := float(pasos_realizados) / float(maxi(1, pasos_para_completar))
	var resultado := (
		GestorLiteratura
		. registrar_lectura_significativa(
			obra_id,
			fuente_documental,
			jornada,
			progreso,
		)
	)

	progreso_cambiado.emit(obra_id, progreso)
	if bool(resultado.get("completa", false)):
		lectura_completada.emit(obra_id)
	_actualizar_label(resultado)
	return resultado


func _actualizar_label(resultado: Dictionary = {}) -> void:
	if label == null:
		return
	if bool(resultado.get("completa", false)):
		if bool(resultado.get("insight_nuevo", false)):
			label.text = "Lectura completa · insight obtenido"
		else:
			label.text = "Lectura completa"
		return
	var progreso := float(pasos_realizados) / float(maxi(1, pasos_para_completar))
	if pasos_realizados == 0:
		label.text = "E para hojear"
	else:
		label.text = "Lectura %d%% · E para continuar" % roundi(progreso * 100.0)
