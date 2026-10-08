## La elección ocurre antes de cargar o modificar una partida del usuario.
##
## #830: el bloque OS98 centrado se sustituye por un diorama 3D en vivo (una
## oficina nocturna con CRT y calle lluviosa, ver `InicioDiorama3D`) sobre el
## que se dibuja una lista de texto sin panel detrás. El contrato funcional
## (foco inicial seguro, confirmación de "Nueva", accesos a ventanilla/
## ajustes/salir) no cambia: solo cambia la piel.
extends Control

const SYSTEM_MARK: Texture2D = preload("res://arte/os98/system_mark.svg")
const CINEMATICA_APP := preload("res://guion/cinematica_app.gd")
const EPIGRAFES_INICIO := preload("res://guion/epigrafes_inicio.gd")
const APERTURA_ONIRICA := preload("res://guion/apertura_onirica_cinematica.gd")
const COLOR_TEXTO := Color(0.92, 0.93, 0.90)
const COLOR_TEXTO_DESACTIVADO := Color(0.55, 0.56, 0.53)
const COLOR_CONTORNO := Color(0.0, 0.0, 0.0, 0.85)
const COLOR_FONDO_ITEM := Color(0.03, 0.035, 0.045, 0.46)
const COLOR_FONDO_ITEM_HOVER := Color(0.05, 0.055, 0.07, 0.78)
const COLOR_FONDO_ITEM_PULSADO := Color(0.02, 0.025, 0.035, 0.88)

## Deriva de encuadre del diorama por cada acción del menú (`InicioDiorama3D.ZONAS`).
const ZONAS_POR_BOTON := {
	"_continuar": "continuar",
	"_nueva": "nueva",
	"_cargar": "cargar",
	"_extras": "extras",
	"_personaje": "extras",
	"_portatil": "extras",
	"_ventanilla": "extras",
	"_ajustes": "opciones",
	"_salir": "salir",
}

static var _apertura_creditos_mostrada := false

var ruta := Partida.RUTA
var partida := Partida.new()
var _diorama: InicioDiorama3D
var _envoltorio: MarginContainer
var _apertura_creditos: Node3D = null
var _epigrafes: Control = null
var _montaje_onirico: Node3D = null
var _continuar: Button
var _nueva: Button
var _cargar: Button
var _extras: Button
var _extras_contenedor: VBoxContainer
var _personaje: Button
var _portatil: Button
var _ventanilla: Button
var _ajustes: Button
var _salir: Button
var _aviso: Label
var _confirmacion: ConfirmationDialog
var _portatil_app: EmuladorPortatilApp = null
var _reinicio_pendiente := false
var _entrando := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = EstiloJuego.tema()
	_construir_interfaz()
	_confirmacion = ConfirmationDialog.new()
	_confirmacion.title = tr("INICIO_NUEVA")
	_confirmacion.dialog_text = tr("INICIO_CONFIRMAR")
	_confirmacion.ok_button_text = tr("INICIO_NUEVA")
	_confirmacion.cancel_button_text = tr("INICIO_CANCELAR")
	_confirmacion.confirmed.connect(_empezar)
	_confirmacion.canceled.connect(func(): _nueva.grab_focus())
	add_child(_confirmacion)
	# #800: importar compras antiguas no debe cargar Partida ni alterar un save
	# corrupto antes de que el jugador decida abrirlo.
	PerfilRoms.migrar_desde_partida(ruta)
	_actualizar()
	_diorama.configurar_reduccion_movimiento(
		bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	)
	if _apertura_creditos_mostrada:
		_enfocar_menu_inicial()
	else:
		_iniciar_apertura_creditos()


func _enfocar_menu_inicial() -> void:
	if _continuar.disabled:
		_nueva.grab_focus()
	else:
		_continuar.grab_focus()


func _iniciar_apertura_creditos() -> void:
	_apertura_creditos_mostrada = true
	_envoltorio.visible = false
	_diorama.configurar_activo(false)
	var epigrafes := EPIGRAFES_INICIO.new()
	epigrafes.name = "EpigrafesInicio"
	epigrafes.terminada.connect(_iniciar_montaje_onirico)
	_epigrafes = epigrafes
	add_child(epigrafes)
	epigrafes.iniciar()


