## La elección ocurre antes de cargar o modificar una partida del usuario.
extends Control

const WALLPAPER: Texture2D = preload("res://arte/os98/wallpaper.svg")
const SYSTEM_MARK: Texture2D = preload("res://arte/os98/system_mark.svg")

var ruta := Partida.RUTA
var partida := Partida.new()
var _continuar: Button
var _nueva: Button
var _cargar: Button
var _personaje: Button
var _ventanilla: Button
var _ajustes: Button
var _salir: Button
var _aviso: Label
var _confirmacion: ConfirmationDialog
var _reinicio_pendiente := false
var _entrando := false


class PanelBisel:
	extends MarginContainer

	var saliente := true
	var fondo := EstiloSiga.GRIS

	func _ready() -> void:
		resized.connect(_redibujar)
		queue_redraw()

	func _redibujar() -> void:
		queue_redraw()

	func _draw() -> void:
		EstiloSiga.dibujar_bisel(self, Rect2(Vector2.ZERO, size), fondo, saliente)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = EstiloSiga.tema()
	_construir_interfaz()
	_confirmacion = ConfirmationDialog.new()
	_confirmacion.title = tr("INICIO_NUEVA")
	_confirmacion.dialog_text = tr("INICIO_CONFIRMAR")
	_confirmacion.ok_button_text = tr("INICIO_NUEVA")
	_confirmacion.cancel_button_text = tr("INICIO_CANCELAR")
	_confirmacion.confirmed.connect(_empezar)
	_confirmacion.canceled.connect(func(): _nueva.grab_focus())
	add_child(_confirmacion)
	_actualizar()
	if _continuar.disabled:
		_nueva.grab_focus()
	else:
		_continuar.grab_focus()


func _construir_interfaz() -> void:
	var wallpaper := TextureRect.new()
	wallpaper.name = "FondoInicio"
	wallpaper.texture = WALLPAPER
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallpaper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wallpaper)

	var centro := CenterContainer.new()
	centro.name = "CentroInicio"
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var marco := PanelBisel.new()
	marco.name = "MarcoInicio"
	marco.custom_minimum_size = Vector2(520, 540)
	marco.saliente = true
	for lado in ["left", "top", "right", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 10)
	centro.add_child(marco)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	marco.add_child(caja)
	_crear_cabecera(caja)
	_crear_estado(caja)

	_continuar = _crear_boton(tr("INICIO_CONTINUAR"), _seguir)
	caja.add_child(_continuar)
	_nueva = _crear_boton(tr("INICIO_NUEVA"), _pedir_nueva)
	caja.add_child(_nueva)
	_cargar = _crear_boton(tr("INICIO_CARGAR"), _cargar_partida)
	_cargar.tooltip_text = tr("INICIO_CARGAR_TOOLTIP")
	caja.add_child(_cargar)
	_personaje = _crear_boton("Crear / editar personaje", _abrir_personaje)
	_personaje.tooltip_text = "Apariencia física y trasfondo del protagonista"
	caja.add_child(_personaje)

	var separador := HSeparator.new()
	separador.name = "SeparadorInicio"
	caja.add_child(separador)

	_ventanilla = _crear_boton(tr("INICIO_VENTANILLA"), _abrir_ventanilla)
	caja.add_child(_ventanilla)
	_ajustes = _crear_boton(tr("MENU_GLOBAL_OPCIONES"), _abrir_ajustes)
	caja.add_child(_ajustes)
	_salir = _crear_boton(tr("MENU_GLOBAL_SALIR"), _salir_del_juego)
	caja.add_child(_salir)


func _crear_cabecera(caja: VBoxContainer) -> void:
	var barra := PanelContainer.new()
	barra.name = "BarraTituloInicio"
	barra.custom_minimum_size.y = 42
	barra.add_theme_stylebox_override(
		"panel", _caja_plana(EstiloSiga.AZUL_TITULO, EstiloSiga.NEGRO, 1)
	)
	caja.add_child(barra)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	barra.add_child(fila)
	var marca := TextureRect.new()
	marca.name = "MarcaInicio"
	marca.texture = SYSTEM_MARK
	marca.custom_minimum_size = Vector2(28, 28)
	marca.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marca.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marca.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(marca)
	var titulo := Label.new()
	titulo.text = tr("INICIO_TITULO")
	titulo.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(titulo)


func _crear_estado(caja: VBoxContainer) -> void:
	var estado := PanelBisel.new()
	estado.name = "EstadoInicio"
	estado.saliente = false
	estado.fondo = Color("ece9d8")
	estado.custom_minimum_size.y = 66
	for lado in ["left", "top", "right", "bottom"]:
		estado.add_theme_constant_override("margin_" + lado, 9)
	caja.add_child(estado)
	_aviso = Label.new()
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.custom_minimum_size.x = 440
	_aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	estado.add_child(_aviso)


