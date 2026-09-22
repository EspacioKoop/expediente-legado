## Punto físico observable para el pasaporte de inspección (#154).
##
## Reutiliza el foco/raycast y la acción semántica de Interactuable3D. El nodo
## no conoce Partida ni guarda nada: observar emite el id y el dueño de la
## escena decide si lo registra y cuándo persiste el estado.
class_name PuntoInspeccion3D
extends Interactuable3D

signal observado(punto_id: String, actor: Node)

var _punto_id := ""


func _init() -> void:
	verbo = Verbo.EXAMINAR
	sonido = SIN_SONIDO
	activado.connect(_emitir_observacion)


func configurar(punto_id: String) -> void:
	_punto_id = punto_id.strip_edges()


func id_punto() -> String:
	return _punto_id


func _emitir_observacion(actor: Node) -> void:
	if _punto_id.is_empty():
		push_warning("Punto de inspección sin id")
		return
	observado.emit(_punto_id, actor)
