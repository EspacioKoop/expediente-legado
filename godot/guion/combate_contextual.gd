## Política de entrada al combate físico de #1752.
##
## No ejecuta golpes ni cobra consecuencias. Solo decide si una escena puede
## abrir el hack & slash común. Así sueño y realidad comparten motor sin
## compartir permiso ni significado.
class_name CombateContextual
extends RefCounted

const PLANO_SUENO := "sueno"
const PLANO_REALIDAD := "realidad"

const ACCION_COMBATIR := "combatir"
const ACCION_CONDUCTA := "conducta"
const ACCION_NINGUNA := "ninguna"


## Decide si un objetivo puede abrir un combate físico.
##
## - Sueño: delega en SuenoCombate, que ya limita a figuras acusadas/no vencidas.
## - Realidad: exige opt-in de la escena Y una consecuencia declarada. Una pelea
##   real sin coste/resultado explícito no es un encuentro autorizado.
## - Fuera de ambos casos: no abre arena. La agresión puede ser consumida por
##   IncidentesConducta (por ejemplo #209), pero nunca genera momentum por sí sola.
static func evaluar(fase: String, objetivo: Dictionary, estado: Dictionary) -> Dictionary:
	if fase == "sueño":
		var permitido := SuenoCombate.se_pelea(objetivo, estado)
		return {
			"permitido": permitido,
			"plano": PLANO_SUENO,
			"accion": ACCION_COMBATIR if permitido else ACCION_NINGUNA,
			"consecuencia": {"tipo": "sueno"} if permitido else {},
			"genera_momentum": permitido,
		}

	var consecuencia = objetivo.get("consecuencia_combate", {})
	var consecuencia_valida: bool = consecuencia is Dictionary and not consecuencia.is_empty()
	var autorizado := bool(objetivo.get("combate_autorizado", false)) and consecuencia_valida
	if autorizado:
		return {
			"permitido": true,
			"plano": PLANO_REALIDAD,
			"accion": ACCION_COMBATIR,
			"consecuencia": consecuencia.duplicate(true),
			"genera_momentum": true,
		}

	return {
		"permitido": false,
		"plano": PLANO_REALIDAD,
		"accion": ACCION_CONDUCTA,
		"consecuencia": {},
		"genera_momentum": false,
	}


## Atajo para escenas reales: obliga a declarar la consecuencia junto al permiso.
static func autorizar_realidad(objetivo: Dictionary, consecuencia: Dictionary) -> Dictionary:
	var copia := objetivo.duplicate(true)
	copia["combate_autorizado"] = not consecuencia.is_empty()
	copia["consecuencia_combate"] = consecuencia.duplicate(true)
	return copia
