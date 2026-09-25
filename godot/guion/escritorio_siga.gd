## Shell corporativo de finales de los 90 para el puesto de trabajo (#534).
##
## No conoce SIGA ni ninguna otra aplicación: recibe fábricas de Control, mantiene
## una sola tabla de ventanas y resuelve su ciclo de vida, foco, orden Z, arrastre
## y representación en la barra inferior. La integración con el día vive fuera.
class_name EscritorioSiga
extends Control

signal salir_solicitado

const ALTO_BARRA := 34.0
const ALTO_TITULO := 28.0
const MARGEN := 12.0
const ANCHO_TITULO_RECUPERABLE := 120.0
## Por encima del bloqueador modal (1002) y de cualquier ventana normal.
const Z_MODAL := 3000
const ESCALA_UI_MIN := 0.8
const ESCALA_UI_MAX := 1.5

## Tamaños de serie para quien registre una aplicación sin declarar los suyos
## (p. ej. las pruebas de humo que solo pasan id/título/fábrica).
const TAMANO_MINIMO_SERIE := Vector2(300, 220)
const TAMANO_PREFERIDO_SERIE := Vector2(760, 540)

## Identidad propia: gramática de 1998 sin copiar el escritorio de Windows.
const FONDO_CORPORATIVO := Color("315d5c")
const PETROLEO := Color("1f4d55")
const PETROLEO_INACTIVO := Color("526b6c")
const CREMA := Color("eee7d0")

var reduccion_movimiento := false

var _escala_ui := 1.0
var _alto_barra := ALTO_BARRA
var _alto_titulo := ALTO_TITULO
var _ancho_titulo_recuperable := ANCHO_TITULO_RECUPERABLE

var _fondo: ColorRect
var _marca: Label
var _iconos: VBoxContainer
var _area_ventanas: Control
var _barra: PanelContainer
var _tareas: HBoxContainer
var _reloj: Label
var _menu: PanelContainer
var _programas_menu: VBoxContainer

var _aplicaciones: Dictionary = {}
var _ventanas: Dictionary = {}
var _z_siguiente := 10
var _arrastre_id := ""
var _redimension_id := ""

## Solo puede haber una modal activa a la vez: bloquea el resto del shell
## (escritorio, barra, menú y demás ventanas) hasta que se cierre.
var _modal_id := ""
var _foco_previo_modal: Control = null
var _bloqueador_modal: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_alto_barra = ALTO_BARRA * _escala_ui
	_alto_titulo = ALTO_TITULO * _escala_ui
	_ancho_titulo_recuperable = ANCHO_TITULO_RECUPERABLE * _escala_ui
	theme = EstiloSiga.tema()
	theme.default_font_size = roundi(theme.default_font_size * _escala_ui)
	_construir_escritorio()
	resized.connect(_al_redimensionar)


## La preferencia ya existe en PreferenciasSiga; el shell solo la consume.
## Este primer vertical no anima minimizar/restaurar, así que ambos caminos son
## instantáneos y por tanto seguros con reducción de movimiento activada.
func configurar_reduccion_movimiento(activa: bool) -> void:
	reduccion_movimiento = activa


## A diferencia de las demás `configurar_*`, esta debe llamarse ANTES de meter
## el escritorio en el árbol: `_ready()` construye la interfaz con el tamaño
## final en cuanto entra, y el primer corte no la reconstruye si la escala
## cambia después.
func configurar_escala_ui(escala: float) -> void:
	_escala_ui = clampf(escala, ESCALA_UI_MIN, ESCALA_UI_MAX)


func _esc(valor: float) -> float:
	return valor * _escala_ui


func _esc_v(valor: Vector2) -> Vector2:
	return valor * _escala_ui


func establecer_reloj_narrativo(texto: String) -> void:
	if _reloj != null:
		_reloj.text = texto


