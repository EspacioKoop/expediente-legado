## Bloc de notas ligero del escritorio OS98 (#538, #791).
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
	add_theme_constant_override("separation", 8)
	_construir_interfaz()
	_editor.text = _texto_inicial
	_actualizar_estado()
	_editor.grab_focus()


func _construir_interfaz() -> void:
	var barra_documento := PanelContainer.new()
	barra_documento.name = "BarraDocumento"
	barra_documento.add_theme_stylebox_override(
		"panel", _caja(Color("#d7c792"), Color("#74623d"), 1, 2, 8.0, 6.0)
	)
	add_child(barra_documento)

	var cabecera_contenido := VBoxContainer.new()
	cabecera_contenido.add_theme_constant_override("separation", 2)
	barra_documento.add_child(cabecera_contenido)

	var cabecera := Label.new()
	cabecera.name = "Cabecera"
	cabecera.text = tr("BLOC_NOTAS_TITULO")
	cabecera.add_theme_font_size_override("font_size", 19)
	cabecera.add_theme_color_override("font_color", Color("#2f2a1e"))
	cabecera_contenido.add_child(cabecera)

	var ayuda := Label.new()
	ayuda.name = "Ayuda"
	ayuda.text = tr("BLOC_NOTAS_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.add_theme_color_override("font_color", Color("#5c5137"))
	cabecera_contenido.add_child(ayuda)

	_editor = TextEdit.new()
	_editor.name = "Editor"
	_editor.placeholder_text = tr("BLOC_NOTAS_PLACEHOLDER")
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.add_theme_color_override("font_color", Color("#252823"))
	_editor.add_theme_color_override("font_placeholder_color", Color("#8c8c82"))
	_editor.add_theme_color_override("caret_color", Color("#315f86"))
	_editor.add_theme_color_override("selection_color", Color("#b8d4ea"))
	_editor.add_theme_stylebox_override(
		"normal", _caja(Color("#fffaf0"), Color("#9d967f"), 1, 2, 12.0, 10.0)
	)
	_editor.add_theme_stylebox_override(
		"focus", _caja(Color("#fffdf6"), Color("#315f86"), 2, 2, 11.0, 9.0)
	)
	_editor.text_changed.connect(_al_cambiar_texto)
	add_child(_editor)

	var pie := PanelContainer.new()
	pie.name = "PieDocumento"
	pie.add_theme_stylebox_override(
		"panel", _caja(Color("#e8e2cf"), Color("#9d967f"), 1, 2, 7.0, 3.0)
	)
	add_child(pie)

	_estado = Label.new()
	_estado.name = "Estado"
	_estado.add_theme_font_size_override("font_size", 12)
	_estado.add_theme_color_override("font_color", Color("#565448"))
	pie.add_child(_estado)


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


func _al_cambiar_texto() -> void:
	_texto_inicial = _editor.text
	_actualizar_estado()
	contenido_cambiado.emit(_editor.text)


func _actualizar_estado() -> void:
	if _estado != null:
		_estado.text = "%d %s" % [exportar_texto().length(), tr("BLOC_NOTAS_ESTADO")]
