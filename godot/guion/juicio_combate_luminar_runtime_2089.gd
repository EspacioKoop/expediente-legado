## Runtime puro del Falso Luminar (#2089/#2395).
##
## MIMETICO produce el señuelo. Solo cuando ese ciclo termina se habilita
## HOSTIGADOR para el ataque real. Nunca hay dos amenazas activas en el mismo tick.
class_name JuicioCombateLuminarRuntime2089
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

const FASE_SENUELO := "senuelo"
const FASE_ATAQUE := "ataque"
const PATRON_SENUELO := "linea"
const DESFASE_SENUELO_RAD := deg_to_rad(35.0)


static func nuevo(raiz: int) -> Dictionary:
	return {
		"_raiz": raiz,
		"fase": FASE_SENUELO,
		"mimetico": ARQUETIPOS.nuevo(ARQUETIPOS.MIMETICO, raiz, 0),
		"hostigador": ARQUETIPOS.nuevo(ARQUETIPOS.HOSTIGADOR, raiz, 1),
		"ciclos": 0,
	}


static func avanzar(
	estado: Dictionary,
	delta: float,
	contexto_hostigador: Dictionary = {},
) -> Dictionary:
	var copia := estado.duplicate(true)
	if copia.is_empty():
		copia = nuevo(0)

	var fase := String(copia.get("fase", FASE_SENUELO))
	if fase == FASE_ATAQUE:
		return _avanzar_ataque(copia, delta, contexto_hostigador)
	return _avanzar_senuelo(copia, delta)


static func _avanzar_senuelo(estado: Dictionary, delta: float) -> Dictionary:
	var unidad: Dictionary = estado.get("mimetico", {})
	if unidad.is_empty():
		unidad = ARQUETIPOS.nuevo(ARQUETIPOS.MIMETICO, int(estado.get("_raiz", 0)), 0)

	var anterior := String(unidad.get("estado", ARQUETIPOS.OBSERVAR))
	var salida := (
		ARQUETIPOS
		. avanzar(
			unidad,
			maxf(0.0, delta),
			{"patron_observado": PATRON_SENUELO},
		)
	)
	var actual: Dictionary = salida.get("unidad", unidad).duplicate(true)
	estado["mimetico"] = actual

	var estado_actual := String(actual.get("estado", ""))
	var visible := estado_actual in [ARQUETIPOS.TELEGRAFIAR_ECO, ARQUETIPOS.REPETIR]
	var completo := anterior == ARQUETIPOS.RECUPERAR and estado_actual == ARQUETIPOS.OBSERVAR
	if completo:
		estado["fase"] = FASE_ATAQUE
		estado["hostigador"] = (
			ARQUETIPOS
			. nuevo(
				ARQUETIPOS.HOSTIGADOR,
				int(estado.get("_raiz", 0)),
				1,
			)
		)

	return {
		"estado": estado,
		"senal_senuelo": visible,
		"desfase_senuelo": DESFASE_SENUELO_RAD,
		"ataque_real": false,
		"telegraph": String(salida.get("telegraph", "")),
		"ventana_respuesta": bool(salida.get("ventana_respuesta", false)),
		"fase": String(estado.get("fase", FASE_SENUELO)),
	}


static func _avanzar_ataque(
	estado: Dictionary,
	delta: float,
	contexto_hostigador: Dictionary,
) -> Dictionary:
	var unidad: Dictionary = estado.get("hostigador", {})
	if unidad.is_empty():
		unidad = ARQUETIPOS.nuevo(ARQUETIPOS.HOSTIGADOR, int(estado.get("_raiz", 0)), 1)

	var anterior := String(unidad.get("estado", ARQUETIPOS.REPOSICIONAR))
	var salida := (
		ARQUETIPOS
		. avanzar(
			unidad,
			maxf(0.0, delta),
			contexto_hostigador,
		)
	)
	var actual: Dictionary = salida.get("unidad", unidad).duplicate(true)
	estado["hostigador"] = actual

	var estado_actual := String(actual.get("estado", ""))
	var ataque_real := String(salida.get("intencion", "")) == ARQUETIPOS.DISPARAR_LINEA
	var completo := anterior == ARQUETIPOS.VULNERABLE and estado_actual == ARQUETIPOS.REPOSICIONAR
	if completo:
		var ciclos := maxi(0, int(estado.get("ciclos", 0))) + 1
		estado = nuevo(int(estado.get("_raiz", 0)))
		estado["ciclos"] = ciclos

	return {
		"estado": estado,
		"senal_senuelo": false,
		"desfase_senuelo": DESFASE_SENUELO_RAD,
		"ataque_real": ataque_real,
		"telegraph": String(salida.get("telegraph", "")),
		"ventana_respuesta": bool(salida.get("ventana_respuesta", false)),
		"fase": String(estado.get("fase", FASE_SENUELO)),
	}
