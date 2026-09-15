## Gato 2D de escritorio para SIGA (#92, #285).
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
const ATLAS_GATO: Texture2D = preload("res://arte/gato_asistente_gba.svg")
const FRAME_IDLE := 0
const FRAME_ALERTA := 1
const FRAME_PARPADEO := 2
const FRAME_HAMBRIENTO := 3
const FRAME_MIRANDO := 6
const NIVEL_COMPLETO := GatoAyuda.COMPLETA
const NIVEL_ESCASO := GatoAyuda.ESCASA

var _nivel := NIVEL_COMPLETO
var _reduccion_movimiento := false
var _tiempo := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(ANCHO, ALTO)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_tiempo = fmod(_tiempo + delta, 8.0)
	queue_redraw()


func _draw() -> void:
	var frame := _frame_actual()
	var origen := Vector2(float(frame) * ANCHO_FRAME, 0.0)
	var region := Rect2(origen, Vector2(ANCHO_FRAME, ALTO_FRAME))
	var posicion := Vector2((ANCHO - TAMANO_DIBUJO.x) * 0.5, ALTO - TAMANO_DIBUJO.y)
	var destino := Rect2(posicion, TAMANO_DIBUJO)
	draw_texture_rect_region(ATLAS_GATO, destino, region)


func _frame_actual() -> int:
	# Hambre es estado, no animación: permanece en una pose legible y estable.
	if _nivel == NIVEL_ESCASO:
		return FRAME_HAMBRIENTO
	if _reduccion_movimiento:
		return FRAME_IDLE

	# El idle evita el efecto de mascota hiperactiva. En cada ciclo solo hay un
	# parpadeo y dos cambios breves de postura sin desplazar el avatar por la UI.
	if _tiempo >= 3.65 and _tiempo < 3.82:
		return FRAME_PARPADEO
	if _tiempo >= 5.70 and _tiempo < 6.35:
		return FRAME_ALERTA
	if _tiempo >= 7.10 and _tiempo < 7.55:
		return FRAME_MIRANDO
	return FRAME_IDLE
