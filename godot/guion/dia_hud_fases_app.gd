## Ajuste de composición del HUD por fase (#397).
##
## Controller hijo: conserva `dia_clima_app.gd` como raíz histórica y observa la
## fase efectiva de Jornada. Gobierna el slot ESTADO y una tarjeta transitoria
## de fase; prompts, diálogo y modales siguen siendo responsabilidad de HUDLayer.
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


func _ready() -> void:
	_temporizador_fase = Timer.new()
	_temporizador_fase.name = "TemporizadorTarjetaFase"
	_temporizador_fase.one_shot = true
	_temporizador_fase.wait_time = DURACION_TARJETA_FASE
	_temporizador_fase.timeout.connect(_ocultar_tarjeta_fase)
	add_child(_temporizador_fase)


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


func _ocultar_tarjeta_fase() -> void:
	var dia := get_parent()
	if dia == null:
		return
	var hud = dia.get("_hud_prioridades")
	if hud is HUDLayer:
		hud.desactivar(HUDLayer.FASE)
