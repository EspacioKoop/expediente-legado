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
	"""Sin eventos #920/#922/#923, el resumen sigue teniendo las capas base."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(["socialdemocrata"] * 8)
	var resumen := FinalPolitico.resumen(estado)
	# Las capas fundamentales existen siempre.
	_comprobar(resumen.has("patron"), "el resumen siempre incluye patron")
	_comprobar(resumen.has("dominantes"), "el resumen siempre incluye dominantes")
	_comprobar(resumen.has("ejemplos"), "el resumen siempre incluye ejemplos")
	# Sin ecos registrados, las claves opcionales deben ser vacías.
	var lecturas = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.is_empty(), "sin lecturas sociales cuando no hay eventos #920")
	var despertar = resumen.get("eco_despertar", {})
	_comprobar(despertar.is_empty(), "sin eco_despertar cuando no hay eventos #922")


func _un_eco_social_aparece_una_vez() -> void:
	"""Un evento social aparece una vez y no altera conteos/ejes/logros."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(["comunismo"] * 8)
	estado[Prometeo.CLAVE_LECTURAS_SOCIALES] = [
		{
			"actor": "cunado",
			"evento_observado": "evento_vertical",
			"reaccion": "cierre_colectivo",
			"etiquetas": ["expediente", "postcierre"],
		}
	]
	var resumen := FinalPolitico.resumen(estado)
	var lecturas = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.size() == 1, "un actor genera un eco social")
	# Los ejes y conteos no cambian por el eco.
	var conteo := FinalPolitico.resumen(estado).get("conteo", {})
	_comprobar(conteo.get("comunismo", 0) == 8, "el conteo conserva el eje real")


func _maximo_dos_ecos_y_orden_estable() -> void:
	"""Varios ecos → máximo 2 y orden estable tras guardar/recargar."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(["centrista"] * 8)
	estado[Prometeo.CLAVE_LECTURAS_SOCIALES] = [
		{"actor": "becario", "evento_observado": "evento_vertical"},
		{"actor": "jubilacion", "evento_observado": "evento_vertical"},
		{"actor": "cunado", "evento_observado": "evento_vertical"},
	]
	var despertar := {
		"id": "eco:2:humedad:papelera",
		"tipo": "humedad",
		"origen_id": "papelera",
		"consumido": false,
	}
	estado["eco_despertar"] = despertar
	var resumen := FinalPolitico.resumen(estado)
	var lecturas = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.size() <= 2, "las lecturas sociales no superan 2")
	# El orden es determinista: prioridad=10 para todos, luego id ascendente.
	if lecturas.size() >= 2:
		var primer_actor := String(lecturas[0].get("actor", ""))
		var segundo_actor := String(lecturas[1].get("actor", ""))
		_comprobar(
			primer_actor < segundo_actor,
			(
				"el orden es id ascendente cuando la prioridad es igual (%s < %s)"
				% [primer_actor, segundo_actor]
			)
		)


func _evento_corrupto_se_ignora() -> void:
	"""Evento desconocido/corrupto → se ignora de forma segura."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(["neoliberal"] * 8)
	# Lecturas rotas: sin tipo correcto, sin actor, con enteros.
	estado[Prometeo.CLAVE_LECTURAS_SOCIALES] = [
		7,  # no es Dictionary
		{"actor": "", "evento_observado": "x"},  # actor vacío
		{"actor": null, "evento_observado": "y"},  # actor null
	]
	var despertar := "esto no es un diccionario"  # formato errado
	estado["eco_despertar"] = despertar
	var resumen := FinalPolitico.resumen(estado)
	var lecturas = resumen.get("lecturas_sociales", [])
	_comprobar(lecturas.is_empty(), "lecturas corruptas se filtran")
	var despertar_res = resumen.get("eco_despertar", {})
	_comprobar(despertar_res.is_empty(), "eco_despertar corrupto se filtra")


func _abrir_cerrar_reabrir_no_muta() -> void:
	"""Abrir/cerrar/reabrir el final → no muta Partida, historial ni registros fuente."""
	var estado := _estado_base()
	estado["historias_cartas"] = _historias(["socialdemocrata"] * 8)
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
	var dominantes1 := resumen1.get("dominantes", [])
	var dominantes2 := resumen2.get("dominantes", [])
	_comprobar(dominantes1 == dominantes2, "reabrir no altera dominantes")
	var lecturas1 = resumen1.get("lecturas_sociales", [])
	var lecturas2 = resumen2.get("lecturas_sociales", [])
	_comprobar(lecturas1 == lecturas2, "reabrir no altera lecturas sociales")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		printerr("FALLO: %s" % nombre)
