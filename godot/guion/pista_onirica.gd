## Recompensa segura para puzzles oníricos (#89).
##
## El sueño no inventa pistas: una recompensa solo puede señalar una pista que
## ya exista en el catálogo del caso y cuyos documentos de origen formen parte
## de las fuentes del puzzle completado. Una pista puede proceder de un único
## documento (detalle recontextualizado, como #161) o de dos documentos
## (relación/contradicción). La capa consumidora decide cómo mostrarla o guardar
## el estado ya actualizado.
class_name PistaOnirica
extends RefCounted


## Devuelve una pista catalogada que el puzzle puede recontextualizar.
##
## `resultado_puzzle` debe proceder de PuzzleOnirico y estar completado. Si el
## puzzle falló, fue abandonado o sus fuentes no cubren todos los orígenes de la
## pista, no hay recompensa. Si `reward_id` viene informado, solo esa pista puede
## resolverse. Sin objetivo explícito se exige una única candidata: varias pistas
## compatibles con las mismas fuentes son ambiguas y se rechazan en vez de elegir
## arbitrariamente la primera del catálogo.
static func resolver(caso: Dictionary, resultado_puzzle: Dictionary) -> Dictionary:
	if str(resultado_puzzle.get("state", "")) != "completado":
		return {}
	var fuentes := _normalizar(resultado_puzzle.get("source_ids", []))
	if fuentes.is_empty():
		return {}
	var origenes_permitidos := _origenes_permitidos(caso, fuentes)
	var objetivo := str(resultado_puzzle.get("reward_id", "")).strip_edges()
	var candidatas: Array = []

	for pista in caso.get("pistas", []):
		var pista_id := str(pista.get("id", ""))
		if not objetivo.is_empty() and pista_id != objetivo:
			continue
		var a := str(pista.get("registroOrigen", ""))
		if pista_id.is_empty() or a.is_empty() or not origenes_permitidos.has(a):
			continue

		var origenes := [a]
		if pista.has("registroOrigen2"):
			var b := str(pista.get("registroOrigen2", ""))
			if b.is_empty() or b == a or not origenes_permitidos.has(b):
				continue
			origenes.append(b)

		(
			candidatas
			. append(
				{
					"id": pista_id,
					"descripcion": str(pista.get("descripcion", "")),
					"fuentes": origenes,
				}
			)
		)

	if candidatas.size() != 1:
		return {}
	return candidatas[0]


## Registra únicamente la identidad catalogada de una recompensa ya resuelta.
##
## No guarda a disco ni conoce Partida: muta el diccionario que el consumidor
## ya posee para que este pueda llamar después a guardar(). Repetir la operación
## es seguro y devuelve true sin duplicar el id, lo que permite reintentar un
## guardado fallido sin volver a aplicar la recompensa.
static func registrar(estado: Dictionary, pista: Dictionary) -> bool:
	var pista_id := str(pista.get("id", ""))
	if pista_id.is_empty():
		return false
	if not estado.has("pistas_descubiertas"):
		estado["pistas_descubiertas"] = []
	if typeof(estado["pistas_descubiertas"]) != TYPE_ARRAY:
		return false
	var descubiertas: Array = estado["pistas_descubiertas"]
	if not descubiertas.has(pista_id):
		descubiertas.append(pista_id)
	return true


## PuzzleOnirico trabaja con identidades visibles para la jornada (folios en
## el flujo real de #161), mientras el catálogo enlaza pistas mediante ids
## internos de registro. Resolver ambos formatos aquí mantiene el núcleo
## desacoplado del catálogo y evita rechazar un documento que sí fue leído.
static func _origenes_permitidos(caso: Dictionary, fuentes: Array) -> Array:
	var permitidos := fuentes.duplicate()
	for registro in caso.get("registros", []):
		var registro_id := str(registro.get("id", ""))
		var folio := str(registro.get("folio", ""))
		if registro_id.is_empty():
			continue
		if fuentes.has(registro_id) or (not folio.is_empty() and fuentes.has(folio)):
			if not permitidos.has(registro_id):
				permitidos.append(registro_id)
	return _normalizar(permitidos)


static func _normalizar(fuentes: Array) -> Array:
	var salida := []
	for fuente in fuentes:
		var id := str(fuente)
		if id.is_empty() or salida.has(id):
			continue
		salida.append(id)
	salida.sort()
	return salida