func _iniciar_montaje_onirico() -> void:
	# Las citas preceden a la sucesion de planos, no sustituyen los creditos.
	if is_instance_valid(_epigrafes):
		_epigrafes.queue_free()
	_epigrafes = null
	var tomas := APERTURA_ONIRICA.planos()
	if tomas.is_empty():
		_iniciar_cinematica_creditos()
		return
	var reproductor := CINEMATICA_APP.new()
	reproductor.name = "MontajeOnirico1998"
	reproductor.terminada.connect(_iniciar_cinematica_creditos)
	_montaje_onirico = reproductor
	add_child(reproductor)
	reproductor.reproducir(tomas, AperturaOniricaCinematica.ID)


func _iniciar_cinematica_creditos() -> void:
	if is_instance_valid(_montaje_onirico):
		_montaje_onirico.queue_free()
	_montaje_onirico = null
	var rodaje := CreditosInicioCinematica.planos()
	if rodaje.is_empty():
		_terminar_apertura_creditos()
		return
	var app := CINEMATICA_APP.new()
	app.name = "AperturaCreditos3D"
	app.terminada.connect(_terminar_apertura_creditos)
	_apertura_creditos = app
	add_child(app)
	app.reproducir(rodaje, CreditosInicioCinematica.ID)


func _terminar_apertura_creditos() -> void:
	if is_instance_valid(_apertura_creditos):
		_apertura_creditos.queue_free()
	_apertura_creditos = null
	_envoltorio.visible = true
	_diorama.configurar_activo(true)
	_enfocar_menu_inicial()


func _unhandled_input(evento: InputEvent) -> void:
	if is_instance_valid(_epigrafes):
		# Ignorar movimiento de ratón: únicamente acciones explícitas saltan el prólogo.
		if evento.is_action_pressed("interactuar") or evento.is_action_pressed("cancelar"):
			_epigrafes.call("saltar")
			get_viewport().set_input_as_handled()
		elif evento is InputEventMouseButton:
			var click_epigrafe := evento as InputEventMouseButton
			if click_epigrafe.pressed and click_epigrafe.button_index == MOUSE_BUTTON_LEFT:
				_epigrafes.call("saltar")
				get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_montaje_onirico):
		if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("ui_cancel"):
			_montaje_onirico.call("saltar")
			get_viewport().set_input_as_handled()
		return
	if not is_instance_valid(_apertura_creditos):
		return
	if evento is InputEventMouseButton:
		var click := evento as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_apertura_creditos.call("saltar")
			get_viewport().set_input_as_handled()


func _construir_interfaz() -> void:
	_diorama = InicioDiorama3D.new()
	_diorama.name = "DioramaInicio3D"
	add_child(_diorama)

	var fondo := TextureRect.new()
	fondo.name = "FondoInicio"
	fondo.texture = _diorama.obtener_textura()
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	_envoltorio = MarginContainer.new()
	_envoltorio.name = "EnvoltorioInicio"
	_envoltorio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		_envoltorio.add_theme_constant_override("margin_" + lado, 48)
	add_child(_envoltorio)

	var caja := VBoxContainer.new()
	caja.name = "ListaInicio"
	caja.alignment = BoxContainer.ALIGNMENT_END
	caja.add_theme_constant_override("separation", 8)
	_envoltorio.add_child(caja)

	_crear_cabecera(caja)
	_crear_estado(caja)

	_continuar = _crear_boton(tr("INICIO_CONTINUAR"), _seguir)
	caja.add_child(_continuar)
	_nueva = _crear_boton(tr("INICIO_NUEVA"), _pedir_nueva)
	caja.add_child(_nueva)
	_cargar = _crear_boton(tr("INICIO_CARGAR"), _cargar_partida)
	_cargar.tooltip_text = tr("INICIO_CARGAR_TOOLTIP")
	caja.add_child(_cargar)
	# #567: la Ventanilla es una acción principal del menú, no un extra
	# escondido. Mantiene acceso directo incluso sin partida guardada.
	_ventanilla = _crear_boton(tr("INICIO_VENTANILLA"), _abrir_ventanilla)
	caja.add_child(_ventanilla)

	# #830: utilidades secundarias siguen agrupadas en Extras sin duplicar
	# escenas ni alterar sus contratos funcionales.
	_extras = _crear_boton("Extras", _alternar_extras)
	caja.add_child(_extras)
	_extras_contenedor = VBoxContainer.new()
	_extras_contenedor.name = "OpcionesExtras"
	_extras_contenedor.visible = false
	_extras_contenedor.add_theme_constant_override("separation", 2)
	caja.add_child(_extras_contenedor)
	_personaje = _crear_boton(tr("INICIO_PERSONAJE"), _abrir_personaje)
	_personaje.tooltip_text = tr("INICIO_PERSONAJE_TOOLTIP")
	_extras_contenedor.add_child(_personaje)
	_portatil = _crear_boton("Portátil Color 98", _abrir_portatil)
	_extras_contenedor.add_child(_portatil)

	_ajustes = _crear_boton(tr("MENU_GLOBAL_OPCIONES"), _abrir_ajustes)
	caja.add_child(_ajustes)
	_salir = _crear_boton(tr("MENU_GLOBAL_SALIR"), _salir_del_juego)
	caja.add_child(_salir)
	_configurar_foco_menu_principal()

	for propiedad in ZONAS_POR_BOTON:
		var boton: Button = get(propiedad)
		var zona: String = ZONAS_POR_BOTON[propiedad]
		boton.focus_entered.connect(_diorama.enfocar.bind(zona))
		boton.mouse_entered.connect(_diorama.enfocar.bind(zona))


