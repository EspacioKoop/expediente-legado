## Prólogo de epígrafes antes de la cinemática 3D de créditos.
##
## Fondo NEGRO puro, texto blanco centrado, fundidos de entrada/salida por cita.
## Respeta reducción de movimiento (texto estático, sin fundido), permite saltar con acción semántica
## y transiciona limpio a _iniciar_apertura_creditos().
class_name EpigrafesInicio
extends Control

signal terminada

## Tiempos por cita (segundos).
const TIEMPO_FADE_IN := 2.0
const TIEMPO_RETENCION_MIN := 2.0
const TIEMPO_RETENCION_MAX := 4.0
const TIEMPO_FADE_OUT := 1.5

## Citas: texto + atribución. El texto de Eliot es un placeholder intencional;
## se podrá sustituir por un texto autorizado sin modificar la lógica.
## No añadas versos ni letra nueva.
static var citas := [
	{"texto": '"We shall not cease from exploration… first time"', "atribucion": "— T. S. Eliot"},
	{"texto": '"There must be some kind of way out of here"', "atribucion": "— Bob Dylan"},
]

var _indice_cita := 0
var _transcurrido := 0.0
var _reproduciendo := false
var _reduccion_movimiento := false
var _fondo: ColorRect
var _texto: Label
var _atribucion: Label
var _cita_actual: Dictionary


func _ready() -> void:
	_montar()
	visible = false


func _montar() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_fondo = ColorRect.new()
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color.BLACK
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)

	var contenedor := CenterContainer.new()
	contenedor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contenedor)

	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.custom_minimum_size.x = minf(get_viewport_rect().size.x * 0.82, 1100.0)
	caja.add_theme_constant_override("separation", 16)
	contenedor.add_child(caja)

	_texto = Label.new()
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_font_size_override("font_size", 32)
	_texto.add_theme_color_override("font_color", Color.WHITE)
	_texto.add_theme_color_override("font_outline_color", Color.BLACK)
	_texto.add_theme_constant_override("outline_size", 3)
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(_texto)

	_atribucion = Label.new()
	_atribucion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_atribucion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_atribucion.add_theme_font_size_override("font_size", 18)
	_atribucion.add_theme_color_override("font_color", Color(0.85, 0.82, 0.55))
	_atribucion.add_theme_color_override("font_outline_color", Color.BLACK)
	_atribucion.add_theme_constant_override("outline_size", 2)
	_atribucion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atribucion.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(_atribucion)


## Inicia la secuencia de epígrafes.
func iniciar() -> void:
	_reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	_indice_cita = 0
	_transcurrido = 0.0
	_reproduciendo = true
	visible = true
	_mostrar_cita_actual()


func saltar() -> void:
	if not _reproduciendo:
		return
	_terminar()


func _process(delta: float) -> void:
	if not _reproduciendo:
		return

	_transcurrido += delta
	var cita := _cita_actual
	var duracion_total := _duracion_cita()

	if _transcurrido >= duracion_total:
		_siguiente_cita()
		return

	_actualizar_opacidad(cita, duracion_total)


func _unhandled_input(evento: InputEvent) -> void:
	if not _reproduciendo:
		return
	if evento.is_action_pressed("interactuar") or evento.is_action_pressed("cancelar"):
		saltar()
		get_viewport().set_input_as_handled()
	if evento is InputEventMouseButton:
		var click := evento as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			saltar()
			get_viewport().set_input_as_handled()


func _duracion_cita() -> float:
	if _reduccion_movimiento:
		return 2.0
	return TIEMPO_FADE_IN + TIEMPO_RETENCION_MAX + TIEMPO_FADE_OUT


func _mostrar_cita_actual() -> void:
	if _indice_cita >= citas.size():
		_terminar()
		return

	_cita_actual = citas[_indice_cita]
	_texto.text = _cita_actual["texto"]
	_atribucion.text = _cita_actual["atribucion"]
	_transcurrido = 0.0

	if _reduccion_movimiento:
		# Con reducción de movimiento: presentar cada cita estática durante 2 s
		_texto.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_atribucion.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		_texto.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_atribucion.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _actualizar_opacidad(_cita: Dictionary, duracion_total: float) -> void:
	var avance := clampf(_transcurrido / duracion_total, 0.0, 1.0)
	var alfa: float

	if _transcurrido < TIEMPO_FADE_IN:
		# Fade in: 0 -> 1
		alfa = avance * (1.0 / (TIEMPO_FADE_IN / duracion_total))
	elif _transcurrido < TIEMPO_FADE_IN + TIEMPO_RETENCION_MAX:
		# Retención: 1
		alfa = 1.0
	else:
		# Fade out: 1 -> 0
		var inicio_fade_out := TIEMPO_FADE_IN + TIEMPO_RETENCION_MAX
		var avance_fade_out := clampf((_transcurrido - inicio_fade_out) / TIEMPO_FADE_OUT, 0.0, 1.0)
		alfa = 1.0 - avance_fade_out

	_texto.modulate = Color(1.0, 1.0, 1.0, alfa)
	_atribucion.modulate = Color(1.0, 1.0, 1.0, alfa)


func _siguiente_cita() -> void:
	_indice_cita += 1
	if _indice_cita >= citas.size():
		_terminar()
	else:
		_mostrar_cita_actual()


func _terminar() -> void:
	_reproduciendo = false
	visible = false
	terminada.emit()
