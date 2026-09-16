## Controller hijo de #677 para el recorrido real de `dia.tscn`.
##
## Sigue el patrón de dressing: observa el mundo ya montado por Dia y no toma
## decisiones de jornada. Solo en casa deriva el estado ambiental oficial y
## refresca la estantería cuando cambia el contenido de home_storage.
extends Node

var _mundo_id := 0
var _firma := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	var fase := String(dia.jornada.get("fase", ""))
	if fase != "casa":
		_mundo_id = mundo_id
		_firma = ""
		return

	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		inventario = {}
	var estado := CasaEstadoAmbiental.derivar(dia.jornada, inventario)
	var firma := CasaAcumulacion3D.firma(estado)
	if mundo_id == _mundo_id and firma == _firma:
		return

	_mundo_id = mundo_id
	_firma = firma
	CasaAcumulacion3D.montar(mundo, estado)
