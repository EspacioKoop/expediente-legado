## Selector mínimo para los marcadores diegéticos de #957.
##
## Vive fuera de MenuGlobal: el controlador lo monta solo cuando el jugador
## entra en la herramienta desde el menú. Reutiliza acciones UI ya sincronizadas
## con Interactuar/Cancelar, por lo que teclado y mando mantienen el remapeo.
extends PanelContainer

const RUTA_TEXTOS := "res://datos/marcadores_mundo_textos.json"

signal colocar_solicitado(tipo: String, color: String, texto: String)
signal eliminar_solicitado
signal eliminar_zona_solicitado
signal cancelar_solicitado

var _tipo: OptionButton
var _color: OptionButton
var _texto: LineEdit
var _estado: Label
var _colocar: Button
var _eliminar: Button
var _limpiar_zona: Button
var _volver: Button
var _confirmar_limpieza: ConfirmationDialog
var _textos: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_textos = _cargar_textos()
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(520, 330)
	_montar()


func _cargar_textos() -> Dictionary:
	if not FileAccess.file_exists(RUTA_TEXTOS):
		return {}
	var archivo := FileAccess.open(RUTA_TEXTOS, FileAccess.READ)
	if archivo == null:
		return {}
	var datos = JSON.parse_string(archivo.get_as_text())
	if typeof(datos) != TYPE_DICTIONARY:
		return {}
	return datos


func _cadena(clave: String) -> String:
	return String(_textos.get(clave, clave))


func abrir(puede_colocar: bool, puede_eliminar: bool, cantidad: int) -> void:
	visible = true
	_colocar.disabled = not puede_colocar or cantidad >= MarcadoresMundo.LIMITE_POR_ZONA
	_eliminar.visible = puede_eliminar
	_limpiar_zona.visible = cantidad > 0
	if not puede_colocar:
		_estado.text = _cadena("superficie_requerida")
	elif cantidad >= MarcadoresMundo.LIMITE_POR_ZONA:
		_estado.text = (_cadena("limite_zona") % MarcadoresMundo.LIMITE_POR_ZONA)
	else:
		_estado.text = _cadena("contador_zona") % [cantidad, MarcadoresMundo.LIMITE_POR_ZONA]
	_tipo.grab_focus.call_deferred()


func mostrar_error(texto: String) -> void:
	_estado.text = texto


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or not evento.is_action_pressed("cancelar"):
		return
	get_viewport().set_input_as_handled()
	cancelar_solicitado.emit()


func _montar() -> void:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 20)
	add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	margen.add_child(caja)

	var titulo := Label.new()
	titulo.text = _cadena("titulo")
	caja.add_child(titulo)

	var ayuda := Label.new()
	ayuda.text = _cadena("ayuda")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(ayuda)

	var formulario := GridContainer.new()
	formulario.columns = 2
	formulario.add_theme_constant_override("h_separation", 14)
	formulario.add_theme_constant_override("v_separation", 8)
	caja.add_child(formulario)

	_anadir_etiqueta(formulario, _cadena("tipo"))
	_tipo = OptionButton.new()
	_anadir_opcion(_tipo, _cadena("tipo_tiza"), MarcadoresMundo.TIPO_TIZA)
	_anadir_opcion(_tipo, _cadena("tipo_cinta"), MarcadoresMundo.TIPO_CINTA)
	_anadir_opcion(_tipo, _cadena("tipo_nota"), MarcadoresMundo.TIPO_NOTA)
	_anadir_opcion(_tipo, _cadena("tipo_carbon"), MarcadoresMundo.TIPO_CARBON)
	_anadir_opcion(_tipo, _cadena("tipo_objeto"), MarcadoresMundo.TIPO_OBJETO)
	_tipo.item_selected.connect(_al_tipo_cambiado)
	formulario.add_child(_tipo)

	_anadir_etiqueta(formulario, _cadena("color"))
	_color = OptionButton.new()
	_anadir_opcion(_color, _cadena("color_blanco"), MarcadoresMundo.COLOR_BLANCO)
	_anadir_opcion(_color, _cadena("color_amarillo"), MarcadoresMundo.COLOR_AMARILLO)
	_anadir_opcion(_color, _cadena("color_rojo"), MarcadoresMundo.COLOR_ROJO)
	_anadir_opcion(_color, _cadena("color_azul"), MarcadoresMundo.COLOR_AZUL)
	_anadir_opcion(_color, _cadena("color_verde"), MarcadoresMundo.COLOR_VERDE)
	formulario.add_child(_color)

	_anadir_etiqueta(formulario, _cadena("texto"))
	_texto = LineEdit.new()
	_texto.max_length = MarcadoresMundo.MAX_TEXTO
	_texto.placeholder_text = (_cadena("texto_placeholder") % MarcadoresMundo.MAX_TEXTO)
	formulario.add_child(_texto)

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_estado)

	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_END
	botones.add_theme_constant_override("separation", 8)
	caja.add_child(botones)

	_eliminar = Button.new()
	_eliminar.text = _cadena("eliminar_apuntada")
	_eliminar.pressed.connect(func(): eliminar_solicitado.emit())
	botones.add_child(_eliminar)

	_limpiar_zona = Button.new()
	_limpiar_zona.text = _cadena("limpiar_zona")
	_limpiar_zona.pressed.connect(_pedir_limpiar_zona)
	botones.add_child(_limpiar_zona)

	_volver = Button.new()
	_volver.text = _cadena("volver")
	_volver.pressed.connect(func(): cancelar_solicitado.emit())
	botones.add_child(_volver)

	_colocar = Button.new()
	_colocar.text = _cadena("colocar")
	_colocar.pressed.connect(_emitir_colocacion)
	botones.add_child(_colocar)

	_confirmar_limpieza = ConfirmationDialog.new()
	_confirmar_limpieza.title = _cadena("limpiar_titulo")
	_confirmar_limpieza.dialog_text = _cadena("limpiar_pregunta")
	_confirmar_limpieza.ok_button_text = _cadena("limpiar_confirmar")
	_confirmar_limpieza.confirmed.connect(func(): eliminar_zona_solicitado.emit())
	add_child(_confirmar_limpieza)

	_al_tipo_cambiado(0)


func _anadir_etiqueta(contenedor: GridContainer, texto: String) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	contenedor.add_child(etiqueta)


func _anadir_opcion(selector: OptionButton, texto: String, valor: String) -> void:
	selector.add_item(texto)
	selector.set_item_metadata(selector.item_count - 1, valor)


func _al_tipo_cambiado(_indice: int) -> void:
	if _texto == null:
		return
	var tipo := String(_tipo.get_item_metadata(_tipo.selected))
	_texto.editable = tipo in [MarcadoresMundo.TIPO_CINTA, MarcadoresMundo.TIPO_NOTA]
	if not _texto.editable:
		_texto.text = ""


func _pedir_limpiar_zona() -> void:
	_confirmar_limpieza.popup_centered()


func _emitir_colocacion() -> void:
	var tipo := String(_tipo.get_item_metadata(_tipo.selected))
	var color := String(_color.get_item_metadata(_color.selected))
	colocar_solicitado.emit(tipo, color, _texto.text)