func _crear_boton(texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size.y = 36
	boton.focus_mode = Control.FOCUS_ALL
	boton.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	boton.add_theme_color_override("font_hover_color", EstiloSiga.NEGRO)
	boton.add_theme_color_override("font_pressed_color", EstiloSiga.NEGRO)
	boton.add_theme_color_override("font_focus_color", EstiloSiga.NEGRO)
	boton.add_theme_color_override("font_disabled_color", EstiloSiga.GRIS_OSCURO)
	boton.add_theme_stylebox_override(
		"normal", _caja_plana(EstiloSiga.GRIS, EstiloSiga.GRIS_OSCURO, 2)
	)
	boton.add_theme_stylebox_override(
		"hover", _caja_plana(EstiloSiga.GRIS_CLARO, EstiloSiga.AZUL_TITULO, 2)
	)
	boton.add_theme_stylebox_override("pressed", _caja_plana(Color("a8a8a8"), EstiloSiga.NEGRO, 2))
	boton.add_theme_stylebox_override(
		"disabled", _caja_plana(Color("b8b8b8"), EstiloSiga.GRIS_OSCURO, 2)
	)
	boton.add_theme_stylebox_override("focus", _caja_plana(Color(0, 0, 0, 0), EstiloSiga.NEGRO, 1))
	boton.pressed.connect(accion)
	return boton


func _caja_plana(fondo: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(grosor)
	caja.content_margin_left = 8
	caja.content_margin_right = 8
	caja.content_margin_top = 6
	caja.content_margin_bottom = 6
	return caja


func _actualizar() -> void:
	var existe := FileAccess.file_exists(ruta)
	_continuar.disabled = not existe or _reinicio_pendiente
	_cargar.disabled = not existe or _reinicio_pendiente
	_aviso.text = tr("INICIO_EXISTENTE" if existe else "INICIO_BIENVENIDA")


func _seguir() -> void:
	if _entrando or _reinicio_pendiente or not FileAccess.file_exists(ruta):
		return
	_entrar()


func _cargar_partida() -> void:
	# Hoy existe una única ranura canónica. Mantener una acción separada deja
	# explícito el contrato del menú y permite introducir selector de ranuras sin
	# cambiar la semántica de Continuar.
	_seguir()


func _pedir_nueva() -> void:
	if _entrando:
		return
	if FileAccess.file_exists(ruta) and not _reinicio_pendiente:
		_confirmacion.popup_centered()
		# Confirmar nunca es el foco inicial de una acción destructiva.
		_confirmacion.get_cancel_button().grab_focus()
	else:
		_empezar()


func _empezar() -> void:
	if _entrando:
		return
	# Si falla guardar, reintentamos el mismo estado sin volver a apartar nada.
	if not _reinicio_pendiente:
		if not partida.borrar(ruta):
			_aviso.text = tr("INICIO_ERROR_REINICIO")
			return
		_reinicio_pendiente = true
	_actualizar()
	if not partida.guardar(ruta):
		_aviso.text = tr("ARCHIVO_ERROR_GUARDAR")
		return
	_reinicio_pendiente = false
	_entrar()


func _abrir_personaje() -> void:
	if _entrando:
		return
	_entrando = true
	var error := get_tree().change_scene_to_file("res://escenas/creador_personaje.tscn")
	if error != OK:
		_entrando = false
		_aviso.text = tr("INICIO_ERROR_ENTRADA")


func _abrir_ventanilla() -> void:
	if _entrando:
		return
	_entrando = true
	var error := get_tree().change_scene_to_file("res://escenas/ventanilla.tscn")
	if error != OK:
		_entrando = false
		_aviso.text = tr("INICIO_ERROR_ENTRADA")


func _abrir_ajustes() -> void:
	if _entrando:
		return
	# MenuGlobal ya contiene la superficie canónica de preferencias y restaura
	# el foco previo al cerrarse. Se reutiliza desde inicio en vez de mantener
	# una segunda copia de volumen/remapeo/reducción de movimiento.
	#
	# Se busca por ruta (no por el identificador global implícito) porque los
	# scripts de prueba que arrancan con `--script` sobre un SceneTree propio
	# nunca pasan por el arranque normal del proyecto: ahí el autoload sigue
	# presente en el árbol, pero el compilador de GDScript no resuelve su
	# nombre global y el script entero deja de compilar.
	var menu := get_node_or_null("/root/MenuGlobal")
	if menu != null and menu.has_method("_abrir"):
		menu.call("_abrir")
	else:
		_aviso.text = tr("INICIO_ERROR_AJUSTES")


func _salir_del_juego() -> void:
	get_tree().quit()


func _entrar() -> void:
	_entrando = true
	var error := get_tree().change_scene_to_file("res://escenas/dia.tscn")
	if error != OK:
		_entrando = false
		_actualizar()
		_aviso.text = tr("INICIO_ERROR_ENTRADA")
