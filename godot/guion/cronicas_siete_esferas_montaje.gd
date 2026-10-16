## Plan de presentación del clímax multicapa de Crónicas (#2589).
##
## Lee exclusivamente el estado canónico de ClimaxHastur. No concede pistas,
## no inicia duelos, no altera guardados y no decide el veredicto ni el final.
class_name CronicasSieteEsferasMontaje
extends RefCounted

const CAPA_OS98 := "os98"
const CAPA_SUENO := "sueno"
const CAPA_CRONICAS := "cronicas"
const CAPA_VIGILIA := "vigilia"


## Las tres banderas de visita proceden de interacciones ya verificadas por
## sus dueños. Este adaptador no las escribe ni las infiere a partir de sueños.
static func plan(
	estado: Dictionary,
	jornada: Dictionary,
	visitas_verificadas: Dictionary = {},
) -> Dictionary:
	var climax := ClimaxHastur.estado_actual(estado, jornada)
	if climax.is_empty():
		return {}

	var fase := String(climax.get("fase", ""))
	if not (
		[
			ClimaxHastur.FASE_COMBATE,
			ClimaxHastur.FASE_VICTORIA,
			ClimaxHastur.FASE_DERROTA,
			ClimaxHastur.FASE_FINAL,
		]
		. has(fase)
	):
		return {}

	# Ninguna secuencia de Crónicas es requisito del final canónico.
	var capas: Array[String] = [CAPA_OS98]
	if bool(visitas_verificadas.get("sueno_cronicas_visto", false)):
		capas.append(CAPA_SUENO)
	if bool(visitas_verificadas.get("cronicas_jugadas", false)):
		capas.append(CAPA_CRONICAS)
	capas.append(CAPA_VIGILIA)

	var modo := "combate"
	if fase == ClimaxHastur.FASE_FINAL:
		modo = "epilogo"
	elif fase != ClimaxHastur.FASE_COMBATE:
		modo = "transicion"

	return {
		"clave_vuelta": ClimaxHastur.clave_vuelta(jornada),
		"fase_canonica": fase,
		"modo": modo,
		"capas": capas,
		"presentacion_solamente": true,
		"resolucion_propietario": "ClimaxHastur",
	}
