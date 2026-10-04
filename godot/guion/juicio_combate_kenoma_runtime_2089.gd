## Adaptador mecánico del Eco del Kenoma (#2089).
##
## Reutiliza el ciclo MIMÉTICO en un conjunto acotado. No instancia cuerpos,
## aplica daño ni decide su representación cultural.
class_name JuicioCombateKenomaRuntime2089
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

const LIMITE_ECOS := 3


static func nuevo(raiz: int, cantidad: int = LIMITE_ECOS) -> Dictionary:
	var ecos: Array = []
	var cantidad_acotada := clampi(cantidad, 0, LIMITE_ECOS)
	for indice in range(cantidad_acotada):
		(
			ecos
			. append(
				{
					"indice": indice,
					"unidad": ARQUETIPOS.nuevo(ARQUETIPOS.MIMETICO, raiz, indice),
				}
			)
		)
	return {
		"_raiz": raiz,
		"ecos": ecos,
		"pendientes_spawn": range(cantidad_acotada),
	}


static func avanzar(
	estado: Dictionary,
	delta: float,
	patron_observado: String,
	ecos_destruidos: Array = [],
	reduccion_movimiento: bool = false,
) -> Dictionary:
	var copia := estado.duplicate(true)
	if copia.is_empty():
		copia = nuevo(0)

	var destruidos := _indices_destruidos(ecos_destruidos)
	var ecos: Array = copia.get("ecos", [])
	var siguientes: Array = []
	var telegraph: Array = []
	var patrones_copiados: Array = []
	var ventanas: Array = []
	var solicitudes_despawn: Array = []

	for eco in ecos:
		if not eco is Dictionary or siguientes.size() >= LIMITE_ECOS:
			continue
		var indice := int(eco.get("indice", siguientes.size()))
		if indice in destruidos:
			solicitudes_despawn.append(indice)
			continue
		var unidad: Dictionary = eco.get("unidad", {})
		if String(unidad.get("tipo", "")) != ARQUETIPOS.MIMETICO:
			unidad = (
				ARQUETIPOS
				. nuevo(
					ARQUETIPOS.MIMETICO,
					int(copia.get("_raiz", 0)),
					indice,
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
		siguientes.append({"indice": indice, "unidad": unidad})
		var patron_copiado := String(unidad.get("patron_eco", ""))
		patrones_copiados.append({"indice": indice, "patron": patron_copiado})
		(
			telegraph
			. append(
				{
					"indice": indice,
					"patron": String(paso.get("telegraph", "")),
					"presentacion": ARQUETIPOS.presentacion(paso, reduccion_movimiento),
				}
			)
		)
		if bool(paso.get("ventana_respuesta", false)):
			ventanas.append(indice)

	copia["ecos"] = siguientes
	var solicitudes_spawn: Array = copia.get("pendientes_spawn", [])
	copia["pendientes_spawn"] = []
	return {
		"estado": copia,
		"telegraph": telegraph,
		"patron_copiado": patrones_copiados,
		"ventana_respuesta": ventanas,
		"solicitudes_spawn": solicitudes_spawn,
		"solicitudes_despawn": solicitudes_despawn,
	}


static func _indices_destruidos(ecos_destruidos: Array) -> Array:
	var indices: Array = []
	for eco in ecos_destruidos:
		var indice := int(eco)
		if indice >= 0 and indice not in indices:
			indices.append(indice)
	return indices
