## Overlay táctil mínimo para gameplay 3D (#98).
##
## No implementa interacción ni menú: publica las mismas acciones semánticas
## que teclado/mando mediante InputEventAction. Al ser Controls normales, el
## toque del botón queda consumido por GUI y no se convierte a la vez en
## movimiento/mirada del Caminante.
extends Node

const ACCION_INTERACTUAR: StringName = &"interactuar"
const ACCION_CANCELAR: StringName = &"cancelar"
const CAPA := 19
const TAMANO_BOTON := Vector2(112.0, 64.0)
const MARGEN := 24.0

var _capa: CanvasLayer
var _acciones: HBoxContainer
var _boton_interactuar: Button
var _boton_cancelar: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_overlay()


func _process(_delta: float) -> void:
	if not is_instance_valid(_acciones):
		return
	var dia := get_parent()
	var caminante = dia.get("_caminante") if dia != null else null
	var fisica_activa: bool = (
		is_instance_valid(caminante)
		and caminante.has_method("is_physics_processing")
		and caminante.is_physics_processing()
	)
	var pantalla_abierta: bool = dia != null and dia.get("_pantalla") != null
	var entrada_activa: bool = dia != null and dia.get("_entrada") != null
	var visible: bool = debe_mostrar_overlay(
		DisplayServer.is_touchscreen_available(),
		fisica_activa,
		get_tree().paused,
		pantalla_abierta,
		entrada_activa,
	)
	_acciones.visible = visible
	if not visible:
		return

	var texto_interaccion := ""
	if is_instance_valid(caminante):
		texto_interaccion = String(caminante.get("_texto_interaccion_actual")).strip_edges()
	_boton_interactuar.visible = not texto_interaccion.is_empty()
	_boton_interactuar.text = texto_interaccion


static func debe_mostrar_overlay(
	tactil_disponible: bool,
	fisica_activa: bool,
	arbol_pausado: bool,
	pantalla_abierta: bool,
	entrada_activa: bool,
) -> bool:
	return (
		tactil_disponible
		and fisica_activa
		and not arbol_pausado
		and not pantalla_abierta
		and not entrada_activa
	)


static func evento_accion(accion: StringName, pulsada: bool) -> InputEventAction:
	var evento := InputEventAction.new()
	evento.action = accion
	evento.pressed = pulsada
	evento.strength = 1.0 if pulsada else 0.0
	return evento


func _montar_overlay() -> void:
	_capa = CanvasLayer.new()
	_capa.name = "ControlesTactiles98"
	_capa.layer = CAPA
	add_child(_capa)

	_acciones = HBoxContainer.new()
	_acciones.name = "Acciones"
	_acciones.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_acciones.offset_left = -(TAMANO_BOTON.x * 2.0 + MARGEN * 3.0)
	_acciones.offset_top = -(TAMANO_BOTON.y + MARGEN)
	_acciones.offset_right = -MARGEN
	_acciones.offset_bottom = -MARGEN
	_acciones.add_theme_constant_override("separation", int(MARGEN))
	_acciones.visible = false
	_capa.add_child(_acciones)

	_boton_cancelar = _crear_boton("Cancelar", "↩")
	_boton_cancelar.button_down.connect(_emitir_accion.bind(ACCION_CANCELAR, true))
	_boton_cancelar.button_up.connect(_emitir_accion.bind(ACCION_CANCELAR, false))
	_acciones.add_child(_boton_cancelar)

	_boton_interactuar = _crear_boton("Interactuar", "")
	_boton_interactuar.button_down.connect(_emitir_accion.bind(ACCION_INTERACTUAR, true))
	_boton_interactuar.button_up.connect(_emitir_accion.bind(ACCION_INTERACTUAR, false))
	_acciones.add_child(_boton_interactuar)


func _crear_boton(nombre: String, texto: String) -> Button:
	var boton := Button.new()
	boton.name = nombre
	boton.text = texto
	boton.custom_minimum_size = TAMANO_BOTON
	boton.focus_mode = Control.FOCUS_NONE
	boton.theme = EstiloSiga.tema()
	return boton


func _emitir_accion(accion: StringName, pulsada: bool) -> void:
	Input.parse_input_event(evento_accion(accion, pulsada))
