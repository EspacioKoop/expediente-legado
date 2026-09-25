## Cliente de correo corporativo del escritorio OS98 (#538, #791).
##
## La UI no decide qué mensajes existen ni cuándo llegan: consulta
## CorreoSigaModelo con el estado vivo de Jornada y solo conserva qué mensajes
## ha leído el jugador y qué respuestas ha enviado. Ese estado se entrega al
## adaptador para persistirlo como estado local de la aplicación, no dentro de
## la campaña.
class_name CorreoSiga
extends HSplitContainer

signal mensaje_leido(id: String)
signal respuesta_enviada(mensaje_id: String, opcion_id: String, dia: int, acciones: int)
signal paquete_software_obtenido(id: String)

const RUTA_TEXTOS := "res://datos/correo_siga_textos.json"

var _modelo := CorreoSigaModelo.new()
var _jornada: Dictionary = {}
var _companeros: Array[String] = []
var _leidos: Array[String] = []
var _respuestas_enviadas: Dictionary = {}
var _firma_contexto := ""

var _lista: ItemList
var _cabecera: Label
var _meta: Label
var _cuerpo: RichTextLabel
var _estado: Label
var _adjunto: Button
var _adjunto_paquete_id := ""
var _respuestas_panel: VBoxContainer


static func texto(clave: String) -> String:
	if not FileAccess.file_exists(RUTA_TEXTOS):
		return clave
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	if datos is Dictionary:
		return String((datos as Dictionary).get(clave, clave))
	return clave


func configurar_contexto(jornada: Dictionary, companeros: Array[String]) -> void:
	_jornada = jornada
	_companeros = companeros.duplicate()
	_firma_contexto = ""
	if is_node_ready():
		_refrescar()


func configurar_leidos(valores: Array) -> void:
	_leidos.clear()
	for valor in valores:
		var id := String(valor)
		if not id.is_empty() and not _leidos.has(id):
			_leidos.append(id)
	if is_node_ready():
		_refrescar()


func configurar_respuestas_enviadas(valores: Dictionary) -> void:
	_respuestas_enviadas = valores.duplicate(true)
	if is_node_ready():
		_refrescar()


func leidos() -> Array[String]:
	return _leidos.duplicate()


func respuestas_enviadas() -> Dictionary:
	return _respuestas_enviadas.duplicate(true)


func _ready() -> void:
	custom_minimum_size = Vector2(620, 400)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_offset = 265
	add_theme_constant_override("separation", 3)
	_construir_interfaz()
	_refrescar()


func _process(_delta: float) -> void:
	if _jornada.is_empty():
		return
	var firma := (
		"%d|%d|%s"
		% [
			int(_jornada.get("dia", 1)),
			int(_jornada.get("acciones", Jornada.ACCIONES_POR_DIA)),
			String(_jornada.get("fase", "archivo")),
		]
	)
	if firma != _firma_contexto:
		_refrescar()


func _construir_interfaz() -> void:
	var izquierda := VBoxContainer.new()
	izquierda.name = "Bandeja"
	izquierda.custom_minimum_size = Vector2(245, 0)
	izquierda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	izquierda.add_theme_constant_override("separation", 5)
	add_child(izquierda)

	var titulo := Label.new()
	titulo.name = "TituloBandeja"
	titulo.text = texto("bandeja")
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color("#1f3f5c"))
	izquierda.add_child(titulo)

	_lista = ItemList.new()
	_lista.name = "Mensajes"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.select_mode = ItemList.SELECT_SINGLE
	_lista.add_theme_color_override("font_color", Color("#172633"))
	_lista.add_theme_color_override("font_selected_color", Color("#f7fbff"))
	_lista.add_theme_stylebox_override(
		"panel", _caja(Color("#e8f0f5"), Color("#668198"), 1, 2, 7.0, 6.0)
	)
	_lista.add_theme_stylebox_override(
		"focus", _caja(Color("#d4e4ee"), Color("#2d658c"), 2, 2, 6.0, 5.0)
	)
	_lista.item_selected.connect(_seleccionar_mensaje)
	izquierda.add_child(_lista)

	_estado = Label.new()
	_estado.name = "EstadoBandeja"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.add_theme_font_size_override("font_size", 12)
	_estado.add_theme_color_override("font_color", Color("#3a5163"))
	izquierda.add_child(_estado)

	var derecha := VBoxContainer.new()
	derecha.name = "Lectura"
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	derecha.add_theme_constant_override("separation", 5)
	add_child(derecha)

	_cabecera = Label.new()
	_cabecera.name = "Asunto"
	_cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cabecera.text = texto("seleccionar")
	_cabecera.add_theme_font_size_override("font_size", 19)
	_cabecera.add_theme_color_override("font_color", Color("#173f61"))
	derecha.add_child(_cabecera)

	_meta = Label.new()
	_meta.name = "Metadatos"
	_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meta.text = ""
	_meta.add_theme_font_size_override("font_size", 12)
	_meta.add_theme_color_override("font_color", Color("#62717b"))
	derecha.add_child(_meta)

	_cuerpo = RichTextLabel.new()
	_cuerpo.name = "Cuerpo"
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cuerpo.selection_enabled = true
	_cuerpo.fit_content = false
	_cuerpo.text = texto("espera")
	_cuerpo.add_theme_color_override("default_color", Color("#252b2f"))
	_cuerpo.add_theme_stylebox_override(
		"normal", _caja(Color("#fffdf6"), Color("#a5a08f"), 1, 2, 11.0, 9.0)
	)
	_cuerpo.add_theme_stylebox_override(
		"focus", _caja(Color("#fffdf6"), Color("#2d658c"), 2, 2, 10.0, 8.0)
	)
	derecha.add_child(_cuerpo)

	_adjunto = Button.new()
	_adjunto.name = "AbrirAdjunto"
	_adjunto.visible = false
	_adjunto.pressed.connect(_abrir_adjunto)
	derecha.add_child(_adjunto)

	_respuestas_panel = VBoxContainer.new()
	_respuestas_panel.name = "Respuestas"
	_respuestas_panel.add_theme_constant_override("separation", 6)
	_respuestas_panel.visible = false
	derecha.add_child(_respuestas_panel)


