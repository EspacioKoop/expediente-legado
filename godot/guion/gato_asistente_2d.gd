## Gato 2D del asistente compartido por SIGA y el shell OS98 (#92, #285, #787).
##
## El avatar usa un atlas original de estética GBA: conserva una silueta felina
## legible a tamaño pequeño sin convertir el asistente en otra fuente de estado.
## Su nivel sigue viniendo de GatoAyuda y toda animación decorativa se congela
## cuando `reduccion_movimiento` está activa.
class_name GatoAsistente2D
extends Control

const ANCHO := 132.0
const ALTO := 150.0
const ANCHO_FRAME := 48.0
const ALTO_FRAME := 64.0
const TAMANO_DIBUJO := Vector2(96.0, 128.0)
const CICLO_ANIMACION := 14.0
const ATLAS_GATO: Texture2D = preload("res://arte/gato_asistente_gba.svg")
const FRAME_IDLE := 0
const FRAME_ALERTA := 1
const FRAME_PARPADEO := 2
const FRAME_HAMBRIENTO := 3
const FRAME_SATISFECHO := 4
const FRAME_LOAF := 5
const FRAME_MIRANDO := 6
const FRAME_ESPALDA := 7
const NIVEL_COMPLETO := GatoAyuda.COMPLETA
const NIVEL_ESCASO := GatoAyuda.ESCASA

var _nivel := NIVEL_COMPLETO
var _reduccion_movimiento := false
var _tiempo := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(ANCHO, ALTO)
	# Solo la silueta del gato captura el arrastre. El bocadillo puede seguir
	# dejando pasar clics a SIGA/OS98 aunque el avatar se mueva por el shell.
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(not _reduccion_movimiento)
	queue_redraw()


func configurar(nivel: String, reduccion_movimiento: bool) -> void:
	_nivel = nivel
	_reduccion_movimiento = reduccion_movimiento
	_tiempo = 0.0
	set_process(not reduccion_movimiento)
	queue_redraw()


func _process(delta: float) -> void:
	_tiempo = fmod(_tiempo + delta, CICLO_ANIMACION)
	queue_redraw()


func _draw() -> void:
	var frame := _frame_actual()
	var origen := Vector2(float(frame) * ANCHO_FRAME, 0.0)
	var region := Rect2(origen, Vector2(ANCHO_FRAME, ALTO_FRAME))
	var respiracion := _respiracion()
	var amplitud := _amplitud_respiracion(frame)
	var escala_x := 1.0 - respiracion * amplitud.x
	var escala_y := 1.0 + respiracion * amplitud.y
	var tamano := Vector2(TAMANO_DIBUJO.x * escala_x, TAMANO_DIBUJO.y * escala_y)
	# El sprite se dilata desde las patas, no desde el centro. Así el cuerpo
	# parece respirar sin flotar ni perder el apoyo sobre la interfaz.
	var posicion := Vector2((ANCHO - tamano.x) * 0.5, ALTO - tamano.y)
	var destino := Rect2(posicion, tamano)
	draw_texture_rect_region(ATLAS_GATO, destino, region)


func _respiracion() -> float:
	if _reduccion_movimiento:
		return 0.0
	# La respiración y el catálogo de poses comparten un ciclo cerrado, pero las
	# frecuencias no coinciden exactamente: evita que cada mirada ocurra siempre
	# en el mismo punto de inspiración y mantiene el loop discreto.
	var respiracion_base := sin((_tiempo / 4.0) * TAU)
	var variacion := 0.78 + 0.22 * sin((_tiempo / CICLO_ANIMACION) * TAU + 0.8)
	return respiracion_base * variacion


func _amplitud_respiracion(frame: int) -> Vector2:
	if frame == FRAME_HAMBRIENTO:
		return Vector2(0.002, 0.006)
	if frame == FRAME_ALERTA or frame == FRAME_MIRANDO or frame == FRAME_ESPALDA:
		return Vector2(0.0025, 0.005)
	if frame == FRAME_LOAF:
		return Vector2(0.004, 0.004)
	if frame == FRAME_SATISFECHO:
		return Vector2(0.003, 0.007)
	return Vector2(0.0035, 0.008)


func _frame_actual() -> int:
	# Hambre es estado, no animación: permanece en una pose legible y estable.
	if _nivel == NIVEL_ESCASO:
		return FRAME_HAMBRIENTO
	if _reduccion_movimiento:
		return FRAME_IDLE

	# Las ocho poses del atlas participan ahora en secuencias cortas. No hay RNG:
	# los in-betweens son presentación determinista y nunca deciden progreso.
	# 1) doble parpadeo, más orgánico que un único frame periódico.
	if (_tiempo >= 2.70 and _tiempo < 2.86) or (_tiempo >= 3.02 and _tiempo < 3.14):
		return FRAME_PARPADEO

	# 2) mirar -> alerta -> mirar: una atención breve hacia otra zona del OS98.
	if _tiempo >= 4.45 and _tiempo < 4.82:
		return FRAME_MIRANDO
	if _tiempo >= 4.82 and _tiempo < 5.18:
		return FRAME_ALERTA
	if _tiempo >= 5.18 and _tiempo < 5.58:
		return FRAME_MIRANDO

	# 3) satisfecho -> loaf -> satisfecho: se acomoda antes de volver a idle.
	if _tiempo >= 7.05 and _tiempo < 7.42:
		return FRAME_SATISFECHO
	if _tiempo >= 7.42 and _tiempo < 8.18:
		return FRAME_LOAF
	if _tiempo >= 8.18 and _tiempo < 8.50:
		return FRAME_SATISFECHO

	# 4) giro completo: usa espalda como transición, no como pose congelada.
	if _tiempo >= 10.35 and _tiempo < 10.76:
		return FRAME_MIRANDO
	if _tiempo >= 10.76 and _tiempo < 11.48:
		return FRAME_ESPALDA
	if _tiempo >= 11.48 and _tiempo < 11.90:
		return FRAME_MIRANDO

	# Un último parpadeo rompe la simetría antes de cerrar el ciclo.
	if _tiempo >= 12.72 and _tiempo < 12.90:
		return FRAME_PARPADEO
	return FRAME_IDLE
