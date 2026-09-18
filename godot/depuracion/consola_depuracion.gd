## Consola de pruebas (#770). Se abre y se cierra con º, la tecla a la izquierda
## del 1.
##
## Es herramienta de playtest, no juego: vive fuera de `guion/` y no tiene textos
## en `textos.csv`. Cada botón escribe el mismo comando que se podría teclear, así
## que el registro enseña los comandos sin tener que leer la ayuda.
##
## Solo toca la partida en curso (`dia.tscn`). Fuera de ella lo dice y no hace
## nada, en vez de fallar.
extends CanvasLayer

const ESCENA_DIA := "res://escenas/dia.tscn"
const FASES := ["archivo", "trayecto", "casa", "sueño"]
const CLIMAS := ["auto", "despejado", "nublado", "lluvia", "niebla", "nieve"]
const COMANDOS := {
	"ayuda": "lista los comandos",
	"fase": "fase archivo|trayecto|casa|sueño — cambia de espacio",
	"sala": "sala <nombre> — entra en esa sala del sueño",
	"dia": "dia <n> — pone el número de día",
	"dinero": "dinero <n> | dinero +<n> — fija o suma dinero",
	"pistas": "pistas — descubre todas las pistas de todos los expedientes",
	"gato": "gato comer | gato hambre <n>",
	"clima": "clima auto|despejado|nublado|lluvia|niebla|nieve",
	"desatascar": "desatascar — vuelve a la entrada del espacio actual",
	"portatil": "portatil — abre la Portátil Color 98",
	"limpiar": "limpiar — borra el registro",
}

var _abierta := false
var _pausa_previa := false
var _raton_previo := Input.MOUSE_MODE_VISIBLE
var _historial: Array[String] = []
var _indice_historial := -1

var _panel: PanelContainer
var _registro: RichTextLabel
var _linea: LineEdit
var _salas: HFlowContainer


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	_panel.visible = false


func _input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if _es_tecla_consola(evento):
		_alternar()
		get_viewport().set_input_as_handled()
		return
	if not _abierta:
		return
	match evento.keycode:
		KEY_ESCAPE:
			_alternar()
			get_viewport().set_input_as_handled()
		KEY_TAB:
			_autocompletar()
			get_viewport().set_input_as_handled()
		KEY_UP:
			_recorrer_historial(1)
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			_recorrer_historial(-1)
			get_viewport().set_input_as_handled()


## º en teclado español; la misma posición física es ` en el inglés. Se aceptan
## las dos para que funcione con cualquier distribución.
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
		_refrescar_salas()
		_linea.clear()
		_linea.grab_focus.call_deferred()
		if _registro.get_parsed_text().is_empty():
			_escribir("Escribe un comando o pulsa un botón. Tab completa, ↑/↓ historial.")
	else:
		_linea.release_focus()
		get_tree().paused = _pausa_previa
		Input.mouse_mode = _raton_previo


func ejecutar(texto: String) -> void:
	var limpio := texto.strip_edges()
	if limpio.is_empty():
		return
	_historial.push_front(limpio)
	_indice_historial = -1
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
		"fase":
			_cmd_fase(args)
		"sala":
			_cmd_sala(args)
		"dia":
			_cmd_dia(args)
		"dinero":
			_cmd_dinero(args)
		"pistas":
			_cmd_pistas()
		"gato":
			_cmd_gato(args)
		"clima":
			_cmd_clima(args)
		"desatascar":
			_cmd_desatascar()
		"portatil", "portátil":
			_cmd_portatil()
		_:
			_error("No conozco «%s». Escribe ayuda." % comando)


# --- Comandos -----------------------------------------------------------------


func _cmd_fase(args: Array) -> void:
	var dia := _dia()
	if dia == null:
		return
	if args.is_empty() or args[0] not in FASES:
		_error("Uso: fase %s" % "|".join(FASES))
		return
	_cerrar_y(func(): dia._entrar_en(args[0]))
	_ok("Fase: %s" % args[0])


