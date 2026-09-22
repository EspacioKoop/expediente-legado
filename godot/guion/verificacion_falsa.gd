## Verificación falsa heredada de la capa Prometeo del legado (#1029).
##
## La aparición es el evento: confirmar/cancelar no decide Tarot. La UI solo
## presenta el absurdo; la adquisición se delega en la frontera común de
## Prometeo para conservar posesión por vuelta + memoria fantasma.
class_name VerificacionFalsa
extends Control

signal cerrada

const PROBABILIDAD := 0.3
const RUTA_TEXTOS := "res://datos/verificacion_falsa_textos.json"

var _textos: Dictionary = {}
var _pregunta: Label
var _confirmar: Button


static func debe_mostrar(valor_azar: float) -> bool:
	return valor_azar >= 0.0 and valor_azar < PROBABILIDAD


static func registrar(estado: Dictionary) -> bool:
	return Prometeo.desbloquear_carta_en_estado(estado, "el-diablo")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_textos = _cargar_textos()
	_montar()


func mostrar(indice_pregunta: int = -1) -> void:
	var preguntas: Array = _textos.get("preguntas", [])
	if not preguntas.is_empty():
		var indice := indice_pregunta
		if indice < 0 or indice >= preguntas.size():
			indice = randi_range(0, preguntas.size() - 1)
		_pregunta.text = String(preguntas[indice])
	visible = true
	_confirmar.grab_focus()


func ocultar() -> void:
	if not visible:
		return
	visible = false
	cerrada.emit()


func _montar() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.0, 0.0, 0.0, 0.82)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 300)
	panel.theme = EstiloSiga.tema()
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)

	var titulo := Label.new()
	titulo.text = String(_textos.get("titulo", ""))
	caja.add_child(titulo)

	_pregunta = Label.new()
	_pregunta.name = "Pregunta"
	_pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_pregunta)

	for texto in _textos.get("opciones", []):
		var opcion := CheckButton.new()
		opcion.text = String(texto)
		caja.add_child(opcion)

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 10)
	caja.add_child(acciones)

	var cancelar := Button.new()
	cancelar.text = String(_textos.get("cancelar", ""))
	cancelar.pressed.connect(ocultar)
	acciones.add_child(cancelar)

	_confirmar = Button.new()
	_confirmar.name = "Confirmar"
	_confirmar.text = String(_textos.get("confirmar", ""))
	_confirmar.pressed.connect(ocultar)
	acciones.add_child(_confirmar)


func _cargar_textos() -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return datos if datos is Dictionary else {}
