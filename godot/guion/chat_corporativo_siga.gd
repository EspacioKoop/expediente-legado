## Cliente del chat corporativo simulado del escritorio OS98 (#666).
##
## La capa de dominio sigue en ChatCorporativoModelo. Esta vista solo presenta
## canales, presencia, historial, enlaces internos y respuestas cerradas; no
## expone entrada libre ni crea una segunda fuente de verdad de campaña.
class_name ChatCorporativoSiga
extends HSplitContainer

signal respuesta_elegida(mensaje_id: String, opcion_id: String)
signal enlace_abierto(recurso_id: String)

const RUTA_TEXTOS := "res://datos/chat_corporativo_textos.json"

var _modelo := ChatCorporativoModelo.new()
var _contexto: Dictionary = {}
var _respuestas: Dictionary = {}
var _canal_actual := ""
var _mensaje_actual := ""
var _firma_contexto := ""
var _enlace_actual := ""

var _canales: ItemList
var _presencias: ItemList
var _titulo_canal: Label
var _descripcion_canal: Label
var _hora: Label
var _mensajes: ItemList
var _detalle: RichTextLabel
var _abrir_enlace: Button
var _respuestas_panel: VBoxContainer


static func texto(clave: String) -> String:
	if not FileAccess.file_exists(RUTA_TEXTOS):
		return clave
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	if datos is Dictionary:
		return String((datos as Dictionary).get(clave, clave))
	return clave


func configurar_contexto(contexto: Dictionary) -> void:
	var copia := contexto.duplicate(true)
	if copia == _contexto:
		return
	_contexto = copia
	_firma_contexto = ""
	if is_node_ready():
		_refrescar()


func configurar_respuestas(valores: Dictionary) -> void:
	_respuestas = valores.duplicate(true)
	if is_node_ready():
		_refrescar_detalle()


func respuestas_guardadas() -> Dictionary:
	return _respuestas.duplicate(true)


func _ready() -> void:
	custom_minimum_size = Vector2(660, 420)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_offset = 230
	add_theme_constant_override("separation", 5)
	_construir_interfaz()
	_refrescar()


func _process(_delta: float) -> void:
	if _contexto.is_empty():
		return
	var firma := _firma_actual()
	if firma != _firma_contexto:
		_refrescar()


func _construir_interfaz() -> void:
	var navegacion := VBoxContainer.new()
	navegacion.name = "Navegacion"
	navegacion.custom_minimum_size = Vector2(210, 0)
	navegacion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	navegacion.add_theme_constant_override("separation", 5)
	add_child(navegacion)

	var titulo_canales := Label.new()
	titulo_canales.text = texto("canales")
	titulo_canales.add_theme_font_size_override("font_size", 17)
	navegacion.add_child(titulo_canales)

	_canales = ItemList.new()
	_canales.name = "Canales"
	_canales.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canales.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canales.select_mode = ItemList.SELECT_SINGLE
	_canales.item_selected.connect(_seleccionar_canal)
	navegacion.add_child(_canales)

	var titulo_presencia := Label.new()
	titulo_presencia.text = texto("presencia")
	titulo_presencia.add_theme_font_size_override("font_size", 15)
	navegacion.add_child(titulo_presencia)

	_presencias = ItemList.new()
	_presencias.name = "Presencias"
	_presencias.custom_minimum_size = Vector2(0, 125)
	_presencias.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_presencias.select_mode = ItemList.SELECT_SINGLE
	navegacion.add_child(_presencias)

	var conversacion := VBoxContainer.new()
	conversacion.name = "Conversacion"
	conversacion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conversacion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conversacion.add_theme_constant_override("separation", 5)
	add_child(conversacion)

	_titulo_canal = Label.new()
	_titulo_canal.name = "TituloCanal"
	_titulo_canal.add_theme_font_size_override("font_size", 19)
	conversacion.add_child(_titulo_canal)

	_descripcion_canal = Label.new()
	_descripcion_canal.name = "DescripcionCanal"
	_descripcion_canal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conversacion.add_child(_descripcion_canal)

	_hora = Label.new()
	_hora.name = "HoraNarrativa"
	conversacion.add_child(_hora)

	_mensajes = ItemList.new()
	_mensajes.name = "Mensajes"
	_mensajes.custom_minimum_size = Vector2(0, 150)
	_mensajes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mensajes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mensajes.select_mode = ItemList.SELECT_SINGLE
	_mensajes.item_selected.connect(_seleccionar_mensaje)
	conversacion.add_child(_mensajes)

	_detalle = RichTextLabel.new()
	_detalle.name = "DetalleMensaje"
	_detalle.custom_minimum_size = Vector2(0, 90)
	_detalle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detalle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detalle.selection_enabled = true
	_detalle.fit_content = false
	_detalle.text = texto("seleccionar")
	conversacion.add_child(_detalle)

	_abrir_enlace = Button.new()
	_abrir_enlace.name = "AbrirWeb98"
	_abrir_enlace.text = texto("abrir_web98")
	_abrir_enlace.visible = false
	_abrir_enlace.pressed.connect(_abrir_enlace_actual)
	conversacion.add_child(_abrir_enlace)

	_respuestas_panel = VBoxContainer.new()
	_respuestas_panel.name = "Respuestas"
	_respuestas_panel.add_theme_constant_override("separation", 5)
	conversacion.add_child(_respuestas_panel)


