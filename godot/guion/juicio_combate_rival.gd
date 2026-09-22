## Lógica determinista del rival en el Juicio por Combate.
##
## Calcula movimiento y transiciones del telegrafiado sin tocar nodos, audio
## ni HUD. JuicioCombate3D aplica el resultado al árbol visual.
class_name JuicioCombateRival
extends RefCounted

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")


static func plan_movimiento(
	posicion_jugador: Vector3,
	posicion_rival: Vector3,
	recarga_rival: float,
	velocidad_rival: float,
	enredo_restante: float,
	ritual: Dictionary,
	delta: float,
) -> Dictionary:
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	var distancia := hacia.length()
	var paso := {
		"desplazamiento": Vector3.ZERO,
		"rotacion_y": 0.0,
		"iniciar_ataque": false,
	}
	if distancia > REGLAS.ALCANCE_RIVAL:
		var direccion := hacia.normalized()
		var velocidad := velocidad_rival
		if enredo_restante > 0.0:
			velocidad *= float(ritual.get("velocidad_enredado_mul", 1.0))
		paso["desplazamiento"] = direccion * velocidad * delta
		paso["rotacion_y"] = atan2(direccion.x, direccion.z)
	elif recarga_rival <= 0.0:
		paso["iniciar_ataque"] = true
	return paso


static func iniciar_telegrafo(comision: bool, ritual: Dictionary) -> Dictionary:
	var total := REGLAS.duracion_telegrafo(comision, ritual)
	return {"restante": total, "total": total}


static func avanzar_telegrafo(restante: float, total: float, delta: float) -> Dictionary:
	var nuevo_restante := maxf(0.0, restante - delta)
	var total_seguro := maxf(total, 0.001)
	var progreso := clampf(1.0 - nuevo_restante / total_seguro, 0.0, 1.0)
	return {
		"restante": nuevo_restante,
		"progreso": progreso,
		"resolver": nuevo_restante <= 0.0,
	}


static func resolver_ataque(distancia: float, esquiva_restante: float) -> Dictionary:
	return {
		"resultado": REGLAS.resultado_ataque_rival(distancia, esquiva_restante),
		"recarga": REGLAS.RECARGA_RIVAL,
	}


static func cancelar_telegrafo(recarga_actual: float) -> Dictionary:
	return {
		"restante": 0.0,
		"total": REGLAS.TELEGRAFO_RIVAL,
		"recarga": maxf(recarga_actual, REGLAS.RECARGA_RIVAL * 0.65),
	}
