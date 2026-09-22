## Resolución pura de las acciones ofensivas del jugador en el Juicio.
##
## No toca nodos, RNG, audio ni HUD. Recibe el resultado del crítico ya
## resuelto por el orquestador y devuelve las transiciones que deben aplicarse.
class_name JuicioCombateJugador
extends RefCounted

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const DURACION_ESQUIVA_BASE := 0.34


static func resolver_impacto(
	dano_base: int,
	dano_combo: int,
	es_critico: bool,
	fuerte: bool,
	ritual: Dictionary,
	ataque_rival_pendiente: bool,
	doctrina_activa: String,
	contraataque: int,
) -> Dictionary:
	var dano := dano_base + dano_combo
	if es_critico:
		dano += 1
	if fuerte:
		dano += int(ritual.get("dano_fuerte_bonus", 0))

	var interrupcion_ritual := REGLAS.interrumpe_ataque(
		fuerte, ataque_rival_pendiente, ritual
	)
	var interrupcion_asamblea := REGLAS.asamblea_interrumpe(
		doctrina_activa, ataque_rival_pendiente
	)
	if interrupcion_ritual:
		dano += int(ritual.get("dano_interrupcion_bonus", 0))

	if contraataque > 0:
		dano += contraataque

	var cerrar_doctrina := interrupcion_asamblea
	if doctrina_activa == "neoliberal":
		dano = REGLAS.dano_externalizado(dano, doctrina_activa)
		cerrar_doctrina = true

	var enredo_segundos := 0.0
	if not fuerte:
		enredo_segundos = maxf(0.0, float(ritual.get("enredo_ligero_segundos", 0.0)))

	return {
		"dano": dano,
		"interrumpir_rival": interrupcion_ritual or interrupcion_asamblea,
		"cerrar_doctrina": cerrar_doctrina,
		"consumir_contraataque": contraataque > 0,
		"enredo_segundos": enredo_segundos,
	}


static func duracion_esquiva(bonus_evasion: float) -> float:
	return DURACION_ESQUIVA_BASE * (1.0 + bonus_evasion)
