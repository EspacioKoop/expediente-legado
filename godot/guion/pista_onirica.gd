## Recompensa segura para puzzles oníricos (#89).
##
## El sueño no inventa pistas: una recompensa solo puede señalar una pista que
## ya exista en el catálogo del caso y cuyos documentos de origen formen parte
## de las fuentes del puzzle completado. Una pista puede proceder de un único
## documento (detalle recontextualizado, como #161) o de dos documentos
## (relación/contradicción). La capa consumidora decide cómo mostrarla o
## persistirla.
class_name PistaOnirica
extends RefCounted


## Devuelve una pista catalogada que el puzzle puede recontextualizar.
##
## `resultado_puzzle` debe proceder de PuzzleOnirico y estar completado. Si el
## puzzle falló, fue abandonado o sus fuentes no cubren todos los orígenes de la
## pista, no hay recompensa. Las relaciones de dos documentos son conmutativas.
static func resolver(caso: Dictionary, resultado_puzzle: Dictionary) -> Dictionary:
	if str(resultado_puzzle.get("state", "")) != "completado":
		return {}
	var fuentes := _normalizar(resultado_puzzle.get("source_ids", []))
	if fuentes.is_empty():
		return {}

	for pista in caso.get("pistas", []):
		var pista_id := str(pista.get("id", ""))
		var a := str(pista.get("registroOrigen", ""))
		if pista_id.is_empty() or a.is_empty() or not fuentes.has(a):
			continue

		var origenes := [a]
		if pista.has("registroOrigen2"):
			var b := str(pista.get("registroOrigen2", ""))
			if b.is_empty() or b == a or not fuentes.has(b):
				continue
			origenes.append(b)

		return {
			"id": pista_id,
			"descripcion": str(pista.get("descripcion", "")),
			"fuentes": origenes,
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
