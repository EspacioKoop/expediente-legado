extends Node

signal evento_iniciado(evento_id)
signal evento_completado(evento_id, recompensas)

var eventos_activos: Dictionary = {}
var eventos_completados: Array = []


func _ready() -> void:
	_registrar_eventos()


func _registrar_eventos() -> void:
	eventos_activos = {
		"noches_poesia":
		{
			"id": "noches_poesia",
			"nombre": "Noches de Poesía",
			"descripcion": "Recita versos bajo la luna para ganar insight y momentum",
			"requisitos": {"obras": ["divina_comedia", "odisea"], "min_momentum": 30},
			"recompensas": {"insight": 50, "momentum": 30, "desbloquea": "finisher_poesia"},
			"periodicidad": "semanal",
			"activo": true
		},
		"debate_cervantino":
		{
			"id": "debate_cervantino",
			"nombre": "Debate Cervantino",
			"descripcion": "Defiende tu visión del Quijote contra otros eruditos",
			"requisitos": {"obra": "donquijote", "arquetipo": "persona", "min_insight": 100},
			"recompensas": {"insight": 100, "habilidad": "escudo_idealismo", "autor": "cervantes"},
			"periodicidad": "mensual",
			"activo": true
		},
		"rito_kafka":
		{
			"id": "rito_kafka",
			"nombre": "Rito de la Metamorfosis",
			"descripcion": "Transforma tu momentum en insight puro mediante la cita correcta",
			"requisitos": {"obra": "metamorfosis", "arquetipo": "sombra", "momentum": 75},
			"recompensas": {"transformacion_temporal": true, "bonus_crit_sombra": 0.2},
			"periodicidad": "unica",
			"activo": true
		},
	}


func iniciar_evento(evento_id: String) -> bool:
	if not eventos_activos.has(evento_id):
		return false
	var evento: Dictionary = eventos_activos[evento_id]
	if not _verificar_requisitos(evento.get("requisitos", {})):
		print("No cumples requisitos para %s" % evento.get("nombre", evento_id))
		return false
	evento_iniciado.emit(evento_id)
	print("Evento iniciado: %s" % evento.get("nombre", evento_id))
	return true


func completar_evento(evento_id: String) -> bool:
	if not eventos_activos.has(evento_id):
		return false
	var evento: Dictionary = eventos_activos[evento_id]
	if not _verificar_requisitos(evento.get("requisitos", {})):
		return false
	var recompensas: Dictionary = evento.get("recompensas", {})
	_otorgar_recompensas(recompensas)
	eventos_completados.append(evento_id)
	if String(evento.get("periodicidad", "")) == "unica":
		eventos_activos.erase(evento_id)
	evento_completado.emit(evento_id, recompensas)
	print("Evento completado: %s" % evento.get("nombre", evento_id))
	return true


func _arquetipo_desbloqueado(id: String):
	var arquetipo = GestorArquetipos.obtener_arquetipo(id)
	if arquetipo == null or not bool(arquetipo.desbloqueado):
		return null
	return arquetipo


func _verificar_requisitos(req: Dictionary) -> bool:
	var cumple := true
	if req.has("obras"):
		for obra_id in req.get("obras", []):
			if obra_id not in GestorLiteratura.obras_conocidas:
				cumple = false
				break
	cumple = (
		cumple and not (req.has("obra") and req.get("obra") not in GestorLiteratura.obras_conocidas)
	)
	cumple = (
		cumple
		and not (
			req.has("arquetipo")
			and _arquetipo_desbloqueado(String(req.get("arquetipo", ""))) == null
		)
	)
	cumple = (
		cumple
		and not (
			req.has("min_momentum") and GestorMomentum.momentum_actual < req.get("min_momentum", 0)
		)
	)
	cumple = (
		cumple
		and not (req.has("momentum") and GestorMomentum.momentum_actual < req.get("momentum", 0))
	)
	cumple = (
		cumple
		and not (
			req.has("min_insight") and GestorArquetipos.insight_total < req.get("min_insight", 0)
		)
	)
	return cumple


func _otorgar_recompensas(recompensas: Dictionary) -> void:
	if recompensas.has("insight"):
		GestorArquetipos.ganar_insight(int(recompensas.get("insight", 0)))
	if recompensas.has("momentum"):
		GestorMomentum.momentum_actual = min(
			GestorMomentum.momentum_max,
			GestorMomentum.momentum_actual + float(recompensas.get("momentum", 0.0))
		)
	if recompensas.has("autor"):
		var autor := String(recompensas.get("autor", ""))
		if not autor.is_empty() and autor not in GestorLiteratura.autores_conocidos:
			GestorLiteratura.autores_conocidos.append(autor)
	if recompensas.has("bonus_crit_sombra"):
		var sombra = _arquetipo_desbloqueado("sombra")
		if sombra != null:
			sombra.efecto_combate["bonus_crit"] = (
				float(sombra.efecto_combate.get("bonus_crit", 0.0))
				+ float(recompensas.get("bonus_crit_sombra", 0.0))
			)


func obtener_eventos_disponibles() -> Array:
	var disponibles: Array = []
	for evento in eventos_activos.values():
		if evento is Dictionary and _verificar_requisitos(evento.get("requisitos", {})):
			disponibles.append(evento)
	return disponibles
