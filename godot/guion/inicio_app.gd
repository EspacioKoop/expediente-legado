## La elección ocurre antes de cargar o modificar una partida del usuario.
extends Control

var ruta := Partida.RUTA
var partida := Partida.new()
var _continuar: Button
var _nueva: Button
var _cargar: Button
var _ventanilla: Button
var _ajustes: Button
var _salir: Button
var _aviso: Label
var _confirmacion: ConfirmationDialog
var _reinicio_pendiente := false
var _entrando := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = EstiloSiga.tema()
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 420)
	centro.add_child(panel)
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)
	var titulo := Label.new()
	titulo.text = tr("INICIO_TITULO")
	caja.add_child(titulo)
	_aviso = Label.new()
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.custom_minimum_size.x = 420
	caja.add_child(_aviso)
	_continuar = Button.new()
	_continuar.text = tr("INICIO_CONTINUAR")
	_continuar.pressed.connect(_seguir)
	caja.add_child(_continuar)
	_nueva = Button.new()
	_nueva.text = tr("INICIO_NUEVA")
	_nueva.pressed.connect(_pedir_nueva)
	caja.add_child(_nueva)
	_cargar = Button.new()
	_cargar.text = "Cargar partida"
	_cargar.tooltip_text = "Carga la partida guardada de este perfil."
	_cargar.pressed.connect(_cargar_partida)
	caja.add_child(_cargar)
	_ventanilla = Button.new()
	_ventanilla.text = "Ventanilla de reclamaciones"
	_ventanilla.pressed.connect(_abrir_ventanilla)
	caja.add_child(_ventanilla)
	_ajustes = Button.new()
	_ajustes.text = tr("MENU_GLOBAL_OPCIONES")
	_ajustes.pressed.connect(_abrir_ajustes)
	caja.add_child(_ajustes)
	_salir = Button.new()
	_salir.text = tr("MENU_GLOBAL_SALIR")
	_salir.pressed.connect(_salir_del_juego)
	caja.add_child(_salir)
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
		_aviso.text = "No se pudieron abrir los ajustes."


func _salir_del_juego() -> void:
	get_tree().quit()


func _entrar() -> void:
	_entrando = true
	var error := get_tree().change_scene_to_file("res://escenas/dia.tscn")
	if error != OK:
		_entrando = false
		_actualizar()
		_aviso.text = tr("INICIO_ERROR_ENTRADA")
