## Remate común de vida para los finales de investigación (#100).
##
## No decide qué final narrativo corresponde ni modifica la partida. Resume
## únicamente señales que ya existen y devuelve una variante de presentación.
class_name RemateVida
extends RefCounted

const ESTABLE := "estable"
const PRECARIA := "precaria"
const SIN_HOGAR := "sin_hogar"


static func resumir(estado: Dictionary) -> Dictionary:
	var jornada: Dictionary = estado.get("jornada", {})
	var alquiler: Dictionary = jornada.get("alquiler", {})
	var gato: Dictionary = jornada.get("gato", {})
	var impagos := int(alquiler.get("impagos", 0))
	var presente := bool(gato.get("presente", true))
	var dinero := int(jornada.get("dinero", 0))
	var vuelta := int(jornada.get("vuelta", 1))

	return {
		"vuelta": vuelta,
		"dinero": dinero,
		"alquileres_pagados": int(alquiler.get("pagados", 0)),
		"alquileres_impagados": impagos,
		"casa_conservada": impagos == 0,
		"gato_presente": presente,
	}


static func variante(estado: Dictionary) -> String:
	var resumen := resumir(estado)
	if not resumen["casa_conservada"]:
		return SIN_HOGAR
	if not resumen["gato_presente"] or resumen["dinero"] < Jornada.COSTE_DIARIO:
		return PRECARIA
	return ESTABLE


## Combina un final ya resuelto con el estado de vida sin alterar ninguno.
static func resolver(final_investigacion: String, estado: Dictionary) -> Dictionary:
	return {
		"final_investigacion": final_investigacion,
		"remate_vida": variante(estado),
		"resumen_vida": resumir(estado),
	}