func _cmd_sala(args: Array) -> void:
	var dia := _dia()
	if dia == null:
		return
	var salas := SuenoFormas.ids()
	if args.is_empty() or args[0] not in salas:
		_error("Uso: sala %s" % "|".join(salas))
		return
	var sala: String = args[0]
	dia.jornada["sueno_escenas"] = [sala, sala, sala]
	dia.jornada["sueno_resto"] = Sueno.segundos_de_noche(dia.jornada["sueno_escenas"])
	_cerrar_y(func(): dia._entrar_en("sueño"))
	_ok("Sueño: %s" % sala)


func _cmd_dia(args: Array) -> void:
	var dia := _dia()
	if dia == null:
		return
	if args.is_empty() or not String(args[0]).is_valid_int() or int(args[0]) < 1:
		_error("Uso: dia <n>, con n ≥ 1")
		return
	dia.jornada["dia"] = int(args[0])
	_cerrar_y(func(): dia._entrar_en(dia.jornada["fase"]))
	_ok("Día %d (el clima automático cambia con el día)" % int(args[0]))


func _cmd_dinero(args: Array) -> void:
	var dia := _dia()
	if dia == null:
		return
	var valor := String(args[0]) if not args.is_empty() else ""
	var sumar := valor.begins_with("+")
	var numero := valor.trim_prefix("+")
	if not numero.is_valid_int():
		_error("Uso: dinero <n> | dinero +<n>")
		return
	var actual := int(dia.jornada.get("dinero", 0))
	dia.jornada["dinero"] = actual + int(numero) if sumar else int(numero)
	dia._refrescar_rotulos(dia._espacio_actual)
	_ok("Dinero: %d" % dia.jornada["dinero"])


func _cmd_pistas() -> void:
	var dia := _dia()
	if dia == null:
		return
	var ids: Array = []
	for caso in dia.contenido.casos:
		for pista in caso["pistas"]:
			ids.append(pista["id"])
	dia.partida.estado["pistas_descubiertas"] = ids
	_ok("%d pistas descubiertas" % ids.size())


func _cmd_gato(args: Array) -> void:
	var dia := _dia()
	if dia == null:
		return
	var gato: Dictionary = dia.jornada.get("gato", {})
	if args.size() >= 1 and args[0] == "comer":
		gato["dias_sin_comer"] = 0
		_ok("El gato ha comido")
	elif args.size() >= 2 and args[0] == "hambre" and String(args[1]).is_valid_int():
		gato["dias_sin_comer"] = maxi(0, int(args[1]))
		_ok("Días sin comer: %d" % gato["dias_sin_comer"])
	else:
		_error("Uso: gato comer | gato hambre <n>")


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
	_ok("Clima: %s (solo se ve en espacios exteriores)" % args[0])


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
	var abrir := func():
		var consola := dia._mundo.find_child("ConsolaPortatil98", true, false) as Interactuable3D
		if consola != null:
			consola.interactuar(dia._caminante)
	if dia.jornada["fase"] != "casa":
		_cerrar_y(
			func():
				dia._entrar_en("casa")
				abrir.call_deferred()
		)
	else:
		_cerrar_y(abrir)
	_ok("Abriendo la portátil")


# --- Apoyo --------------------------------------------------------------------


func _dia() -> Node:
	var escena := get_tree().current_scene
	if escena == null or escena.scene_file_path != ESCENA_DIA:
		_error("Solo funciona dentro de una partida. Empieza o continúa una desde el menú.")
		return null
	return escena


## Cambiar de espacio con la consola abierta dejaría el árbol en pausa y el
## ratón suelto encima del mundo nuevo.
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


func _autocompletar() -> void:
	var texto := _linea.text
	var partes := texto.split(" ")
	var candidatos: Array = []
	if partes.size() <= 1:
		candidatos = COMANDOS.keys()
	else:
		match partes[0]:
			"fase":
				candidatos = FASES
			"sala":
				candidatos = SuenoFormas.ids()
			"clima":
				candidatos = CLIMAS
			"gato":
				candidatos = ["comer", "hambre"]
	var prefijo: String = partes[partes.size() - 1]
	var encajan := candidatos.filter(func(c): return String(c).begins_with(prefijo))
	if encajan.size() == 1:
		partes[partes.size() - 1] = encajan[0]
		_linea.text = " ".join(partes) + " "
		_linea.caret_column = _linea.text.length()
	elif encajan.size() > 1:
		_escribir("  " + "   ".join(encajan))