## Registra una aplicación sin acoplar el shell a su escena.
## [param creador] debe devolver un Control nuevo cada vez que se abra tras cerrar.
## [param tamano_minimo]/[param tamano_preferido]/[param redimensionable]/
## [param multiples_instancias] vienen de [method EscritorioSigaApp.describir_capacidades];
## quien no las declare recibe los valores de serie de siempre.
func registrar_aplicacion(
	id: String,
	titulo: String,
	creador: Callable,
	tamano_minimo: Vector2 = TAMANO_MINIMO_SERIE,
	tamano_preferido: Vector2 = TAMANO_PREFERIDO_SERIE,
	redimensionable: bool = false,
	multiples_instancias: bool = false
) -> void:
	if id.is_empty() or _aplicaciones.has(id) or not creador.is_valid():
		return
	_aplicaciones[id] = {
		"titulo": titulo,
		"creador": creador,
		"tamano_minimo": tamano_minimo,
		"tamano_preferido": tamano_preferido,
		"redimensionable": redimensionable,
		"multiples_instancias": multiples_instancias,
	}
	_crear_lanzador(id, titulo)
	_crear_entrada_programa(id, titulo)


## Adopta una instancia ya creada. Sirve para migrar el visor histórico sin
## obligar al día a construir dos veces la misma aplicación durante la transición.
func adoptar_aplicacion(
	id: String,
	titulo: String,
	contenido: Control,
	creador: Callable = Callable(),
	tamano_minimo: Vector2 = TAMANO_MINIMO_SERIE,
	tamano_preferido: Vector2 = TAMANO_PREFERIDO_SERIE,
	redimensionable: bool = false,
	multiples_instancias: bool = false
) -> void:
	if contenido == null:
		return
	if not _aplicaciones.has(id):
		if not creador.is_valid():
			return
		registrar_aplicacion(
			id,
			titulo,
			creador,
			tamano_minimo,
			tamano_preferido,
			redimensionable,
			multiples_instancias
		)
	elif creador.is_valid():
		_aplicaciones[id]["creador"] = creador
	if _ventanas.has(id):
		cerrar(id)
	_crear_ventana(id, titulo, contenido, false, id)


## Abre [param id]. Si la aplicación declara [code]multiples_instancias[/code]
## y ya hay una ventana abierta, crea una instancia independiente en vez de
## reenfocar la existente; si no lo declara, mantiene el comportamiento de
## siempre (reenfocar/restaurar la única ventana).
func abrir_aplicacion(id: String) -> void:
	if not _modal_id.is_empty() or not _aplicaciones.has(id):
		return
	var multiples: bool = bool(_aplicaciones[id].get("multiples_instancias", false))
	if _ventanas.has(id) and not multiples:
		var datos: Dictionary = _ventanas[id]
		if bool(datos.get("minimizada", false)):
			restaurar(id)
		else:
			enfocar(id)
		return
	var id_ventana := id
	if _ventanas.has(id) and multiples:
		id_ventana = _siguiente_id_instancia(id)
	var creador: Callable = _aplicaciones[id]["creador"]
	if not creador.is_valid():
		return
	var creado: Variant = creador.call()
	if not creado is Control:
		if creado is Node:
			(creado as Node).queue_free()
		return
	_crear_ventana(id_ventana, String(_aplicaciones[id]["titulo"]), creado as Control, false, id)


## Sufija con "#2", "#3"... el primer id libre. La primera instancia siempre
## se queda con el id desnudo, así que las llamadas existentes (una sola
## ventana por aplicación) no ven ningún cambio en su id de ventana.
func _siguiente_id_instancia(id_app: String) -> String:
	var numero := 2
	while _ventanas.has("%s#%d" % [id_app, numero]):
		numero += 1
	return "%s#%d" % [id_app, numero]


## Abre [param contenido] como ventana modal: bloquea el resto del shell
## (escritorio, barra, menú y demás ventanas) y atrapa el foco de teclado
## dentro suyo hasta que se cierre con [method cerrar], su botón de cerrar o Esc.
## Al cerrarse, el foco vuelve a quien lo tenía antes de abrirla.
func abrir_modal(id: String, titulo: String, contenido: Control) -> void:
	if id.is_empty() or contenido == null or _ventanas.has(id) or not _modal_id.is_empty():
		return
	_foco_previo_modal = get_viewport().gui_get_focus_owner()
	_menu.visible = false
	_bloqueador_modal = ColorRect.new()
	_bloqueador_modal.name = "BloqueadorModal"
	_bloqueador_modal.color = Color(EstiloSiga.NEGRO, 0.35)
	_bloqueador_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_bloqueador_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bloqueador_modal.z_index = 1002
	add_child(_bloqueador_modal)
	_modal_id = id
	_crear_ventana(id, titulo, contenido, true)
	var primero := _primer_control_enfocable(contenido)
	if primero != null:
		primero.grab_focus()


