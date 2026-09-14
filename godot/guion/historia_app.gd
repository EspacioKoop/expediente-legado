## Una decisión de la carta: las reglas siguen viviendo en Historias.
## La ventana exclusiva impide votar y operar el expediente a la vez.
extends Window

signal cerrada

var partida: Partida
var carta_id := ""
var guardar: Callable

var _historias := Historias.new()
var _opciones: VBoxContainer
var _texto: Label
var _secuela: Label
var _aviso: Label
var _volver: Button
var _reintentar: Button
var _sin_guardar := false


func _ready() -> void:
	theme = EstiloSiga.tema()
	var foco := StyleBoxFlat.new()
	foco.bg_color = Color.TRANSPARENT
	foco.border_color = EstiloSiga.AZUL_TITULO
	foco.set_border_width_all(3)
	theme.set_stylebox("focus", "Button", foco)
	title = tr("HISTORIA_TITULO")
	close_requested.connect(_cerrar)
	_historias.cargar()
	_construir()
	_mostrar()


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = EstiloSiga.GRIS
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	columna.add_child(scroll)
	var relato := VBoxContainer.new()
	relato.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relato.add_theme_constant_override("separation", 16)
	scroll.add_child(relato)
	_texto = _linea()
	relato.add_child(_texto)
	_opciones = VBoxContainer.new()
	_opciones.add_theme_constant_override("separation", 12)
	relato.add_child(_opciones)
	_secuela = _linea()
	relato.add_child(_secuela)
	_aviso = _linea()
	columna.add_child(_aviso)
	_reintentar = Button.new()
	_reintentar.text = tr("HISTORIA_REINTENTAR")
	_reintentar.pressed.connect(_guardar)
	columna.add_child(_reintentar)
	_volver = Button.new()
	_volver.text = tr("A7_VOLVER")
	_volver.pressed.connect(_cerrar)
	columna.add_child(_volver)


func _mostrar() -> void:
	var vista := _historias.vista(partida.estado, carta_id)
	_texto.text = vista.get("texto", "")
	_secuela.text = vista.get("secuela", "")
	for boton in _opciones.get_children():
		_opciones.remove_child(boton)
		boton.queue_free()
	for opcion in vista.get("opciones", []):
		var boton := Button.new()
		boton.text = tr("HISTORIA_OPCION") % [opcion["etiqueta"], opcion["texto"]]
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.pressed.connect(_elegir.bind(opcion["eje"]))
		_opciones.add_child(boton)
	_aviso.text = tr("HISTORIA_NO_DISPONIBLE") if vista.is_empty() else ""
	_reintentar.visible = _sin_guardar
	_enfocar.call_deferred()


func _enfocar() -> void:
	var botones: Array[Node] = _opciones.get_children()
	if _reintentar.visible:
		botones.append(_reintentar)
	if not _volver.disabled:
		botones.append(_volver)
	# El foco queda dentro del relato también al llegar al último botón.
	for i in botones.size():
		var boton: Control = botones[i]
		var anterior: Control = botones[(i - 1 + botones.size()) % botones.size()]
		var siguiente: Control = botones[(i + 1) % botones.size()]
		boton.focus_neighbor_top = boton.get_path_to(anterior)
		boton.focus_previous = boton.get_path_to(anterior)
		boton.focus_neighbor_bottom = boton.get_path_to(siguiente)
		boton.focus_next = boton.get_path_to(siguiente)
	if not botones.is_empty():
		botones[0].grab_focus()


func _elegir(eje: String) -> void:
	_historias.resolver(partida.estado, carta_id, eje)
	_mostrar()
	_guardar()


func _guardar() -> void:
	var guardada: bool = guardar.call() if guardar.is_valid() else partida.guardar()
	_sin_guardar = not guardada
	_aviso.text = "" if guardada else tr("ARCHIVO_ERROR_GUARDAR")
	_reintentar.visible = _sin_guardar
	_volver.disabled = _sin_guardar
	_enfocar.call_deferred()


func _cerrar() -> void:
	if _sin_guardar:
		return
	cerrada.emit()


func _unhandled_input(evento: InputEvent) -> void:
	# ui_accept no trae botón de mando en todas las versiones del motor.
	if evento is InputEventJoypadButton and evento.pressed:
		if evento.button_index == JOY_BUTTON_A:
			var boton := gui_get_focus_owner() as Button
			set_input_as_handled()
			if boton != null and not boton.disabled:
				boton.pressed.emit()
		elif evento.button_index == JOY_BUTTON_B:
			set_input_as_handled()
			_cerrar()
	elif evento.is_action_pressed("ui_cancel"):
		set_input_as_handled()
		_cerrar()


func _linea() -> Label:
	var linea := Label.new()
	linea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linea.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	return linea
