class_name ArbolIndividuacion
extends Resource

@export var nodos: Dictionary = {}

var nodos_completados: Array[String] = []
var nodo_actual: String = ""


func puede_desbloquear(nodo_id: String) -> bool:
	if not nodos.has(nodo_id) or nodo_id in nodos_completados:
		return false
	var nodo: Dictionary = nodos[nodo_id]
	var requisitos: Dictionary = nodo.get("requisitos", {})
	var cumple := true

	if requisitos.has("insight"):
		var gestor_arquetipos := _autoload("GestorArquetipos")
		cumple = gestor_arquetipos != null
		if cumple:
			cumple = (
				int(gestor_arquetipos.get("insight_total"))
				>= int(requisitos.get("insight", 0))
			)
	if cumple and requisitos.has("nodo_previo"):
		cumple = String(requisitos.get("nodo_previo", "")) in nodos_completados
	if cumple:
		for previo in requisitos.get("nodos_previos", []):
			if String(previo) not in nodos_completados:
				cumple = false
				break
	if cumple and requisitos.has("evento"):
		cumple = _evento_completado(String(requisitos["evento"]))
	if cumple and requisitos.has("ritual"):
		cumple = _ritual_completado(String(requisitos["ritual"]))
	if cumple and requisitos.has("nodos_completados"):
		cumple = nodos_completados.size() >= int(requisitos["nodos_completados"])
	return cumple


func desbloquear_nodo(nodo_id: String) -> bool:
	if not puede_desbloquear(nodo_id):
		return false
	nodos_completados.append(nodo_id)
	var nodo: Dictionary = nodos[nodo_id]
	_aplicar_recompensas(nodo.get("recompensas", {}))
	nodo_actual = nodo_id
	return true


func obtener_progreso() -> Dictionary:
	var total := nodos.size()
	var porcentaje := 0.0
	if total > 0:
		porcentaje = float(nodos_completados.size()) / float(total) * 100.0
	return {
		"completados": nodos_completados.size(),
		"total": total,
		"porcentaje": porcentaje,
	}


func _aplicar_recompensas(recompensas: Dictionary) -> void:
	if recompensas.has("desbloquea_arquetipo"):
		var gestor_arquetipos := _autoload("GestorArquetipos")
		if gestor_arquetipos != null:
			gestor_arquetipos.call(
				"desbloquear_arquetipo", String(recompensas["desbloquea_arquetipo"])
			)


func _evento_completado(evento: String) -> bool:
	var gestor := _autoload("GestorJuego")
	return (
		gestor != null
		and gestor.has_method("evento_completado")
		and bool(gestor.call("evento_completado", evento))
	)


func _ritual_completado(ritual: String) -> bool:
	var gestor := _autoload("GestorRituales")
	return (
		gestor != null
		and gestor.has_method("ritual_completado")
		and bool(gestor.call("ritual_completado", ritual))
	)


func _autoload(nombre: String) -> Node:
	var arbol_escenas := Engine.get_main_loop() as SceneTree
	if arbol_escenas == null:
		return null
	return arbol_escenas.root.get_node_or_null(nombre)
