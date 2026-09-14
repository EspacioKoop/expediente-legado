## Archivado manual: decidir dónde va cada carpeta sin depender de una escena.
##
## La clasificación usa únicamente metadatos ya presentes en `casos.json`.
## No toca Partida ni concede recursos: quien pinte el minijuego solo consume
## estos resultados y decide cómo representarlos.
class_name Archivado
extends RefCounted


## Un archivador estable y legible a partir de los tres metadatos disponibles.
## El año se agrupa por década para no crear un mueble distinto por expediente.
static func destino_de(caso: Dictionary) -> String:
	var anio := int(caso.get("anioSuceso", 0))
	var decada := (anio / 10) * 10 if anio > 0 else 0
	var estado := str(caso.get("estado", "desconocido")).to_upper()
	var acceso := "CONFIDENCIAL" if bool(caso.get("confidencial", false)) else "GENERAL"
	return "%s-%s-%s" % [str(decada) if decada > 0 else "sin-fecha", estado, acceso]


## Una carpeta solo se puede clasificar si el jugador conoce al menos uno de sus
## folios. Se comparan los folios reales del caso; no se introduce estado nuevo.
static func es_clasificable(caso: Dictionary, folios_leidos: Array) -> bool:
	if folios_leidos.is_empty():
		return false
	for registro in caso.get("registros", []):
		if folios_leidos.has(registro.get("folio", "")):
			return true
	return false


## Evalúa una bandeja sin mutarla. Cada colocación puede traer `caso`, `destino`
## y opcionalmente `folios_leidos`. Las no clasificables quedan pendientes y no
## cuentan ni como acierto ni como error. Una bandeja parcial sigue siendo un
## resultado válido: eso permite abandonarla sin bloquear el día.
static func evaluar(colocaciones: Array) -> Dictionary:
	var aciertos := 0
	var errores := 0
	var pendientes := 0
	for colocacion in colocaciones:
		var caso: Dictionary = colocacion.get("caso", {})
		var folios_leidos: Array = colocacion.get("folios_leidos", [])
		if not es_clasificable(caso, folios_leidos):
			pendientes += 1
			continue
		if str(colocacion.get("destino", "")) == destino_de(caso):
			aciertos += 1
		else:
			errores += 1

	var evaluadas := aciertos + errores
	var precision := 0.0 if evaluadas == 0 else float(aciertos) / float(evaluadas)
	var rango := "sin-datos"
	if evaluadas > 0:
		if errores == 0:
			rango = "perfecta"
		elif precision >= 0.75:
			rango = "alta"
		elif precision >= 0.5:
			rango = "media"
		else:
			rango = "baja"

	return {
		"aciertos": aciertos,
		"errores": errores,
		"pendientes": pendientes,
		"evaluadas": evaluadas,
		"precision": precision,
		"rango": rango,
	}
