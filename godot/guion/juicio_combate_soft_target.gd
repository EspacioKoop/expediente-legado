## Política geométrica pura de soft-targeting melee (#2471).
class_name JuicioCombateSoftTarget
extends RefCounted

const ALCANCE := 4.25
const ANGULO_MAXIMO := deg_to_rad(70.0)
const BONUS_OBJETIVO_ACTUAL := 0.22
const PESO_DISTANCIA := 0.35


static func elegir(
	posicion: Vector3,
	rumbo_y: float,
	candidatos: Array,
	objetivo_actual: String = "",
) -> Dictionary:
	var frente := Vector3(sin(rumbo_y), 0.0, cos(rumbo_y))
	var opciones := []

	for candidato in candidatos:
		if not candidato is Dictionary:
			continue
		var id := String(candidato.get("id", "")).strip_edges()
		if id.is_empty() or not bool(candidato.get("vivo", true)):
			continue

		var destino: Vector3 = candidato.get("posicion", posicion)
		var vector := destino - posicion
		vector.y = 0.0
		var distancia := vector.length()
		if distancia <= 0.001 or distancia > ALCANCE:
			continue

		var direccion := vector / distancia
		var coseno := clampf(frente.dot(direccion), -1.0, 1.0)
		var angulo := acos(coseno)
		if angulo > ANGULO_MAXIMO:
			continue

		var angular := 1.0 - (angulo / ANGULO_MAXIMO)
		var cercania := 1.0 - (distancia / ALCANCE)
		var puntuacion := angular + cercania * PESO_DISTANCIA
		if id == objetivo_actual:
			puntuacion += BONUS_OBJETIVO_ACTUAL

		opciones.append(
			{
				"id": id,
				"direccion": direccion,
				"distancia": distancia,
				"angulo": angulo,
				"puntuacion": puntuacion,
			}
		)

	if opciones.is_empty():
		return _vacio()

	opciones.sort_custom(_comparar)
	var mejor: Dictionary = opciones[0]
	return {
		"objetivo_id": String(mejor["id"]),
		"direccion": mejor["direccion"],
		"distancia": float(mejor["distancia"]),
		"angulo": float(mejor["angulo"]),
	}


static func _comparar(a: Dictionary, b: Dictionary) -> bool:
	var pa := float(a["puntuacion"])
	var pb := float(b["puntuacion"])
	if not is_equal_approx(pa, pb):
		return pa > pb
	return String(a["id"]) < String(b["id"])


static func _vacio() -> Dictionary:
	return {
		"objetivo_id": "",
		"direccion": Vector3.ZERO,
		"distancia": 0.0,
		"angulo": 0.0,
	}