func minimizar(id: String) -> void:
	if not _ventanas.has(id) or (not _modal_id.is_empty() and id != _modal_id):
		return
	var datos: Dictionary = _ventanas[id]
	var panel: Control = datos["panel"]
	panel.visible = false
	datos["minimizada"] = true
	_actualizar_boton_tarea(id)
	_enfocar_superior()


func restaurar(id: String) -> void:
	if not _ventanas.has(id) or (not _modal_id.is_empty() and id != _modal_id):
		return
	var datos: Dictionary = _ventanas[id]
	var panel: Control = datos["panel"]
	panel.visible = true
	datos["minimizada"] = false
	_limitar_ventana(panel, datos.get("tamano_minimo", Vector2.ONE))
	enfocar(id)


func cerrar(id: String) -> void:
	if not _ventanas.has(id):
		return
	var datos: Dictionary = _ventanas[id]
	var panel: Control = datos["panel"]
	var tarea: Button = datos.get("tarea")
	_ventanas.erase(id)
	if is_instance_valid(panel):
		panel.queue_free()
	if is_instance_valid(tarea):
		tarea.queue_free()
	if _arrastre_id == id:
		_arrastre_id = ""
	if _modal_id == id:
		_cerrar_modal()
	else:
		_enfocar_superior()


func _cerrar_modal() -> void:
	_modal_id = ""
	if is_instance_valid(_bloqueador_modal):
		_bloqueador_modal.queue_free()
	_bloqueador_modal = null
	if is_instance_valid(_foco_previo_modal):
		_foco_previo_modal.grab_focus()
	else:
		_enfocar_superior()
	_foco_previo_modal = null


func enfocar(id: String) -> void:
	if not _ventanas.has(id):
		return
	if not _modal_id.is_empty() and id != _modal_id:
		return
	_z_siguiente += 1
	var datos: Dictionary = _ventanas[id]
	var panel: Control = datos["panel"]
	panel.z_index = Z_MODAL if id == _modal_id else _z_siguiente
	for otro_id in _ventanas:
		var otro: Dictionary = _ventanas[otro_id]
		var activo := String(otro_id) == id and not bool(otro.get("minimizada", false))
		_establecer_titulo_activo(otro["titulo_barra"], activo)
		_actualizar_boton_tarea(String(otro_id))


## Ayuda es una utilidad del propio shell, no lógica de una aplicación de juego.
func activar_ayuda_sistema() -> void:
	if _aplicaciones.has("ayuda-sistema"):
		return
	registrar_aplicacion("ayuda-sistema", tr("ESCRITORIO_AYUDA"), _crear_ayuda_sistema)


func _construir_escritorio() -> void:
	_fondo = ColorRect.new()
	_fondo.name = "FondoCorporativo"
	_fondo.color = FONDO_CORPORATIVO
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fondo)

	_marca = Label.new()
	_marca.name = "MarcaCorporativa"
	_marca.text = tr("ESCRITORIO_MARCA")
	_marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_marca.add_theme_color_override("font_color", Color(CREMA, 0.62))
	_marca.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_marca.offset_left = -330.0
	_marca.offset_top = 14.0
	_marca.offset_right = -16.0
	_marca.offset_bottom = 42.0
	_marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_marca)

	_iconos = VBoxContainer.new()
	_iconos.name = "Lanzadores"
	_iconos.position = _esc_v(Vector2(12, 14))
	_iconos.size = _esc_v(Vector2(132, 360))
	_iconos.add_theme_constant_override("separation", roundi(_esc(8)))
	add_child(_iconos)

	_area_ventanas = Control.new()
	_area_ventanas.name = "AreaVentanas"
	_area_ventanas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_area_ventanas.offset_bottom = -_alto_barra
	_area_ventanas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_area_ventanas)

	_construir_barra()
	_construir_menu()


