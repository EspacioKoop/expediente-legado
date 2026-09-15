## Ajuste de composición del HUD por fase (#397) e inventario transversal (#97).
##
## Controller hijo: conserva `dia_clima_app.gd` como raíz histórica y observa la
## fase efectiva de Jornada. Gobierna el slot ESTADO, una tarjeta transitoria
## de fase y la superficie modal del inventario; prompts y diálogo siguen siendo
## responsabilidad de HUDLayer.
extends Node

const DURACION_TARJETA_FASE := 1.5
const NOMBRES_FASE := {
	"archivo": "ARCHIVO · PLANTA 4",
	"trayecto": "TRAYECTO",
	"casa": "CASA",
	"sueño": "SUEÑO",
}

var _fase_anterior := ""
var _tarjeta_fase: PanelContainer
var _texto_fase: Label
var _temporizador_fase: Timer
var _inventario_panel: InventarioMenuApp
var _mouse_previo := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_temporizador_fase = Timer.new()
	_temporizador_fase.name = "TemporizadorTarjetaFase"
	_temporizador_fase.one_shot = true
	_temporizador_fase.wait_time = DURACION_TARJETA_FASE
	_temporizador_fase.timeout.connect(_ocultar_tarjeta_fase)
	add_child(_temporizador_fase)


func _unhandled_input(evento: InputEvent) -> void:
	if (
		is_instance_valid(_inventario_panel)
		and _inventario_panel.visible
		and evento.is_action_pressed("cancelar")
	):
		_cerrar_inventario()
		get_viewport().set_input_as_handled()
		return
	if not evento.is_action_pressed("inventario"):
		return
	if is_instance_valid(_inventario_panel) and _inventario_panel.visible:
		_cerrar_inventario()
	else:
		_abrir_inventario()
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var jornada = dia.get("jornada")
	if not jornada is Dictionary:
		return
	var fase := String(jornada.get("fase", ""))
	if fase == _fase_anterior:
		return
	var hud = dia.get("_hud_prioridades")
	if not hud is HUDLayer:
		return
	# La entrada 3D oculta el HUD completo. No consumimos la tarjeta detrás de la
	# cinemática: la fase se confirma cuando el HUD vuelve a estar disponible.
	if not hud.visible:
		return
	_fase_anterior = fase
	_sincronizar_estado_hud(hud, fase)
	_mostrar_tarjeta_fase(hud, fase)


func _sincronizar_estado_hud(hud: HUDLayer, fase: String) -> void:
	if fase == "archivo":
		hud.activar(HUDLayer.ESTADO)
	else:
		hud.desactivar(HUDLayer.ESTADO)


func _mostrar_tarjeta_fase(hud: HUDLayer, fase: String) -> void:
	if not NOMBRES_FASE.has(fase):
		return
	_asegurar_tarjeta_fase(hud)
	_texto_fase.text = String(NOMBRES_FASE[fase])
	hud.activar(HUDLayer.FASE)
	_temporizador_fase.start(DURACION_TARJETA_FASE)


func _asegurar_tarjeta_fase(hud: HUDLayer) -> void:
	if is_instance_valid(_tarjeta_fase):
		return
	_tarjeta_fase = PanelContainer.new()
	_tarjeta_fase.name = "TarjetaFase"
	_tarjeta_fase.theme = EstiloSiga.tema()
	_tarjeta_fase.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_tarjeta_fase.offset_left = -180.0
	_tarjeta_fase.offset_top = 30.0
	_tarjeta_fase.offset_right = 180.0
	_tarjeta_fase.offset_bottom = 80.0
	_tarjeta_fase.visible = false
	hud.add_child(_tarjeta_fase)

	_texto_fase = Label.new()
	_texto_fase.name = "TextoFase"
	_texto_fase.custom_minimum_size = Vector2(340.0, 42.0)
	_texto_fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto_fase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tarjeta_fase.add_child(_texto_fase)

	hud.registrar(HUDLayer.FASE, _tarjeta_fase)


func _abrir_inventario() -> void:
	if get_tree().paused:
		return
	var dia := get_parent()
	if dia == null:
		return
	var hud = dia.get("_hud_prioridades")
	var partida_actual = dia.get("partida")
	if not hud is HUDLayer or not partida_actual is Partida or not hud.visible:
		return
	if hud.esta_activa(HUDLayer.MODAL):
		return
	_asegurar_inventario(hud)
	_mouse_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_inventario_panel.abrir(partida_actual.estado)
	hud.activar(HUDLayer.MODAL)
	get_tree().paused = true


func _asegurar_inventario(hud: HUDLayer) -> void:
	if is_instance_valid(_inventario_panel):
		return
	_inventario_panel = InventarioMenuApp.new()
	_inventario_panel.name = "InventarioModal"
	_inventario_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_inventario_panel.volver.connect(_cerrar_inventario)
	hud.add_child(_inventario_panel)
	hud.registrar(HUDLayer.MODAL, _inventario_panel)


func _cerrar_inventario() -> void:
	if not is_instance_valid(_inventario_panel) or not _inventario_panel.visible:
		return
	_inventario_panel.visible = false
	var dia := get_parent()
	var hud = dia.get("_hud_prioridades") if dia != null else null
	if hud is HUDLayer:
		hud.desactivar(HUDLayer.MODAL)
	get_tree().paused = false
	Input.mouse_mode = _mouse_previo


func _ocultar_tarjeta_fase() -> void:
	var dia := get_parent()
	if dia == null:
		return
	var hud = dia.get("_hud_prioridades")
	if hud is HUDLayer:
		hud.desactivar(HUDLayer.FASE)
