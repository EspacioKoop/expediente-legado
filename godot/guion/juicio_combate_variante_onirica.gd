## Selector de revestimientos oníricos de combate.
##
## Solo consume hechos culturales/religiosos observables ya registrados. Nunca
## infiere convicción ni modifica la política mecánica elegida por el host.
class_name JuicioCombateVarianteOnirica
extends RefCounted

const GARGOLA_UMBRAL := "gargola_umbral"


static func elegir(
	arquetipo: String,
	estado_partida: Dictionary,
	jornada: Dictionary,
	plano: String,
) -> String:
	if plano != CombateContextual.PLANO_SUENO or arquetipo != JuicioCombateArquetipos.BLOQUEADOR:
		return ""
	var registro = estado_partida.get(ReligionEventos.CLAVE_ESTADO, {})
	if typeof(registro) != TYPE_DICTIONARY:
		return ""
	var dia := int(jornada.get("dia", 0))
	if dia <= 0:
		return ""
	for canal in [
		ReligionEventos.CANAL_EXPOSICION,
		ReligionEventos.CANAL_PRACTICA,
		ReligionEventos.CANAL_VINCULO,
	]:
		for valor in ReligionEventos.eventos(registro, canal):
			if typeof(valor) != TYPE_DICTIONARY:
				continue
			if int(valor.get("jornada", -1)) == dia:
				return GARGOLA_UMBRAL
	return ""
