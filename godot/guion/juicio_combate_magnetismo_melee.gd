## Corrección corta de aproximación melee (#2479).
class_name JuicioCombateMagnetismoMelee
extends RefCounted

const MAX_DESPLAZAMIENTO := 0.45


static func calcular(
	posicion_jugador: Vector3,
	posicion_objetivo: Vector3,
	alcance: float,
	margen_asistencia: float,
	linea_libre: bool = true,
) -> Dictionary:
	var vector := posicion_objetivo - posicion_jugador
	vector.y = 0.0
	var distancia := vector.length()
	var alcance_seguro := maxf(0.0, alcance)
	var margen := clampf(margen_asistencia, 0.0, MAX_DESPLAZAMIENTO)

	if not linea_libre or distancia <= alcance_seguro or distancia <= 0.001:
		return _resultado(false, Vector3.ZERO, distancia, distancia)

	var exceso := distancia - alcance_seguro
	if exceso > margen:
		return _resultado(false, Vector3.ZERO, distancia, distancia)

	var avance := minf(exceso, MAX_DESPLAZAMIENTO)
	var desplazamiento := vector.normalized() * avance
	var restante := maxf(0.0, distancia - avance)
	return _resultado(true, desplazamiento, distancia, restante)


static func _resultado(
	aplicar: bool,
	desplazamiento: Vector3,
	distancia_original: float,
	distancia_restante: float,
) -> Dictionary:
	return {
		"aplicar": aplicar,
		"desplazamiento": desplazamiento,
		"distancia_original": distancia_original,
		"distancia_restante": distancia_restante,
	}