func _construir_barra() -> void:
	_barra = PanelContainer.new()
	_barra.name = "BarraInferior"
	_barra.anchor_left = 0.0
	_barra.anchor_right = 1.0
	_barra.anchor_top = 1.0
	_barra.anchor_bottom = 1.0
	_barra.offset_top = -_alto_barra
	_barra.offset_bottom = 0.0
	_barra.z_index = 1000
	_barra.add_theme_stylebox_override("panel", _estilo_panel(EstiloSiga.PAPEL, EstiloSiga.NEGRO))
	add_child(_barra)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 5)
	_barra.add_child(fila)

	var boton_menu := Button.new()
	boton_menu.name = "BotonMenu"
	boton_menu.text = tr("ESCRITORIO_MENU")
	boton_menu.custom_minimum_size = _esc_v(Vector2(78, 0))
	_preparar_boton(boton_menu)
	boton_menu.pressed.connect(_alternar_menu)
	fila.add_child(boton_menu)

	_tareas = HBoxContainer.new()
	_tareas.name = "Tareas"
	_tareas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tareas.add_theme_constant_override("separation", 3)
	fila.add_child(_tareas)

	_reloj = Label.new()
	_reloj.name = "RelojNarrativo"
	_reloj.text = tr("ESCRITORIO_RELOJ_VACIO")
	_reloj.custom_minimum_size = _esc_v(Vector2(88, 0))
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reloj.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reloj.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	fila.add_child(_reloj)


func _construir_menu() -> void:
	_menu = PanelContainer.new()
	_menu.name = "MenuSistema"
	_menu.anchor_left = 0.0
	_menu.anchor_right = 0.0
	_menu.anchor_top = 1.0
	_menu.anchor_bottom = 1.0
	_menu.offset_left = 4.0
	_menu.offset_right = _esc(230.0)
	_menu.offset_top = -(_alto_barra + _esc(250.0))
	_menu.offset_bottom = -_alto_barra
	_menu.z_index = 1001
	_menu.visible = false
	_menu.add_theme_stylebox_override("panel", _estilo_panel(EstiloSiga.PAPEL, EstiloSiga.NEGRO))
	add_child(_menu)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 7)
	margen.add_theme_constant_override("margin_right", 7)
	margen.add_theme_constant_override("margin_top", 7)
	margen.add_theme_constant_override("margin_bottom", 7)
	_menu.add_child(margen)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	margen.add_child(columna)

	var cabecera := Label.new()
	cabecera.text = tr("ESCRITORIO_CABECERA")
	cabecera.add_theme_color_override("font_color", PETROLEO)
	columna.add_child(cabecera)

	var separador := HSeparator.new()
	columna.add_child(separador)

	var rotulo_programas := Label.new()
	rotulo_programas.text = tr("ESCRITORIO_PROGRAMAS")
	columna.add_child(rotulo_programas)

	_programas_menu = VBoxContainer.new()
	_programas_menu.add_theme_constant_override("separation", 2)
	columna.add_child(_programas_menu)

	var relleno := Control.new()
	relleno.custom_minimum_size.y = 8
	columna.add_child(relleno)

	var salir := Button.new()
	salir.text = tr("ESCRITORIO_CERRAR_SESION")
	_preparar_boton(salir)
	salir.pressed.connect(_solicitar_salida)
	columna.add_child(salir)


func _crear_lanzador(id: String, titulo: String) -> void:
	var boton := Button.new()
	boton.name = "Lanzador_%s" % id
	boton.text = titulo
	boton.custom_minimum_size = _esc_v(Vector2(118, 48))
	boton.focus_mode = Control.FOCUS_ALL
	_preparar_boton(boton, true)
	boton.gui_input.connect(_al_input_lanzador.bind(id))
	_iconos.add_child(boton)


func _crear_entrada_programa(id: String, titulo: String) -> void:
	var boton := Button.new()
	boton.name = "Programa_%s" % id
	boton.text = titulo
	boton.focus_mode = Control.FOCUS_ALL
	_preparar_boton(boton)
	boton.pressed.connect(_abrir_desde_menu.bind(id))
	_programas_menu.add_child(boton)


