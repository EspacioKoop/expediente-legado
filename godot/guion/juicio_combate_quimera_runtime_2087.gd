## Runtime puro de Quimera elite (#2087/#2385).
##
## Alterna un conjunto fijo de políticas ya existentes. Solo una unidad está
## activa a la vez; movimiento, colisiones, daño y presentación pertenecen al
## host común.
class_name JuicioCombateQuimeraRuntime2087
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

const PATRONES := [
	ARQUETIPOS.EMBESTIDOR,
	ARQUETIPOS.HOSTIGADOR,
	ARQUETIPOS.BLOQUEADOR,
]


static func nuevo(raiz: int) -> Dictionary:
	return _estado_para_patron(raiz, 0, 0)


static func avanzar(
	estado: Dictionary,
	delta: float,
	contextos: Dictionary = {},
) -> Dictionary:
	var copia := estado.duplicate(true)
	if copia.is_empty():
		copia = nuevo(0)

	var indice := clampi(int(copia.get("indice_patron", 0)), 0, PATRONES.size() - 1)
	var patron := String(PATRONES[indice])
	var unidad: Dictionary = copia.get("unidad", {})
	if unidad.is_empty() or String(unidad.get("tipo", "")) != patron:
		unidad = ARQUETIPOS.nuevo(patron, int(copia.get("_raiz", 0)), indice)

	var estado_anterior := String(unidad.get("estado", ""))
	var contexto = contextos.get(patron, {})
	if not contexto is Dictionary:
		contexto = {}

	var salida := ARQUETIPOS.avanzar(
		unidad,
		maxf(0.0, delta),
		contexto,
	)
	var unidad_actual: Dictionary = salida.get("unidad", unidad).duplicate(true)
	var cambio := _ciclo_completado(
		patron,
		estado_anterior,
		String(unidad_actual.get("estado", "")),
	)

	copia["unidad"] = unidad_actual
	copia["patron_actual"] = patron
	copia["indice_patron"] = indice

	if cambio:
		var ciclos := maxi(0, int(copia.get("ciclos", 0))) + 1
		var siguiente_indice := (indice + 1) % PATRONES.size()
		var siguiente_patron := String(PATRONES[siguiente_indice])
		copia = _estado_para_patron(
			int(copia.get("_raiz", 0)),
			siguiente_indice,
			ciclos,
		)
		return _resultado(
			copia,
			salida,
			patron,
			siguiente_patron,
			true,
		)

	return _resultado(
		copia,
		salida,
		patron,
		patron,
		false,
	)


static func _estado_para_patron(raiz: int, indice: int, ciclos: int) -> Dictionary:
	var acotado := posmod(indice, PATRONES.size())
	var patron := String(PATRONES[acotado])
	return {
		"_raiz": raiz,
		"indice_patron": acotado,
		"patron_actual": patron,
		"unidad": ARQUETIPOS.nuevo(patron, raiz, acotado),
		"ciclos": maxi(0, ciclos),
	}


static func _ciclo_completado(
	patron: String,
	estado_anterior: String,
	estado_actual: String,
) -> bool:
	match patron:
		ARQUETIPOS.EMBESTIDOR:
			return (
				estado_anterior == ARQUETIPOS.RECUPERAR
				and estado_actual == ARQUETIPOS.REPOSICIONAR
			)
		ARQUETIPOS.HOSTIGADOR:
			return (
				estado_anterior == ARQUETIPOS.VULNERABLE
				and estado_actual == ARQUETIPOS.REPOSICIONAR
			)
		ARQUETIPOS.BLOQUEADOR:
			return (
				estado_anterior == ARQUETIPOS.RECUPERAR
				and estado_actual == ARQUETIPOS.GUARDIA
			)
		_:
			return false


static func _resultado(
	estado: Dictionary,
	salida: Dictionary,
	patron_ejecutado: String,
	patron_actual: String,
	cambio_patron: bool,
) -> Dictionary:
	return {
		"estado": estado,
		"patron_ejecutado": patron_ejecutado,
		"patron_actual": patron_actual,
		"indice_patron": int(estado.get("indice_patron", 0)),
		"salida": salida.duplicate(true),
		"telegraph": String(salida.get("telegraph", "")),
		"ventana_respuesta": bool(salida.get("ventana_respuesta", false)),
		"cambio_patron": cambio_patron,
	}
