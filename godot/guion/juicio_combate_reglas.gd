## Reglas puras del Juicio por Combate.
##
## No dependen del SceneTree ni de nodos visuales. JuicioCombate3D conserva
## wrappers compatibles mientras la escena se reduce a orquestación.
class_name JuicioCombateReglas
extends RefCounted

const DETERMINACION_BASE := 8
const DETERMINACION_MINIMA_RIVAL := 4
const ALCANCE_RIVAL := 1.45
const RECARGA_RIVAL := 1.15
const TELEGRAFO_RIVAL := 0.45
const DURACION_DOCTRINA := 4.0
const BONUS_TELEGRAFO_COMISION := 0.55


static func determinacion_rival(bono_documental: int) -> int:
	return maxi(DETERMINACION_MINIMA_RIVAL, DETERMINACION_BASE - maxi(0, bono_documental))


static func resultado_ataque_rival(distancia: float, esquiva_restante: float) -> String:
	if distancia > ALCANCE_RIVAL:
		return "falla"
	if esquiva_restante > 0.0:
		return "esquiva"
	return "impacto"


static func interrumpe_ataque(fuerte: bool, ataque_pendiente: bool, ritual: Dictionary) -> bool:
	return fuerte and ataque_pendiente and bool(ritual.get("interrumpe_telegrafo_fuerte", false))


static func modificadores_doctrina_ritual(eje: String, ritual: Dictionary) -> Dictionary:
	var etiquetas = ritual.get("tags", [])
	if typeof(etiquetas) != TYPE_ARRAY:
		return {}
	var modificadores := {}
	match eje:
		"comunismo":
			if etiquetas.has("control_espacio"):
				modificadores["duracion_mul"] = 1.25
		"centrista":
			if etiquetas.has("neutralizar"):
				modificadores["recarga_rival_mul"] = 1.25
		"socialdemocrata":
			if etiquetas.has("telegraph"):
				modificadores["telegraph_bonus"] = 0.25
		"neoliberal":
			if etiquetas.has("riesgo"):
				modificadores["duracion_mul"] = 1.25
	return modificadores


static func duracion_doctrina(eje: String, ritual: Dictionary) -> float:
	var modificadores := modificadores_doctrina_ritual(eje, ritual)
	return DURACION_DOCTRINA * float(modificadores.get("duracion_mul", 1.0))


static func duracion_telegrafo(comision: bool, ritual: Dictionary) -> float:
	if not comision:
		return TELEGRAFO_RIVAL
	var modificadores := modificadores_doctrina_ritual("socialdemocrata", ritual)
	return (
		TELEGRAFO_RIVAL
		+ BONUS_TELEGRAFO_COMISION
		+ float(modificadores.get("telegraph_bonus", 0.0))
	)


static func recarga_mesa(ritual: Dictionary) -> float:
	var modificadores := modificadores_doctrina_ritual("centrista", ritual)
	return RECARGA_RIVAL * float(modificadores.get("recarga_rival_mul", 1.0))


static func asamblea_interrumpe(eje_activo: String, ataque_pendiente: bool) -> bool:
	return eje_activo == "comunismo" and ataque_pendiente


static func dano_externalizado(dano_base: int, eje_activo: String) -> int:
	return dano_base * 2 if eje_activo == "neoliberal" else dano_base


static func determinacion_retorno(ritual: Dictionary, retornos_usados: int) -> int:
	var maximo := int(ritual.get("retornos_rival", 0))
	if retornos_usados >= maximo:
		return 0
	return maxi(0, int(ritual.get("determinacion_retorno", 0)))
