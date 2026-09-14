## Auditoría pura de densidad 3D para #282.
##
## Un `bulto` sin `modelo` sigue siendo un proxy geométrico. Este módulo no
## cambia la escena: mide cuánto queda por sustituir y prioriza los proxies más
## visibles por volumen para que #282 avance por cortes pequeños y verificables.
class_name Densidad3D
extends RefCounted


static func auditar(espacio: Dictionary) -> Dictionary:
	var bultos: Array = espacio.get("bultos", [])
	var modelados := 0
	var proxies := 0
	for bulto in bultos:
		if typeof(bulto) != TYPE_DICTIONARY:
			continue
		if not String(bulto.get("modelo", "")).is_empty():
			modelados += 1
		else:
			proxies += 1
	var total := modelados + proxies
	return {
		"total": total,
		"modelados": modelados,
		"proxies": proxies,
		"ratio_modelado": 0.0 if total == 0 else float(modelados) / float(total),
	}


static func priorizar(espacio: Dictionary, limite: int = 5) -> Array:
	var candidatos := []
	var bultos: Array = espacio.get("bultos", [])
	for indice in bultos.size():
		var bulto = bultos[indice]
		if typeof(bulto) != TYPE_DICTIONARY:
			continue
		if not String(bulto.get("modelo", "")).is_empty():
			continue
		var tam: Vector3 = bulto.get("tam", Vector3.ZERO)
		(
			candidatos
			. append(
				{
					"indice": indice,
					"volumen": absf(tam.x * tam.y * tam.z),
					"pos": bulto.get("pos", Vector3.ZERO),
					"tam": tam,
				}
			)
		)
	candidatos.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if not is_equal_approx(a["volumen"], b["volumen"]):
				return a["volumen"] > b["volumen"]
			return a["indice"] < b["indice"]
	)
	return candidatos.slice(0, mini(maxi(limite, 0), candidatos.size()))
