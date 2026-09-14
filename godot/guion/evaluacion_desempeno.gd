## Evaluación automática de una vida laboral a partir del estado ya guardado.
##
## No puntúa al jugador ni concede recompensas. Devuelve categorías independientes
## con rangos corporativos deliberadamente descriptivos. Todo sale de Partida /
## Jornada: aquí no se crean contadores paralelos ni se modifica ningún estado.
class_name EvaluacionDesempeno
extends RefCounted

const BAJA := "BAJA"
const MEDIA := "MEDIA"
const ALTA := "ALTA"


static func calcular(partida: Dictionary) -> Dictionary:
	var jornada: Dictionary = partida.get("jornada", {})
	var gato: Dictionary = jornada.get("gato", {})
	var veredictos: Dictionary = partida.get("veredictos", {})
	var mapa: Array = jornada.get("mapa", [])
	var dinero := int(jornada.get("dinero", 0))
	var dias_sin_comer := int(gato.get("dias_sin_comer", 0))

	return {
		"productividad": _rango(veredictos.size(), 2, 6),
		"precipitacion": ALTA if bool(partida.get("perdio_vida_en_esta_vuelta", false)) else BAJA,
		"cuidado_gato": _rango_invertido(dias_sin_comer, 1, Jornada.PACIENCIA_GATO),
		"liquidez": _rango(dinero, Jornada.PRECIO_COMIDA_GATO, Jornada.PRECIO_ALQUILER),
		"exploracion_onirica": _rango(mapa.size(), 2, 6),
	}


## Los umbrales son inclusivos y solo clasifican magnitudes observadas. No hay
## una suma final porque una vida puede ser simultáneamente productiva, precaria
## y poco exploradora sin que una categoría invalide las demás.
static func _rango(valor: int, umbral_medio: int, umbral_alto: int) -> String:
	if valor >= umbral_alto:
		return ALTA
	if valor >= umbral_medio:
		return MEDIA
	return BAJA


static func _rango_invertido(valor: int, umbral_medio: int, umbral_alto: int) -> String:
	if valor >= umbral_alto:
		return BAJA
	if valor >= umbral_medio:
		return MEDIA
	return ALTA
