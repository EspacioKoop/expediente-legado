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


## Valida el catálogo secundario sin asumir que una clave desconocida es un
## registro real. `registros_validos` se deriva del catálogo de casos cargado y
## permite detectar referencias rotas antes de que el visor las silencie.
static func errores_catalogo(catalogo: Dictionary, registros_validos: Array) -> Array[String]:
	var resultado: Array[String] = []
	for registro_id in catalogo:
		var id := String(registro_id)
		if not registros_validos.has(id):
			resultado.append("registro_inexistente:%s" % id)
			continue
		var ficha := {"anexos": catalogo[registro_id]}
		for error in errores(ficha):
			resultado.append("%s:%s" % [id, error])
	return resultado


## Devuelve todos los ids de registro declarados por los casos sin copiar ni
## interpretar sus contenidos. Se usa únicamente para comprobar referencias.
static func ids_registro(casos: Array) -> Array:
	var ids := []
	for caso in casos:
		if not caso is Dictionary:
			continue
		for registro in caso.get("registros", []):
			if registro is Dictionary:
				var id := String(registro.get("id", "")).strip_edges()
				if not id.is_empty():
					ids.append(id)
	return ids


static func _validar_anexo(
	anexo: Dictionary, ids_vistos: Dictionary, errores_salida: Array[String]
) -> void:
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

	# Un recurso visual/sonoro no puede ser una URL remota ni una ruta inventada:
	# debe estar vendorizado dentro del proyecto y existir de verdad. Además se
	# exige procedencia/licencia incluso para material propio (por ejemplo
	# `procedencia: propio`, `licencia: proyecto`) para que nunca quede ambiguo.
	if not recurso.is_empty():
		if not recurso.begins_with("res://"):
			errores_salida.append("recurso_no_local:%s" % anexo_id)
		elif not FileAccess.file_exists(recurso):
			errores_salida.append("recurso_inexistente:%s" % anexo_id)
		if String(anexo.get("procedencia", "")).strip_edges().is_empty():
			errores_salida.append("procedencia_vacia:%s" % anexo_id)
		if String(anexo.get("licencia", "")).strip_edges().is_empty():
			errores_salida.append("licencia_vacia:%s" % anexo_id)
