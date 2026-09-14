## Estado mínimo y determinista de progreso para una escena onírica (#299).
##
## No conoce nodos, contenido ni recompensas: recibe ids estables, cuenta cada
## uno una sola vez y decide cuándo se alcanza el umbral. La presentación y la
## transición pertenecen a la capa de día.
class_name SuenoObjetivos
extends RefCounted

const POSIBLES_PRIMER_CORTE := 3
const REQUERIDOS_PRIMER_CORTE := 2


static func nuevo(ids: Array, requeridos: int = REQUERIDOS_PRIMER_CORTE) -> Dictionary:
	var unicos := []
	for objetivo in ids:
		var id := String(objetivo)
		if id.is_empty() or unicos.has(id):
			continue
		unicos.append(id)
	return {
		"ids": unicos,
		"completados": [],
		"requeridos": clampi(requeridos, 0, unicos.size()),
		"resuelto": requeridos <= 0,
	}


## Devuelve true sólo cuando este evento acaba de producir progreso real.
static func completar(estado: Dictionary, id: String) -> bool:
	if bool(estado.get("resuelto", false)):
		return false
	var ids: Array = estado.get("ids", [])
	var completados: Array = estado.get("completados", [])
	if not ids.has(id) or completados.has(id):
		return false
	completados.append(id)
	estado["completados"] = completados
	if completados.size() >= int(estado.get("requeridos", 0)):
		estado["resuelto"] = true
	return true


static func progreso(estado: Dictionary) -> Vector2i:
	return Vector2i(
		estado.get("completados", []).size(),
		int(estado.get("requeridos", 0)),
	)


static func resuelto(estado: Dictionary) -> bool:
	return bool(estado.get("resuelto", false))
