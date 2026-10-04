## Síntesis factual del cierre político (#925 / #1103).
##
## No asigna una personalidad ni un alignment. Resume elecciones registradas en
## la vuelta, conserva empates reales y concede únicamente logros que describen
## patrones verificables de esas decisiones.
class_name FinalPolitico
extends RefCounted

const PATRON_SIN_REGISTRO := "sin_registro"
const PATRON_CONSISTENTE := "consistente"
const PATRON_PLURAL := "plural"
const PATRON_CONTEXTUAL := "contextual"

const LOGRO_FINAL := "papeleta-depositada"
const LOGRO_DISCIPLINA := "disciplina-de-partido"
const LOGRO_INSTINTO := "instinto-de-archivo"
const LOGRO_DESCARTE := "metodo-del-descarte"


static func resumen(estado: Dictionary, contrato: Dictionary = {}) -> Dictionary:
	var elecciones := Prometeo.elecciones_ideologicas(estado)
	var conteo := Prometeo.conteo_elecciones_ideologicas(estado)
	var dominantes := Prometeo.ejes_dominantes(estado)
	var patron := _patron(elecciones, dominantes)
	var auditoria := Auditorias.resumen_narrativo(estado)
	var religion := ReligionTrayectoria.resumir(ReligionEventos.resumen_trayectoria(estado))
	var ejemplos := []
	var eco_exposicion := _eco_exposicion(estado)
	var lecturas_sociales := _lecturas_sociales(estado)

	for evento in elecciones:
		if ejemplos.size() >= 4:
			break
		(
			ejemplos
			. append(
				{
					"contexto": String(evento.get("contexto", evento.get("id", ""))),
					"eje": String(evento.get("eje", "")),
					"fuente": String(evento.get("fuente", "")),
				}
			)
		)

	return {
		"patron": patron,
		"conteo": conteo,
		"dominantes": dominantes,
		"elecciones": elecciones.size(),
		"ejemplos": ejemplos,
		"eco_exposicion": eco_exposicion,
		"auditoria": auditoria,
		"religion": religion,
		"lecturas_sociales": lecturas_sociales,
		"veredicto": String(contrato.get("veredicto", "")),
	}


static func aplicar_logros(estado: Dictionary) -> Array:
	var ids := [LOGRO_FINAL]
	var historias := _historias_completas(estado)
	if historias.is_empty():
		return _desbloquear_logros(estado, ids)

	var ejes: Array = historias.values()
	if not ejes.is_empty() and ejes.all(func(eje): return eje == ejes[0]):
		ids.append(LOGRO_DISCIPLINA)

	var clases := []
	for carta_id in historias:
		clases.append(Prometeo.clasificar_eleccion(String(carta_id), String(historias[carta_id])))
	if clases.all(func(clase): return clase == "pista"):
		ids.append(LOGRO_INSTINTO)
	if clases.all(func(clase): return clase == "confusion"):
		ids.append(LOGRO_DESCARTE)

	return _desbloquear_logros(estado, ids)


static func confirmar_cierre(estado: Dictionary) -> Array:
	EvaluacionDesempeno.sellar(estado, "final_narrativo")
	Prometeo.archivar_trayectoria_ideologica(estado, "final_narrativo")
	ReligionEventos.archivar_trayectoria(estado, "final_narrativo")
	estado["final_politico_mostrado"] = true
	return aplicar_logros(estado)


static func _patron(elecciones: Array, dominantes: Array) -> String:
	if elecciones.is_empty():
		return PATRON_SIN_REGISTRO
	var ejes := {}
	for evento in elecciones:
		ejes[String(evento.get("eje", ""))] = true
	if ejes.size() == 1:
		return PATRON_CONSISTENTE
	if dominantes.size() > 1:
		return PATRON_PLURAL
	return PATRON_CONTEXTUAL


