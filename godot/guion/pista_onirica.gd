## Recompensa segura para puzzles oníricos (#89).
##
## El sueño no inventa pistas: una recompensa solo puede señalar una relación
## que ya exista en el catálogo del caso y cuyos dos documentos formen parte
## de las fuentes del puzzle completado. La capa que consume este resultado
## decide después cómo presentarlo o persistirlo.
class_name PistaOnirica
extends RefCounted


## Devuelve una pista catalogada que el puzzle puede recontextualizar.
##
## `resultado_puzzle` debe proceder de PuzzleOnirico y estar completado. Si el
## puzzle falló, fue abandonado o sus fuentes no coinciden con la relación, no
## hay recompensa. La pareja es conmutativa, como en el visor.
static func resolver(caso: Dictionary, resultado_puzzle: Dictionary) -> Dictionary:
	if str(resultado_puzzle.get("state", "")) != "completado":
		return {}
	var fuentes := _normalizar(resultado_puzzle.get("source_ids", []))
	if fuentes.size() < 2:
		return {}

	for pista in caso.get("pistas", []):
		if not pista.has("registroOrigen2"):
			continue
		var a := str(pista.get("registroOrigen", ""))
		var b := str(pista.get("registroOrigen2", ""))
		if a.is_empty() or b.is_empty() or a == b:
			continue
		if fuentes.has(a) and fuentes.has(b):
			return {
				"id": str(pista.get("id", "")),
				"descripcion": str(pista.get("descripcion", "")),
				"fuentes": [a, b],
			}
	return {}


static func _normalizar(fuentes: Array) -> Array:
	var salida := []
	for fuente in fuentes:
		var id := str(fuente)
		if id.is_empty() or salida.has(id):
			continue
		salida.append(id)
	salida.sort()
	return salida
