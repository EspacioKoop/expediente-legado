## Adaptador onírico del contrato religioso común (#935).
##
## No selecciona familias, no inventa símbolos sagrados y no interpreta una
## tradición concreta. Solo traduce hechos ya registrados por ReligionEventos
## durante la jornada actual a parámetros de la gramática visual común.
class_name ReligionSueno935
extends RefCounted

const PRIORIDAD_POR_CANAL := {
	ReligionEventos.CANAL_CONVICCION: 10,
	ReligionEventos.CANAL_PRACTICA: 20,
	ReligionEventos.CANAL_VINCULO: 30,
	ReligionEventos.CANAL_EXPOSICION: 40,
}

const NOMBRE_ORIGEN_POR_CANAL := {
	ReligionEventos.CANAL_EXPOSICION: "exposicion",
	ReligionEventos.CANAL_PRACTICA: "practica",
	ReligionEventos.CANAL_CONVICCION: "conviccion",
	ReligionEventos.CANAL_VINCULO: "vinculo",
}

## Perfiles no confesionales y parciales. Reutilizan exclusivamente parámetros
## admitidos por SuenoCielos; no codifican iconografía ni equivalencias entre
## religiones, mitologías o Tarot.
const PARAMETROS_POR_CANAL := {
	ReligionEventos.CANAL_EXPOSICION:
	{
		"cirros": 0.28,
		"estrellas_secundarias": 0.48,
	},
	ReligionEventos.CANAL_PRACTICA:
	{
		"luna_halo": 0.16,
		"luz_lunar_nubes": 0.48,
	},
	ReligionEventos.CANAL_CONVICCION:
	{
		"ocaso_mezcla": 0.30,
		"via_lactea": 0.15,
	},
	ReligionEventos.CANAL_VINCULO:
	{
		"bruma_fuerza": 0.46,
		"resplandor_fuerza": 0.38,
	},
}


static func modificadores(
	registro: Dictionary, jornada_actual: int, reduccion_movimiento: bool = false
) -> Array:
	var resultado := []
	for canal in ReligionEventos.CANALES:
		if not _hay_evento_en_jornada(registro, canal, jornada_actual):
			continue
		var parametros: Dictionary = PARAMETROS_POR_CANAL.get(canal, {}).duplicate(true)
		if reduccion_movimiento:
			parametros = _reducir_movimiento(parametros)
		(
			resultado
			. append(
				{
					"origen": "religion:%s" % String(NOMBRE_ORIGEN_POR_CANAL.get(canal, canal)),
					"prioridad": int(PRIORIDAD_POR_CANAL.get(canal, 100)),
					"parametros": parametros,
				}
			)
		)
	return resultado


static func _hay_evento_en_jornada(
	registro: Dictionary, canal: String, jornada_actual: int
) -> bool:
	for evento_crudo in ReligionEventos.eventos(registro, canal):
		if typeof(evento_crudo) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = evento_crudo
		if int(evento.get("jornada", -1)) == jornada_actual:
			return true
	return false


## Los perfiles son estáticos, pero algunos uniforms animan nubes/cirros en el
## shader común. Con reducción de movimiento bajamos su peso sin eliminar la
## distinción entre canales.
static func _reducir_movimiento(parametros: Dictionary) -> Dictionary:
	var reducido := parametros.duplicate(true)
	for clave in ["cirros", "nubes", "luz_lunar_nubes"]:
		if reducido.has(clave):
			reducido[clave] = float(reducido[clave]) * 0.55
	return reducido
