## Consola diegética de trucos para release (#116).
##
## No es la consola QA. Solo existe para utilidades reversibles/no económicas y
## solo se abre después de completar el catálogo disponible de Bit 98.
extends CanvasLayer

const ESCENA_DIA := "res://escenas/dia.tscn"
const CLIMAS := ["auto", "despejado", "nublado", "lluvia", "niebla", "nieve"]
const COMANDOS := {
	"ayuda": "lista los comandos del manual de servicio",
	"clima": "clima auto|despejado|nublado|lluvia|niebla|nieve",
	"desatascar": "vuelve a la entrada del espacio actual",
	"portatil": "abre la Portátil Color 98",
	"diagnostico": "muestra semilla/día/vuelta/versión para reportar bugs",
	"limpiar": "borra el registro",
}

var _abierta := false
var _pausa_previa := false
var _raton_previo := Input.MOUSE_MODE_VISIBLE
var _panel: PanelContainer
var _registro: RichTextLabel
var _linea: LineEdit


func _ready() -> void:
	layer = 119
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	_panel.visible = false


func _input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if _es_tecla_consola(evento):
		if not TiendaVideojuegos.consola_trucos_desbloqueada():
			return
		if _dia(false) == null:
			return
		_alternar()
		get_viewport().set_input_as_handled()
		return
	if not _abierta:
		return
	if evento.keycode == KEY_ESCAPE:
		_alternar()
		get_viewport().set_input_as_handled()


func _es_tecla_consola(evento: InputEventKey) -> bool:
	return evento.physical_keycode == KEY_QUOTELEFT or evento.unicode == "º".unicode_at(0)


func _alternar() -> void:
	_abierta = not _abierta
	_panel.visible = _abierta
	if _abierta:
		_pausa_previa = get_tree().paused
		_raton_previo = Input.mouse_mode
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_linea.clear()
		_linea.grab_focus.call_deferred()
		if _registro.get_parsed_text().is_empty():
			_escribir("MANUAL DE SERVICIO BIT 98 · escribe ayuda")
	else:
		_linea.release_focus()
		get_tree().paused = _pausa_previa
		Input.mouse_mode = _raton_previo


func ejecutar(texto: String) -> void:
	var limpio := texto.strip_edges()
	if limpio.is_empty():
		return
	_escribir("[color=#9fd3ff]> %s[/color]" % limpio)
	var partes := limpio.split(" ", false)
	var comando := partes[0].to_lower()
	var args := partes.slice(1)
	match comando:
		"ayuda", "help", "?":
			for nombre in COMANDOS:
				_escribir("  [b]%s[/b]  %s" % [nombre, COMANDOS[nombre]])
		"limpiar", "clear":
			_registro.clear()
		"clima":
			_cmd_clima(args)
		"desatascar":
			_cmd_desatascar()
		"portatil", "portátil":
			_cmd_portatil()
		"diagnostico", "diagnóstico":
			_cmd_diagnostico()
		_:
			_error("Ese comando no figura en el manual de servicio.")


func _cmd_clima(args: Array) -> void:
	var dia := _dia()
	if dia == null:
		return
	if args.is_empty() or args[0] not in CLIMAS:
		_error("Uso: clima %s" % "|".join(CLIMAS))
		return
	if args[0] == "auto":
		dia.jornada.erase("clima_forzado")
	else:
		dia.jornada["clima_forzado"] = args[0]
	_cerrar_y(func(): dia._entrar_en(dia.jornada["fase"]))
	_ok("Clima: %s" % args[0])


func _cmd_desatascar() -> void:
	var dia := _dia()
	if dia == null:
		return
	var espacio: Dictionary = dia._espacio_actual
	dia._caminante.situar(espacio["entrada"], espacio.get("mirada", NAN))
	_ok("De vuelta en la entrada")


func _cmd_portatil() -> void:
	var dia := _dia()
	if dia == null:
		return
	if dia.jornada["fase"] != "casa":
		_error("La portátil solo puede abrirse cuando ya estás en casa.")
		return
	var consola := dia._mundo.find_child("ConsolaPortatil98", true, false) as Interactuable3D
	if consola == null:
		_error("No encuentro la portátil en esta escena.")
		return
	_cerrar_y(func(): consola.interactuar(dia._caminante))
	_ok("Abriendo la portátil")


func _cmd_diagnostico() -> void:
	var dia := _dia()
	if dia == null:
		return
	_ok(Azar.manifiesto_en_texto(dia.partida.estado))


func _dia(mostrar_error: bool = true) -> Node:
	var escena := get_tree().current_scene
	if escena == null or escena.scene_file_path != ESCENA_DIA:
		if mostrar_error:
			_error("Solo funciona dentro de una partida.")
		return null
	return escena


func _cerrar_y(accion: Callable) -> void:
	if _abierta:
		_alternar()
	accion.call_deferred()


func _ok(texto: String) -> void:
	_escribir("[color=#b6f0a0]%s[/color]" % texto)


func _error(texto: String) -> void:
	_escribir("[color=#ffb0a0]%s[/color]" % texto)


func _escribir(texto: String) -> void:
	_registro.append_text(texto + "\n")


func _montar() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.anchor_bottom = 0.42
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.05, 0.06, 0.08, 0.94)
	fondo.border_color = Color(0.35, 0.75, 1.0)
	fondo.border_width_bottom = 2
	fondo.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", fondo)
	add_child(_panel)

	var caja := VBoxContainer.new()
	_panel.add_child(caja)

	var titulo := Label.new()
	titulo.text = "BIT 98 · MANUAL DE SERVICIO"
	titulo.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0))
	caja.add_child(titulo)

	var fuente_terminal := EstiloSiga.fuente_terminal()
	_registro = RichTextLabel.new()
	_registro.bbcode_enabled = true
	_registro.scroll_following = true
	_registro.selection_enabled = true
	_registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_registro.add_theme_font_override("normal_font", fuente_terminal)
	_registro.add_theme_font_override("bold_font", fuente_terminal)
	caja.add_child(_registro)

	_linea = LineEdit.new()
	_linea.placeholder_text = "ayuda · clima lluvia · diagnostico"
	_linea.add_theme_font_override("font", fuente_terminal)
	_linea.text_submitted.connect(
		func(valor: String):
			_linea.clear()
			ejecutar(valor)
	)
	caja.add_child(_linea)
