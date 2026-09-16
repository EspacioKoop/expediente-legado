## Panel transitorio del teléfono fijo (#671).
##
## Toda llamada relevante se presenta también como texto. La ventana no posee
## reloj ni estado propio de campaña: muta exclusivamente el diccionario de
## Jornada mediante TelefonoFijo y emite `estado_cambiado` para que Dia guarde.
class_name TelefonoFijoPanel
extends Window

signal cerrada
signal estado_cambiado

var jornada: Dictionary = {}
var _estado: Label
var _contenido: RichTextLabel
var _descolgar: Button
var _contestador: Button
var _escuchar: Button
var _colgar: Button
var _contactos: VBoxContainer
var _cerrar: Button


func _init() -> void:
	visible = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	title = "Teléfono fijo"
	size = Vector2i(760, 560)
	exclusive = true
	transient = true
	close_requested.connect(_cerrar_panel)
	_construir()


func abrir(estado_jornada: Dictionary) -> void:
	jornada = estado_jornada
	_contenido.text = ""
	_refrescar()
	popup_centered()
	_enfocar.call_deferred()


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.70, 0.67, 0.57)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	add_child(margen)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	margen.add_child(columna)

	_estado = Label.new()
	_estado.name = "TelefonoEstado"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_estado)

	_contenido = RichTextLabel.new()
	_contenido.name = "TelefonoTranscript"
	_contenido.bbcode_enabled = false
	_contenido.fit_content = false
	_contenido.scroll_active = true
	_contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_contenido.custom_minimum_size.y = 220
	columna.add_child(_contenido)

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	columna.add_child(acciones)

	_descolgar = _boton("Descolgar", _al_descolgar)
	acciones.add_child(_descolgar)
	_contestador = _boton("Dejar al contestador", _al_contestador)
	acciones.add_child(_contestador)
	_escuchar = _boton("Escuchar mensaje", _al_escuchar)
	acciones.add_child(_escuchar)
	_colgar = _boton("Colgar", _al_colgar)
	acciones.add_child(_colgar)

	_contactos = VBoxContainer.new()
	_contactos.add_theme_constant_override("separation", 6)
	columna.add_child(_contactos)
	for contacto in TelefonoFijo.contactos():
		var contacto_id := String(contacto.get("id", ""))
		var boton := Button.new()
		boton.name = "Llamar_%s" % contacto_id
		boton.text = "%s · %s" % [contacto.get("nombre", "Contacto"), contacto.get("numero", "")]
		boton.pressed.connect(_al_llamar.bind(contacto_id))
		_contactos.add_child(boton)

	_cerrar = _boton("Cerrar", _cerrar_panel)
	columna.add_child(_cerrar)


func _boton(texto: String, callable: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(callable)
	return boton


func _refrescar() -> void:
	if jornada.is_empty():
		return
	var llamada := TelefonoFijo.llamada_activa(jornada)
	var telefono := TelefonoFijo.estado(jornada)
	var descolgado := bool(telefono.get(TelefonoFijo.DESCOLGADO, false))
	var nuevos := TelefonoFijo.mensajes_nuevos(jornada)
	var partes: Array[String] = []
	if llamada.is_empty():
		partes.append("Línea libre.")
	else:
		partes.append(
			(
				"Llamada entrante · %s · día %d · %s"
				% [
					llamada.get("remitente", "Número desconocido"),
					llamada.get("dia", 1),
					llamada.get("hora", "")
				]
			)
		)
	partes.append("Contestador: %d mensaje(s) nuevo(s)." % nuevos)
	partes.append("Auricular: %s." % ("descolgado" if descolgado else "colgado"))
	_estado.text = "\n".join(partes)

	_descolgar.disabled = descolgado
	_contestador.disabled = llamada.is_empty()
	_escuchar.disabled = nuevos <= 0
	_colgar.disabled = not descolgado
	for hijo in _contactos.get_children():
		if hijo is Button:
			hijo.disabled = not descolgado


func _al_descolgar() -> void:
	var resultado := TelefonoFijo.descolgar(jornada)
	if not bool(resultado.get("ok", false)):
		_mostrar_error(resultado)
		return
	if String(resultado.get("tipo", "")) == "entrante":
		var llamada = resultado.get("llamada", {})
		_contenido.text = (
			"%s · %s\n\n%s"
			% [
				llamada.get("remitente", "Número desconocido"),
				llamada.get("hora", ""),
				resultado.get("texto", ""),
			]
		)
	else:
		_contenido.text = String(resultado.get("texto", "Tono de línea."))
	_estado_cambio()


func _al_contestador() -> void:
	var resultado := TelefonoFijo.pasar_a_contestador(jornada)
	if not bool(resultado.get("ok", false)):
		_mostrar_error(resultado)
		return
	var mensaje = resultado.get("mensaje", {})
	_contenido.text = (
		"El contestador graba el mensaje.\n\n%s · %s\n%s"
		% [
			mensaje.get("remitente", "Número desconocido"),
			mensaje.get("hora", ""),
			mensaje.get("texto", ""),
		]
	)
	_estado_cambio()


func _al_escuchar() -> void:
	var resultado := TelefonoFijo.escuchar_siguiente(jornada)
	if not bool(resultado.get("ok", false)):
		_mostrar_error(resultado)
		return
	var mensaje = resultado.get("mensaje", {})
	_contenido.text = (
		"Contestador · día %d · %s\n%s\n\n%s"
		% [
			mensaje.get("dia", 1),
			mensaje.get("hora", ""),
			mensaje.get("remitente", "Número desconocido"),
			mensaje.get("texto", ""),
		]
	)
	_estado_cambio()


func _al_llamar(contacto_id: String) -> void:
	var resultado := TelefonoFijo.llamar(jornada, contacto_id)
	if not bool(resultado.get("ok", false)):
		_mostrar_error(resultado)
		return
	var contacto = resultado.get("contacto", {})
	_contenido.text = (
		"Llamada saliente · %s · %s\n\n%s"
		% [
			contacto.get("nombre", "Contacto"),
			contacto.get("numero", ""),
			resultado.get("texto", ""),
		]
	)
	_estado_cambio()


func _al_colgar() -> void:
	var resultado := TelefonoFijo.colgar(jornada)
	if not bool(resultado.get("ok", false)):
		_mostrar_error(resultado)
		return
	_contenido.text = ""
	_estado_cambio()


func _estado_cambio() -> void:
	_refrescar()
	estado_cambiado.emit()


func _mostrar_error(resultado: Dictionary) -> void:
	_contenido.text = (
		"No se puede completar la acción: %s." % resultado.get("motivo", "estado_no_valido")
	)
	_refrescar()


func _enfocar() -> void:
	if is_instance_valid(_descolgar) and not _descolgar.disabled:
		_descolgar.grab_focus()
	elif is_instance_valid(_escuchar) and not _escuchar.disabled:
		_escuchar.grab_focus()
	elif is_instance_valid(_cerrar):
		_cerrar.grab_focus()


func _cerrar_panel() -> void:
	cerrada.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventJoypadButton and evento.pressed:
		if evento.button_index == JOY_BUTTON_A:
			var boton := gui_get_focus_owner() as Button
			set_input_as_handled()
			if boton != null and not boton.disabled:
				boton.pressed.emit()
		elif evento.button_index == JOY_BUTTON_B:
			set_input_as_handled()
			_cerrar_panel()
	elif evento.is_action_pressed("cancelar") or evento.is_action_pressed("ui_cancel"):
		set_input_as_handled()
		_cerrar_panel()