func _al_input_lanzador(evento: InputEvent, id: String) -> void:
	if evento is InputEventMouseButton:
		var raton := evento as InputEventMouseButton
		if raton.button_index == MOUSE_BUTTON_LEFT and raton.pressed:
			var boton := get_viewport().gui_get_focus_owner()
			if boton == null or boton.name != "Lanzador_%s" % id:
				for candidato in _iconos.get_children():
					if candidato.name == "Lanzador_%s" % id:
						(candidato as Control).grab_focus()
						break
			if raton.double_click:
				abrir_aplicacion(id)
				get_viewport().set_input_as_handled()
		return
	if evento is InputEventKey:
		var tecla := evento as InputEventKey
		if (
			tecla.pressed
			and not tecla.echo
			and tecla.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
		):
			abrir_aplicacion(id)
			get_viewport().set_input_as_handled()


func _abrir_desde_menu(id: String) -> void:
	_menu.visible = false
	abrir_aplicacion(id)


## [param id_app] es la aplicación registrada de la que vienen las capacidades
## (tamaños, redimensionado); puede diferir de [param id] cuando este es una
## instancia adicional ("explorador#2"). Vacío equivale a usar [param id],
## que es lo que hacen las modales y las llamadas sin varias instancias.
func _crear_ventana(
	id: String, titulo: String, contenido: Control, es_modal: bool = false, id_app: String = ""
) -> void:
	var capacidades: Dictionary = _aplicaciones.get(id_app if not id_app.is_empty() else id, {})
	var tamano_minimo: Vector2 = capacidades.get("tamano_minimo", TAMANO_MINIMO_SERIE)
	var tamano_preferido: Vector2 = capacidades.get("tamano_preferido", TAMANO_PREFERIDO_SERIE)
	var redimensionable: bool = capacidades.get("redimensionable", false)
	var tamano_minimo_esc := _esc_v(tamano_minimo)

	## Control simple (no contenedor) para que el agarre de redimensionado
	## pueda convivir con el resto sin que el layout lo estire a pantalla
	## completa, como haría un segundo hijo de un PanelContainer.
	var panel := Control.new()
	panel.name = "Ventana_%s" % id
	panel.position = _posicion_inicial(_ventanas.size())
	panel.size = _tamano_inicial(tamano_minimo, tamano_preferido)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area_ventanas.add_child(panel)

	var fondo := PanelContainer.new()
	fondo.name = "Fondo"
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo.add_theme_stylebox_override("panel", _estilo_panel(EstiloSiga.PAPEL, EstiloSiga.NEGRO))
	panel.add_child(fondo)

	var columna := VBoxContainer.new()
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columna.add_theme_constant_override("separation", 0)
	fondo.add_child(columna)

	var titulo_barra := PanelContainer.new()
	titulo_barra.name = "BarraTitulo"
	titulo_barra.custom_minimum_size.y = _alto_titulo
	titulo_barra.mouse_filter = Control.MOUSE_FILTER_STOP
	titulo_barra.gui_input.connect(_al_input_titulo.bind(id))
	columna.add_child(titulo_barra)

	var fila_titulo := HBoxContainer.new()
	fila_titulo.add_theme_constant_override("separation", 4)
	titulo_barra.add_child(fila_titulo)

	var etiqueta := Label.new()
	etiqueta.text = titulo
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_titulo.add_child(etiqueta)

	if not es_modal:
		var minimizar_boton := Button.new()
		minimizar_boton.text = "—"
		minimizar_boton.tooltip_text = tr("ESCRITORIO_MINIMIZAR")
		minimizar_boton.custom_minimum_size = _esc_v(Vector2(31, 24))
		_preparar_boton(minimizar_boton)
		minimizar_boton.pressed.connect(minimizar.bind(id))
		fila_titulo.add_child(minimizar_boton)

	var cerrar_boton := Button.new()
	cerrar_boton.text = String.chr(0xD7)
	cerrar_boton.tooltip_text = tr("ESCRITORIO_CERRAR")
	cerrar_boton.custom_minimum_size = _esc_v(Vector2(31, 24))
	_preparar_boton(cerrar_boton)
	cerrar_boton.pressed.connect(cerrar.bind(id))
	fila_titulo.add_child(cerrar_boton)

	var marco := MarginContainer.new()
	marco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marco.add_theme_constant_override("margin_left", 3)
	marco.add_theme_constant_override("margin_right", 3)
	marco.add_theme_constant_override("margin_top", 3)
	marco.add_theme_constant_override("margin_bottom", 3)
	columna.add_child(marco)

	contenido.name = "Contenido"
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if contenido.get_parent() != null:
		contenido.reparent(marco, false)
	else:
		marco.add_child(contenido)
	contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var tarea := Button.new()
	tarea.name = "Tarea_%s" % id
	tarea.text = titulo
	tarea.custom_minimum_size.x = _esc(122)
	_preparar_boton(tarea)
	tarea.pressed.connect(_al_pulsar_tarea.bind(id))
	if not es_modal:
		_tareas.add_child(tarea)

	if redimensionable and not es_modal:
		var lado := _esc(14.0)
		var agarre := ColorRect.new()
		agarre.name = "AgarreRedimension"
		agarre.color = Color(EstiloSiga.NEGRO, 0.5)
		agarre.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		agarre.mouse_filter = Control.MOUSE_FILTER_STOP
		agarre.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		agarre.offset_left = -lado
		agarre.offset_top = -lado
		agarre.offset_right = 0.0
		agarre.offset_bottom = 0.0
		agarre.gui_input.connect(_al_input_agarre.bind(id))
		panel.add_child(agarre)

	_ventanas[id] = {
		"panel": panel,
		"titulo_barra": titulo_barra,
		"tarea": tarea,
		"minimizada": false,
		"modal": es_modal,
		"tamano_minimo": tamano_minimo_esc,
	}
	_limitar_ventana(panel, tamano_minimo_esc)
	enfocar(id)