func _caja(
	fondo: Color,
	borde: Color,
	ancho: int,
	radio: int,
	margen_horizontal: float,
	margen_vertical: float
) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.border_width_left = ancho
	caja.border_width_top = ancho
	caja.border_width_right = ancho
	caja.border_width_bottom = ancho
	caja.corner_radius_top_left = radio
	caja.corner_radius_top_right = radio
	caja.corner_radius_bottom_left = radio
	caja.corner_radius_bottom_right = radio
	caja.content_margin_left = margen_horizontal
	caja.content_margin_top = margen_vertical
	caja.content_margin_right = margen_horizontal
	caja.content_margin_bottom = margen_vertical
	return caja


func _estilizar_respuesta(boton: Button) -> void:
	boton.add_theme_color_override("font_color", Color("#20313d"))
	boton.add_theme_color_override("font_focus_color", Color("#102430"))
	boton.add_theme_stylebox_override(
		"normal", _caja(Color("#e6eef4"), Color("#71899a"), 1, 2, 8.0, 5.0)
	)
	boton.add_theme_stylebox_override(
		"hover", _caja(Color("#f1f6f9"), Color("#4b748f"), 1, 2, 8.0, 5.0)
	)
	boton.add_theme_stylebox_override(
		"focus", _caja(Color("#f1f6f9"), Color("#2d658c"), 2, 2, 7.0, 4.0)
	)


func _refrescar() -> void:
	if _lista == null:
		return
	_modelo.configurar_contexto(_contexto_actual())
	_modelo.configurar_respuestas_enviadas(_respuestas_enviadas)
	var mensajes := _modelo.mensajes_disponibles()
	var seleccionado := _mensaje_seleccionado()
	_lista.clear()
	for mensaje in mensajes:
		var id := String(mensaje.get("id", ""))
		var indice := _lista.add_item(_rotulo(mensaje, not _leidos.has(id)))
		_lista.set_item_metadata(indice, mensaje)
		_lista.set_item_tooltip_enabled(indice, true)
		_lista.set_item_tooltip(indice, _tooltip(mensaje))
		if id == seleccionado:
			_lista.select(indice)
	_actualizar_estado(mensajes.size())
	_firma_contexto = (
		"%d|%d|%s"
		% [
			int(_jornada.get("dia", 1)),
			int(_jornada.get("acciones", Jornada.ACCIONES_POR_DIA)),
			String(_jornada.get("fase", "archivo")),
		]
	)
	var seleccion := _lista.get_selected_items()
	if not seleccion.is_empty():
		_seleccionar_mensaje(seleccion[0])


