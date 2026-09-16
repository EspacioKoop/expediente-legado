## Controller hijo de #675 para el recorrido real de `dia.tscn`.
##
## Espera a que Dia monte la casa base, deriva el estado ambiental oficial y
## superpone las cinco microinteracciones sobre los anclajes existentes.
extends Node

const CasaEstadoAmbientalScript := preload("res://guion/casa_estado_ambiental.gd")
const CasaRutinas3DScript := preload("res://guion/casa_rutinas_3d.gd")

var _mundo_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	var fase := String(dia.jornada.get("fase", ""))
	if fase != "casa":
		_mundo_id = mundo_id
		return
	if mundo_id == _mundo_id and mundo.get_node_or_null(CasaRutinas3DScript.NOMBRE_RAIZ) != null:
		return

	# `CasaUtileria` se monta desde la capa principal del día; si todavía no han
	# aparecido sus anclajes, esperamos al siguiente frame sin crear una casa paralela.
	if mundo.find_child("VentanaCasa", true, false) == null:
		return

	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		inventario = {}
	var estado := CasaEstadoAmbientalScript.derivar(dia.jornada, inventario)
	var reduccion := bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	CasaRutinas3DScript.montar(mundo, dia.jornada, estado, reduccion)
	_mundo_id = mundo_id