func _al_pulsar_tarea(id: String) -> void:
	if not _ventanas.has(id):
		return
	var datos: Dictionary = _ventanas[id]
	if bool(datos.get("minimizada", false)):
		restaurar(id)
		return
	var panel: Control = datos["panel"]
	var es_superior := panel.z_index == _z_mayor_visible()
	if es_superior:
		minimizar(id)
	else:
		enfocar(id)


func _al_input_titulo(evento: InputEvent, id: String) -> void:
	if not _ventanas.has(id):
		return
	if evento is InputEventMouseButton:
		var raton := evento as InputEventMouseButton
		if raton.button_index != MOUSE_BUTTON_LEFT:
			return
		if raton.pressed:
			_arrastre_id = id
			enfocar(id)
		else:
			_arrastre_id = ""
		get_viewport().set_input_as_handled()
		return
	if evento is InputEventMouseMotion and _arrastre_id == id:
		var movimiento := evento as InputEventMouseMotion
		var datos: Dictionary = _ventanas[id]
		var panel: Control = datos["panel"]
		panel.position += movimiento.relative
		_limitar_ventana(panel, datos.get("tamano_minimo", Vector2.ONE))
		get_viewport().set_input_as_handled()


## Arrastre del agarre inferior-derecho. Solo existe en ventanas cuya
## aplicación declaró [code]redimensionable = true[/code]; el resto ni
## siquiera tiene el control de arrastre en su árbol.
func _al_input_agarre(evento: InputEvent, id: String) -> void:
	if not _ventanas.has(id):
		return
	if evento is InputEventMouseButton:
		var raton := evento as InputEventMouseButton
		if raton.button_index != MOUSE_BUTTON_LEFT:
			return
		if raton.pressed:
			_redimension_id = id
			enfocar(id)
		else:
			_redimension_id = ""
		get_viewport().set_input_as_handled()
		return
	if evento is InputEventMouseMotion and _redimension_id == id:
		var movimiento := evento as InputEventMouseMotion
		var datos: Dictionary = _ventanas[id]
		var panel: Control = datos["panel"]
		panel.size += movimiento.relative
		_limitar_ventana(panel, datos.get("tamano_minimo", Vector2.ONE))
		get_viewport().set_input_as_handled()


