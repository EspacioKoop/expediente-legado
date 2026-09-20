## Reglas contextuales de religión dentro de un conflicto (#936).
##
## No consulta identidad religiosa ni compara tradiciones. Consume hechos
## explícitos de ReligionEventos y solo traduce práctica/convicción declarada a
## compromisos que cambian una decisión. El combate sin compromisos conserva
## todas sus acciones.
class_name ReligionConflicto
extends RefCounted

const REGLA_NO_INICIAR := "no_iniciar_agresion"
const REGLA_TREGUA_MUTUA := "tregua_mutua"
const REGLAS := [REGLA_NO_INICIAR, REGLA_TREGUA_MUTUA]


## Compromisos disponibles en un contexto concreto.
##
## Exposición y vínculo quedan fuera a propósito: conocer una tradición o tener
## relación con una comunidad no autoriza a deducir una obligación personal.
## Una tregua mutua exige además que el hecho sea público y conocido por el
## actor rival; una práctica privada nunca aparece mágicamente en su conocimiento.
static func compromisos_disponibles(
	registro: Dictionary, contexto: String, actor_rival: String = ""
) -> Array:
	var contexto_actual := contexto.strip_edges()
	if contexto_actual.is_empty():
		return []

	var resultado := []
	for canal in [ReligionEventos.CANAL_PRACTICA, ReligionEventos.CANAL_CONVICCION]:
		for evento_bruto in ReligionEventos.eventos(registro, canal):
			if typeof(evento_bruto) != TYPE_DICTIONARY:
				continue
			var evento: Dictionary = evento_bruto
			if String(evento.get("contexto", "")) != contexto_actual:
				continue
			for regla_bruta in evento.get("reglas_conflicto", []):
				var regla := String(regla_bruta)
				if regla == REGLA_NO_INICIAR:
					resultado.append(_compromiso_propio(evento))
				elif regla == REGLA_TREGUA_MUTUA and _hecho_conocido_por(evento, actor_rival):
					resultado.append(_compromiso_mutuo(evento))
	resultado.sort_custom(_ordenar)
	return resultado


## Regla táctica del primer vertical: mientras el compromiso esté vigente, el
## jugador cede la iniciativa. Puede responder cuando el rival ya inició la
## acción. Sin compromiso, la regla base permanece intacta.
static func puede_iniciar_accion_ofensiva(
	compromiso: Dictionary, rival_ya_inicio: bool
) -> bool:
	if String(compromiso.get("regla", "")) != REGLA_NO_INICIAR:
		return true
	return rival_ya_inicio


## Una tregua solo es una regla bilateral cuando fue validada como compromiso
## mutuo por compromisos_disponibles().
static func tregua_mutua_activa(compromiso: Dictionary) -> bool:
	return (
		String(compromiso.get("regla", "")) == REGLA_TREGUA_MUTUA
		and String(compromiso.get("alcance", "")) == "mutuo"
	)


static func _compromiso_propio(evento: Dictionary) -> Dictionary:
	return {
		"id": "%s:%s" % [String(evento.get("id", "")), REGLA_NO_INICIAR],
		"regla": REGLA_NO_INICIAR,
		"alcance": "propio",
		"fuente_evento": String(evento.get("id", "")),
		"etiquetas": ["restriccion", "respuesta"],
	}


static func _compromiso_mutuo(evento: Dictionary) -> Dictionary:
	return {
		"id": "%s:%s" % [String(evento.get("id", "")), REGLA_TREGUA_MUTUA],
		"regla": REGLA_TREGUA_MUTUA,
		"alcance": "mutuo",
		"fuente_evento": String(evento.get("id", "")),
		"etiquetas": ["control_espacio", "restriccion"],
	}


static func _hecho_conocido_por(evento: Dictionary, actor_rival: String) -> bool:
	var actor := actor_rival.strip_edges()
	if actor.is_empty() or not bool(evento.get("publico", false)):
		return false
	var conocidos = evento.get("conocido_por", [])
	return typeof(conocidos) == TYPE_ARRAY and conocidos.has(actor)


static func _ordenar(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("id", "")) < String(b.get("id", ""))
