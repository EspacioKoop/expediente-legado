## Contrato opcional de anexos documentales (#319 / #286).
##
## Esta capa solo valida datos. No descubre pistas, no interpreta contenido y no
## decide si un anexo participa en una relación. Eso sigue perteneciendo al
## catálogo y a las reglas explícitas de investigación.
class_name AnexosDocumentales
extends RefCounted

const TIPOS_VALIDOS := ["texto", "sello", "imagen", "metadato"]


static func anexos_de(registro: Dictionary) -> Array:
	var anexos: Variant = registro.get("anexos", [])
	if not anexos is Array:
		return []
	return (anexos as Array).duplicate(true)


static func errores(registro: Dictionary) -> Array[String]:
	var resultado: Array[String] = []
	if not registro.has("anexos"):
		return resultado
	if not registro["anexos"] is Array:
		resultado.append("anexos_no_es_lista")
		return resultado

	var ids_vistos := {}
	for anexo in registro["anexos"]:
		if not anexo is Dictionary:
			resultado.append("anexo_no_es_objeto")
			continue
		_validar_anexo(anexo, ids_vistos, resultado)
	return resultado


static func es_valido(registro: Dictionary) -> bool:
	return errores(registro).is_empty()


static func _validar_anexo(anexo: Dictionary, ids_vistos: Dictionary, errores_salida: Array[String]) -> void:
	var anexo_id := String(anexo.get("id", "")).strip_edges()
	if anexo_id.is_empty():
		errores_salida.append("id_vacio")
	elif ids_vistos.has(anexo_id):
		errores_salida.append("id_duplicado:%s" % anexo_id)
	else:
		ids_vistos[anexo_id] = true

	var tipo := String(anexo.get("tipo", "")).strip_edges()
	if not TIPOS_VALIDOS.has(tipo):
		errores_salida.append("tipo_invalido:%s" % tipo)

	var titulo := String(anexo.get("titulo", anexo.get("etiqueta", ""))).strip_edges()
	if titulo.is_empty():
		errores_salida.append("titulo_vacio:%s" % anexo_id)

	var contenido := String(anexo.get("contenido", "")).strip_edges()
	var recurso := String(anexo.get("recurso", "")).strip_edges()
	if contenido.is_empty() and recurso.is_empty():
		errores_salida.append("sin_contenido_ni_recurso:%s" % anexo_id)
