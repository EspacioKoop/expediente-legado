## Enrutado central de audio (#119).
##
## `Master` sigue siendo el volumen global. Todo reproductor que no declare un
## bus propio entra por `Efectos`, salvo los dos nodos canónicos ya separados
## por responsabilidad: ambiente continuo y música puntual.
extends Node

const BUS_MASTER := &"Master"
const BUS_EFECTOS := &"Efectos"
const BUS_AMBIENTE := &"Ambiente"
const BUS_MUSICA := &"Musica"
const NODO_AMBIENTE := &"AmbienteContinuo"
const NODO_MUSICA := &"MusicaPuntual"


func _ready() -> void:
	get_tree().node_added.connect(_al_anadir_nodo)
	_enrutar_subarbol(get_tree().root)


func _al_anadir_nodo(nodo: Node) -> void:
	_enrutar(nodo)


func _enrutar_subarbol(nodo: Node) -> void:
	_enrutar(nodo)
	for hijo in nodo.get_children():
		_enrutar_subarbol(hijo)


func _enrutar(nodo: Node) -> void:
	if not _es_reproductor(nodo):
		return
	if StringName(nodo.get("bus")) != BUS_MASTER:
		return

	var destino := BUS_EFECTOS
	if nodo.name == NODO_AMBIENTE:
		destino = BUS_AMBIENTE
	elif nodo.name == NODO_MUSICA:
		destino = BUS_MUSICA
	nodo.set("bus", destino)


func _es_reproductor(nodo: Node) -> bool:
	return (
		nodo is AudioStreamPlayer
		or nodo is AudioStreamPlayer2D
		or nodo is AudioStreamPlayer3D
	)
