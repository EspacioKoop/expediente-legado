class_name ArbolIndividuacion
extends Resource

signal nodo_desbloqueado(nodo_id: String, recompensas: Dictionary)

@export_storage var nodos: Dictionary = {}
var nodos_completados: Array = []
var nodo_actual: String = ""
var eventos_completados: Array[String] = []
var rituales_completados: Array[String] = []
var gestor_arquetipos: Node = null


func configurar_gestor_arquetipos(gestor: Node) -> void:
	gestor_arquetipos = gestor


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

	var requisitos = nodo.get("requisitos", {})
	if typeof(requisitos) != TYPE_DICTIONARY:
		return false
	return _cumple_requisitos(requisitos)


func _cumple_requisitos(requisitos: Dictionary) -> bool:
	return (
		_cumple_insight(requisitos)
		and _cumple_nodos_previos(requisitos)
		and _cumple_evento(requisitos)
		and _cumple_ritual(requisitos)
		and _cumple_total_nodos(requisitos)
	)


func _cumple_insight(requisitos: Dictionary) -> bool:
	if not requisitos.has("insight"):
		return true
	if gestor_arquetipos == null:
		return false
	return int(gestor_arquetipos.get("insight_total")) >= int(requisitos.get("insight", 0))


func _cumple_nodos_previos(requisitos: Dictionary) -> bool:
	if (
		requisitos.has("nodo_previo")
		and String(requisitos.get("nodo_previo", "")) not in nodos_completados
	):
		return false
	if not requisitos.has("nodos_previos"):
		return true

	var previos = requisitos.get("nodos_previos", [])
	if typeof(previos) != TYPE_ARRAY:
		return false
	for previo in previos:
		if String(previo) not in nodos_completados:
			return false
	return true


func _cumple_evento(requisitos: Dictionary) -> bool:
	return not requisitos.has("evento") or _evento_completado(String(requisitos.get("evento", "")))


func _cumple_ritual(requisitos: Dictionary) -> bool:
	return not requisitos.has("ritual") or _ritual_completado(String(requisitos.get("ritual", "")))


func _cumple_total_nodos(requisitos: Dictionary) -> bool:
	return (
		not requisitos.has("nodos_completados")
		or nodos_completados.size() >= int(requisitos.get("nodos_completados", 0))
	)


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
	if gestor_arquetipos == null or not recompensas.has("desbloquea_arquetipo"):
		return
	var arquetipo = gestor_arquetipos.call(
		"obtener_arquetipo", String(recompensas.get("desbloquea_arquetipo", ""))
	)
	if arquetipo != null:
		arquetipo.call("desbloquear")


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
