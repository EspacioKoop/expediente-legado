## Micro-recomposición visual del castillo sincronizada con sus campanadas (#947).
##
## Solo transforma nodos de presentación marcados con el grupo
## `castillo_anomalia`. No crea colisión, no mueve el suelo y no conoce estado
## de partida: la navegación sigue perteneciendo íntegramente a ANULAR.
class_name SuenoCastilloPulso3D
extends Node

const GRUPO_ANOMALIA := "castillo_anomalia"

var _campanas: AudioStreamPlayer3D
var _nodos: Array[Node3D] = []
var _posiciones: Array[Vector3] = []
var _rotaciones: Array[Vector3] = []
var _escalas: Array[Vector3] = []
var _ultimo_pulso := -2


func configurar(arquitectura: Node3D, campanas: AudioStreamPlayer3D) -> void:
	_campanas = campanas
	_nodos.clear()
	_posiciones.clear()
	_rotaciones.clear()
	_escalas.clear()

	if arquitectura == null:
		set_process(false)
		return

	for candidato in arquitectura.find_children("*", "Node3D", true, false):
		var nodo := candidato as Node3D
		if nodo == null or not nodo.is_in_group(GRUPO_ANOMALIA):
			continue
		_nodos.append(nodo)
		_posiciones.append(nodo.position)
		_rotaciones.append(nodo.rotation_degrees)
		_escalas.append(nodo.scale)

	_ultimo_pulso = -2
	aplicar_pulso(-1)
	set_process(not _nodos.is_empty() and _campanas != null)


func _process(_delta: float) -> void:
	if _campanas == null or not is_instance_valid(_campanas) or not _campanas.playing:
		return

	var posicion := fmod(_campanas.get_playback_position(), SuenoCastilloAudio.DURACION)
	var pulso := -1
	for i in SuenoCastilloAudio.CAMPANADAS.size():
		if posicion >= float(SuenoCastilloAudio.CAMPANADAS[i]):
			pulso = i

	if pulso != _ultimo_pulso:
		aplicar_pulso(pulso)


## Expuesto para la evidencia visual reproducible. Un índice negativo restaura
## el estado base; 0..2 corresponden a las tres campanadas del bucle.
func aplicar_pulso(indice: int) -> void:
	_ultimo_pulso = indice
	for i in _nodos.size():
		var nodo := _nodos[i]
		if not is_instance_valid(nodo):
			continue

		nodo.position = _posiciones[i]
		nodo.rotation_degrees = _rotaciones[i]
		nodo.scale = _escalas[i]
		if indice < 0:
			continue

		var signo := 1.0 if i % 2 == 0 else -1.0
		var posicion := _posiciones[i]
		var rotacion := _rotaciones[i]
		var escala := _escalas[i]
		match indice:
			0:
				posicion.y += 0.08
				rotacion.y += 1.5 * signo
			1:
				posicion += Vector3(0.12 * signo, 0.16, -0.08 * signo)
				rotacion.y += 4.0 * signo
				escala = Vector3(escala.x * 0.98, escala.y * 1.04, escala.z * 0.98)
			_:
				posicion += Vector3(-0.14 * signo, 0.24, 0.12 * signo)
				rotacion.y -= 5.0 * signo
				escala = Vector3(escala.x * 1.02, escala.y * 0.97, escala.z * 1.02)

		nodo.position = posicion
		nodo.rotation_degrees = rotacion
		nodo.scale = escala
