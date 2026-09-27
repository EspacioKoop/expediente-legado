## Paseo presentacional del gato asistente por el shell OS98 (#787).
##
## No conoce SIGA, expedientes ni progreso. Solo desplaza el mismo avatar entre
## posiciones seguras del escritorio mediante una ruta determinista. El arrastre
## manual pausa el recorrido y `reduccion_movimiento` lo desactiva por completo.
class_name GatoAsistentePaseoOs98
extends Node

const Z_ASISTENTE := 900
const PAUSA_INICIAL := 3.5
const PAUSA_ENTRE_DESTINOS := 5.5
const PAUSA_TRAS_ARRASTRE := 7.0
const VELOCIDAD := 185.0
const DURACION_MIN := 1.2
const DURACION_MAX := 3.8
const MARGEN := Vector2(18.0, 14.0)

# Evita la columna de lanzadores de la izquierda y alterna zonas altas/bajas.
# Al ser una secuencia fija, guardar/cargar o repetir una prueba no cambia nada
# jugable ni introduce una fuente global de aleatoriedad.
const DESTINOS_NORMALIZADOS := [
	Vector2(0.88, 0.78),
	Vector2(0.70, 0.16),
	Vector2(0.50, 0.66),
	Vector2(0.32, 0.30),
	Vector2(0.76, 0.46),
	Vector2(0.44, 0.12),
]

var _avatar: Control
var _escritorio: Control
var _reduccion_movimiento := false
var _pausado := false
var _indice_destino := 0
var _espera := PAUSA_INICIAL
var _tween: Tween


func configurar(avatar: Control, escritorio: Control, reduccion_movimiento: bool) -> void:
	_avatar = avatar
	_escritorio = escritorio
	_reduccion_movimiento = reduccion_movimiento
	_pausado = false
	_indice_destino = 0
	_espera = PAUSA_INICIAL
	_detener_tween()
	set_process(not reduccion_movimiento)


func pausar(activo: bool) -> void:
	_pausado = activo
	if activo:
		_detener_tween()
	else:
		_espera = PAUSA_TRAS_ARRASTRE


func _process(delta: float) -> void:
	if (
		_reduccion_movimiento
		or _pausado
		or not is_instance_valid(_avatar)
		or not is_instance_valid(_escritorio)
	):
		return
	if _tween != null and _tween.is_running():
		return
	_espera -= delta
	if _espera > 0.0:
		return
	_mover_a_siguiente_destino()


func _mover_a_siguiente_destino() -> void:
	var destino := siguiente_destino()
	var distancia := _avatar.position.distance_to(destino)
	if distancia < 6.0:
		_espera = PAUSA_ENTRE_DESTINOS
		return
	var duracion := clampf(distancia / VELOCIDAD, DURACION_MIN, DURACION_MAX)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_avatar, "position", destino, duracion)
	_tween.finished.connect(_al_terminar_paso)


func siguiente_destino() -> Vector2:
	if not is_instance_valid(_avatar) or not is_instance_valid(_escritorio):
		return Vector2.ZERO
	var normalizado: Vector2 = DESTINOS_NORMALIZADOS[_indice_destino % DESTINOS_NORMALIZADOS.size()]
	_indice_destino = (_indice_destino + 1) % DESTINOS_NORMALIZADOS.size()

	var max_x := maxf(MARGEN.x, _escritorio.size.x - _avatar.size.x - MARGEN.x)
	var max_y := maxf(MARGEN.y, _escritorio.size.y - _avatar.size.y - MARGEN.y)
	var barra := _escritorio.get_node_or_null("BarraInferior") as Control
	if barra != null and barra.is_visible_in_tree():
		max_y = minf(max_y, maxf(MARGEN.y, barra.position.y - _avatar.size.y - MARGEN.y))

	return Vector2(
		lerpf(MARGEN.x, max_x, normalizado.x),
		lerpf(MARGEN.y, max_y, normalizado.y),
	)


func _al_terminar_paso() -> void:
	_tween = null
	_espera = PAUSA_ENTRE_DESTINOS


func _detener_tween() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = null
