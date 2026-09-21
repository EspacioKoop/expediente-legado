## Catálogo de microdetalles opcionales para #961.
##
## Los detalles solo enriquecen la lectura material del expediente. El contrato
## rechaza cualquier entrada marcada como crítica y nunca toca pistas, relaciones
## válidas ni reglas de resolución.
class_name DetallesMeticulosidad
extends RefCounted


static func visibles(
	catalogo: Dictionary,
	jornada: Dictionary,
	documento_id: String,
) -> Array[Dictionary]:
	var id := documento_id.strip_edges()
	if id.is_empty():
		return []
	var eventos: Array[String] = Meticulosidad.eventos_documento(jornada, id)
	var motivos: Array[String] = Meticulosidad.motivos_documento(jornada, id)
	var crudo: Variant = catalogo.get(id, [])
	if not crudo is Array:
		return []

	var resultado: Array[Dictionary] = []
	for valor in crudo:
		if not valor is Dictionary:
			continue
		var detalle := valor as Dictionary
		if bool(detalle.get("critico", true)):
			continue
		var evento := String(detalle.get("evento", "")).strip_edges()
		var motivo := String(detalle.get("motivo", "")).strip_edges()
		if not eventos.has(evento) or not motivos.has(motivo):
			continue
		if Meticulosidad.motivo_de_evento(jornada, id, evento) != motivo:
			continue
		resultado.append(detalle.duplicate(true))
	return resultado


static func errores_catalogo(
	catalogo: Dictionary,
	registros_validos: Array,
) -> Array[String]:
	var errores: Array[String] = []
	var ids_vistos := {}
	for documento_id in catalogo:
		var id := String(documento_id).strip_edges()
		if not registros_validos.has(id):
			errores.append("registro_inexistente:%s" % id)
			continue
		var crudo: Variant = catalogo[documento_id]
		if not crudo is Array:
			errores.append("detalles_no_es_lista:%s" % id)
			continue
		for valor in crudo:
			if not valor is Dictionary:
				errores.append("detalle_no_es_objeto:%s" % id)
				continue
			_validar_detalle(id, valor as Dictionary, ids_vistos, errores)
	return errores


static func _validar_detalle(
	documento_id: String,
	detalle: Dictionary,
	ids_vistos: Dictionary,
	errores: Array[String],
) -> void:
	var detalle_id := String(detalle.get("id", "")).strip_edges()
	if detalle_id.is_empty():
		errores.append("id_vacio:%s" % documento_id)
	elif ids_vistos.has(detalle_id):
		errores.append("id_duplicado:%s" % detalle_id)
	else:
		ids_vistos[detalle_id] = true

	var evento := String(detalle.get("evento", "")).strip_edges()
	if not Meticulosidad.EVENTOS_VALIDOS.has(evento):
		errores.append("evento_invalido:%s" % detalle_id)

	var motivo := String(detalle.get("motivo", "")).strip_edges()
	if not Meticulosidad.MOTIVOS_VALIDOS.has(motivo):
		errores.append("motivo_invalido:%s" % detalle_id)

	if String(detalle.get("texto", "")).strip_edges().is_empty():
		errores.append("texto_vacio:%s" % detalle_id)
	if bool(detalle.get("critico", true)):
		errores.append("detalle_critico:%s" % detalle_id)
