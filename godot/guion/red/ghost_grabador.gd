class_name GhostGrabador
extends RefCounted

## Grabador local acotado para #376. Muestrea solo pose + gesto visual.

const GhostDatos = preload("res://guion/red/ghost_datos.gd")

var _scene_key := ""
var _scene_revision := ""
var _game_build := ""
var _actor_public_id := ""
var _sample_rate := 6.0
var _space := "scene"
var _anchor_key := ""
var _inicio := -1.0
var _ultimo_t := -1.0
var _frames: Array = []


func _init(
	scene_key: String,
	scene_revision: String,
	game_build: String,
	actor_public_id: String,
	sample_rate: float = 6.0,
	space: String = "scene",
	anchor_key: String = ""
) -> void:
	_scene_key = scene_key
	_scene_revision = scene_revision
	_game_build = game_build
	_actor_public_id = actor_public_id
	_sample_rate = clampf(sample_rate, GhostDatos.MIN_SAMPLE_RATE, GhostDatos.MAX_SAMPLE_RATE)
	_space = space
	_anchor_key = anchor_key


func registrar(
	instante_segundos: float, position: Vector3, yaw: float, gesture: String = ""
) -> bool:
	if _frames.size() >= GhostDatos.MAX_FRAMES:
		return false
	if not is_finite(instante_segundos):
		return false
	if _inicio < 0.0:
		_inicio = instante_segundos
	var relativo := instante_segundos - _inicio
	if relativo < 0.0 or relativo > GhostDatos.MAX_DURACION:
		return false
	var intervalo := 1.0 / _sample_rate
	if _ultimo_t >= 0.0 and relativo - _ultimo_t < intervalo:
		return false
	(
		_frames
		. append(
			{
				"t": relativo,
				"position": [position.x, position.y, position.z],
				"yaw": yaw,
				"gesture": gesture,
			}
		)
	)
	_ultimo_t = relativo
	return true


func frames() -> Array:
	return _frames.duplicate(true)


func reiniciar() -> void:
	_inicio = -1.0
	_ultimo_t = -1.0
	_frames.clear()


func exportar_evento(ahora_unix: int, event_id: String = "") -> Dictionary:
	return GhostDatos.crear_evento(
		_scene_key,
		_scene_revision,
		_game_build,
		_actor_public_id,
		_frames,
		_sample_rate,
		ahora_unix,
		event_id,
		_space,
		_anchor_key
	)
