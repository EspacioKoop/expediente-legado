## Resolver puro de desenlaces especiales de la cinta onírica (#2286 / #140).
##
## La calidad de la toma ya está resuelta por GrabacionOniricaContrato. Esta
## capa solo puede promover una toma técnicamente válida a un estado especial
## usando hechos del sujeto que ya quedaron persistidos al grabarla.
class_name GrabacionOniricaDesenlace
extends RefCounted

const ESTADO_CAOS := "caos"
const DESENCADENANTE_SUJETO_REACTIVO := "sujeto_reactivo"


static func resolver(proyeccion: Dictionary, sujeto: Dictionary) -> Dictionary:
	var salida := proyeccion.duplicate(true)
	if String(salida.get("estado", "")) != GrabacionOniricaContrato.ESTADO_VALIDA:
		return salida

	var anomalia_id := String(sujeto.get("anomalia_id", "")).strip_edges()
	if anomalia_id.is_empty() or not bool(sujeto.get("reactiva", false)):
		return salida

	salida["estado"] = ESTADO_CAOS
	salida["desencadenante"] = DESENCADENANTE_SUJETO_REACTIVO
	return salida
