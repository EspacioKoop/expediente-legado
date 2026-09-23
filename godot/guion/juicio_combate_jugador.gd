## Resolución pura de las acciones ofensivas del jugador en el Juicio.
##
## No toca nodos, RNG, audio ni HUD. Recibe el resultado del crítico ya
## resuelto por el orquestador y devuelve las transiciones que deben aplicarse.
class_name JuicioCombateJugador
extends RefCounted

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const DURACION_ESQUIVA_BASE := 0.34
const MULTIPLICADOR_VELOCIDAD_ESQUIVA := 2.25


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

	var interrupcion_ritual := REGLAS.interrumpe_ataque(fuerte, ataque_rival_pendiente, ritual)
	var interrupcion_asamblea := REGLAS.asamblea_interrumpe(doctrina_activa, ataque_rival_pendiente)
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


## `entrada` es el eje de movimiento tal como lo da Input (x lateral, y
## profundidad). Solo se reorienta con entrada apreciable para que soltar el
## stick no devuelva la figura a rotación cero.
static func plan_movimiento(
	posicion: Vector3,
	entrada: Vector2,
	velocidad: float,
	esquivando: bool,
	radio_arena: float,
	delta: float,
) -> Dictionary:
	var direccion := entrada
	if direccion.length_squared() > 1.0:
		direccion = direccion.normalized()
	var multiplicador := MULTIPLICADOR_VELOCIDAD_ESQUIVA if esquivando else 1.0
	var destino := (
		posicion + Vector3(direccion.x, 0.0, direccion.y) * velocidad * multiplicador * delta
	)
	var orientar := direccion.length_squared() > 0.01
	return {
		"posicion": REGLAS.limitar_a_arena(destino, radio_arena),
		"orientar": orientar,
		"rotacion_y": atan2(direccion.x, direccion.y) if orientar else 0.0,
	}


## Esquivar un golpe real del rival con un ritual que lo premie deja un
## contraataque pendiente. No se acumula: se queda con el mayor.
static func contraataque_tras_esquiva(ritual: Dictionary, contraataque_actual: int) -> Dictionary:
	var bono := int(ritual.get("contraataque_esquiva", 0))
	if bono <= 0:
		return {"aplica": false, "contraataque": contraataque_actual}
	return {"aplica": true, "contraataque": maxi(contraataque_actual, bono)}
