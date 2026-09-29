## Regresión standalone del epílogo político de #1103/#925.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	_consistente()
	_plural()
	_contextual()
	_auditorias_descriptivas()
	_remate_vida_descriptivo()
	_logros_idempotentes()
	_ecos_sin_eventos_mismo_cierre()
	_un_eco_social_aparece_una_vez()
	_maximo_dos_ecos_y_orden_estable()
	_evento_corrupto_se_ignora()
	_abrir_cerrar_reabrir_no_muta()
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


func _ocho(eje: String) -> Array:
	return [eje, eje, eje, eje, eje, eje, eje, eje]


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


func _remate_vida_descriptivo() -> void:
	var estado := _estado_base()
	var jornada: Dictionary = estado["jornada"]
	jornada["dinero"] = 0
	jornada["alquiler"]["impagos"] = 1
	jornada["gato"]["presente"] = false
	var antes := JSON.stringify(estado)
	var figura := RemateVidaCinematica.figura_de(estado)
	_comprobar(not figura.is_empty(), "el final puede reutilizar el remate visual de vida")
	_comprobar(
		RemateVida.variante(estado) == RemateVida.SIN_HOGAR,
		"el remate conserva la variante de vida ya resuelta",
	)
	_comprobar(JSON.stringify(estado) == antes, "montar el remate no muta la partida")


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


func _ecos_sin_eventos_mismo_cierre() -> void:
	"""Sin lecturas #920, el resumen sigue teniendo las capas base."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(_ocho("socialdemocrata"))
	var resumen := FinalPolitico.resumen(estado)
	_comprobar(resumen.has("patron"), "el resumen siempre incluye patron")
	_comprobar(resumen.has("dominantes"), "el resumen siempre incluye dominantes")
	_comprobar(resumen.has("ejemplos"), "el resumen siempre incluye ejemplos")
	var lecturas: Array = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.is_empty(), "sin lecturas sociales cuando no hay eventos #920")


func _un_eco_social_aparece_una_vez() -> void:
	"""Un evento social aparece una vez y no altera conteos/ejes/logros."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(_ocho("comunismo"))
	estado[Prometeo.CLAVE_LECTURAS_SOCIALES] = [
		{
			"actor": "cunado",
			"evento_observado": "evento_vertical",
			"reaccion": "cierre_colectivo",
			"etiquetas": ["expediente", "postcierre"],
		}
	]
	var resumen := FinalPolitico.resumen(estado)
	var lecturas: Array = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.size() == 1, "un actor genera un eco social")
	var panel := FinalPoliticoPanel.new()
	var ecos: Array = panel._preparar_ecos(resumen)
	_comprobar(ecos.size() == 1, "el presentador muestra el eco una sola vez")
	panel.free()
	# Los ejes y conteos no cambian por el eco.
	var conteo: Dictionary = FinalPolitico.resumen(estado).get("conteo", {})
	_comprobar(conteo.get("comunismo", 0) == 8, "el conteo conserva el eje real")


func _maximo_dos_ecos_y_orden_estable() -> void:
	"""El presentador selecciona máximo 2 ecos con orden estable."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(_ocho("centrista"))
	estado[Prometeo.CLAVE_LECTURAS_SOCIALES] = [
		{"actor": "jubilacion", "evento_observado": "evento_vertical"},
		{"actor": "becario", "evento_observado": "evento_vertical"},
		{"actor": "cunado", "evento_observado": "evento_vertical"},
	]
	var resumen := FinalPolitico.resumen(estado)
	var lecturas: Array = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.size() == 3, "el modelo conserva los tres hechos fuente")

	var panel := FinalPoliticoPanel.new()
	var ecos: Array = panel._preparar_ecos(resumen)
	_comprobar(ecos.size() == 2, "el presentador limita los ecos a dos")
	if ecos.size() == 2:
		var detalle0: Dictionary = ecos[0].get("detalle", {})
		var detalle1: Dictionary = ecos[1].get("detalle", {})
		_comprobar(String(detalle0.get("actor", "")) == "becario", "orden estable: becario primero")
		_comprobar(String(detalle1.get("actor", "")) == "cunado", "orden estable: cunado segundo")
	panel.free()


func _evento_corrupto_se_ignora() -> void:
	"""Lecturas desconocidas o corruptas se ignoran de forma segura."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(_ocho("neoliberal"))
	estado[Prometeo.CLAVE_LECTURAS_SOCIALES] = [
		7,
		{"actor": "", "evento_observado": "x"},
		{"actor": null, "evento_observado": "y"},
		{"actor": "remedios", "evento_observado": null},
	]
	var resumen := FinalPolitico.resumen(estado)
	var lecturas: Array = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.is_empty(), "lecturas corruptas se filtran")


func _abrir_cerrar_reabrir_no_muta() -> void:
	"""Abrir/cerrar/reabrir el final → no muta Partida, historial ni registros fuente."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(_ocho("socialdemocrata"))
	estado[Prometeo.CLAVE_LECTURAS_SOCIALES] = [
		{"actor": "remedios", "evento_observado": "v", "reaccion": "apoyo"}
	]
	var snapshot := JSON.stringify(estado)
	var resumen1 := FinalPolitico.resumen(estado)
	_comprobar(JSON.stringify(estado) == snapshot, "resumen no muta estado")
	var logros := FinalPolitico.confirmar_cierre(estado)
	_comprobar(not logros.is_empty(), "confirmar_cierre genera logros esperados")
	var resumen2 := FinalPolitico.resumen(estado)
	# Los ejes y lecturas sociales no se alteran al cerrar ni reabrir.
	var dominantes1: Array = resumen1.get("dominantes", [])
	var dominantes2: Array = resumen2.get("dominantes", [])
	_comprobar(dominantes1 == dominantes2, "reabrir no altera dominantes")
	var lecturas1: Array = resumen1.get("lecturas_sociales", [])
	var lecturas2: Array = resumen2.get("lecturas_sociales", [])
	_comprobar(lecturas1 == lecturas2, "reabrir no altera lecturas sociales")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		printerr("FALLO: %s" % nombre)
