## Regresión standalone del epílogo político de #1103/#925.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	_consistente()
	_plural()
	_contextual()
	_auditorias_descriptivas()
	_logros_idempotentes()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _estado_base() -> Dictionary:
	return Partida.nueva()


func _historias(ejes: Array) -> Dictionary:
	var ids: Array = Prometeo.UTILIDAD_CARTAS.keys()
	ids.sort()
	var resultado := {}
	for indice in range(ids.size()):
		resultado[ids[indice]] = ejes[indice]
	return resultado


func _consistente() -> void:
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(
		[
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
		]
	)
	var resumen := FinalPolitico.resumen(estado, {"veredicto": "hastur_confrontado"})
	_comprobar(resumen["patron"] == FinalPolitico.PATRON_CONSISTENTE, "run mono-eje consistente")
	_comprobar(resumen["dominantes"] == ["comunismo"], "consistente conserva eje dominante")
	_comprobar(resumen["ejemplos"].size() == 4, "el cierre cita decisiones reales")


func _plural() -> void:
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(
		[
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"centrista",
			"centrista",
			"centrista",
			"centrista",
		]
	)
	var resumen := FinalPolitico.resumen(estado)
	_comprobar(resumen["patron"] == FinalPolitico.PATRON_PLURAL, "empate real queda plural")
	_comprobar(resumen["dominantes"].size() == 2, "pluralidad conserva todos los dominantes")


func _contextual() -> void:
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(
		[
			"socialdemocrata",
			"socialdemocrata",
			"socialdemocrata",
			"socialdemocrata",
			"socialdemocrata",
			"neoliberal",
			"neoliberal",
			"centrista",
		]
	)
	var resumen := FinalPolitico.resumen(estado)
	_comprobar(
		resumen["patron"] == FinalPolitico.PATRON_CONTEXTUAL,
		"mezcla con dominante se describe como contextual",
	)
	_comprobar(
		resumen["dominantes"] == ["socialdemocrata"],
		"contextual conserva el recuento transversal",
	)


func _auditorias_descriptivas() -> void:
	var estado := _estado_base()
	estado[Auditorias.CLAVE_ESTADO] = Auditorias.nueva(
		[Auditorias.SIN_RELEER, Auditorias.SUENO_COMPLETO]
	)
	Auditorias.fallar(estado[Auditorias.CLAVE_ESTADO], Auditorias.SIN_RELEER, "documento_releido")
	var antes := JSON.stringify(estado)
	var resumen := FinalPolitico.resumen(estado, {"veredicto": "hastur_confrontado"})
	var auditoria: Dictionary = resumen.get("auditoria", {})
	_comprobar(
		auditoria.get("origen", "") == "actual", "el final lee la auditoría viva sin cerrarla"
	)
	var condiciones: Array = auditoria.get("condiciones", [])
	_comprobar(condiciones.size() == 2, "el final conserva todas las condiciones seleccionadas")
	var por_id := {}
	for condicion in condiciones:
		por_id[String(condicion.get("id", ""))] = String(condicion.get("estado", ""))
	_comprobar(
		por_id.get(Auditorias.SIN_RELEER, "") == "fallida",
		"el final refleja una condición ya fallida",
	)
	_comprobar(
		por_id.get(Auditorias.SUENO_COMPLETO, "") == "activa",
		"el final no completa una condición que sigue vigente",
	)
	_comprobar(JSON.stringify(estado) == antes, "resumir el final no muta Auditorías")


func _logros_idempotentes() -> void:
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(
		[
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
			"comunismo",
		]
	)
	var nuevos := FinalPolitico.confirmar_cierre(estado)
	_comprobar(bool(estado["final_politico_mostrado"]), "cerrar persiste la presentación")
	_comprobar(nuevos.has("papeleta-depositada"), "llegar al final concede papeleta")
	_comprobar(nuevos.has("disciplina-de-partido"), "mono-eje completo conserva disciplina")
	_comprobar(
		not nuevos.has("instinto-de-archivo"),
		"disciplina no inventa utilidad perfecta",
	)
	var repetidos := FinalPolitico.confirmar_cierre(estado)
	_comprobar(repetidos.is_empty(), "confirmar dos veces no duplica logros")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		printerr("FALLO: %s" % nombre)
