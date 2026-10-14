## Receta pura de feedback de impacto (#2473 / #2568).
##
## Devuelve datos declarativos para presentación de golpes. No instancia nodos,
## no reproduce sonido, no toca daño y no guarda estado.
class_name JuicioCombateRecetaImpacto
extends RefCounted

const LIGERO := "ligero"
const FUERTE := "fuerte"
const FINISHER := "finisher"
const BLOQUEADO := "bloqueado"
const STAGGER := "stagger"

const CLAVE_REDUCCION_MOVIMIENTO := "reduccion_movimiento"

const MAX_HITSTOP := 0.18
const MAX_SHAKE_DURACION := 0.22
const MAX_SHAKE_INTENSIDAD := 0.78
const MAX_DESPLAZAMIENTO := 0.75
const MAX_PARTICULAS := 12
const MAX_FLASH_DURACION := 0.16
const MAX_FLASH_INTENSIDAD := 0.7

const _TIPOS_VALIDOS: Array[String] = [LIGERO, FUERTE, FINISHER, BLOQUEADO, STAGGER]

const _RECETAS_BASE := {
	LIGERO:
	{
		"hitstop": 0.045,
		"shake": {"duracion": 0.055, "intensidad": 0.18},
		"desplazamiento_reaccion": 0.12,
		"particulas": 3,
		"flash": {"duracion": 0.04, "intensidad": 0.14, "animado": true},
		"senal_estatica": {"duracion": 0.045, "intensidad": 0.14},
		"intensidad": 1.0,
	},
	FUERTE:
	{
		"hitstop": 0.09,
		"shake": {"duracion": 0.105, "intensidad": 0.38},
		"desplazamiento_reaccion": 0.32,
		"particulas": 7,
		"flash": {"duracion": 0.08, "intensidad": 0.34, "animado": true},
		"senal_estatica": {"duracion": 0.09, "intensidad": 0.34},
		"intensidad": 2.0,
	},
	FINISHER:
	{
		"hitstop": MAX_HITSTOP,
		"shake": {"duracion": MAX_SHAKE_DURACION, "intensidad": MAX_SHAKE_INTENSIDAD},
		"desplazamiento_reaccion": MAX_DESPLAZAMIENTO,
		"particulas": MAX_PARTICULAS,
		"flash":
		{"duracion": MAX_FLASH_DURACION, "intensidad": MAX_FLASH_INTENSIDAD, "animado": true},
		"senal_estatica": {"duracion": MAX_HITSTOP, "intensidad": MAX_FLASH_INTENSIDAD},
		"intensidad": 3.0,
	},
	BLOQUEADO:
	{
		"hitstop": 0.035,
		"shake": {"duracion": 0.0, "intensidad": 0.0},
		"desplazamiento_reaccion": 0.0,
		"particulas": 2,
		"flash": {"duracion": 0.0, "intensidad": 0.0, "animado": false},
		"senal_estatica": {"duracion": 0.05, "intensidad": 0.22},
		"intensidad": 0.6,
	},
	STAGGER:
	{
		"hitstop": 0.12,
		"shake": {"duracion": 0.16, "intensidad": 0.52},
		"desplazamiento_reaccion": 0.48,
		"particulas": 6,
		"flash": {"duracion": 0.11, "intensidad": 0.46, "animado": true},
		"senal_estatica": {"duracion": 0.12, "intensidad": 0.5},
		"intensidad": 2.45,
	},
}


static func tipos_validos() -> Array[String]:
	return _TIPOS_VALIDOS.duplicate()


static func receta(tipo: String, contexto: Dictionary = {}) -> Dictionary:
	var tipo_normalizado := _normalizar_tipo(tipo)
	var resultado: Dictionary = _RECETAS_BASE[tipo_normalizado].duplicate(true)
	resultado["tipo"] = tipo_normalizado
	if bool(contexto.get(CLAVE_REDUCCION_MOVIMIENTO, false)):
		_aplicar_reduccion_movimiento(resultado)
	return _aplicar_cotas(resultado)


static func intensidad(tipo: String) -> float:
	return float(_RECETAS_BASE[_normalizar_tipo(tipo)].get("intensidad", 0.0))


