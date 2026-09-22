extends Area3D

@export var obra_id: String = "odisea"
@onready var label = $InteractionLabel


func _ready() -> void:
	label.visible = false


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("jugador"):
		label.visible = true


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("jugador"):
		label.visible = false


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_interactuar()
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_interactuar()


func _interactuar() -> void:
	var gestor = GestorLiteratura
	var fuente := "interactable:libro:%s" % obra_id
	if gestor.conocer_obra(obra_id, fuente, "lectura_interactiva"):
		label.text = "Has descubierto: %s" % obra_id
		print("Interactuado con obra %s" % obra_id)
	else:
		label.text = "Ya conoces esta obra"
	await get_tree().create_timer(2.0).timeout
	label.text = "E para leer"
