## Contrato puro de orientación para la catedral invertida (#2431).
##
## Este primer corte NO cambia la gravedad global de Godot ni mueve al jugador.
## Define las cuatro orientaciones permitidas y un plan de transición seguro
## que la futura escena 3D puede consumir sin duplicar reglas.
class_name CatedralInvertida
extends RefCounted

const SUELO := "suelo"
const MURO_DERECHO := "muro_derecho"
const TECHO := "techo"
const MURO_IZQUIERDO := "muro_izquierdo"
const ORIENTACIONES: Array[String] = [SUELO, MURO_DERECHO, TECHO, MURO_IZQUIERDO]

const ANGULOS := {
	SUELO: Vector3(0.0, 0.0, 0.0),
	MURO_DERECHO: Vector3(0.0, 0.0, -90.0),
	TECHO: Vector3(0.0, 0.0, 180.0),
	MURO_IZQUIERDO: Vector3(0.0, 0.0, 90.0),
}

const DURACION_GIRO := 0.55


static func orientacion_valida(id: String) -> bool:
	return ORIENTACIONES.has(id)


static func siguiente(actual: String, pasos: int = 1) -> String:
	var indice := ORIENTACIONES.find(actual)
	if indice < 0:
		indice = 0
	return ORIENTACIONES[posmod(indice + pasos, ORIENTACIONES.size())]


static func plan_transicion(
	actual: String,
	destino: String,
	reduccion_movimiento: bool = false,
	ancla: Vector3 = Vector3.ZERO
) -> Dictionary:
	var origen_valido := actual if orientacion_valida(actual) else SUELO
	var destino_valido := destino if orientacion_valida(destino) else origen_valido
	return {
		"origen": origen_valido,
		"destino": destino_valido,
		"rotacion_origen": ANGULOS[origen_valido],
		"rotacion_destino": ANGULOS[destino_valido],
		"ancla": ancla,
		"modo": "corte_fundido" if reduccion_movimiento else "rotacion_arquitectura",
		"animar": not reduccion_movimiento,
		"duracion": 0.0 if reduccion_movimiento else DURACION_GIRO,
		"mover_jugador": false,
		"mover_camara": false,
		"mantener_referencia_visual": true,
	}


static func secuencia_vertical(inicio: String = SUELO) -> Array[String]:
	var base := inicio if orientacion_valida(inicio) else SUELO
	return [base, siguiente(base), siguiente(base, 2)]


static func validar_anclas(anclas: Dictionary) -> bool:
	for orientacion in ORIENTACIONES:
		if not anclas.has(orientacion):
			return false
		if not anclas[orientacion] is Vector3:
			return false
	return true


static func estado_reproducible(
	orientacion: String,
	anclas: Dictionary,
	reduccion_movimiento: bool = false
) -> Dictionary:
	var actual := orientacion if orientacion_valida(orientacion) else SUELO
	return {
		"orientacion": actual,
		"rotacion": ANGULOS[actual],
		"anclas_validas": validar_anclas(anclas),
		"reduccion_movimiento": reduccion_movimiento,
	}