func _configurar_foco_menu_principal() -> void:
	# #98: el mando no depende de la heurística espacial de Godot. El recorrido
	# principal es estable y cíclico; al abrir Extras se entra explícitamente en
	# sus dos acciones y desde la última se continúa hacia Ajustes.
	var principales := [_continuar, _nueva, _cargar, _ventanilla, _extras, _ajustes, _salir]
	for i in principales.size():
		var actual: Control = principales[i]
		var anterior: Control = principales[(i - 1 + principales.size()) % principales.size()]
		var siguiente: Control = principales[(i + 1) % principales.size()]
		actual.focus_neighbor_top = actual.get_path_to(anterior)
		actual.focus_neighbor_left = actual.focus_neighbor_top
		actual.focus_previous = actual.focus_neighbor_top
		actual.focus_neighbor_bottom = actual.get_path_to(siguiente)
		actual.focus_neighbor_right = actual.focus_neighbor_bottom
		actual.focus_next = actual.focus_neighbor_bottom

	_personaje.focus_neighbor_top = _personaje.get_path_to(_extras)
	_personaje.focus_neighbor_left = _personaje.focus_neighbor_top
	_personaje.focus_previous = _personaje.focus_neighbor_top
	_personaje.focus_neighbor_bottom = _personaje.get_path_to(_portatil)
	_personaje.focus_neighbor_right = _personaje.focus_neighbor_bottom
	_personaje.focus_next = _personaje.focus_neighbor_bottom
	_portatil.focus_neighbor_top = _portatil.get_path_to(_personaje)
	_portatil.focus_neighbor_left = _portatil.focus_neighbor_top
	_portatil.focus_previous = _portatil.focus_neighbor_top
	_portatil.focus_neighbor_bottom = _portatil.get_path_to(_ajustes)
	_portatil.focus_neighbor_right = _portatil.focus_neighbor_bottom
	_portatil.focus_next = _portatil.focus_neighbor_bottom


