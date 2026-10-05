## Política pura de postura/stagger (#2462).
##
## No conoce nodos, daño, vida ni Partida. El host declara cuánta presión de
## postura aporta cada impacto y esta capa abre una ventana corta al alcanzar el
## umbral. Durante stagger se ignoran impactos para evitar stun-lock.
class_name JuicioCombatePostura
extends RefCounted

const UMBRAL := 4.0
const STAGGER_SEGUNDOS := 0.75


static func nuevo() -> Dictionary:
	return {"postura": 0.0, "stagger_restante": 0.0}


static func impactar(
	estado: Dictionary,
	peso: float,
	multiplicador_contexto: float = 1.0,
) -> Dictionary:
	var salida := _normalizar(estado)
	if float(salida["stagger_restante"]) > 0.0:
		return {
			"estado": salida,
			"stagger_iniciado": false,
			"postura_aplicada": 0.0,
		}

	var aplicada := maxf(0.0, peso) * maxf(0.0, multiplicador_contexto)
	if aplicada <= 0.0:
		return {
			"estado": salida,
			"stagger_iniciado": false,
			"postura_aplicada": 0.0,
		}

	salida["postura"] = minf(UMBRAL, float(salida["postura"]) + aplicada)
	var iniciado := float(salida["postura"]) >= UMBRAL
	if iniciado:
		salida["postura"] = 0.0
		salida["stagger_restante"] = STAGGER_SEGUNDOS

	return {
		"estado": salida,
		"stagger_iniciado": iniciado,
		"postura_aplicada": aplicada,
	}


static func avanzar(estado: Dictionary, delta: float) -> Dictionary:
	var salida := _normalizar(estado)
	if float(salida["stagger_restante"]) <= 0.0:
		return salida

	salida["stagger_restante"] = maxf(
		0.0,
		float(salida["stagger_restante"]) - maxf(0.0, delta),
	)
	return salida


static func en_stagger(estado: Dictionary) -> bool:
	return float(_normalizar(estado)["stagger_restante"]) > 0.0


static func _normalizar(estado: Dictionary) -> Dictionary:
	return {
		"postura": clampf(float(estado.get("postura", 0.0)), 0.0, UMBRAL),
		"stagger_restante": maxf(0.0, float(estado.get("stagger_restante", 0.0))),
	}
