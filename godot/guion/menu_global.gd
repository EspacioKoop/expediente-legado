## Menú común a archivo, casa y sueño (#113).
##
## Recupera del menú web legado su contrato útil: diálogo modal, pausa real,
## navegación por foco, B/Escape para volver y restauración del foco previo.
## Vive como autoload para no duplicarse entre las tres partes del juego.
extends CanvasLayer

var _preferencias: Dictionary = {}
var _fondo: ColorRect
var _panel_principal: PanelContainer
var _panel_opciones: PanelContainer
var _continuar: Button
var _opciones: Button
var _volver: Button
var _salir: Button
var _volumen: HSlider
var _reduccion: CheckButton
var _estado_remapeo: Label
var _botones_remapeo: Dictionary = {}
var _captura_accion := ""
var _captura_tipo := ""
var _foco_previo: Control
var _mouse_previo := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_preferencias = PreferenciasSiga.cargar()
	PreferenciasSiga.aplicar(_preferencias)
	_aplicar_volumen()
	_montar()


func _unhandled_input(evento: InputEvent) -> void:
	if not _captura_accion.is_empty():
		if evento is InputEventKey and evento.pressed and not evento.echo:
			_aplicar_remapeo("teclado", int(evento.physical_keycode))
			get_viewport().set_input_as_handled()
			return
		if evento is InputEventJoypadButton and evento.pressed:
			_aplicar_remapeo("mando", int(evento.button_index))
			get_viewport().set_input_as_handled()
			return
	if not evento.is_action_pressed("cancelar"):
		return
	if _fondo.visible:
		_cerrar()
	elif _puede_abrir():
		_abrir()
	get_viewport().set_input_as_handled()


func _puede_abrir() -> bool:
	var escena := get_tree().current_scene
	return escena != null and escena.scene_file_path == "res://escenas/dia.tscn"


func _montar() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color(0.0, 0.0, 0.0, 0.72)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_fondo.visible = false
	add_child(_fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.add_child(centro)

	_panel_principal = _crear_panel()
	centro.add_child(_panel_principal)
	var principal := _caja(_panel_principal)
	_principal_contenido(principal)

	_panel_opciones = _crear_panel()
	_panel_opciones.visible = false
	centro.add_child(_panel_opciones)
	var opciones := _caja(_panel_opciones)
	_opciones_contenido(opciones)


func _crear_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 300)
	panel.theme = EstiloSiga.tema()
	return panel


func _caja(panel: PanelContainer) -> VBoxContainer:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	margen.add_child(caja)
	return caja


