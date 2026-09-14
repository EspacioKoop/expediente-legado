## El formulario de imputación: la ventana donde se firma.
##
## Una acusación no se hace pulsando "acusar" — se rellena. La ceremonia es el
## contenido: número de formulario, casilla por sospechoso, y una declaración
## responsable que hay que marcar antes de poder presentar.
##
## Esa declaración es el chiste central de la pantalla: dice «declaro haber
## revisado la documentación» y **la marcas hayas leído o no**, porque sin ella
## el botón no se activa. El sistema no comprueba la casilla; comprueba, por su
## cuenta y sin decírtelo, cuántas pistas habías descubierto de verdad. La
## casilla es la burocracia; `Acusacion.acusar` es lo que pasa de verdad.
##
## No decide nada: la regla vive en `Acusacion` y el careo en su escena. Aquí
## solo se rellena un papel.
extends Control

signal firmada(resultado: Dictionary)
signal cancelada

var caso: Dictionary = {}
var estado: Dictionary = {}
var jornada: Dictionary = {}
var descubiertas: Array = []

var _elegido := -1
var _declarado := false
var _casillas: Array = []
var _declaracion: CheckBox
var _presentar: Button
var _volver: Button
var _aviso: Label


func _ready() -> void:
	theme = EstiloSiga.tema()
	_construir()
	# El foco se entrega después de terminar de montar el árbol: así abrir o
	# reconstruir el A-7 nunca conserva una referencia a un control ya liberado.
	if not _casillas.is_empty():
		_casillas[0].call_deferred("grab_focus")
	else:
		_declaracion.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancelada.emit()


func _draw() -> void:
	EstiloSiga.dibujar_bisel(self, Rect2(Vector2.ZERO, size), EstiloSiga.GRIS, true)


func _construir() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 10
	raiz.offset_top = 10
	raiz.offset_right = -10
	raiz.offset_bottom = -10
	raiz.add_theme_constant_override("separation", 8)
	add_child(raiz)

	raiz.add_child(_titulo(tr("A7_TITULO")))
	raiz.add_child(_linea(tr("A7_EXPEDIENTE") % tr(caso.get("titulo", ""))))
	raiz.add_child(_linea(tr("A7_EJERCICIO") % str(caso.get("anioSuceso", tr("A7_SIN_FECHA")))))

	raiz.add_child(_linea(tr("A7_INSTRUCCION")))

	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 2)
	var hueco := PanelContainer.new()
	hueco.add_theme_stylebox_override("panel", _hundido(EstiloSiga.BLANCO))
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hueco.add_child(lista)
	raiz.add_child(hueco)

	for i in Acusacion.sospechosos_de(caso).size():
		var sospechoso: Dictionary = caso["sospechosos"][i]
		var casilla := CheckBox.new()
		casilla.text = tr("A7_CASILLA") % [sospechoso["nombre"], sospechoso.get("descripcion", "")]
		casilla.add_theme_color_override("font_color", EstiloSiga.NEGRO)
		_hacer_enfocable(casilla)
		casilla.toggled.connect(_al_marcar.bind(i))
		lista.add_child(casilla)
		_casillas.append(casilla)

	# La declaración responsable. Obligatoria para presentar y completamente
	# irrelevante para lo que pasa después.
	_declaracion = CheckBox.new()
	_declaracion.text = tr("A7_DECLARACION")
	_declaracion.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	_hacer_enfocable(_declaracion)
	_declaracion.toggled.connect(
		func(marcada: bool):
			_declarado = marcada
			_revisar()
	)
	raiz.add_child(_declaracion)

	_aviso = _linea("")
	raiz.add_child(_aviso)

	var botones := HBoxContainer.new()
	_presentar = Button.new()
	_presentar.text = tr("A7_PRESENTAR")
	_presentar.disabled = true
	_hacer_enfocable(_presentar)
	_presentar.pressed.connect(_al_presentar)
	botones.add_child(_presentar)

	_volver = Button.new()
	_volver.text = tr("A7_VOLVER")
	_hacer_enfocable(_volver)
	_volver.pressed.connect(func(): cancelada.emit())
	botones.add_child(_volver)
	raiz.add_child(botones)

	# El aviso desde el principio: un botón desactivado sin explicación se lee
	# como una pantalla rota.
	_revisar()


