extends Node
class_name GestorEventosLiterarios
signal evento_iniciado(evento_id)
signal evento_completado(evento_id, recompensas)

var eventos_activos: Dictionary = {}
var eventos_completados: Array = []

func _ready() -> void:
    _registrar_eventos()

func _registrar_eventos() -> void:
    eventos_activos = {
        "noches_poesia": {
            "id": "noches_poesia",
            "nombre": "Noches de Poesía",
            "descripcion": "Recita versos bajo la luna para ganar insight y momentum",
            "requisitos": {"obras": ["divina_comedia", "odisea"], "min_momentum": 30},
            "recompensas": {"insight": 50, "momentum": 30, "desbloquea": "finisher_poesia"},
            "periodicidad": "semanal",
            "activo": true
        },
        "debate_cervantino": {
            "id": "debate_cervantino",
            "nombre": "Debate Cervantino",
            "descripcion": "Defiende tu visión del Quijote contra otros eruditos",
            "requisitos": {"obra": "donquijote", "arquetipo": "persona", "min_insight": 100},
            "recompensas": {"insight": 100, "habilidad": "escudo_idealismo", "autor": "cervantes"},
            "periodicidad": "mensual",
            "activo": true
        },
        "rito_kafka": {
            "id": "rito_kafka",
            "nombre": "Rito de la Metamorfosis",
            "descripcion": "Transforma tu momentum en insight puro mediante la cita correcta",
            "requisitos": {"obra": "metamorfosis", "arquetipo": "sombra", "momentum": 75},
            "recompensas": {"transformacion_temporal": true, "bonus_crit_sombra": 0.2},
            "periodicidad": "unica",
            "activo": true
        }
    }

func iniciar_evento(evento_id: String) -> bool:
    if not eventos_activos.has(evento_id):
        return False
    var evento = eventos_activos[evento_id]
    if not _verificar_requisitos(evento.requisitos):
        print(f"No cumples requisitos para {evento.nombre}")
        return False
    evento_iniciado.emit(evento_id)
    print(f"Evento iniciado: {evento.nombre}")
    return true

func completar_evento(evento_id: String) -> bool:
    if not eventos_activos.has(evento_id):
        return False
    var evento = eventos_activos[evento_id]
    if not _verificar_requisitos(evento.requisitos):
        return False
    _otorgar_recompensas(evento.recompensas)
    eventos_completados.append(evento_id)
    if evento.periodicidad == "unica":
        eventos_activos.erase(evento_id)
    evento_completado.emit(evento_id, evento.recompensas)
    print(f"Evento completado: {evento.nombre}")
    return true

func _verificar_requisitos(req: Dictionary) -> bool:
    if req.has("obras"):
        for o in req.obras:
            if o not in GestorLiteratura.obras_conocidas:
                return False
    if req.has("obra"):
        if req.obra not in GestorLiteratura.obras_conocidas:
            return False
    if req.has("arquetipo"):
        if not GestorArquetipos.obtener_arquetipo(req.arquetipo)?.desbloqueado:
            return False
    if req.has("min_momentum"):
        if GestorMomentum.momentum_actual < req.min_momentum:
            return False
    if req.has("min_insight"):
        if GestorArquetipos.insight_total < req.min_insight:
            return False
    return true

func _otorgar_recompensas(recompensas: Dictionary) -> void:
    if recompensas.has("insight"):
        GestorArquetipos.ganar_insight(recompensas.insight)
    if recompensas.has("momentum"):
        GestorMomentum.momentum_actual = min(GestorMomentum.momentum_max, GestorMomentum.momentum_actual + recompensas.momentum)
    if recompensas.has("desbloquea"):
        # unlock special finisher
        pass
    if recompensas.has("habilidad"):
        # grant special ability
        pass
    if recompensas.has("autor"):
        if recompensas.autor not in GestorLiteratura.autores_conocidos:
            GestorLiteratura.autores_conocidos.append(recompensas.autor)
    if recompensas.has("transformacion_temporal"):
        # apply temporary transformation
        pass
    if recompensas.has("bonus_crit_sombra"):
        if GestorArquetipos.obtener_arquetipo("sombra")?.desbloqueado:
            GestorArquetipos.obtener_arquetipo("sombra").efecto_combate.bonus_crit += recompensas.bonus_crit_sombra

func obtener_eventos_disponibles() -> Array:
    var disponibles = []
    for e in eventos_activos.values():
        if _verificar_requisitos(e.requisitos):
            disponibles.append(e)
    return disponibles
