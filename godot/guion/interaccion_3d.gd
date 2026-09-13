## Contrato común para objetos interactuables del entorno (#283).
##
## Esta capa no conoce escenas ni estado de partida. Un objeto declara qué verbos
## admite y qué texto de feedback ofrece. Quien controla al jugador decide cuál
## está enfocado, comprueba el rango y ejecuta el resultado correspondiente.
class_name Interaccion3D
extends RefCounted

const DISTANCIA_DEFECTO := 2.2
const VERBOS := ["examinar", "usar", "abrir", "coger", "leer", "dar", "encender"]
const ETIQUETAS := {
	"examinar": "Examinar",
	"usar": "Usar",
	"abrir": "Abrir",
	"coger": "Coger",
	"leer": "Leer",
	"dar": "Dar",
	"encender": "Encender",
}


static func declaracion(
	id: String,
	verbos: Array,
	feedback: Dictionary = {},
	distancia: float = DISTANCIA_DEFECTO,
) -> Dictionary:
	var admitidos := []
	for valor in verbos:
		var verbo := String(valor)
		if VERBOS.has(verbo) and not admitidos.has(verbo):
			admitidos.append(verbo)
	return {
		"id": id,
		"verbos": admitidos,
		"feedback": feedback.duplicate(true),
		"distancia": maxf(distancia, 0.1),
	}


static func es_valida(objeto: Dictionary) -> bool:
	if String(objeto.get("id", "")).is_empty():
		return false
	var verbos: Variant = objeto.get("verbos", [])
	if not verbos is Array or verbos.is_empty():
		return false
	for valor in verbos:
		if not VERBOS.has(String(valor)):
			return false
	return float(objeto.get("distancia", DISTANCIA_DEFECTO)) > 0.0


static func permite(objeto: Dictionary, verbo: String) -> bool:
	return es_valida(objeto) and objeto.get("verbos", []).has(verbo)


static func en_rango(objeto: Dictionary, origen: Vector3, destino: Vector3) -> bool:
	if not es_valida(objeto):
		return false
	var limite := float(objeto.get("distancia", DISTANCIA_DEFECTO))
	return origen.distance_to(destino) <= limite


## La entrada es semántica: el llamador pasa la representación actual de la
## acción `interactuar` de PreferenciasSiga. Aquí nunca se escribe una tecla fija.
static func prompt(objeto: Dictionary, verbo: String, entrada: String) -> String:
	if not permite(objeto, verbo):
		return ""
	var etiqueta := String(ETIQUETAS.get(verbo, verbo.capitalize()))
	if entrada.is_empty():
		return etiqueta
	return "%s · %s" % [entrada, etiqueta]


## Ejecutar aquí significa resolver feedback declarativo. Las mutaciones reales
## (abrir una puerta, alimentar al gato, guardar estado) pertenecen a la regla
## concreta que consuma este resultado.
static func ejecutar(objeto: Dictionary, verbo: String) -> Dictionary:
	if not permite(objeto, verbo):
		return {"ok": false, "motivo": "verbo-no-admitido"}
	var feedback: Dictionary = objeto.get("feedback", {})
	return {
		"ok": true,
		"id": String(objeto.get("id", "")),
		"verbo": verbo,
		"texto": String(feedback.get(verbo, "")),
	}
