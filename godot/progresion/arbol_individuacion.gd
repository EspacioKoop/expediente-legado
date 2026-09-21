extends Resource
class_name ArbolIndividuacion

var nodos: Dictionary = {}
var nodos_completados: Array = []
var nodo_actual: String = ""

func _init() -> void:
    # Se carga desde el .tres
    pass

func puede_desbloquear(nodo_id: String) -> bool:
    var nodo = nodos[nodo_id]
    if not nodo:
        return false
    if nodo_id in nodos_completados:
        return false
    
    var req = nodo.requisitos
    # Verificar insight
    if req.has("insight") and GestorArquetipos.insight_total < req.insight:
        return false
    # Verificar nodo previo
    if req.has("nodo_previo") and req.nodo_previo not in nodos_completados:
        return false
    # Verificar nodos previos múltiples
    if req.has("nodos_previos"):
        for n in req.nodos_previos:
            if n not in nodos_completados:
                return false
    # Verificar eventos/rituales (flags en juego)
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
    
    # Verificar si desbloquea conexiones
    for conn in nodo.conexiones:
        if puede_desbloquear(conn):
            # Marcar como disponible
            pass
    
    return true

func _aplicar_recompensas(recompensas: Dictionary) -> void:
    if recompensas.has("desbloquea_arquetipo"):
        var arq = GestorArquetipos.obtener_arquetipo(recompensas.desbloquea_arquetipo)
        if arq:
            arq.desbloquear()
    
    # Otras recompensas se aplican via eventos/sistema de stats

func _evento_completado(evento: String) -> bool:
    # Consultar sistema de eventos/flags del juego
    return get_node("/root/GestorJuego").evento_completado(evento)

func _ritual_completado(ritual: String) -> bool:
    return get_node("/root/GestorRituales").ritual_completado(ritual)

func obtener_progreso() -> Dictionary:
    return {
        "completados": nodos_completados.size(),
        "total": nodos.size(),
        "porcentaje": nodos_completados.size() / float(nodos.size()) * 100.0
    }
