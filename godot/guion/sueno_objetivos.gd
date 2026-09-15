## Estado mínimo y determinista de progreso para una escena onírica (#299).
##
## No conoce nodos, contenido ni recompensas: recibe objetivos estables, cuenta
## cada uno una sola vez y decide cuándo se alcanza el umbral. La presentación
## y la transición pertenecen a la capa de día.
class_name SuenoObjetivos
extends RefCounted

const POSIBLES_PRIMER_CORTE := 3
const REQUERIDOS_PRIMER_CORTE := 2


static func nuevo(objetivos: Array, requeridos: int = REQUERIDOS_PRIMER_CORTE) -> Dictionary:
	var normalizados: Array = []
	var ids: Array = []
	for dato in objetivos:
		var objetivo := _normalizar(dato)
		var id := String(objetivo.get("id", ""))
		if id.is_empty() or ids.has(id):
			continue
		ids.append(id)
		normalizados.append(objetivo)

	var requeridos_efectivos := clampi(requeridos, 0, _cantidad_puntuables(normalizados))
	return {
		"ids": ids,
		"objetivos": normalizados,
		"completados": [],
		"completados_puntuables": [],
		"fallidos": [],
		"requeridos": requeridos_efectivos,
		"resuelto": requeridos_efectivos <= 0,
	}


## Devuelve true sólo cuando este evento acaba de completar un objetivo nuevo.
## Un objetivo no puntuable cambia de estado, pero no incrementa el umbral.
static func completar(estado: Dictionary, id: String) -> bool:
	if bool(estado.get("resuelto", false)):
		return false
	var ids: Array = estado.get("ids", [])
	var completados: Array = estado.get("completados", [])
	var fallidos: Array = estado.get("fallidos", [])
	if not ids.has(id) or completados.has(id) or fallidos.has(id):
		return false

	completados.append(id)
	estado["completados"] = completados
	_marcar_estado(estado, id, "completed")
	if _cuenta_para_umbral(estado, id):
		var puntuables := _completados_puntuables(estado)
		if not puntuables.has(id):
			puntuables.append(id)
		estado["completados_puntuables"] = puntuables

	if progreso(estado).x >= int(estado.get("requeridos", 0)):
		estado["resuelto"] = true
	return true


## Un fallo terminal queda registrado de forma idempotente. No suma progreso y
## no impide resolver la escena mientras queden objetivos puntuables suficientes.
static func fallar(estado: Dictionary, id: String) -> bool:
	if bool(estado.get("resuelto", false)):
		return false
	var ids: Array = estado.get("ids", [])
	var completados: Array = estado.get("completados", [])
	var fallidos: Array = estado.get("fallidos", [])
	if not ids.has(id) or completados.has(id) or fallidos.has(id):
		return false
	fallidos.append(id)
	estado["fallidos"] = fallidos
	_marcar_estado(estado, id, "failed")
	return true


static func progreso(estado: Dictionary) -> Vector2i:
	return Vector2i(
		_completados_puntuables(estado).size(),
		int(estado.get("requeridos", 0)),
	)


static func resuelto(estado: Dictionary) -> bool:
	return bool(estado.get("resuelto", false))


static func _normalizar(dato) -> Dictionary:
	var id := ""
	var tipo := "interaccion"
	var condicion := "evento_determinista"
	var feedback := "ambiente"
	var cuenta := true
	if typeof(dato) == TYPE_DICTIONARY:
		id = String(dato.get("id", ""))
		tipo = String(dato.get("tipo", tipo))
		condicion = String(dato.get("condicion", condicion))
		feedback = String(dato.get("feedback", feedback))
		cuenta = bool(dato.get("cuenta", true))
	else:
		id = String(dato)
	return {
		"id": id,
		"tipo": tipo,
		"estado": "pending",
		"condicion": condicion,
		"feedback": feedback,
		"cuenta": cuenta,
	}


static func _cantidad_puntuables(objetivos: Array) -> int:
	var total := 0
	for objetivo in objetivos:
		if bool(objetivo.get("cuenta", true)):
			total += 1
	return total


static func _cuenta_para_umbral(estado: Dictionary, id: String) -> bool:
	for objetivo in estado.get("objetivos", []):
		if String(objetivo.get("id", "")) == id:
			return bool(objetivo.get("cuenta", true))
	# Compatibilidad con partidas creadas antes de guardar descriptores.
	return true


static func _completados_puntuables(estado: Dictionary) -> Array:
	if estado.has("completados_puntuables"):
		return estado.get("completados_puntuables", [])
	var migrados: Array = []
	for id in estado.get("completados", []):
		var objetivo_id := String(id)
		if _cuenta_para_umbral(estado, objetivo_id):
			migrados.append(objetivo_id)
	estado["completados_puntuables"] = migrados
	return migrados


static func _marcar_estado(estado: Dictionary, id: String, valor: String) -> void:
	var objetivos: Array = estado.get("objetivos", [])
	for i in objetivos.size():
		var objetivo: Dictionary = objetivos[i]
		if String(objetivo.get("id", "")) != id:
			continue
		objetivo["estado"] = valor
		objetivos[i] = objetivo
		estado["objetivos"] = objetivos
		return