func _seleccionar_mensaje(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var valor: Variant = _lista.get_item_metadata(indice)
	if not valor is Dictionary:
		return
	var mensaje := valor as Dictionary
	var id := String(mensaje.get("id", ""))
	_cabecera.text = String(mensaje.get("asunto", ""))
	_meta.text = (
		texto("metadatos")
		% [
			String(mensaje.get("remitente", "")),
			String(mensaje.get("direccion", "")),
			int(mensaje.get("dia_entrega", 1)),
			String(mensaje.get("hora", "--:--")),
		]
	)
	_cuerpo.text = String(mensaje.get("cuerpo", ""))
	_configurar_adjunto(mensaje)
	_mostrar_respuestas(mensaje)
	if not _leidos.has(id):
		_leidos.append(id)
		_lista.set_item_text(indice, _rotulo(mensaje, false))
		mensaje_leido.emit(id)
		_actualizar_estado(_lista.item_count)


func _configurar_adjunto(mensaje: Dictionary) -> void:
	_adjunto_paquete_id = String(mensaje.get("paquete_software", "")).strip_edges()
	var nombre := String(mensaje.get("adjunto", "")).strip_edges()
	_adjunto.visible = not nombre.is_empty() and not _adjunto_paquete_id.is_empty()
	if _adjunto.visible:
		_adjunto.text = texto("abrir_adjunto") % nombre


func _abrir_adjunto() -> void:
	if _adjunto_paquete_id.is_empty():
		return
	paquete_software_obtenido.emit(_adjunto_paquete_id)


func _mostrar_respuestas(mensaje: Dictionary) -> void:
	for hijo in _respuestas_panel.get_children():
		_respuestas_panel.remove_child(hijo)
		hijo.queue_free()
	var mensaje_id := String(mensaje.get("id", ""))
	var opciones := _modelo.opciones_respuesta(mensaje_id)
	_respuestas_panel.visible = not opciones.is_empty()
	if opciones.is_empty():
		return

	var titulo := Label.new()
	titulo.text = texto("responder")
	titulo.add_theme_color_override("font_color", Color("#173f61"))
	_respuestas_panel.add_child(titulo)

	var envio: Variant = _respuestas_enviadas.get(mensaje_id, {})
	if envio is Dictionary and not (envio as Dictionary).is_empty():
		var opcion_id := String((envio as Dictionary).get("opcion_id", ""))
		var texto_enviado := opcion_id
		for opcion in opciones:
			if String(opcion.get("id", "")) == opcion_id:
				texto_enviado = String(opcion.get("texto", opcion_id))
				break
		var enviado := Label.new()
		enviado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		enviado.text = texto("respuesta_enviada") % texto_enviado
		_respuestas_panel.add_child(enviado)
		var espera := Label.new()
		espera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		espera.text = texto("respuesta_espera")
		_respuestas_panel.add_child(espera)
		return

	for opcion in opciones:
		var opcion_id := String(opcion.get("id", ""))
		if opcion_id.is_empty():
			continue
		var boton := Button.new()
		boton.text = String(opcion.get("texto", opcion_id))
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_estilizar_respuesta(boton)
		boton.pressed.connect(_enviar_respuesta.bind(mensaje_id, opcion_id))
		_respuestas_panel.add_child(boton)


func _enviar_respuesta(mensaje_id: String, opcion_id: String) -> void:
	if mensaje_id.is_empty() or opcion_id.is_empty() or _respuestas_enviadas.has(mensaje_id):
		return
	var opcion_valida := false
	for opcion in _modelo.opciones_respuesta(mensaje_id):
		if String(opcion.get("id", "")) == opcion_id:
			opcion_valida = true
			break
	if not opcion_valida:
		return
	var dia := int(_jornada.get("dia", 1))
	var acciones := int(_jornada.get("acciones", Jornada.ACCIONES_POR_DIA))
	_respuestas_enviadas[mensaje_id] = {
		"opcion_id": opcion_id,
		"dia": dia,
		"acciones": acciones,
	}
	_modelo.configurar_respuestas_enviadas(_respuestas_enviadas)
	respuesta_enviada.emit(mensaje_id, opcion_id, dia, acciones)
	var seleccion := _lista.get_selected_items()
	if not seleccion.is_empty():
		_seleccionar_mensaje(seleccion[0])


func _contexto_actual() -> Dictionary:
	return {
		"dia": int(_jornada.get("dia", 1)),
		"acciones": int(_jornada.get("acciones", Jornada.ACCIONES_POR_DIA)),
		"fase": String(_jornada.get("fase", "archivo")),
		"companeros": _companeros.duplicate(),
	}


func _mensaje_seleccionado() -> String:
	if _lista == null:
		return ""
	var seleccion := _lista.get_selected_items()
	if seleccion.is_empty():
		return ""
	var valor: Variant = _lista.get_item_metadata(seleccion[0])
	if valor is Dictionary:
		return String((valor as Dictionary).get("id", ""))
	return ""


func _rotulo(mensaje: Dictionary, nuevo: bool) -> String:
	var marca := texto("marca_nuevo") if nuevo else ""
	return (
		"%s%s · %s\n%s"
		% [
			marca,
			String(mensaje.get("hora", "--:--")),
			String(mensaje.get("remitente", "")),
			String(mensaje.get("asunto", "")),
		]
	)


func _tooltip(mensaje: Dictionary) -> String:
	return (
		"%s <%s>"
		% [
			String(mensaje.get("remitente", "")),
			String(mensaje.get("direccion", "")),
		]
	)


func _actualizar_estado(total: int) -> void:
	var nuevos := _modelo.contar_no_leidos(_leidos)
	_estado.text = texto("estado") % [total, nuevos]
