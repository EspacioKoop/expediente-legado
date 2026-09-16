## Wiring de HYDRA_LOOP al recorrido doméstico real (#439).
##
## El cartucho solo aparece en casa y conserva la regla del vertical: verlo de
## lejos no activa nada; HidraVigilia exige dos interacciones deliberadas antes
## de escribir semilla_onirica_hidra en la Jornada actual.
extends Node

const POSICION_CARTUCHO := Vector3(2.4, 0.72, -2.8)

var _mundo_montado_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return

	_mundo_montado_id = mundo_id
	if String(dia.jornada.get("fase", "")) != "casa":
		return
	_montar_cartucho(mundo, dia.jornada)


func _montar_cartucho(mundo: Node3D, jornada: Dictionary) -> void:
	if mundo.get_node_or_null("HidraVigiliaCasa") != null:
		return
	var cartucho := HidraVigilia.new()
	cartucho.name = "HidraVigiliaCasa"
	cartucho.position = POSICION_CARTUCHO
	mundo.add_child(cartucho)
	cartucho.configurar(jornada)