func _recorrer_historial(paso: int) -> void:
	if _historial.is_empty():
		return
	_indice_historial = clampi(_indice_historial + paso, -1, _historial.size() - 1)
	_linea.text = "" if _indice_historial < 0 else _historial[_indice_historial]
	_linea.caret_column = _linea.text.length()


# --- Interfaz -----------------------------------------------------------------


func _montar() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.anchor_bottom = 0.62
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.05, 0.06, 0.08, 0.94)
	fondo.border_color = Color(0.35, 0.75, 1.0)
	fondo.border_width_bottom = 2
	fondo.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", fondo)
	add_child(_panel)

	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 14)
	_panel.add_child(columnas)

	var botones := ScrollContainer.new()
	botones.custom_minimum_size.x = 420
	botones.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columnas.add_child(botones)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(lista)

	_grupo(lista, "Ir a", FASES.map(func(f): return ["fase " + f, f.capitalize()]))
	_salas = _grupo(lista, "Sala del sueño", [])
	_grupo(lista, "Clima", CLIMAS.map(func(c): return ["clima " + c, c.capitalize()]))
	_grupo(
		lista,
		"Partida",
		[
			["dinero +100", "+100 dinero"],
			["pistas", "Todas las pistas"],
			["gato comer", "Gato: comer"],
			["gato hambre 3", "Gato: hambre 3"],
		]
	)
	_grupo(
		lista,
		"Utilidades",
		[
			["desatascar", "Desatascar"],
			["portatil", "Portátil 98"],
			["ayuda", "Ayuda"],
			["limpiar", "Limpiar"],
		]
	)

	var derecha := VBoxContainer.new()
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(derecha)

	var titulo := Label.new()
	titulo.text = "CONSOLA DE PRUEBAS  ·  º o Esc para cerrar"
	titulo.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0))
	derecha.add_child(titulo)

	var fuente_terminal := EstiloSiga.fuente_terminal()

	_registro = RichTextLabel.new()
	_registro.bbcode_enabled = true
	_registro.scroll_following = true
	_registro.selection_enabled = true
	_registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_registro.add_theme_color_override("default_color", Color(0.9, 0.92, 0.95))
	_registro.add_theme_font_override("normal_font", fuente_terminal)
	_registro.add_theme_font_override("bold_font", fuente_terminal)
	_registro.add_theme_font_size_override("normal_font_size", 16)
	_registro.add_theme_font_size_override("bold_font_size", 16)
	derecha.add_child(_registro)

	_linea = LineEdit.new()
	_linea.placeholder_text = "fase casa · sala patio · dinero +500 · clima lluvia · ayuda"
	_linea.add_theme_font_override("font", fuente_terminal)
	_linea.add_theme_font_size_override("font_size", 18)
	_linea.text_submitted.connect(
		func(texto: String):
			_linea.clear()
			ejecutar(texto)
	)
	derecha.add_child(_linea)


func _grupo(padre: VBoxContainer, titulo: String, acciones: Array) -> HFlowContainer:
	var etiqueta := Label.new()
	etiqueta.text = titulo
	etiqueta.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	padre.add_child(etiqueta)
	var fila := HFlowContainer.new()
	padre.add_child(fila)
	for accion in acciones:
		_boton(fila, accion[0], accion[1])
	return fila


func _boton(fila: HFlowContainer, comando: String, texto: String) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.tooltip_text = comando
	boton.focus_mode = Control.FOCUS_NONE
	boton.pressed.connect(func(): ejecutar(comando))
	fila.add_child(boton)


func _refrescar_salas() -> void:
	for hijo in _salas.get_children():
		hijo.queue_free()
	for sala in SuenoFormas.ids():
		_boton(_salas, "sala " + sala, sala)
