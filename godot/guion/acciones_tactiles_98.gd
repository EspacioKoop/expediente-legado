class_name AccionesTactiles98
extends CanvasLayer

## Overlay táctil mínimo de #98.
##
## Los botones no llaman gameplay directamente: TouchScreenButton publica las
## acciones semánticas existentes de InputMap. El caminante decide cuándo el
## gameplay 3D está disponible; este nodo solo presenta esas acciones.

const ACCION_INTERACTUAR := "interactuar"
const ACCION_CANCELAR := "cancelar"
const TAMANO_BOTON := 88.0
const RADIO_BOTON := TAMANO_BOTON * 0.5
const MARGEN := 24.0

var _raiz_visual: Control
var _panel_interactuar: PanelContainer
var _panel_cancelar: PanelContainer
var _boton_interactuar: TouchScreenButton
var _boton_cancelar: TouchScreenButton


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	get_viewport().size_changed.connect(_reposicionar)
	_reposicionar()
	_actualizar_visibilidad()


func _process(_delta: float) -> void:
	_actualizar_visibilidad()


static func debe_mostrarse(
	fisica_activa: bool,
	arbol_pausado: bool,
	dialogo_activo: bool,
	puntero_capturado: bool,
) -> bool:
	return fisica_activa and not arbol_pausado and not dialogo_activo and puntero_capturado


func _gameplay_activo() -> bool:
	var caminante := get_parent()
	if caminante == null or not caminante.has_method("acciones_tactiles_disponibles"):
		return false
	return bool(caminante.acciones_tactiles_disponibles())


func _actualizar_visibilidad() -> void:
	var activa := DisplayServer.is_touchscreen_available() and _gameplay_activo()
	if _raiz_visual != null:
		_raiz_visual.visible = activa
	if _boton_interactuar != null:
		_boton_interactuar.visible = activa
	if _boton_cancelar != null:
		_boton_cancelar.visible = activa


func _construir() -> void:
	_raiz_visual = Control.new()
	_raiz_visual.name = "Visual"
	_raiz_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz_visual)

	_panel_interactuar = _crear_panel("InteractuarVisual", "USAR")
	_panel_cancelar = _crear_panel("CancelarVisual", "ATRÁS")
	_raiz_visual.add_child(_panel_interactuar)
	_raiz_visual.add_child(_panel_cancelar)

	_boton_interactuar = _crear_boton("Interactuar", ACCION_INTERACTUAR)
	_boton_cancelar = _crear_boton("Cancelar", ACCION_CANCELAR)
	add_child(_boton_interactuar)
	add_child(_boton_cancelar)


func _crear_boton(nombre: String, accion: String) -> TouchScreenButton:
	var boton := TouchScreenButton.new()
	boton.name = nombre
	boton.action = accion
	boton.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	boton.passby_press = false
	boton.shape_visible = false
	var forma := CircleShape2D.new()
	forma.radius = RADIO_BOTON
	boton.shape = forma
	return boton


func _crear_panel(nombre: String, texto: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = nombre
	panel.custom_minimum_size = Vector2(TAMANO_BOTON, TAMANO_BOTON)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.04, 0.05, 0.06, 0.64)
	estilo.border_color = Color(0.78, 0.82, 0.76, 0.78)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(int(RADIO_BOTON))
	panel.add_theme_stylebox_override("panel", estilo)

	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(etiqueta)
	return panel


func _reposicionar() -> void:
	if _raiz_visual == null:
		return
	var tamano := get_viewport().get_visible_rect().size
	var centro_interactuar := tamano - Vector2(MARGEN + RADIO_BOTON, MARGEN + RADIO_BOTON)
	var centro_cancelar := centro_interactuar - Vector2(TAMANO_BOTON + 18.0, 0.0)

	_panel_interactuar.position = centro_interactuar - Vector2.ONE * RADIO_BOTON
	_panel_cancelar.position = centro_cancelar - Vector2.ONE * RADIO_BOTON
	_boton_interactuar.position = centro_interactuar
	_boton_cancelar.position = centro_cancelar
