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
	var ejemplos := []

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
