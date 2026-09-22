class_name ArbolIndividuacion
extends Resource

signal nodo_desbloqueado(nodo_id: String, recompensas: Dictionary)

var nodos: Dictionary = {}
var nodos_completados: Array = []
var nodo_actual: String = ""
var eventos_completados: Array[String] = []
var rituales_completados: Array[String] = []


func reiniciar() -> void:
	nodos_completados.clear()
	nodo_actual = ""
	eventos_completados.clear()
	rituales_completados.clear()


func registrar_evento(evento: String) -> void:
	if evento.is_empty() or evento in eventos_completados:
		return
	eventos_completados.append(evento)


func registrar_ritual(ritual: String) -> void:
	if ritual.is_empty() or ritual in rituales_completados:
		return
	rituales_completados.append(ritual)


func puede_desbloquear(nodo_id: String) -> bool:
	var nodo = nodos.get(nodo_id)
	if typeof(nodo) != TYPE_DICTIONARY or nodo_id in nodos_completados:
		return false

	var req = nodo.get("requisitos", {})
	if typeof(req) != TYPE_DICTIONARY:
		return false

	if req.has("insight") and GestorArquetipos.insight_total < int(req.get("insight", 0)):
		return false
	if req.has("nodo_previo") and String(req.get("nodo_previo", "")) not in nodos_completados:
		return false
	if req.has("nodos_previos"):
		var previos = req.get("nodos_previos", [])
		if typeof(previos) != TYPE_ARRAY:
			return false
		for previo in previos:
			if String(previo) not in nodos_completados:
				return false
	if req.has("evento") and not _evento_completado(String(req.get("evento", ""))):
		return false
	if req.has("ritual") and not _ritual_completado(String(req.get("ritual", ""))):
		return false
	if (
		req.has("nodos_completados")
		and nodos_completados.size() < int(req.get("nodos_completados", 0))
	):
		return false
	return true


func desbloquear_nodo(nodo_id: String) -> bool:
	if not puede_desbloquear(nodo_id):
		return false

	var nodo: Dictionary = nodos[nodo_id]
	nodos_completados.append(nodo_id)
	nodo_actual = nodo_id
	var recompensas = nodo.get("recompensas", {})
	if typeof(recompensas) == TYPE_DICTIONARY:
		_aplicar_recompensas(recompensas)
		nodo_desbloqueado.emit(nodo_id, recompensas.duplicate(true))
	else:
		nodo_desbloqueado.emit(nodo_id, {})
	return true


func conexiones_disponibles(nodo_id: String = "") -> Array[String]:
	var origen := nodo_actual if nodo_id.is_empty() else nodo_id
	var disponibles: Array[String] = []
	var nodo = nodos.get(origen)
	if typeof(nodo) != TYPE_DICTIONARY:
		return disponibles
	var conexiones = nodo.get("conexiones", [])
	if typeof(conexiones) != TYPE_ARRAY:
		return disponibles
	for conexion in conexiones:
		var conexion_id := String(conexion)
		if puede_desbloquear(conexion_id):
			disponibles.append(conexion_id)
	return disponibles


func _aplicar_recompensas(recompensas: Dictionary) -> void:
	if recompensas.has("desbloquea_arquetipo"):
		var arquetipo = GestorArquetipos.obtener_arquetipo(
			String(recompensas.get("desbloquea_arquetipo", ""))
		)
		if arquetipo != null:
			arquetipo.desbloquear()


func _evento_completado(evento: String) -> bool:
	return not evento.is_empty() and evento in eventos_completados


func _ritual_completado(ritual: String) -> bool:
	return not ritual.is_empty() and ritual in rituales_completados


func obtener_progreso() -> Dictionary:
	var porcentaje := 0.0
	if not nodos.is_empty():
		porcentaje = nodos_completados.size() / float(nodos.size()) * 100.0
	return {
		"completados": nodos_completados.size(),
		"total": nodos.size(),
		"porcentaje": porcentaje,
		"nodo_actual": nodo_actual,
	}
