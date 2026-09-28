## Sincronización unidireccional de logros de Prometeo hacia un backend externo (#114).
##
## Solo lee estado ya resuelto. Nunca crea logros, no re-bloquea los ya publicados
## y un fallo del backend no cambia el estado local.
class_name LogrosExternos
extends RefCounted


static func desbloqueados(estado: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var bruto = estado.get("logros", [])
	if typeof(bruto) != TYPE_ARRAY:
		return ids
	for logro in bruto:
		if typeof(logro) != TYPE_DICTIONARY:
			continue
		var logro_id := String(logro.get("id", "")).strip_edges()
		if logro_id.is_empty() or not bool(logro.get("desbloqueado", false)):
			continue
		if not ids.has(logro_id):
			ids.append(logro_id)
	ids.sort()
	return ids


static func sincronizar(estado: Dictionary, backend: LogrosBackend) -> Dictionary:
	var resultado := {
		"backend_disponible": false,
		"candidatos": desbloqueados(estado),
		"publicados": [],
		"ya_publicados": [],
		"fallidos": [],
		"guardado": true,
	}
	if backend == null or not backend.disponible():
		return resultado

	resultado["backend_disponible"] = true
	for logro_id in resultado["candidatos"]:
		if backend.esta_desbloqueado(logro_id):
			resultado["ya_publicados"].append(logro_id)
			continue
		if backend.desbloquear(logro_id):
			resultado["publicados"].append(logro_id)
		else:
			resultado["fallidos"].append(logro_id)

	if not resultado["publicados"].is_empty():
		resultado["guardado"] = backend.guardar()
	return resultado
