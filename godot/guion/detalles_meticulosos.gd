## Detalles opcionales autorados para la atención documental de #961.
##
## El catálogo no contiene pistas, gates ni recompensas. Solo enlaza un documento
## y un motivo ya observado con una clave de texto contextual.
class_name DetallesMeticulosos
extends RefCounted

const RUTA := "res://datos/detalles_meticulosos.json"


static func detalles_para(documento_id: String, motivos: Array) -> Array:
	var id := documento_id.strip_edges()
	if id.is_empty():
		return []
	var catalogo := _cargar_catalogo()
	var entradas: Variant = catalogo.get(id, [])
	if not entradas is Array:
		return []

	var motivos_validos: Array[String] = []
	for valor in motivos:
		var motivo := String(valor).strip_edges()
		if Meticulosidad.MOTIVOS_VALIDOS.has(motivo) and not motivos_validos.has(motivo):
			motivos_validos.append(motivo)

	var resultado := []
	for entrada in entradas:
		if not entrada is Dictionary:
			continue
		var motivo := String((entrada as Dictionary).get("motivo", "")).strip_edges()
		if motivos_validos.has(motivo):
			resultado.append((entrada as Dictionary).duplicate(true))
	return resultado


static func errores_catalogo(catalogo: Dictionary, registros_validos: Array) -> Array[String]:
	var errores: Array[String] = []
	var ids_detalle := {}
	for registro_id in catalogo:
		var id := String(registro_id).strip_edges()
		if not registros_validos.has(id):
			errores.append("registro_inexistente:%s" % id)
			continue
		var entradas: Variant = catalogo[registro_id]
		if not entradas is Array:
			errores.append("detalles_no_es_lista:%s" % id)
			continue
		for entrada in entradas:
			if not entrada is Dictionary:
				errores.append("detalle_no_es_objeto:%s" % id)
				continue
			var detalle: Dictionary = entrada
			var detalle_id := String(detalle.get("id", "")).strip_edges()
			if detalle_id.is_empty():
				errores.append("id_vacio:%s" % id)
			elif ids_detalle.has(detalle_id):
				errores.append("id_duplicado:%s" % detalle_id)
			else:
				ids_detalle[detalle_id] = true
			var motivo := String(detalle.get("motivo", "")).strip_edges()
			if not Meticulosidad.MOTIVOS_VALIDOS.has(motivo):
				errores.append("motivo_invalido:%s" % detalle_id)
			if String(detalle.get("texto", "")).strip_edges().is_empty():
				errores.append("texto_vacio:%s" % detalle_id)
	return errores


static func _cargar_catalogo() -> Dictionary:
	if not FileAccess.file_exists(RUTA):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	return datos if datos is Dictionary else {}
