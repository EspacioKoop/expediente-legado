## Wiring del corte de vigilia de Aquiles (#438) al recorrido real.
##
## Este controller hijo observa el mundo que ya monta Dia y añade la estampa
## únicamente en casa. La lógica de la semilla sigue perteneciendo a
## `AquilesVigilia`/`SemillasOniricas`; aquí solo se hace alcanzable con la
## Jornada real, sin añadir estado paralelo ni contaminar la raíz del día.
extends Node

const POSICION_ESTAMPA := Vector3(-2.6, 1.35, -3.2)

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
	_montar_estampa(mundo, dia.jornada)


func _montar_estampa(mundo: Node3D, jornada: Dictionary) -> void:
	if mundo.get_node_or_null("AquilesVigiliaCasa") != null:
		return
	var estampa := AquilesVigilia.new()
	estampa.name = "AquilesVigiliaCasa"
	estampa.position = POSICION_ESTAMPA
	mundo.add_child(estampa)
	estampa.configurar(jornada)
