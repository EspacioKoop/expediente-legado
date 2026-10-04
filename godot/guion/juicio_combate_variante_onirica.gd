## Selector de revestimientos oníricos de combate.
##
## Solo consume hechos culturales/religiosos observables ya registrados. Nunca
## infiere convicción ni modifica la política mecánica elegida por el host.
class_name JuicioCombateVarianteOnirica
extends RefCounted

const GARGOLA_UMBRAL := "gargola_umbral"
const ARCONTE_UMBRAL := "arconte_umbral"
const TRADICION_GNOSTICA := "gnosticismo"
const CONTEXTO_ARCONTE := "nag_hammadi:ii_4:hypostasis_archons"


static func elegir(
	arquetipo: String,
	estado_partida: Dictionary,
	jornada: Dictionary,
	plano: String,
) -> String:
	if plano != CombateContextual.PLANO_SUENO:
		return ""
	var registro = estado_partida.get(ReligionEventos.CLAVE_ESTADO, {})
	if typeof(registro) != TYPE_DICTIONARY:
		return ""
	var dia := int(jornada.get("dia", 0))
	if dia <= 0:
		return ""

	if arquetipo == JuicioCombateArquetipos.BLOQUEADOR:
		return GARGOLA_UMBRAL if _hay_exposicion_gargola(registro, dia) else ""
	if arquetipo == JuicioCombateArquetipos.CONTROLADOR:
		return ARCONTE_UMBRAL if _hay_exposicion_arconte(registro, dia) else ""
	return ""


static func _hay_exposicion_gargola(registro: Dictionary, dia: int) -> bool:
	for canal in [
		ReligionEventos.CANAL_EXPOSICION,
		ReligionEventos.CANAL_PRACTICA,
		ReligionEventos.CANAL_VINCULO,
	]:
		for valor in ReligionEventos.eventos(registro, canal):
			if typeof(valor) != TYPE_DICTIONARY:
				continue
			if int(valor.get("jornada", -1)) == dia:
				return true
	return false


static func _hay_exposicion_arconte(registro: Dictionary, dia: int) -> bool:
	for valor in ReligionEventos.eventos(registro, ReligionEventos.CANAL_EXPOSICION):
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		if int(valor.get("jornada", -1)) != dia:
			continue
		var tradicion := String(valor.get("tradicion", "")).strip_edges()
		var contexto := String(valor.get("contexto", "")).strip_edges()
		if tradicion == TRADICION_GNOSTICA and contexto == CONTEXTO_ARCONTE:
			return true
	return false
