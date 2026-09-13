## Contexto documental que puede acompañar un careo (#366).
##
## Solo devuelve conclusiones relacionales que el jugador YA descubrió. No
## calcula culpables, no descubre pistas y no modifica el combate: transforma
## estado existente en una pieza de presentación estable.
class_name ContextoCareo
extends RefCounted


static func de_folio(casos: Array, folio: String, descubiertas: Array) -> Dictionary:
	for caso in casos:
		if _es_caso_de_folio(caso, folio):
			return de_caso(caso, descubiertas)
	return {}


static func de_caso(caso: Dictionary, descubiertas: Array) -> Dictionary:
	for pista in caso.get("pistas", []):
		var pista_id := String(pista.get("id", ""))
		if pista_id.is_empty() or not descubiertas.has(pista_id):
			continue
		var segundo_origen := String(pista.get("registroOrigen2", ""))
		if segundo_origen.is_empty():
			continue
		return {
			"id": pista_id,
			"descripcion": String(pista.get("descripcion", "")),
			"registroOrigen": String(pista.get("registroOrigen", "")),
			"registroOrigen2": segundo_origen,
		}
	return {}


static func _es_caso_de_folio(caso: Dictionary, folio: String) -> bool:
	if folio.is_empty():
		return false
	if String(caso.get("titulo", "")) == folio:
		return true
	for registro in caso.get("registros", []):
		if String(registro.get("folio", "")) == folio:
			return true
	return false
