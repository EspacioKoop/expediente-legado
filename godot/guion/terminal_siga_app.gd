## Pantalla diegética del terminal SIGA-98 (#956).
##
## La lógica de comandos vive en TerminalSiga. Esta clase solo presenta el
## historial, recoge la línea de entrada y ofrece el salto al visor SIGA real.
class_name TerminalSigaApp
extends Control

signal cerrar_solicitado
signal abrir_siga_solicitado

const VERDE_TERMINAL := Color("9dcc9a")
const FONDO_TERMINAL := Color("101812")
const BORDE_TERMINAL := Color("49684d")

var _terminal := TerminalSiga.new()
var _registro: RichTextLabel
var _linea: LineEdit
var _abrir_siga: Button
var _cerrar: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = EstiloSiga.tema()
	_montar()
	_escribir(tr("TERMINAL_SIGA_INICIO"))
	_escribir(tr("TERMINAL_SIGA_AYUDA"))
	_linea.grab_focus.call_deferred()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("cancelar") or evento.is_action_pressed("ui_cancel"):
		cerrar_solicitado.emit()
		get_viewport().set_input_as_handled()


func ejecutar(texto: String) -> Dictionary:
	var limpio := texto.strip_edges()
	if limpio.is_empty():
		return {"ok": true, "salida": "", "cwd": _terminal.cwd()}
	_escribir("%s> %s" % [_terminal.cwd(), limpio])
	var resultado := _terminal.ejecutar(limpio)
	var salida := String(resultado.get("salida", ""))
	if not salida.is_empty():
		_escribir(salida)
	_linea.clear()
	return resultado


func _montar() -> void:
	var velo := ColorRect.new()
	velo.color = Color(0.0, 0.0, 0.0, 0.55)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	var panel := PanelContainer.new()
	panel.name = "MarcoTerminalSIGA"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -390.0
	panel.offset_top = -250.0
	panel.offset_right = 390.0
	panel.offset_bottom = 250.0
	add_child(panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	panel.add_child(caja)

	var barra := Label.new()
	barra.text = tr("TERMINAL_SIGA_TITULO")
	barra.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	barra.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	var fondo_barra := StyleBoxFlat.new()
	fondo_barra.bg_color = EstiloSiga.AZUL_TITULO
	fondo_barra.content_margin_left = 8.0
	fondo_barra.content_margin_top = 4.0
	fondo_barra.content_margin_right = 8.0
	fondo_barra.content_margin_bottom = 4.0
	barra.add_theme_stylebox_override("normal", fondo_barra)
	caja.add_child(barra)

	_registro = RichTextLabel.new()
	_registro.name = "RegistroTerminal"
	_registro.fit_content = false
	_registro.scroll_following = true
	_registro.selection_enabled = true
	_registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_registro.custom_minimum_size = Vector2(0.0, 340.0)
	_registro.accessibility_name = tr("TERMINAL_SIGA_HISTORIAL_ACCESIBLE")
	_registro.add_theme_font_override("normal_font", EstiloSiga.fuente_terminal())
	_registro.add_theme_color_override("default_color", VERDE_TERMINAL)
	var caja_registro := StyleBoxFlat.new()
	caja_registro.bg_color = FONDO_TERMINAL
	caja_registro.border_color = BORDE_TERMINAL
	caja_registro.set_border_width_all(2)
	caja_registro.set_content_margin_all(8.0)
	_registro.add_theme_stylebox_override("normal", caja_registro)
	caja.add_child(_registro)

	_linea = LineEdit.new()
	_linea.name = "LineaTerminal"
	_linea.placeholder_text = tr("TERMINAL_SIGA_PLACEHOLDER")
	_linea.accessibility_name = tr("TERMINAL_SIGA_COMANDO_ACCESIBLE")
	_linea.add_theme_font_override("font", EstiloSiga.fuente_terminal())
	_linea.text_submitted.connect(ejecutar)
	caja.add_child(_linea)

	var acciones := HBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_END
	caja.add_child(acciones)

	_abrir_siga = Button.new()
	_abrir_siga.name = "AbrirSIGA"
	_abrir_siga.text = tr("TERMINAL_SIGA_ABRIR")
	_abrir_siga.accessibility_name = _abrir_siga.text
	_abrir_siga.pressed.connect(func(): abrir_siga_solicitado.emit())
	acciones.add_child(_abrir_siga)

	_cerrar = Button.new()
	_cerrar.name = "CerrarTerminal"
	_cerrar.text = tr("TERMINAL_SIGA_CERRAR")
	_cerrar.accessibility_name = _cerrar.text
	_cerrar.pressed.connect(func(): cerrar_solicitado.emit())
	acciones.add_child(_cerrar)

	_linea.focus_neighbor_bottom = _linea.get_path_to(_abrir_siga)
	_abrir_siga.focus_neighbor_top = _abrir_siga.get_path_to(_linea)
	_abrir_siga.focus_neighbor_right = _abrir_siga.get_path_to(_cerrar)
	_cerrar.focus_neighbor_left = _cerrar.get_path_to(_abrir_siga)
	_cerrar.focus_neighbor_top = _cerrar.get_path_to(_linea)


func _escribir(texto: String) -> void:
	_registro.append_text(texto + "\n")
