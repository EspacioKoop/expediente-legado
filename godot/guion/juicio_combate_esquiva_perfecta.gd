## Política pura de esquiva perfecta (#2450, #2567).
##
## No conoce animaciones, daño, cámara, momentum real ni Partida. El host
## identifica una amenaza que iba a impactar y entrega tiempos explícitos.
##
## Contrato monofichero del issue #2567:
## - Entradas: amenaza válida y no consumida, segundos hasta impacto,
##   esquiva activa, segundos desde inicio de la esquiva, identificador de amenaza
## - Salida: perfecta, amenaza_consumida, ventana_contraataque, bonus_momentum
## - Ventana real (ver constantes): tiempo_hasta_impacto en [0.0, VENTANA_IMPACTO]
##   y tiempo_desde_esquiva en [ESQUIVA_MINIMA, ESQUIVA_MAXIMA]; ambos bordes
##   son inclusivos y no dependen de FPS ni de un reloj global.
## - Una amenaza no concede dos premios; entradas tempranas/tardías y límites exactos estables
## - Sin RNG, física ni SceneTree
class_name JuicioCombateEsquivaPerfecta
extends RefCounted

## La amenaza debe estar como máximo a 160 ms del impacto.
const VENTANA_IMPACTO := 0.16

## Evita premiar el mismo instante de pulsación como si ya existiera una esquiva
## estable y limita la parte de la animación que puede producir perfecta.
const ESQUIVA_MINIMA := 0.02
const ESQUIVA_MAXIMA := 0.24

## Recompensas declarativas. El host decide cómo representarlas/aplicarlas.
const VENTANA_CONTRAATAQUE := 0.30
const BONUS_MOMENTUM := 1


## Crea un estado nuevo para rastrear amenazas consumidas.
static func nuevo() -> Dictionary:
	return {"amenazas_consumidas": {}}


## Evalúa una amenaza contra el estado de esquiva.
## Entradas posicionales para compatibilidad con la regresión headless existente:
##   estado           - dict con "amenazas_consumidas"
##   amenaza_id       - identificador único de la amenaza
##   amenaza_valida   - la amenaza realmente va a impactar
##   esquivando       - el jugador está esquivando ahora
##   tiempo_hasta_impacto - tiempo restante hasta que la amenaza impactaría
##   tiempo_desde_esquiva - tiempo transcurrido desde que empezó la esquiva
static func evaluar(
	estado: Dictionary,
	amenaza_id: String,
	amenaza_valida: bool,
	esquivando: bool,
	tiempo_hasta_impacto: float,
	tiempo_desde_esquiva: float,
) -> Dictionary:
	var salida := _normalizar(estado)
	var id := amenaza_id.strip_edges()
	var perfecta := false

	if (
		amenaza_valida
		and esquivando
		and not id.is_empty()
		and not salida["amenazas_consumidas"].has(id)
		and tiempo_hasta_impacto >= 0.0
		and tiempo_hasta_impacto <= VENTANA_IMPACTO
		and tiempo_desde_esquiva >= ESQUIVA_MINIMA
		and tiempo_desde_esquiva <= ESQUIVA_MAXIMA
	):
		perfecta = true
		salida["amenazas_consumidas"][id] = true

	return {
		"estado": salida,
		"perfecta": perfecta,
		"amenaza_consumida": id if perfecta else "",
		"ventana_contraataque": VENTANA_CONTRAATAQUE if perfecta else 0.0,
		"bonus_momentum": BONUS_MOMENTUM if perfecta else 0,
	}


## Comprueba si una amenaza ya fue consumida en el estado dado.
static func consumida(estado: Dictionary, amenaza_id: String) -> bool:
	var salida := _normalizar(estado)
	return salida["amenazas_consumidas"].has(amenaza_id.strip_edges())


## Normaliza el estado para que siempre tenga "amenazas_consumidas" como dict.
static func _normalizar(estado: Dictionary) -> Dictionary:
	var consumidas := {}
	var origen = estado.get("amenazas_consumidas", {})
	if origen is Dictionary:
		consumidas = origen.duplicate(true)
	return {"amenazas_consumidas": consumidas}
