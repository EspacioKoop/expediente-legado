## Superficie aislada para ejecutar ROMs GB desde la Portátil Color 98 (#124).
##
## La UI pausa el mundo mientras está abierta y solo habla con la clase nativa
## Siga98GB. No conoce estado persistente, casos, economía ni guardados de campaña.
class_name EmuladorPortatilApp
extends CanvasLayer

signal cerrado

const ROM_PROPIA := "res://roms/caza_pixeles_98.gbc"
const TEXTOS := "res://datos/emulador_gb_textos.json"
const ANCHO := 160
const ALTO := 144

const BTN_A := 0x01
const BTN_B := 0x02
const BTN_SELECT := 0x04
const BTN_START := 0x08
const BTN_RIGHT := 0x10
const BTN_LEFT := 0x20
const BTN_UP := 0x40
const BTN_DOWN := 0x80

var _textos: Dictionary = {}
var _emulador: Object = null
var _vista: TextureRect
var _estado: Label
var _lista: VBoxContainer
var _textura: ImageTexture
var _jugando := false
var _pausa_anterior := false
var _abierto := false


func abrir() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_textos = _cargar_textos()
	_pausa_anterior = get_tree().paused
	get_tree().paused = true
	_abierto = true
	_construir_ui()
	_preparar_nucleo()
	_refrescar_roms()
	set_process(true)


func _process(_delta: float) -> void:
	if not _jugando or _emulador == null:
		return
	_emulador.call("set_buttons", _botones())
	var datos: PackedByteArray = _emulador.call("run_frame_rgba")
	if datos.size() != ANCHO * ALTO * 4:
		_jugando = false
		_estado.text = _formatear("error_runtime", [_emulador.call("last_error")])
		return
	var imagen := Image.create_from_data(ANCHO, ALTO, false, Image.FORMAT_RGBA8, datos)
	if _textura == null:
		_textura = ImageTexture.create_from_image(imagen)
		_vista.texture = _textura
	else:
		_textura.update(imagen)


func _input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cerrar()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if _abierto and get_tree() != null:
		get_tree().paused = _pausa_anterior
	_abierto = false


func _construir_ui() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.025, 0.03, 0.028, 0.97)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 36)
	margen.add_theme_constant_override("margin_right", 36)
	margen.add_theme_constant_override("margin_top", 24)
	margen.add_theme_constant_override("margin_bottom", 24)
	add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 12)
	margen.add_child(raiz)

	var titulo := Label.new()
	titulo.text = _texto("titulo")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 26)
	raiz.add_child(titulo)

	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 24)
	raiz.add_child(cuerpo)

	var izquierda := VBoxContainer.new()
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(izquierda)

	_vista = TextureRect.new()
	_vista.custom_minimum_size = Vector2(480, 432)
	_vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_vista.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	izquierda.add_child(_vista)

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.custom_minimum_size = Vector2(480, 52)
	izquierda.add_child(_estado)

	var derecha := VBoxContainer.new()
	derecha.custom_minimum_size = Vector2(360, 0)
	derecha.add_theme_constant_override("separation", 8)
	cuerpo.add_child(derecha)

	var carpeta := Label.new()
	carpeta.text = _formatear("carpeta", [CatalogoRomsUsuario.ruta_absoluta()])
	carpeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(carpeta)

	_lista = VBoxContainer.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	derecha.add_child(_lista)

	var aviso := Label.new()
	aviso.text = _texto("aviso")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(aviso)

	var audio := Label.new()
	audio.text = _texto("audio")
	audio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(audio)

	var salir := Button.new()
	salir.text = _texto("cerrar")
	salir.pressed.connect(_cerrar)
	derecha.add_child(salir)


func _preparar_nucleo() -> void:
	if not ClassDB.class_exists(&"Siga98GB"):
		_estado.text = _texto("sin_nucleo")
		return
	_emulador = ClassDB.instantiate(&"Siga98GB")


func _refrescar_roms() -> void:
	for hijo in _lista.get_children():
		hijo.queue_free()

	var entradas: Array[Dictionary] = []
	if FileAccess.file_exists(ROM_PROPIA):
		entradas.append({"nombre": _texto("rom_propia"), "ruta": ROM_PROPIA})
	elif _emulador != null:
		_estado.text = _texto("rom_propia_ausente")
	entradas.append_array(CatalogoRomsUsuario.listar())

	if entradas.is_empty():
		var vacio := Label.new()
		vacio.text = _texto("sin_roms")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista.add_child(vacio)
		return

	for entrada in entradas:
		var boton := Button.new()
		boton.text = String(entrada.get("nombre", ""))
		boton.pressed.connect(_cargar_rom.bind(String(entrada.get("ruta", ""))))
		_lista.add_child(boton)


func _cargar_rom(ruta: String) -> void:
	if _emulador == null or ruta.is_empty():
		return
	_estado.text = _formatear("cargando", [ruta.get_file()])
	var rom := FileAccess.get_file_as_bytes(ruta)
	var resultado := int(_emulador.call("load_rom", rom))
	if resultado == 3:
		_estado.text = _texto("error_cgb")
		_jugando = false
		return
	if resultado != 0:
		_estado.text = _formatear("error_rom", [_emulador.call("last_error")])
		_jugando = false
		return
	_jugando = true
	var titulo := String(_emulador.call("rom_title"))
	if titulo.is_empty():
		titulo = ruta.get_file()
	_estado.text = _formatear("ejecutando", [titulo])


func _botones() -> int:
	var botones := 0
	if _tecla(KEY_RIGHT) or _tecla(KEY_D) or _joy(JOY_BUTTON_DPAD_RIGHT):
		botones |= BTN_RIGHT
	if _tecla(KEY_LEFT) or _tecla(KEY_A) or _joy(JOY_BUTTON_DPAD_LEFT):
		botones |= BTN_LEFT
	if _tecla(KEY_UP) or _tecla(KEY_W) or _joy(JOY_BUTTON_DPAD_UP):
		botones |= BTN_UP
	if _tecla(KEY_DOWN) or _tecla(KEY_S) or _joy(JOY_BUTTON_DPAD_DOWN):
		botones |= BTN_DOWN
	if _tecla(KEY_Z) or _tecla(KEY_SPACE) or _joy(JOY_BUTTON_A):
		botones |= BTN_A
	if _tecla(KEY_X) or _joy(JOY_BUTTON_B):
		botones |= BTN_B
	if _tecla(KEY_ENTER) or _joy(JOY_BUTTON_START):
		botones |= BTN_START
	if _tecla(KEY_TAB) or _joy(JOY_BUTTON_BACK):
		botones |= BTN_SELECT
	return botones


func _tecla(codigo: Key) -> bool:
	return Input.is_key_pressed(codigo)


func _joy(boton: JoyButton) -> bool:
	return Input.is_joy_button_pressed(0, boton)


func _cerrar() -> void:
	if not _abierto:
		return
	_jugando = false
	_abierto = false
	get_tree().paused = _pausa_anterior
	cerrado.emit()
	queue_free()


func _cargar_textos() -> Dictionary:
	if not FileAccess.file_exists(TEXTOS):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(TEXTOS))
	return datos if datos is Dictionary else {}


func _texto(clave: String) -> String:
	return String(_textos.get(clave, clave))


func _formatear(clave: String, valores: Array) -> String:
	return _texto(clave) % valores