## Recorta tamaño y posición al área disponible del escritorio y, si se da
## [param tamano_minimo], no deja que la ventana baje de ahí (el agarre de
## redimensionado y cualquier reflujo por cambio de tamaño del escritorio
## comparten esta misma regla).
func _limitar_ventana(panel: Control, tamano_minimo: Vector2 = Vector2.ONE) -> void:
	# El mínimo declarado NUNCA se viola, aunque el área disponible sea menor
	# (un escritorio diminuto o, como en las pruebas de humo sin ventana real,
	# de 64×64): el límite superior se ensancha para no pedirle a [method
	# clampf] un rango imposible, y la ventana puede quedar más grande que el
	# área en vez de más pequeña que su mínimo.
	var ancho_disponible := maxf(maxf(_area_ventanas.size.x, 1.0), tamano_minimo.x)
	var alto_disponible := maxf(maxf(_area_ventanas.size.y, _alto_titulo), tamano_minimo.y)
	panel.size.x = clampf(panel.size.x, tamano_minimo.x, ancho_disponible)
	panel.size.y = clampf(panel.size.y, tamano_minimo.y, alto_disponible)
	var minimo_pos_x := minf(0.0, -panel.size.x + _ancho_titulo_recuperable)
	var maximo_pos_x := maxf(0.0, ancho_disponible - _ancho_titulo_recuperable)
	var maximo_pos_y := maxf(0.0, alto_disponible - _alto_titulo)
	panel.position.x = clampf(panel.position.x, minimo_pos_x, maximo_pos_x)
	panel.position.y = clampf(panel.position.y, 0.0, maximo_pos_y)


func _tamano_inicial(tamano_minimo: Vector2, tamano_preferido: Vector2) -> Vector2:
	return Vector2(
		minf(
			_esc(tamano_preferido.x),
			maxf(_esc(tamano_minimo.x), _area_ventanas.size.x - _esc(86.0))
		),
		minf(
			_esc(tamano_preferido.y),
			maxf(_esc(tamano_minimo.y), _area_ventanas.size.y - _esc(64.0))
		)
	)


func _posicion_inicial(indice: int) -> Vector2:
	var desplazamiento := float(indice % 6) * _esc(24.0)
	return Vector2(_esc(156.0) + desplazamiento, _esc(42.0) + desplazamiento)


func _al_redimensionar() -> void:
	for id in _ventanas:
		var datos: Dictionary = _ventanas[id]
		_limitar_ventana(datos["panel"], datos.get("tamano_minimo", Vector2.ONE))


func _enfocar_superior() -> void:
	var elegido := ""
	var mayor := -1
	for id in _ventanas:
		var datos: Dictionary = _ventanas[id]
		if bool(datos.get("minimizada", false)):
			continue
		var panel: Control = datos["panel"]
		if panel.z_index > mayor:
			mayor = panel.z_index
			elegido = String(id)
	if not elegido.is_empty():
		enfocar(elegido)


func _z_mayor_visible() -> int:
	var mayor := -1
	for id in _ventanas:
		var datos: Dictionary = _ventanas[id]
		if bool(datos.get("minimizada", false)):
			continue
		mayor = maxi(mayor, int((datos["panel"] as Control).z_index))
	return mayor


func _establecer_titulo_activo(barra_titulo: PanelContainer, activo: bool) -> void:
	var color := PETROLEO if activo else PETROLEO_INACTIVO
	barra_titulo.add_theme_stylebox_override("panel", _estilo_panel(color, EstiloSiga.NEGRO))


func _actualizar_boton_tarea(id: String) -> void:
	if not _ventanas.has(id):
		return
	var datos: Dictionary = _ventanas[id]
	var tarea: Button = datos["tarea"]
	var panel: Control = datos["panel"]
	var minimizada := bool(datos.get("minimizada", false))
	tarea.button_pressed = not minimizada and panel.z_index == _z_mayor_visible()


func _alternar_menu() -> void:
	_menu.visible = not _menu.visible
	if _menu.visible:
		var primero := _primer_control_en(_programas_menu)
		if primero != null:
			primero.grab_focus()


func _primer_control_en(nodo: Node) -> Control:
	for hijo in nodo.get_children():
		if hijo is Control and (hijo as Control).focus_mode != Control.FOCUS_NONE:
			return hijo as Control
	return null


## A diferencia de [method _primer_control_en], baja recursivamente: el
## contenido de una modal puede anidar contenedores antes del primer control.
func _primer_control_enfocable(nodo: Node) -> Control:
	if nodo is Control and (nodo as Control).focus_mode != Control.FOCUS_NONE:
		return nodo as Control
	for hijo in nodo.get_children():
		var encontrado := _primer_control_enfocable(hijo)
		if encontrado != null:
			return encontrado
	return null


## Controles enfocables de la ventana modal activa, en orden de aparición.
func _controles_enfocables_modal() -> Array[Control]:
	var resultado: Array[Control] = []
	if _modal_id.is_empty() or not _ventanas.has(_modal_id):
		return resultado
	var panel: Control = _ventanas[_modal_id]["panel"]
	_recolectar_enfocables(panel, resultado)
	return resultado


