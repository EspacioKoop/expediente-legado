## Montaje de las pieles materiales del trayecto (#399).
##
## Vive separado del dressing Retro Urban (#295): los materiales base de calle
## forman parte del espacio aunque el kit CC0 se desactive o se mida aislado.
extends Node

var _mundo_montado_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	if String(dia.jornada.get("fase", "")) != "trayecto":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	CalleMateriales.montar(mundo)
