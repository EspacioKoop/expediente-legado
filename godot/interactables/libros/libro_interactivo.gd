extends Area3D

@onready var label = $InteractionLabel
@export var obra_id: String = "odisea"


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
	if gestor.conocer_obra(obra_id):
		label.text = "Has descubierto: %s" % obra_id
		var efecto := _obtener_efecto_obra(obra_id)
		if efecto.has("bonus_insight"):
			GestorArquetipos.ganar_insight(int(efecto.get("bonus_insight", 0)))
		print("Interactuado con obra %s" % obra_id)
	else:
		label.text = "Ya conoces esta obra"
	await get_tree().create_timer(2.0).timeout
	label.text = "E para leer"


func _obtener_efecto_obra(id_obra: String) -> Dictionary:
	var archivo := FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
	if archivo == null:
		return {}
	var data = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if not (data is Dictionary):
		return {}
	var obras = data.get("obras", [])
	if not (obras is Array):
		return {}
	for obra in obras:
		if obra is Dictionary and String(obra.get("id", "")) == id_obra:
			var efecto = obra.get("efecto", {})
			return efecto if efecto is Dictionary else {}
	return {}
