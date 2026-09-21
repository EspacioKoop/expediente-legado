extends Control

@onready var selector: OptionButton = $Panel/VBoxContainer/ObraSelector
@onready var citar_btn: Button = $Panel/VBoxContainer/CitarButton
@onready var close_btn: Button = $Panel/VBoxContainer/CloseButton


func _ready() -> void:
	_poblar_selector()
	citar_btn.pressed.connect(_on_citar_pressed)
	close_btn.pressed.connect(hide)
	visible = false


func _poblar_selector() -> void:
	selector.clear()
	var literatura := _gestor("GestorLiteratura")
	if literatura == null:
		return
	for obra_id in literatura.get("obras_conocidas"):
		var obra = literatura.call("obtener_obra", String(obra_id))
		var titulo := String(obra.get("titulo", obra_id))
		selector.add_item(titulo)
		selector.set_item_metadata(selector.item_count - 1, String(obra_id))


func _on_citar_pressed() -> void:
	var indice := selector.selected
	if indice >= 0:
		var obra_id := String(selector.get_item_metadata(indice))
		_ejecutar_cita(obra_id)
	hide()


func _ejecutar_cita(obra_id: String) -> void:
	var literatura := _gestor("GestorLiteratura")
	var momentum := _gestor("GestorMomentum")
	if literatura == null or momentum == null:
		return
	var efecto = literatura.call("obtener_efecto_obra", obra_id)
	if typeof(efecto) != TYPE_DICTIONARY:
		return
	if not bool(momentum.call("consumir_momentum", 30.0)):
		return

	var efecto_especial := String(efecto.get("efecto_especial", ""))
	if efecto_especial.is_empty():
		momentum.call("agregar_momentum", 10.0)
	else:
		literatura.call("aplicar_cita_especial", efecto_especial)
	print("Citado %s, momentum restante: %.1f" % [obra_id, float(momentum.get("momentum_actual"))])


func show_ritual() -> void:
	_poblar_selector()
	visible = true


func _gestor(nombre: String) -> Node:
	return get_node_or_null("/root/" + nombre)
