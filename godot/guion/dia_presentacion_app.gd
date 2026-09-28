## Presentación común del movimiento del día (#1761).
##
## Centraliza pasos, material pisado y efectos de sonido. DiaApp conserva los
## hooks históricos para que las capas hijas no dependan de esta implementación.
class_name DiaPresentacionApp
extends Node

const METROS_POR_ZANCADA := 0.72

var _caminante: CharacterBody3D
var _voz: AudioStreamPlayer
var _pisada: AudioStreamPlayer3D
var _desde_paso := 0.0


func configurar(
	caminante: CharacterBody3D,
	voz: AudioStreamPlayer,
	pisada: AudioStreamPlayer3D,
) -> void:
	_caminante = caminante
	_voz = voz
	_pisada = pisada


func andar(delta: float, bloqueado: bool, suelo: String) -> void:
	if bloqueado or not _caminante.is_physics_processing():
		return
	var avance := Vector2(_caminante.velocity.x, _caminante.velocity.z).length() * delta
	_desde_paso += avance
	if _desde_paso < METROS_POR_ZANCADA:
		return
	_desde_paso = 0.0
	_pisada.stream = Sonido.paso_sobre(suelo)
	_pisada.pitch_scale = randf_range(0.94, 1.06)
	_pisada.play()


static func suelo_pisado(jornada: Dictionary, espacio_actual: Dictionary) -> String:
	if (
		String(jornada.get("fase", "")) == "trayecto"
		and Clima.estado(int(jornada.get("dia", 1))) == Clima.NIEVE
	):
		return "nieve"
	return String(espacio_actual.get("textura_suelo", ""))


func sonar(nombre: String) -> void:
	var stream := Sonido.stream(nombre)
	if stream != null:
		_voz.stream = stream
		_voz.play()
