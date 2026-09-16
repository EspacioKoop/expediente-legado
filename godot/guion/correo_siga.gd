## Cliente de correo corporativo del escritorio OS98 (#538).
##
## La UI no decide qué mensajes existen ni cuándo llegan: consulta
## CorreoSigaModelo con el estado vivo de Jornada y solo conserva qué mensajes
## ha leído el jugador. Esa lista se entrega al adaptador para persistirla como
## estado local de la aplicación, no dentro de la campaña.
class_name CorreoSiga
extends HSplitContainer

signal mensaje_leido(id: String)

const RUTA_TEXTOS := "res://datos/correo_siga_textos.json"

var _modelo := CorreoSigaModelo.new()
var _jornada: Dictionary = {}
var _companeros: Array[String] = []
var _leidos: Array[String] = []
var _firma_contexto := ""

var _lista: ItemList
var _cabecera: Label
var _meta: Label
var _cuerpo: RichTextLabel
var _estado: Label


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


func leidos() -> Array[String]:
	return _leidos.duplicate()


func _ready() -> void:
	custom_minimum_size = Vector2(620, 400)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_offset = 265
	_construir_interfaz()
	_refrescar()


func _process(_delta: float) -> void:
	if _jornada.is_empty():
		return
	var firma := "%d|%d|%s" % [
		int(_jornada.get("dia", 1)),
		int(_jornada.get("acciones", Jornada.ACCIONES_POR_DIA)),
		String(_jornada.get("fase", "archivo")),
	]
	if firma != _firma_contexto:
		_refrescar()


func _construir_interfaz() -> void:
	var izquierda := VBoxContainer.new()
	izquierda.name = "Bandeja"
	izquierda.custom_minimum_size = Vector2(245, 0)
	izquierda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(izquierda)

	var titulo := Label.new()
	titulo.name = "TituloBandeja"
	titulo.text = texto("bandeja")
	izquierda.add_child(titulo)

	_lista = ItemList.new()
	_lista.name = "Mensajes"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.select_mode = ItemList.SELECT_SINGLE
	_lista.item_selected.connect(_seleccionar_mensaje)
	izquierda.add_child(_lista)

	_estado = Label.new()
	_estado.name = "EstadoBandeja"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izquierda.add_child(_estado)

	var derecha := VBoxContainer.new()
	derecha.name = "Lectura"
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(derecha)

	_cabecera = Label.new()
	_cabecera.name = "Asunto"
	_cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cabecera.text = texto("seleccionar")
	derecha.add_child(_cabecera)

	_meta = Label.new()
	_meta.name = "Metadatos"
	_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meta.text = ""
	derecha.add_child(_meta)

	_cuerpo = RichTextLabel.new()
	_cuerpo.name = "Cuerpo"
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cuerpo.selection_enabled = true
	_cuerpo.fit_content = false
	_cuerpo.text = texto("espera")
	derecha.add_child(_cuerpo)


func _refrescar() -> void:
	if _lista == null:
		return
	_modelo.configurar_contexto(_contexto_actual())
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
	_firma_contexto = "%d|%d|%s" % [
		int(_jornada.get("dia", 1)),
		int(_jornada.get("acciones", Jornada.ACCIONES_POR_DIA)),
		String(_jornada.get("fase", "archivo")),
	]


func _seleccionar_mensaje(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var valor: Variant = _lista.get_item_metadata(indice)
	if not valor is Dictionary:
		return
	var mensaje := valor as Dictionary
	var id := String(mensaje.get("id", ""))
	_cabecera.text = String(mensaje.get("asunto", ""))
	_meta.text = texto("metadatos") % [
		String(mensaje.get("remitente", "")),
		String(mensaje.get("direccion", "")),
		int(mensaje.get("dia_entrega", 1)),
		String(mensaje.get("hora", "--:--")),
	]
	_cuerpo.text = String(mensaje.get("cuerpo", ""))
	if not _leidos.has(id):
		_leidos.append(id)
		_lista.set_item_text(indice, _rotulo(mensaje, false))
		mensaje_leido.emit(id)
		_actualizar_estado(_lista.item_count)


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
	return "%s%s · %s\n%s" % [
		marca,
		String(mensaje.get("hora", "--:--")),
		String(mensaje.get("remitente", "")),
		String(mensaje.get("asunto", "")),
	]


func _tooltip(mensaje: Dictionary) -> String:
	return "%s <%s>" % [
		String(mensaje.get("remitente", "")),
		String(mensaje.get("direccion", "")),
	]


func _actualizar_estado(total: int) -> void:
	var nuevos := _modelo.contar_no_leidos(_leidos)
	_estado.text = texto("estado") % [total, nuevos]
