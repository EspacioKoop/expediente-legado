extends Resource
class_name ArbolIndividuacion

var nodos: Dictionary = {}
var nodos_completados: Array = []
var nodo_actual: String = ""


func _init() -> void:
	# Se carga desde el .tres
	pass


func puede_desbloquear(nodo_id: String) -> bool:
	var nodo = nodos.get(nodo_id)
	if nodo == null:
		return false
	if nodo_id in nodos_completados:
		return false

	var req: Dictionary = nodo.requisitos
	if req.has("insight") and GestorArquetipos.insight_total < req.insight:
		return false
	if req.has("nodo_previo") and req.nodo_previo not in nodos_completados:
		return false
	if req.has("nodos_previos"):
		for previo in req.nodos_previos:
			if previo not in nodos_completados:
				return false
	if req.has("evento") and not _evento_completado(req.evento):
		return false
	if req.has("ritual") and not _ritual_completado(req.ritual):
		return false
	if req.has("nodos_completados") and nodos_completados.size() < req.nodos_completados:
		return false
	return true


func desbloquear_nodo(nodo_id: String) -> bool:
	if not puede_desbloquear(nodo_id):
		return false

	nodos_completados.append(nodo_id)
	var nodo = nodos[nodo_id]
	_aplicar_recompensas(nodo.recompensas)

	for conexion in nodo.conexiones:
		if puede_desbloquear(conexion):
			pass
	return true


func _aplicar_recompensas(recompensas: Dictionary) -> void:
	if recompensas.has("desbloquea_arquetipo"):
		var arquetipo = GestorArquetipos.obtener_arquetipo(recompensas.desbloquea_arquetipo)
		if arquetipo != null:
			arquetipo.desbloquear()


func _evento_completado(evento: String) -> bool:
	return get_node("/root/GestorJuego").evento_completado(evento)


func _ritual_completado(ritual: String) -> bool:
	return get_node("/root/GestorRituales").ritual_completado(ritual)


func obtener_progreso() -> Dictionary:
	var porcentaje := 0.0
	if not nodos.is_empty():
		porcentaje = nodos_completados.size() / float(nodos.size()) * 100.0
	return {
		"completados": nodos_completados.size(),
		"total": nodos.size(),
		"porcentaje": porcentaje,
	}
