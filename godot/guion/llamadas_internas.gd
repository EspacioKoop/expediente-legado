## Núcleo determinista de llamadas internas de oficina (#1769).
##
## Solo guarda estado ambiental de la jornada para que recargar no repita una
## llamada ya atendida/ignorada. No modifica acciones, dinero, pistas, casos ni
## veredictos.
class_name LlamadasInternas
extends RefCounted

const CLAVE := "llamadas_internas"
const MAX_LLAMADAS := 2
const DURACION_VENTANA_MIN := 35

const TIPOS := [
	{
		"id": "companero",
		"prompt": "teléfono interno · buscan a un compañero",
		"respuesta": "Buscan a un compañero. Transfieres la llamada.",
		"reaccion_companero": true,
	},
	{
		"id": "administrativo",
		"prompt": "teléfono interno · aviso administrativo",
		"respuesta": "Un aviso administrativo genérico. Tomas nota y cuelgas.",
		"reaccion_companero": false,
	},
	{
		"id": "equivocada",
		"prompt": "teléfono interno · llamada equivocada",
		"respuesta": "Se han equivocado de extensión. Cortas sin más.",
		"reaccion_companero": false,
	},
]


static func plan(jornada: Dictionary) -> Array[Dictionary]:
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var cantidad := 1 + (dia % MAX_LLAMADAS)
	var primera := 9 * 60 + 25 + (dia * 17) % 35
	var salida: Array[Dictionary] = []
	for indice in cantidad:
		var tipo: Dictionary = TIPOS[(dia + indice) % TIPOS.size()]
		var desde := primera + indice * 125
		salida.append(
			{
				"id": "d%d-%d" % [dia, indice],
				"tipo": String(tipo["id"]),
				"prompt": String(tipo["prompt"]),
				"respuesta": String(tipo["respuesta"]),
				"reaccion_companero": bool(tipo["reaccion_companero"]),
				"desde": desde,
				"hasta": desde + DURACION_VENTANA_MIN,
			}
		)
	return salida


static func estado(jornada: Dictionary) -> Dictionary:
	var dia := maxi(1, int(jornada.get("dia", 1)))
	var actual = jornada.get(CLAVE, {})
	if typeof(actual) != TYPE_DICTIONARY or int(actual.get("dia", 0)) != dia:
		actual = {"dia": dia, "resueltas": {}, "activa": ""}
		jornada[CLAVE] = actual
	if typeof(actual.get("resueltas", {})) != TYPE_DICTIONARY:
		actual["resueltas"] = {}
	if not actual.has("activa"):
		actual["activa"] = ""
	return actual


static func siguiente(jornada: Dictionary) -> Dictionary:
	if String(jornada.get("fase", "")) != "archivo":
		return {}
	var actual := estado(jornada)
	if not String(actual.get("activa", "")).is_empty():
		return {}
	var resueltas: Dictionary = actual["resueltas"]
	var ahora := Jornada.hora_minutos(jornada)
	for llamada in plan(jornada):
		var id := String(llamada["id"])
		if resueltas.has(id):
			continue
		if ahora >= int(llamada["desde"]) and ahora < int(llamada["hasta"]):
			return llamada
		if ahora >= int(llamada["hasta"]):
			resueltas[id] = "ignorada"
	return {}


static func iniciar(jornada: Dictionary, llamada: Dictionary) -> bool:
	var id := String(llamada.get("id", ""))
	if id.is_empty():
		return false
	var actual := estado(jornada)
	if not String(actual.get("activa", "")).is_empty():
		return false
	if (actual["resueltas"] as Dictionary).has(id):
		return false
	actual["activa"] = id
	return true


static func resolver(jornada: Dictionary, llamada: Dictionary, decision: String) -> Dictionary:
	var id := String(llamada.get("id", ""))
	var actual := estado(jornada)
	if id.is_empty() or String(actual.get("activa", "")) != id:
		return {"ok": false}
	var resueltas: Dictionary = actual["resueltas"]
	if resueltas.has(id):
		actual["activa"] = ""
		return {"ok": false}
	var resultado := "atendida" if decision == "atender" else "ignorada"
	resueltas[id] = resultado
	actual["activa"] = ""
	return {
		"ok": true,
		"id": id,
		"tipo": String(llamada.get("tipo", "")),
		"resultado": resultado,
		"respuesta": String(llamada.get("respuesta", "")),
		"reaccion_companero": bool(llamada.get("reaccion_companero", false)),
	}


static func cancelar_activa(jornada: Dictionary, llamada: Dictionary) -> Dictionary:
	return resolver(jornada, llamada, "ignorar")
