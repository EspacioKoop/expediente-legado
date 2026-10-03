## Adaptador mecánico del Tentador miniado (#2252 / #2088).
##
## Delega íntegramente en la política MIMÉTICO. Este fichero no decide arte,
## selección cultural, daño, colisiones ni consecuencias.
class_name JuicioCombateTentadorRuntime2088
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")


static func nuevo(raiz: int, indice: int = 0) -> Dictionary:
	return {
		"_raiz": raiz,
		"_indice": indice,
		"unidad": ARQUETIPOS.nuevo(ARQUETIPOS.MIMETICO, raiz, indice),
	}


static func avanzar(
	estado: Dictionary,
	delta: float,
	patron_observado: String,
) -> Dictionary:
	var copia := estado.duplicate(true)
	if copia.is_empty():
		copia = nuevo(0)

	var unidad: Dictionary = copia.get("unidad", {})
	if String(unidad.get("tipo", "")) != ARQUETIPOS.MIMETICO:
		unidad = (
			ARQUETIPOS
			. nuevo(
				ARQUETIPOS.MIMETICO,
				int(copia.get("_raiz", 0)),
				int(copia.get("_indice", 0)),
			)
		)

	var paso := (
		ARQUETIPOS
		. avanzar(
			unidad,
			delta,
			{"patron_observado": patron_observado},
		)
	)
	unidad = paso.get("unidad", unidad)
	copia["unidad"] = unidad

	return {
		"estado": copia,
		"intencion": String(paso.get("intencion", "")),
		"telegraph": String(paso.get("telegraph", "")),
		"ventana_respuesta": bool(paso.get("ventana_respuesta", false)),
		"patron_eco": String(unidad.get("patron_eco", "")),
	}
