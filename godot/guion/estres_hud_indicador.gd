## Indicador no verbal de estrés/paranoia para el HUD (#952).
##
## El estado interno nunca se presenta como cifra, porcentaje o barra. El jugador
## ve un ojo estable rodeado por cuatro segmentos; cuantos más segmentos activos,
## mayor es la tensión. La forma sigue siendo legible sin depender del color.
extends Control

const SEGMENTOS := 4
const RADIO := 11.0
const GROSOR := 2.0
const ANGULO_SEGMENTO := TAU / 4.0
const HUECO := 0.22

var _segmentos_activos := 1


func _ready() -> void:
	custom_minimum_size = Vector2(32.0, 32.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configurar_segmentos(cantidad: int) -> void:
	var nueva := clampi(cantidad, 1, SEGMENTOS)
	if nueva == _segmentos_activos:
		return
	_segmentos_activos = nueva
	queue_redraw()


func segmentos_activos() -> int:
	return _segmentos_activos


func _draw() -> void:
	var centro := size * 0.5
	var color_activo := EstiloSiga.NEGRO
	var color_inactivo := EstiloSiga.GRIS_OSCURO

	# Ojo central: dos arcos y pupila, reconocible incluso con el anillo vacío.
	draw_arc(centro, 6.5, PI + 0.35, TAU - 0.35, 16, color_activo, GROSOR, true)
	draw_arc(centro, 6.5, 0.35, PI - 0.35, 16, color_activo, GROSOR, true)
	draw_circle(centro, 2.0, color_activo)

	# Cuatro cuartos separados. La cantidad activa codifica el estado por forma.
	for indice in SEGMENTOS:
		var inicio := -PI / 2.0 + float(indice) * ANGULO_SEGMENTO + HUECO
		var fin := -PI / 2.0 + float(indice + 1) * ANGULO_SEGMENTO - HUECO
		var color := color_activo if indice < _segmentos_activos else color_inactivo
		draw_arc(centro, RADIO, inicio, fin, 12, color, GROSOR, true)
