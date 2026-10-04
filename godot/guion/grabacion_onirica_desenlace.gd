## Resolver puro de desenlaces especiales de la cinta onírica (#2286 / #140).
##
## La calidad de la toma ya está resuelta por GrabacionOniricaContrato. Esta
## capa solo puede promover una toma técnicamente válida a un estado especial
## usando hechos del sujeto que ya quedaron persistidos al grabarla.
class_name GrabacionOniricaDesenlace
extends RefCounted

const ESTADO_CAOS := "caos"
const ESTADO_BLANCO := "blanco"
const DESENCADENANTE_SUJETO_REACTIVO := "sujeto_reactivo"
const DESENCADENANTE_DEGRADACION_VUELTA := "degradacion_vuelta"


static func resolver(
	proyeccion: Dictionary,
	sujeto: Dictionary,
	contexto: Dictionary = {},
) -> Dictionary:
	var salida := proyeccion.duplicate(true)
	if String(salida.get("estado", "")) != GrabacionOniricaContrato.ESTADO_VALIDA:
		return salida

	var anomalia_id := String(sujeto.get("anomalia_id", "")).strip_edges()
	if not anomalia_id.is_empty() and bool(sujeto.get("reactiva", false)):
		salida["estado"] = ESTADO_CAOS
		salida["desencadenante"] = DESENCADENANTE_SUJETO_REACTIVO
		return salida

	var vuelta_grabada = sujeto.get("vuelta_grabada", null)
	var vuelta_actual = contexto.get("vuelta_actual", null)
	if _vuelta_valida(vuelta_grabada) and _vuelta_valida(vuelta_actual):
		if int(vuelta_actual) > int(vuelta_grabada):
			salida["estado"] = ESTADO_BLANCO
			salida["desencadenante"] = DESENCADENANTE_DEGRADACION_VUELTA
	return salida


static func _vuelta_valida(valor: Variant) -> bool:
	if typeof(valor) == TYPE_INT:
		return int(valor) >= 1
	if typeof(valor) == TYPE_FLOAT:
		var numero := float(valor)
		return numero >= 1.0 and is_equal_approx(numero, roundf(numero))
	return false
