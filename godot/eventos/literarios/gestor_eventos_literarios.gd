extends Node

signal evento_iniciado(evento_id: String)
signal evento_completado(evento_id: String, recompensas: Dictionary)

var eventos_activos: Dictionary = {}
var eventos_completados: Array[String] = []


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
			"activo": true,
		},
		"debate_cervantino":
		{
			"id": "debate_cervantino",
			"nombre": "Debate Cervantino",
			"descripcion": "Defiende tu visión del Quijote contra otros eruditos",
			"requisitos": {"obra": "donquijote", "arquetipo": "persona", "min_insight": 100},
			"recompensas":
			{
				"insight": 100,
				"habilidad": "escudo_idealismo",
				"autor": "cervantes",
			},
			"periodicidad": "mensual",
			"activo": true,
		},
		"rito_kafka":
		{
			"id": "rito_kafka",
			"nombre": "Rito de la Metamorfosis",
			"descripcion": "Transforma momentum en insight mediante la cita correcta",
			"requisitos": {"obra": "metamorfosis", "arquetipo": "sombra", "momentum": 75},
			"recompensas": {"transformacion_temporal": true, "bonus_crit_sombra": 0.2},
			"periodicidad": "unica",
			"activo": true,
		},
	}


func iniciar_evento(evento_id: String) -> bool:
	if not eventos_activos.has(evento_id):
		return false
	var evento: Dictionary = eventos_activos[evento_id]
	if not _verificar_requisitos(evento.get("requisitos", {})):
		print("No cumples requisitos para %s" % String(evento.get("nombre", evento_id)))
		return false
	evento_iniciado.emit(evento_id)
	print("Evento iniciado: %s" % String(evento.get("nombre", evento_id)))
	return true


func completar_evento(evento_id: String) -> bool:
	if not eventos_activos.has(evento_id):
		return false
	var evento: Dictionary = eventos_activos[evento_id]
	if not _verificar_requisitos(evento.get("requisitos", {})):
		return false
	var recompensas: Dictionary = evento.get("recompensas", {})
	_otorgar_recompensas(recompensas)
	if evento_id not in eventos_completados:
		eventos_completados.append(evento_id)
	if String(evento.get("periodicidad", "")) == "unica":
		eventos_activos.erase(evento_id)
	evento_completado.emit(evento_id, recompensas)
	print("Evento completado: %s" % String(evento.get("nombre", evento_id)))
	return true


func _verificar_requisitos(requisitos: Dictionary) -> bool:
	var literatura := _gestor("GestorLiteratura")
	var arquetipos := _gestor("GestorArquetipos")
	var momentum := _gestor("GestorMomentum")
	if literatura == null or arquetipos == null or momentum == null:
		return false

	var cumple := true
	var conocidas: Array = literatura.get("obras_conocidas")
	for obra_id in requisitos.get("obras", []):
		if String(obra_id) not in conocidas:
			cumple = false
			break
	if cumple and requisitos.has("obra"):
		cumple = String(requisitos["obra"]) in conocidas
	if cumple and requisitos.has("arquetipo"):
		var arquetipo = arquetipos.call("obtener_arquetipo", String(requisitos["arquetipo"]))
		cumple = arquetipo != null and bool(arquetipo.get("desbloqueado"))
	if cumple and requisitos.has("min_momentum"):
		cumple = (
			float(momentum.get("momentum_actual"))
			>= float(requisitos["min_momentum"])
		)
	if cumple and requisitos.has("momentum"):
		cumple = float(momentum.get("momentum_actual")) >= float(requisitos["momentum"])
	if cumple and requisitos.has("min_insight"):
		cumple = int(arquetipos.get("insight_total")) >= int(requisitos["min_insight"])
	return cumple


func _otorgar_recompensas(recompensas: Dictionary) -> void:
	var literatura := _gestor("GestorLiteratura")
	var arquetipos := _gestor("GestorArquetipos")
	var momentum := _gestor("GestorMomentum")
	if arquetipos != null and recompensas.has("insight"):
		arquetipos.call("ganar_insight", int(recompensas["insight"]))
	if momentum != null and recompensas.has("momentum"):
		momentum.call("agregar_momentum", float(recompensas["momentum"]))
	if literatura != null and recompensas.has("autor"):
		var autores: Array = literatura.get("autores_conocidos")
		var autor := String(recompensas["autor"])
		if autor not in autores:
			autores.append(autor)
			literatura.set("autores_conocidos", autores)
	if arquetipos != null and recompensas.has("bonus_crit_sombra"):
		_sumar_bonus_sombra(arquetipos, float(recompensas["bonus_crit_sombra"]))


func _sumar_bonus_sombra(arquetipos: Node, cantidad: float) -> void:
	var sombra = arquetipos.call("obtener_arquetipo", "sombra")
	if sombra == null or not bool(sombra.get("desbloqueado")):
		return
	var efectos = sombra.get("efecto_combate")
	if typeof(efectos) != TYPE_DICTIONARY:
		return
	efectos["bonus_crit"] = float(efectos.get("bonus_crit", 0.0)) + cantidad
	sombra.set("efecto_combate", efectos)


func obtener_eventos_disponibles() -> Array:
	var disponibles: Array = []
	for evento in eventos_activos.values():
		if (
			typeof(evento) == TYPE_DICTIONARY
			and _verificar_requisitos(evento.get("requisitos", {}))
		):
			disponibles.append(evento)
	return disponibles


func _gestor(nombre: String) -> Node:
	return get_node_or_null("/root/" + nombre)
