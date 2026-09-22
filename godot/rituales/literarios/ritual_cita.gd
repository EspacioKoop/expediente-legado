extends Control

@onready var selector = $Panel/VBoxContainer/ObraSelector
@onready var citar_btn = $Panel/VBoxContainer/CitarButton
@onready var close_btn = $Panel/VBoxContainer/CloseButton


func _ready() -> void:
	_poblar_selector()
	citar_btn.pressed.connect(_on_citar_pressed)
	close_btn.pressed.connect(hide)
	visible = false


func _poblar_selector() -> void:
	selector.clear()
	var archivo := FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
	if archivo == null:
		return
	var data = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if not (data is Dictionary):
		return
	var obras = data.get("obras", [])
	if not (obras is Array):
		return

	for obra_id in GestorLiteratura.obras_conocidas:
		for obra in obras:
			if obra is Dictionary and String(obra.get("id", "")) == String(obra_id):
				selector.add_item(String(obra.get("titulo", obra_id)))
				selector.set_item_metadata(selector.item_count - 1, obra_id)
				break


func _on_citar_pressed() -> void:
	var indice := selector.get_selected()
	if indice >= 0:
		var obra_id := String(selector.get_item_metadata(indice))
		_ejecutar_cita(obra_id)
	hide()


func _ejecutar_cita(obra_id: String) -> void:
	var efecto := _obtener_efecto_obra(obra_id)
	var momentum_cost := 30
	if GestorMomentum.momentum_actual < momentum_cost:
		return

	GestorMomentum.momentum_actual -= momentum_cost
	if efecto.has("efecto_especial"):
		_aplicar_cita_especial(obra_id, String(efecto.get("efecto_especial", "")))
	else:
		GestorMomentum.momentum_actual = min(
			GestorMomentum.momentum_max,
			GestorMomentum.momentum_actual + 10,
		)
	print("Citado %s, momentum restante: %s" % [obra_id, GestorMomentum.momentum_actual])


func _aplicar_cita_especial(_obra_id: String, efecto: String) -> void:
	match efecto:
		"revelacion":
			print("Revelacion: debilidad enemiga expuesta")
		"transformacion":
			print("Transformacion: forma alternativa activada")
		"no_linealidad":
			print("No linealidad: combos desordenados temporalmente")


func _obtener_efecto_obra(obra_id: String) -> Dictionary:
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
		if obra is Dictionary and String(obra.get("id", "")) == obra_id:
			var efecto = obra.get("efecto", {})
			return efecto if efecto is Dictionary else {}
	return {}


func show_ritual() -> void:
	_poblar_selector()
	visible = true
