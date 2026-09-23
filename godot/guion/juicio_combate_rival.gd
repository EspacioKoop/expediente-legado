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
		"mover": false,
		"desplazamiento": Vector3.ZERO,
		"rotacion_y": 0.0,
		"iniciar_ataque": false,
	}
	if distancia > REGLAS.ALCANCE_RIVAL:
		paso["mover"] = true
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


## Qué le hace al jugador un ataque del rival ya resuelto por distancia y
## esquiva. Los dos cierres de doctrina van separados porque el controlador
## los aplica en momentos distintos: Externalizar se consume con el golpe,
## antes de una posible derrota; Comisión acompaña a la intención observada
## y termina después, pase lo que pase con ella.
static func resolver_impacto_en_jugador(
	resultado: String,
	determinacion_jugador: int,
	invulnerabilidad: float,
	doctrina_activa: String,
) -> Dictionary:
	var desenlace := resultado
	var dano := 0
	if resultado != "falla" and resultado != "esquiva":
		desenlace = "negado" if invulnerabilidad > 0.0 else "impacto"
	if desenlace == "impacto":
		dano = REGLAS.dano_externalizado(1, doctrina_activa)
	var restante := maxi(0, determinacion_jugador - dano)
	return {
		"desenlace": desenlace,
		"dano": dano,
		"determinacion_jugador": restante,
		"cerrar_externalizar": desenlace == "impacto" and doctrina_activa == "neoliberal",
		"cerrar_comision": doctrina_activa == "socialdemocrata",
		"derrota": desenlace == "impacto" and restante <= 0,
	}


## Segunda vida ritual del rival al quedarse sin determinación. «acepta» en
## falso significa que el combate termina; el resto solo vale si acepta.
static func retorno(ritual: Dictionary, retornos_usados: int) -> Dictionary:
	var determinacion := REGLAS.determinacion_retorno(ritual, retornos_usados)
	return {
		"acepta": determinacion > 0,
		"determinacion": determinacion,
		"retornos": retornos_usados + 1 if determinacion > 0 else retornos_usados,
		"recarga": REGLAS.RECARGA_RIVAL * 0.50,
	}


## Posición a la que Mesa de diálogo aparta al rival, sin limitar a la arena:
## ese límite depende del radio ritual y lo aplica el controlador. Si ambos
## coinciden en el plano se usa una dirección fija para no normalizar cero.
static func posicion_mesa(
	posicion_jugador: Vector3, posicion_rival: Vector3, distancia: float
) -> Vector3:
	var separacion := posicion_rival - posicion_jugador
	separacion.y = 0.0
	if separacion.length_squared() < 0.001:
		separacion = Vector3(0.0, 0.0, -1.0)
	return posicion_jugador + separacion.normalized() * distancia