## Todos los controles interactivos aceptan foco de teclado/mando y comparten
## una marca geométrica. El borde sigue siendo reconocible incluso sin percibir
## la diferencia de color del tema SIGA-98.
func _hacer_enfocable(control: BaseButton) -> void:
	control.focus_mode = Control.FOCUS_ALL
	var foco := StyleBoxFlat.new()
	foco.bg_color = Color(0, 0, 0, 0)
	foco.border_width_left = 2
	foco.border_width_top = 2
	foco.border_width_right = 2
	foco.border_width_bottom = 2
	foco.border_color = EstiloSiga.NEGRO
	foco.content_margin_left = 3
	foco.content_margin_top = 2
	foco.content_margin_right = 3
	foco.content_margin_bottom = 2
	control.add_theme_stylebox_override("focus", foco)


## El recorrido no depende del orden accidental del árbol. `Presentar` entra en
## la cadena únicamente cuando está habilitado; antes se salta y el foco nunca
## queda atrapado en un botón muerto. El último vuelve al primero.
func _actualizar_vecinos_foco() -> void:
	var controles: Array = []
	for casilla in _casillas:
		controles.append(casilla)
	controles.append(_declaracion)
	if not _presentar.disabled:
		controles.append(_presentar)
	controles.append(_volver)

	for i in controles.size():
		var actual: Control = controles[i]
		var anterior: Control = controles[(i - 1 + controles.size()) % controles.size()]
		var siguiente: Control = controles[(i + 1) % controles.size()]
		actual.focus_neighbor_top = actual.get_path_to(anterior)
		actual.focus_neighbor_left = actual.focus_neighbor_top
		actual.focus_neighbor_bottom = actual.get_path_to(siguiente)
		actual.focus_neighbor_right = actual.focus_neighbor_bottom
		actual.focus_next = actual.focus_neighbor_bottom
		actual.focus_previous = actual.focus_neighbor_top


func _al_marcar(marcada: bool, indice: int) -> void:
	Sonido.sonar(self, "marcar")
	if not marcada:
		if _elegido == indice:
			_elegido = -1
		_revisar()
		return
	# Una casilla y solo una: el formulario no admite dos responsables, que es
	# precisamente lo que casi todos estos expedientes tienen.
	_elegido = indice
	for i in _casillas.size():
		if i != indice:
			_casillas[i].set_pressed_no_signal(false)
	_revisar()


func _revisar() -> void:
	_presentar.disabled = _elegido < 0 or not _declarado
	_actualizar_vecinos_foco()
	if _elegido < 0:
		_aviso.text = tr("A7_FALTA_CASILLA")
	elif not _declarado:
		_aviso.text = tr("A7_FALTA_DECLARACION")
	else:
		_aviso.text = tr("A7_AVISO_CIERRE")


func _al_presentar() -> void:
	var resultado := Acusacion.acusar(
		estado, jornada, caso, caso["sospechosos"][_elegido], descubiertas
	)

	if resultado["resultado"] == "sin_acciones":
		Sonido.sonar(self, "error")
		_aviso.text = tr("A7_SIN_JORNADA")
		return
	if resultado["resultado"] == "ya_cerrado":
		Sonido.sonar(self, "error")
		_aviso.text = tr("A7_YA_CERRADO")
		return

	# Firmar suena distinto de todo lo demás: es lo único irreversible que hace
	# el juego, y el sonido es la última vez que se dice.
	Sonido.sonar(self, "firmar")
	firmada.emit(resultado)


# --- Cajas ------------------------------------------------------------------


func _titulo(texto: String) -> Control:
	var barra := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = EstiloSiga.AZUL_TITULO
	caja.set_corner_radius_all(0)
	caja.content_margin_left = 6
	caja.content_margin_top = 3
	caja.content_margin_bottom = 3
	barra.add_theme_stylebox_override("panel", caja)
	var etiqueta := _linea(texto)
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	barra.add_child(etiqueta)
	return barra


func _linea(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	etiqueta.add_theme_font_size_override("font_size", 14)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return etiqueta


func _hundido(fondo: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.set_corner_radius_all(0)
	caja.border_width_top = EstiloSiga.GROSOR
	caja.border_width_left = EstiloSiga.GROSOR
	caja.border_width_bottom = EstiloSiga.GROSOR
	caja.border_width_right = EstiloSiga.GROSOR
	caja.border_color = EstiloSiga.GRIS_OSCURO
	caja.content_margin_left = 8
	caja.content_margin_right = 8
	caja.content_margin_top = 6
	caja.content_margin_bottom = 6
	return caja