func _refrescar() -> void:
	if _canales == null:
		return
	_modelo.configurar_contexto(_contexto)
	var visibles := _modelo.canales_visibles()
	var ids: Array[String] = []
	for canal in visibles:
		ids.append(String(canal.get("id", "")))
	if not ids.has(_canal_actual):
		_canal_actual = ids[0] if not ids.is_empty() else ""
		_mensaje_actual = ""

	_canales.clear()
	var indice_canal := -1
	for canal in visibles:
		var indice := _canales.add_item(String(canal.get("nombre", "")))
		_canales.set_item_metadata(indice, canal)
		if String(canal.get("id", "")) == _canal_actual:
			indice_canal = indice

	_firma_contexto = _firma_actual()
	if indice_canal >= 0:
		_canales.select(indice_canal)
		_mostrar_canal(visibles[indice_canal])
	else:
		_vaciar_canal()


func _seleccionar_canal(indice: int) -> void:
	if indice < 0 or indice >= _canales.item_count:
		return
	var valor: Variant = _canales.get_item_metadata(indice)
	if not valor is Dictionary:
		return
	var canal := valor as Dictionary
	_canal_actual = String(canal.get("id", ""))
	_mensaje_actual = ""
	_mostrar_canal(canal)


func _mostrar_canal(canal: Dictionary) -> void:
	_titulo_canal.text = String(canal.get("nombre", ""))
	_descripcion_canal.text = String(canal.get("descripcion", ""))
	_hora.text = texto("hora") % _modelo.hora_narrativa()
	_refrescar_presencias()
	_refrescar_mensajes()


func _refrescar_presencias() -> void:
	_presencias.clear()
	for usuario in _modelo.presencias(_canal_actual):
		var estado := String(usuario.get("estado", "desconectado"))
		var nick := String(usuario.get("nick", ""))
		var indice := _presencias.add_item("%s · %s" % [nick, _texto_estado(estado)])
		_presencias.set_item_metadata(indice, usuario)
		_presencias.set_item_tooltip_enabled(indice, true)
		_presencias.set_item_tooltip(indice, String(usuario.get("estilo", "")))


func _refrescar_mensajes() -> void:
	var disponibles := _modelo.mensajes_de_canal(_canal_actual)
	var ids: Array[String] = []
	for mensaje in disponibles:
		ids.append(String(mensaje.get("id", "")))
	if not ids.has(_mensaje_actual):
		_mensaje_actual = ids.back() if not ids.is_empty() else ""

	_mensajes.clear()
	var indice_mensaje := -1
	for mensaje in disponibles:
		var indice := _mensajes.add_item(_rotulo_mensaje(mensaje))
		_mensajes.set_item_metadata(indice, mensaje)
		if String(mensaje.get("id", "")) == _mensaje_actual:
			indice_mensaje = indice

	if indice_mensaje >= 0:
		_mensajes.select(indice_mensaje)
		_mostrar_mensaje(disponibles[indice_mensaje])
	else:
		_detalle.text = texto("sin_mensajes")
		_enlace_actual = ""
		_abrir_enlace.visible = false
		_limpiar_respuestas()


func _seleccionar_mensaje(indice: int) -> void:
	if indice < 0 or indice >= _mensajes.item_count:
		return
	var valor: Variant = _mensajes.get_item_metadata(indice)
	if not valor is Dictionary:
		return
	var mensaje := valor as Dictionary
	_mensaje_actual = String(mensaje.get("id", ""))
	_mostrar_mensaje(mensaje)


