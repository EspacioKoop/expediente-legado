class_name EstresPeriferia
extends CanvasLayer

const ALPHA_MAX := 0.16
var _capa: ColorRect

func _init() -> void:
	layer = 20
	_capa = ColorRect.new()
	_capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.color = Color(0.08, 0.0, 0.02, 0.0)
	add_child(_capa)

func sincronizar(nivel: float, _reduccion_movimiento: bool = false) -> void:
	var normalizado := clampf(nivel, 0.0, 1.0)
	_capa.color.a = normalizado * ALPHA_MAX
	visible = not is_zero_approx(normalizado)

func intensidad() -> float:
	return _capa.color.a