func _recolectar_enfocables(nodo: Node, resultado: Array[Control]) -> void:
	if nodo is Control and (nodo as Control).focus_mode != Control.FOCUS_NONE:
		resultado.append(nodo as Control)
	for hijo in nodo.get_children():
		_recolectar_enfocables(hijo, resultado)


func _solicitar_salida() -> void:
	_menu.visible = false
	salir_solicitado.emit()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey:
		return
	var tecla := evento as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	if tecla.keycode == KEY_ESCAPE:
		if not _modal_id.is_empty():
			cerrar(_modal_id)
			get_viewport().set_input_as_handled()
		elif _menu.visible:
			_menu.visible = false
			get_viewport().set_input_as_handled()
		return
	if tecla.keycode == KEY_TAB and not _modal_id.is_empty():
		_ciclar_foco_modal(tecla.shift_pressed)
		get_viewport().set_input_as_handled()


## El foco por defecto de Godot recorre todo el árbol visible; con una modal
## abierta debe quedarse dentro de ella, para no "escapar" al escritorio o la
## barra que hay detrás del bloqueador.
func _ciclar_foco_modal(hacia_atras: bool) -> void:
	var controles := _controles_enfocables_modal()
	if controles.is_empty():
		return
	var actual := get_viewport().gui_get_focus_owner()
	var indice := controles.find(actual)
	if indice == -1:
		controles[0].grab_focus()
		return
	var siguiente := (indice - 1 + controles.size()) if hacia_atras else (indice + 1)
	controles[siguiente % controles.size()].grab_focus()


func _crear_ayuda_sistema() -> Control:
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 16)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	margen.add_child(columna)

	var titulo := Label.new()
	titulo.text = tr("ESCRITORIO_AYUDA_TITULO")
	titulo.add_theme_font_size_override("font_size", 18)
	columna.add_child(titulo)

	var texto := Label.new()
	texto.text = (
		"\n"
		. join(
			[
				tr("ESCRITORIO_AYUDA_ABRIR"),
				tr("ESCRITORIO_AYUDA_TECLADO"),
				tr("ESCRITORIO_AYUDA_ARRASTRAR"),
				tr("ESCRITORIO_AYUDA_BARRA"),
				tr("ESCRITORIO_AYUDA_CERRAR_MENU"),
			]
		)
	)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_child(texto)
	return margen


func _preparar_boton(boton: Button, icono_escritorio: bool = false) -> void:
	boton.focus_mode = Control.FOCUS_ALL
	var normal := _estilo_panel(Color(EstiloSiga.PAPEL_BOTON, 0.96), EstiloSiga.GRIS_OSCURO)
	if icono_escritorio:
		normal = _estilo_panel(Color(FONDO_CORPORATIVO, 0.35), Color(FONDO_CORPORATIVO, 0.0))
	boton.add_theme_stylebox_override("normal", normal)
	boton.add_theme_stylebox_override(
		"hover", _estilo_panel(EstiloSiga.BLANCO, EstiloSiga.GRIS_OSCURO)
	)
	boton.add_theme_stylebox_override(
		"pressed", _estilo_panel(EstiloSiga.PAPEL_PULSADO, EstiloSiga.NEGRO)
	)
	var foco := _estilo_panel(Color(0, 0, 0, 0), CREMA)
	foco.border_width_left = 2
	foco.border_width_top = 2
	foco.border_width_right = 2
	foco.border_width_bottom = 2
	boton.add_theme_stylebox_override("focus", foco)
	boton.add_theme_color_override("font_color", CREMA if icono_escritorio else EstiloSiga.NEGRO)
	boton.add_theme_color_override(
		"font_focus_color", CREMA if icono_escritorio else EstiloSiga.NEGRO
	)


func _estilo_panel(fondo: Color, borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.border_width_left = 1
	estilo.border_width_top = 1
	estilo.border_width_right = 1
	estilo.border_width_bottom = 1
	estilo.content_margin_left = 5.0
	estilo.content_margin_right = 5.0
	estilo.content_margin_top = 3.0
	estilo.content_margin_bottom = 3.0
	return estilo