func _mostrar_mensaje(mensaje: Dictionary) -> void:
	var autor := _modelo.perfil_usuario(String(mensaje.get("autor", "")))
	var nick := String(autor.get("nick", mensaje.get("autor", "")))
	_detalle.text = "%s · %s\n%s" % [String(mensaje.get("hora", "--:--")), nick, String(mensaje.get("texto", ""))]
	var enlace := _modelo.enlace_de_mensaje(_mensaje_actual)
	_enlace_actual = String(enlace.get("recurso_id", ""))
	_abrir_enlace.visible = not _enlace_actual.is_empty()
	_refrescar_respuestas()


func _refrescar_detalle() -> void:
	if _mensaje_actual.is_empty():
		return
	for mensaje in _modelo.mensajes_de_canal(_canal_actual):
		if String(mensaje.get("id", "")) == _mensaje_actual:
			_mostrar_mensaje(mensaje)
			return


func _refrescar_respuestas() -> void:
	_limpiar_respuestas()
	var opciones := _modelo.opciones_respuesta(_mensaje_actual)
	if opciones.is_empty():
		return

	var titulo := Label.new()
	titulo.text = texto("responder")
	_respuestas_panel.add_child(titulo)

	var guardada: Variant = _respuestas.get(_mensaje_actual, {})
	if guardada is Dictionary and not (guardada as Dictionary).is_empty():
		var opcion_id := String((guardada as Dictionary).get("opcion_id", ""))
		var resultado := _modelo.resolver_respuesta(_mensaje_actual, opcion_id)
		if resultado.is_empty():
			return
		var elegida := Label.new()
		elegida.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		elegida.text = texto("respuesta_elegida") % String(resultado.get("texto", ""))
		_respuestas_panel.add_child(elegida)
		var contestacion := Label.new()
		contestacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contestacion.text = texto("contestacion") % String(resultado.get("contestacion", ""))
		_respuestas_panel.add_child(contestacion)
		return

	for opcion in opciones:
		var opcion_id := String(opcion.get("id", ""))
		if opcion_id.is_empty():
			continue
		var boton := Button.new()
		boton.text = String(opcion.get("texto", opcion_id))
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.pressed.connect(_elegir_respuesta.bind(_mensaje_actual, opcion_id))
		_respuestas_panel.add_child(boton)


func _limpiar_respuestas() -> void:
	for hijo in _respuestas_panel.get_children():
		_respuestas_panel.remove_child(hijo)
		hijo.queue_free()


func _elegir_respuesta(mensaje_id: String, opcion_id: String) -> void:
	if mensaje_id.is_empty() or opcion_id.is_empty() or _respuestas.has(mensaje_id):
		return
	var resultado := _modelo.resolver_respuesta(mensaje_id, opcion_id)
	if resultado.is_empty():
		return
	_respuestas[mensaje_id] = {"opcion_id": opcion_id}
	respuesta_elegida.emit(mensaje_id, opcion_id)
	_refrescar_respuestas()


func _abrir_enlace_actual() -> void:
	if not _enlace_actual.is_empty():
		enlace_abierto.emit(_enlace_actual)


func _rotulo_mensaje(mensaje: Dictionary) -> String:
	var autor := _modelo.perfil_usuario(String(mensaje.get("autor", "")))
	var nick := String(autor.get("nick", mensaje.get("autor", "")))
	var tipo := String(mensaje.get("tipo", "mensaje"))
	var prefijo := ""
	if tipo == "sistema":
		prefijo = "[%s] " % texto("tipo_sistema")
	elif tipo == "presencia":
		prefijo = "[%s] " % texto("tipo_presencia")
	return "%s%s · %s" % [prefijo, String(mensaje.get("hora", "--:--")), nick]


func _texto_estado(estado: String) -> String:
	if estado == "conectado":
		return texto("estado_conectado")
	if estado == "ausente":
		return texto("estado_ausente")
	return texto("estado_desconectado")


func _vaciar_canal() -> void:
	_titulo_canal.text = texto("sin_canales")
	_descripcion_canal.text = ""
	_hora.text = ""
	_presencias.clear()
	_mensajes.clear()
	_detalle.text = texto("sin_canales")
	_enlace_actual = ""
	_abrir_enlace.visible = false
	_limpiar_respuestas()


func _firma_actual() -> String:
	return "%d|%d|%s|%s|%s|%s" % [
		int(_contexto.get("dia", 1)),
		int(_contexto.get("acciones", Jornada.ACCIONES_POR_DIA)),
		String(_contexto.get("fase", "archivo")),
		str(_contexto.get("companeros", [])),
		str(_contexto.get("conocimiento", [])),
		str(_contexto.get("eventos", [])),
	]
