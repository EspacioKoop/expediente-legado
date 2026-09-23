extends Area3D

@export var ritual_ui_path: NodePath

@onready var label: Label = get_node_or_null("InteractionLabel")


func _ready() -> void:
	if label != null:
		label.visible = false


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("jugador") and label != null:
		label.visible = true


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("jugador") and label != null:
		label.visible = false


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		abrir_ritual()
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		abrir_ritual()


func abrir_ritual() -> bool:
	var ritual := get_node_or_null(ritual_ui_path)
	if ritual == null or not ritual.has_method("show_ritual"):
		return false
	ritual.call("show_ritual")
	return true