func _principal_contenido(caja: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = tr("MENU_GLOBAL_TITULO")
	caja.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = tr("MENU_GLOBAL_SUBTITULO")
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(subtitulo)

	_continuar = Button.new()
	_continuar.text = tr("MENU_GLOBAL_CONTINUAR")
	_continuar.pressed.connect(_cerrar)
	caja.add_child(_continuar)

	_opciones = Button.new()
	_opciones.text = tr("MENU_GLOBAL_OPCIONES")
	_opciones.pressed.connect(_mostrar_opciones)
	caja.add_child(_opciones)

	_salir = Button.new()
	_salir.text = tr("MENU_GLOBAL_SALIR")
	_salir.pressed.connect(func(): get_tree().quit())
	caja.add_child(_salir)


func _opciones_contenido(caja: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = tr("MENU_GLOBAL_OPCIONES")
	caja.add_child(titulo)

	var volumen_titulo := Label.new()
	volumen_titulo.text = tr("MENU_GLOBAL_VOLUMEN")
	caja.add_child(volumen_titulo)

	_volumen = HSlider.new()
	_volumen.min_value = 0.0
	_volumen.max_value = 1.0
	_volumen.step = 0.05
	_volumen.value = float(_preferencias.get("volumen", 1.0))
	_volumen.value_changed.connect(_al_cambiar_volumen)
	caja.add_child(_volumen)

	_reduccion = CheckButton.new()
	_reduccion.text = tr("MENU_GLOBAL_REDUCCION_MOVIMIENTO")
	_reduccion.button_pressed = bool(_preferencias.get("reduccion_movimiento", false))
	_reduccion.toggled.connect(_al_cambiar_reduccion)
	caja.add_child(_reduccion)

	var separador := HSeparator.new()
	caja.add_child(separador)
	_montar_remapeo(caja)

	_volver = Button.new()
	_volver.text = tr("MENU_GLOBAL_VOLVER")
	_volver.pressed.connect(_mostrar_principal)
	caja.add_child(_volver)


func _montar_remapeo(caja: VBoxContainer) -> void:
	_botones_remapeo.clear()
	for accion in PreferenciasSiga.ACCIONES:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		caja.add_child(fila)

		var nombre := Label.new()
		nombre.text = accion.replace("_", " ").capitalize()
		nombre.custom_minimum_size.x = 180
		fila.add_child(nombre)

		for tipo in ["teclado", "mando"]:
			var boton := Button.new()
			boton.custom_minimum_size.x = 120
			boton.pressed.connect(_iniciar_captura.bind(accion, tipo))
			fila.add_child(boton)
			_botones_remapeo[_clave_boton(accion, tipo)] = boton

	var controles := HBoxContainer.new()
	controles.add_theme_constant_override("separation", 8)
	caja.add_child(controles)

	_estado_remapeo = Label.new()
	_estado_remapeo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controles.add_child(_estado_remapeo)

	var restaurar := Button.new()
	restaurar.text = "↺"
	restaurar.pressed.connect(_restaurar_controles)
	controles.add_child(restaurar)
	_refrescar_remapeo()


func _clave_boton(accion: String, tipo: String) -> String:
	return accion + ":" + tipo


func _iniciar_captura(accion: String, tipo: String) -> void:
	_cancelar_captura()
	_captura_accion = accion
	_captura_tipo = tipo
	_estado_remapeo.text = accion.replace("_", " ") + " · " + tipo
	var boton: Button = _botones_remapeo[_clave_boton(accion, tipo)]
	boton.text = "…"
	boton.grab_focus()


func _aplicar_remapeo(tipo: String, codigo: int) -> void:
	if tipo != _captura_tipo:
		return
	var accion := _captura_accion
	var resultado := PreferenciasSiga.remapear(_preferencias, accion, tipo, codigo)
	if resultado.get("ok", false):
		PreferenciasSiga.aplicar(_preferencias)
		PreferenciasSiga.guardar(_preferencias)
		_estado_remapeo.text = "✓ " + accion.replace("_", " ")
	else:
		_estado_remapeo.text = "⚠ " + String(resultado.get("accion", resultado.get("motivo", "")))
	_captura_accion = ""
	_captura_tipo = ""
	_refrescar_remapeo()


func _cancelar_captura() -> void:
	if _captura_accion.is_empty():
		return
	_captura_accion = ""
	_captura_tipo = ""
	_refrescar_remapeo()


func _restaurar_controles() -> void:
	_preferencias["acciones"] = PreferenciasSiga.nuevas()["acciones"].duplicate(true)
	PreferenciasSiga.aplicar(_preferencias)
	PreferenciasSiga.guardar(_preferencias)
	_estado_remapeo.text = "↺"
	_refrescar_remapeo()


func _refrescar_remapeo() -> void:
	for accion in _preferencias.get("acciones", {}):
		var mapa: Dictionary = _preferencias["acciones"][accion]
		var tecla: Button = _botones_remapeo.get(_clave_boton(accion, "teclado"))
		var mando: Button = _botones_remapeo.get(_clave_boton(accion, "mando"))
		if tecla != null:
			tecla.text = OS.get_keycode_string(int(mapa.get("teclado", 0)))
		if mando != null:
			mando.text = "🎮 %d" % int(mapa.get("mando", 0))


func _abrir() -> void:
	_foco_previo = get_viewport().gui_get_focus_owner()
	_mouse_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_panel_principal.visible = true
	_panel_opciones.visible = false
	_fondo.visible = true
	get_tree().paused = true
	_continuar.grab_focus()


func _cerrar() -> void:
	if not _fondo.visible:
		return
	_cancelar_captura()
	_fondo.visible = false
	get_tree().paused = false
	Input.mouse_mode = _mouse_previo
	if is_instance_valid(_foco_previo) and _foco_previo.is_inside_tree():
		_foco_previo.grab_focus()
	_foco_previo = null


func _mostrar_opciones() -> void:
	_panel_principal.visible = false
	_panel_opciones.visible = true
	_volumen.grab_focus()


func _mostrar_principal() -> void:
	_cancelar_captura()
	_panel_opciones.visible = false
	_panel_principal.visible = true
	_opciones.grab_focus()


func _al_cambiar_volumen(valor: float) -> void:
	_preferencias["volumen"] = valor
	_aplicar_volumen()
	PreferenciasSiga.guardar(_preferencias)


func _al_cambiar_reduccion(activa: bool) -> void:
	_preferencias["reduccion_movimiento"] = activa
	PreferenciasSiga.guardar(_preferencias)


func _aplicar_volumen() -> void:
	var volumen := clampf(float(_preferencias.get("volumen", 1.0)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volumen, 0.0001)))
	AudioServer.set_bus_mute(0, volumen <= 0.0)