## Devuelve como máximo un eco factual de exposición de la jornada actual.
## El historial completo permanece en Prometeo.CLAVE_EXPOSICION_IDEOLOGICA.
static func _eco_exposicion(estado: Dictionary) -> Dictionary:
	var jornada = estado.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return {}
	var dia_actual := int((jornada as Dictionary).get("dia", 0))
	if dia_actual <= 0:
		return {}

	var valor = estado.get(Prometeo.CLAVE_EXPOSICION_IDEOLOGICA, [])
	if typeof(valor) != TYPE_ARRAY:
		return {}

	for exposicion in valor:
		if typeof(exposicion) != TYPE_DICTIONARY:
			continue
		var entrada: Dictionary = exposicion
		var id_crudo = entrada.get("id")
		var fuente_cruda = entrada.get("fuente")
		var eje_crudo = entrada.get("eje")
		var jornada_cruda = entrada.get("jornada")
		if (
			typeof(id_crudo) != TYPE_STRING
			or typeof(fuente_cruda) != TYPE_STRING
			or typeof(eje_crudo) != TYPE_STRING
			or (typeof(jornada_cruda) != TYPE_INT and typeof(jornada_cruda) != TYPE_FLOAT)
		):
			continue
		var jornada_numero := float(jornada_cruda)
		if not is_equal_approx(jornada_numero, roundf(jornada_numero)):
			continue
		if int(jornada_numero) != dia_actual:
			continue
		var id := String(id_crudo).strip_edges()
		var fuente := String(fuente_cruda).strip_edges()
		var eje := String(eje_crudo).strip_edges()
		if id.is_empty() or fuente.is_empty() or not Prometeo.EJES.has(eje):
			continue
		return {"id": id, "fuente": fuente, "eje": eje}
	return {}


static func _historias_completas(estado: Dictionary) -> Dictionary:
	var bruto = estado.get("historias_cartas", {})
	if typeof(bruto) != TYPE_DICTIONARY:
		return {}
	var historias: Dictionary = bruto
	if historias.size() != Prometeo.UTILIDAD_CARTAS.size():
		return {}
	for carta_id in Prometeo.UTILIDAD_CARTAS:
		if not historias.has(carta_id):
			return {}
		if not Prometeo.EJES.has(String(historias[carta_id])):
			return {}
	return historias


static func _desbloquear_logros(estado: Dictionary, ids: Array) -> Array:
	var nuevos := []
	var logros = estado.get("logros", [])
	if typeof(logros) != TYPE_ARRAY:
		return nuevos

	for logro in logros:
		if not ids.has(String(logro.get("id", ""))):
			continue
		if bool(logro.get("desbloqueado", false)):
			continue
		logro["desbloqueado"] = true
		nuevos.append(String(logro.get("id", "")))
	return nuevos


## Devuelve las lecturas sociales ya registradas en el estado (#920).
## Solo copia datos persistidos por su owner; no crea un segundo registro de epílogo.
static func _lecturas_sociales(estado: Dictionary) -> Array:
	var valor = estado.get(Prometeo.CLAVE_LECTURAS_SOCIALES, [])
	if typeof(valor) != TYPE_ARRAY:
		return []
	var salida := []
	for lectura in valor:
		if typeof(lectura) != TYPE_DICTIONARY:
			continue
		var entrada: Dictionary = lectura
		var actor_crudo = entrada.get("actor")
		var evento_crudo = entrada.get("evento_observado")
		if typeof(actor_crudo) != TYPE_STRING or typeof(evento_crudo) != TYPE_STRING:
			continue
		var actor := String(actor_crudo).strip_edges()
		var evento := String(evento_crudo).strip_edges()
		if actor.is_empty() or evento.is_empty():
			continue
		var reaccion_cruda = entrada.get("reaccion", "")
		var etiquetas_crudas = entrada.get("etiquetas", [])
		(
			salida
			. append(
				{
					"actor": actor,
					"evento_observado": evento,
					"reaccion":
					String(reaccion_cruda) if typeof(reaccion_cruda) == TYPE_STRING else "",
					"etiquetas":
					(
						(etiquetas_crudas as Array).duplicate(true)
						if typeof(etiquetas_crudas) == TYPE_ARRAY
						else []
					),
				}
			)
		)
	return salida
