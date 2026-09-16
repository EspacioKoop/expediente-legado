## Bloc de notas ligero del escritorio OS98 (#538).
##
## No toca el sistema de archivos real: el contenido vive en el estado local de
## EscritorioSigaApp y se persiste junto al resto de preferencias de aplicaciones.
class_name BlocNotasSiga
extends VBoxContainer

signal contenido_cambiado(texto: String)

var _texto_inicial := ""
var _editor: TextEdit
var _estado: Label


func configurar_texto(texto: String) -> void:
	_texto_inicial = texto
	if is_node_ready() and _editor != null:
		_editor.text = texto
		_actualizar_estado()


func exportar_texto() -> String:
	if _editor != null:
		return _editor.text
	return _texto_inicial


func _ready() -> void:
	custom_minimum_size = Vector2(440, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_construir_interfaz()
	_editor.text = _texto_inicial
	_actualizar_estado()
	_editor.grab_focus()


func _construir_interfaz() -> void:
	var cabecera := Label.new()
	cabecera.text = "Bloc de notas"
	add_child(cabecera)

	var ayuda := Label.new()
	ayuda.text = "Anotaciones locales de trabajo. Se guardan con el estado de esta partida."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ayuda)

	_editor = TextEdit.new()
	_editor.name = "Editor"
	_editor.placeholder_text = "Escriba aquí sus notas..."
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.text_changed.connect(_al_cambiar_texto)
	add_child(_editor)

	_estado = Label.new()
	_estado.name = "Estado"
	add_child(_estado)


func _al_cambiar_texto() -> void:
	_texto_inicial = _editor.text
	_actualizar_estado()
	contenido_cambiado.emit(_editor.text)


func _actualizar_estado() -> void:
	if _estado != null:
		_estado.text = (
			"%d caracteres · guardado local al persistir la partida" % exportar_texto().length()
		)
