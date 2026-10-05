## Cálculo puro de framing multiblanco para combate (#2481).
class_name JuicioCombateCameraFraming
extends RefCounted

const DISTANCIA_BASE := 8.2
const DISTANCIA_MIN := 7.0
const DISTANCIA_MAX := 12.0
const FACTOR_RADIO := 0.85
const RADIO_SIN_ZOOM_EXTRA := 2.5


static func calcular(
	posicion_jugador: Vector3,
	objetivos: Array,
	distancia_base: float = DISTANCIA_BASE,
	distancia_min: float = DISTANCIA_MIN,
	distancia_max: float = DISTANCIA_MAX,
) -> Dictionary:
	var puntos := [Vector3(posicion_jugador.x, 0.0, posicion_jugador.z)]
	for objetivo in objetivos:
		if objetivo is Vector3:
			var punto: Vector3 = objetivo
			puntos.append(Vector3(punto.x, 0.0, punto.z))

	var centro := Vector3.ZERO
	for punto in puntos:
		centro += punto
	centro /= float(puntos.size())

	var radio := 0.0
	for punto in puntos:
		radio = maxf(radio, centro.distance_to(punto))

	var minimo := minf(distancia_min, distancia_max)
	var maximo := maxf(distancia_min, distancia_max)
	var base := clampf(distancia_base, minimo, maximo)
	var exceso_radio := maxf(0.0, radio - RADIO_SIN_ZOOM_EXTRA)
	var distancia := clampf(base + exceso_radio * FACTOR_RADIO, minimo, maximo)

	return {
		"centro": centro,
		"radio": radio,
		"distancia_camara": distancia,
		"cantidad_objetivos": puntos.size() - 1,
	}
