## Capa fina que monta los cuatro ejemplares encontrables de #674 en los mundos
## reales de archivo/casa. No decide inventario: Recogible3D escribe en el
## Dictionary persistido de Partida y este controller solo pide guardado al dueño.
extends Node

const Encontrables := preload("res://guion/publicaciones_encontrables_3d.gd")

var _mundo_id := 0
var _firma := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var fase := String(dia.jornada.get("fase", ""))
	if fase not in ["archivo", "casa"]:
		_limpiar_si_toca(mundo)
		return

	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		return
	Inventario.completar(inventario)

	var numero_dia := int(dia.jornada.get("dia", 1))
	if not Encontrables.listo_para_montar(mundo, fase, numero_dia, inventario):
		return

	var mundo_id := mundo.get_instance_id()
	var firma := Encontrables.firma(fase, numero_dia, inventario)
	if mundo_id == _mundo_id and firma == _firma:
		return

	_mundo_id = mundo_id
	_firma = firma
	var raiz := Encontrables.montar(mundo, fase, numero_dia, inventario)
	for nodo in raiz.get_children():
		if nodo is Recogible3D:
			nodo.recogido.connect(_al_recoger)


func _limpiar_si_toca(mundo: Node3D) -> void:
	if mundo.get_node_or_null(Encontrables.NOMBRE_RAIZ) != null:
		Encontrables.limpiar(mundo)
	_mundo_id = mundo.get_instance_id()
	_firma = ""


func _al_recoger(_objeto: Dictionary, _actor: Node) -> void:
	# La siguiente iteración cambiará la firma porque el ID ya está en Inventario,
	# evitando respawn. Guardamos por el mismo dueño que el resto del día.
	_firma = ""
	var dia := get_parent()
	if dia != null and dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