func _crear_cabecera(caja: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.name = "CabeceraInicio"
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var marca := TextureRect.new()
	marca.name = "MarcaInicio"
	marca.texture = SYSTEM_MARK
	marca.custom_minimum_size = Vector2(22, 22)
	marca.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marca.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marca.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(marca)
	var titulo := Label.new()
	titulo.text = tr("INICIO_TITULO")
	_aplicar_contraste(titulo)
	titulo.add_theme_font_size_override("font_size", 16)
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(titulo)


func _crear_estado(caja: VBoxContainer) -> void:
	_aviso = Label.new()
	_aviso.name = "EstadoInicio"
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.custom_minimum_size.x = 360
	_aplicar_contraste(_aviso)
	_aviso.accessibility_live = AccessibilityServer.LIVE_POLITE
	caja.add_child(_aviso)


func _crear_boton(texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.accessibility_name = texto
	# #1449 / #830: el menú debe leerse como una lista compacta superpuesta al
	# diorama, no como una botonera que ocupa todo el viewport.
	boton.custom_minimum_size = Vector2(380, 40)
	boton.size_flags_horizontal = Control.SIZE_SHRINK_END
	boton.focus_mode = Control.FOCUS_ALL
	boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	boton.flat = false
	_aplicar_contraste(boton)
	boton.add_theme_color_override("font_disabled_color", COLOR_TEXTO_DESACTIVADO)
	boton.add_theme_color_override("font_hover_color", EstiloJuego.ACENTO)
	boton.add_theme_color_override("font_focus_color", EstiloJuego.ACENTO)
	boton.add_theme_stylebox_override(
		"normal", EstiloJuego.caja(COLOR_FONDO_ITEM, Color.TRANSPARENT, 10.0)
	)
	boton.add_theme_stylebox_override(
		"hover", EstiloJuego.caja(COLOR_FONDO_ITEM_HOVER, EstiloJuego.BORDE, 10.0)
	)
	boton.add_theme_stylebox_override(
		"pressed", EstiloJuego.caja(COLOR_FONDO_ITEM_PULSADO, EstiloJuego.ACENTO, 10.0)
	)
	boton.add_theme_stylebox_override("focus", EstiloJuego.caja_foco())
	boton.focus_entered.connect(func(): boton.text = "> " + texto)
	boton.focus_exited.connect(func(): boton.text = texto)
	boton.pressed.connect(accion)
	return boton


func _aplicar_contraste(control: Control) -> void:
	control.add_theme_color_override("font_color", COLOR_TEXTO)
	control.add_theme_color_override("font_hover_color", COLOR_TEXTO)
	control.add_theme_color_override("font_pressed_color", COLOR_TEXTO)
	control.add_theme_color_override("font_focus_color", COLOR_TEXTO)
	control.add_theme_color_override("font_outline_color", COLOR_CONTORNO)
	control.add_theme_constant_override("outline_size", 5)


func _alternar_extras() -> void:
	var abrir := not _extras_contenedor.visible
	_extras_contenedor.visible = abrir
	if abrir:
		_personaje.grab_focus()
	else:
		_extras.grab_focus()


func _actualizar() -> void:
	var existe := FileAccess.file_exists(ruta)
	_continuar.disabled = not existe or _reinicio_pendiente
	_cargar.disabled = not existe or _reinicio_pendiente
	_aviso.text = tr("INICIO_EXISTENTE" if existe else "INICIO_BIENVENIDA")


func _seguir() -> void:
	if _entrando or _reinicio_pendiente or not FileAccess.file_exists(ruta):
		return
	partida.cargar(ruta)
	var perfil := PerfilJugador.completar(partida.estado.get("perfil_jugador", {}))
	if not PerfilJugador.esta_configurado(perfil):
		_abrir_personaje()
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
	var perfil := PerfilJugador.completar(partida.estado.get("perfil_jugador", {}))
	perfil["configurado"] = false
	partida.estado["perfil_jugador"] = perfil
	if not partida.guardar(ruta):
		_aviso.text = tr("ARCHIVO_ERROR_GUARDAR")
		return
	_reinicio_pendiente = false
	_abrir_personaje()


func _abrir_personaje() -> void:
	if _entrando:
		return
	_entrando = true
	var error := get_tree().change_scene_to_file("res://escenas/creador_personaje.tscn")
	if error != OK:
		_entrando = false
		_aviso.text = tr("INICIO_ERROR_ENTRADA")


func _abrir_portatil() -> void:
	if _entrando or _portatil_app != null:
		return
	# Repetir la migración es barato e idempotente y cubre una partida copiada a
	# la carpeta del usuario mientras el menú ya estaba abierto.
	PerfilRoms.migrar_desde_partida(ruta)
	CatalogoRomsUsuario.asegurar_carpeta()
	var app := EmuladorPortatilAudioApp.new()
	app.roms_compradas = TiendaVideojuegos.compras({})
	app.cerrado.connect(_al_cerrar_portatil)
	_portatil_app = app
	_diorama.configurar_activo(false)
	get_tree().root.add_child(app)
	app.abrir()


func _al_cerrar_portatil() -> void:
	_portatil_app = null
	if is_instance_valid(_diorama):
		_diorama.configurar_activo(true)
	if is_instance_valid(_portatil):
		_portatil.grab_focus()


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
