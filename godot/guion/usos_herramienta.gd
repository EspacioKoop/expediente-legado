## Resolución semántica de herramientas llevadas (#1773).
##
## Las escenas piden una capacidad ("forzar", "iluminar", "estabilizar") y no
## un ID visual concreto. El módulo solo LEE Inventario.CARRIED: no abre el
## almacenamiento doméstico, no mueve objetos y no consume nada por sí mismo.
class_name UsosHerramienta
extends RefCounted

const FORZAR := "forzar"
const ILUMINAR := "iluminar"
const ESTABILIZAR := "estabilizar"
const CALZAR := "calzar"

const VALIDOS: Array[String] = [FORZAR, ILUMINAR, ESTABILIZAR]
const ALIASES := {
	CALZAR: ESTABILIZAR,
}


static func uso_canonico(uso: String) -> String:
	var clave := uso.strip_edges().to_lower()
	if ALIASES.has(clave):
		clave = String(ALIASES[clave])
	return clave if VALIDOS.has(clave) else ""


## Todas las herramientas llevadas que pueden resolver el uso pedido. Se
## devuelven copias para que inspeccionar una opción no pueda mutar Inventario.
static func compatibles(inventario: Dictionary, uso: String) -> Array[Dictionary]:
	var clave := uso_canonico(uso)
	var resultado: Array[Dictionary] = []
	if clave.is_empty():
		return resultado

	var llevados: Variant = inventario.get(Inventario.CARRIED, [])
	if not llevados is Array:
		return resultado
	for crudo in llevados as Array:
		if not crudo is Dictionary:
			continue
		var objeto := crudo as Dictionary
		if not _tiene_uso(objeto, clave):
			continue
		resultado.append(objeto.duplicate(true))
	return resultado


static func puede(inventario: Dictionary, uso: String) -> bool:
	return not compatibles(inventario, uso).is_empty()


## Selecciona la primera herramienta compatible en el orden canónico de carried.
## El resultado describe si el contrato declara consumo, pero NO retira el
## objeto: esa decisión transaccional pertenece a la interacción que lo use.
static func resolver(inventario: Dictionary, uso: String) -> Dictionary:
	var clave := uso_canonico(uso)
	if clave.is_empty():
		return {
			"ok": false,
			"uso": "",
			"herramienta": {},
			"consumir": false,
			"motivo": "uso_desconocido",
		}
	var opciones := compatibles(inventario, clave)
	if opciones.is_empty():
		return {
			"ok": false,
			"uso": clave,
			"herramienta": {},
			"consumir": false,
			"motivo": "sin_herramienta",
		}
	var herramienta: Dictionary = opciones[0]
	return {
		"ok": true,
		"uso": clave,
		"herramienta": herramienta,
		"consumir": consumo_declarado(herramienta, clave),
		"motivo": "",
	}


## El consumo es opt-in y por uso. Declarar un objeto como herramienta no basta:
## debe incluir explícitamente ese uso en `consumir_usos`.
static func consumo_declarado(objeto: Dictionary, uso: String) -> bool:
	var clave := uso_canonico(uso)
	if clave.is_empty():
		return false
	var crudo: Variant = objeto.get("consumir_usos", [])
	if not crudo is Array:
		return false
	for valor in crudo as Array:
		if uso_canonico(String(valor)) == clave:
			return true
	return false


static func _tiene_uso(objeto: Dictionary, uso: String) -> bool:
	var crudo: Variant = objeto.get("usos", [])
	if not crudo is Array:
		return false
	for valor in crudo as Array:
		if uso_canonico(String(valor)) == uso:
			return true
	return false