static func es_valida(receta_candidata: Dictionary) -> bool:
	return (
		receta_candidata.has("tipo")
		and receta_candidata.has("hitstop")
		and receta_candidata.has("shake")
		and receta_candidata.has("desplazamiento_reaccion")
		and receta_candidata.has("particulas")
		and receta_candidata.has("flash")
		and receta_candidata.has("senal_estatica")
		and receta_candidata.has("intensidad")
		and String(receta_candidata["tipo"]) in _TIPOS_VALIDOS
		and _numero_en_rango(receta_candidata["hitstop"], 0.0, MAX_HITSTOP)
		and _numero_en_rango(receta_candidata["desplazamiento_reaccion"], 0.0, MAX_DESPLAZAMIENTO)
		and int(receta_candidata["particulas"]) >= 0
		and int(receta_candidata["particulas"]) <= MAX_PARTICULAS
		and _shake_valido(receta_candidata["shake"])
		and _flash_valido(receta_candidata["flash"])
		and receta_candidata["senal_estatica"] is Dictionary
		and _es_numero(receta_candidata["intensidad"])
	)


static func _normalizar_tipo(tipo: String) -> String:
	var normalizado := tipo.strip_edges().to_lower()
	if normalizado in _TIPOS_VALIDOS:
		return normalizado
	return LIGERO


static func _aplicar_reduccion_movimiento(resultado: Dictionary) -> void:
	resultado["shake"] = {"duracion": 0.0, "intensidad": 0.0}
	resultado["desplazamiento_reaccion"] = 0.0
	resultado["flash"] = {
		"duracion": 0.0,
		"intensidad": 0.0,
		"animado": false,
	}
	var senal: Dictionary = resultado.get("senal_estatica", {}).duplicate(true)
	senal["duracion"] = maxf(
		float(senal.get("duracion", 0.0)), float(resultado.get("hitstop", 0.0))
	)
	resultado["senal_estatica"] = senal


static func _aplicar_cotas(resultado: Dictionary) -> Dictionary:
	var copia := resultado.duplicate(true)
	copia["hitstop"] = clampf(float(copia.get("hitstop", 0.0)), 0.0, MAX_HITSTOP)
	copia["desplazamiento_reaccion"] = clampf(
		float(copia.get("desplazamiento_reaccion", 0.0)), 0.0, MAX_DESPLAZAMIENTO
	)
	copia["particulas"] = clampi(int(copia.get("particulas", 0)), 0, MAX_PARTICULAS)
	copia["shake"] = _acotar_shake(copia.get("shake", {}))
	copia["flash"] = _acotar_flash(copia.get("flash", {}))
	return copia


static func _acotar_shake(valor: Variant) -> Dictionary:
	var shake := valor if valor is Dictionary else {}
	return {
		"duracion": clampf(float(shake.get("duracion", 0.0)), 0.0, MAX_SHAKE_DURACION),
		"intensidad": clampf(float(shake.get("intensidad", 0.0)), 0.0, MAX_SHAKE_INTENSIDAD),
	}


static func _acotar_flash(valor: Variant) -> Dictionary:
	var flash := valor if valor is Dictionary else {}
	return {
		"duracion": clampf(float(flash.get("duracion", 0.0)), 0.0, MAX_FLASH_DURACION),
		"intensidad": clampf(float(flash.get("intensidad", 0.0)), 0.0, MAX_FLASH_INTENSIDAD),
		"animado": bool(flash.get("animado", false)),
	}


static func _shake_valido(valor: Variant) -> bool:
	return (
		valor is Dictionary
		and _numero_en_rango(valor.get("duracion", -1.0), 0.0, MAX_SHAKE_DURACION)
		and _numero_en_rango(valor.get("intensidad", -1.0), 0.0, MAX_SHAKE_INTENSIDAD)
	)


static func _flash_valido(valor: Variant) -> bool:
	return (
		valor is Dictionary
		and _numero_en_rango(valor.get("duracion", -1.0), 0.0, MAX_FLASH_DURACION)
		and _numero_en_rango(valor.get("intensidad", -1.0), 0.0, MAX_FLASH_INTENSIDAD)
		and typeof(valor.get("animado", false)) == TYPE_BOOL
	)


static func _numero_en_rango(valor: Variant, minimo: float, maximo: float) -> bool:
	if not _es_numero(valor):
		return false
	var numero := float(valor)
	return numero >= minimo and numero <= maximo


static func _es_numero(valor: Variant) -> bool:
	return typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT
