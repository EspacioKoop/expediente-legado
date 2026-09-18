## Preparación de la memoria nocturna (#162).
##
## Este módulo no conoce escenas ni UI. Solo protege el contrato de los tres
## huecos: cada entrada debe ser un folio realmente leído hoy, el orden importa
## y repetir un folio es válido. Jornada decide cuándo puede editarse; Sueno
## consume la copia ya persistida.
class_name SeleccionNocturna
extends RefCounted

const MAX_DOCUMENTOS := 3


## Devuelve errores descriptivos sin modificar estado.
static func validar(leido_hoy: Array, seleccion: Array) -> Array:
	var errores := []
	if seleccion.size() > MAX_DOCUMENTOS:
		errores.append("demasiados_documentos")
	for dato in seleccion:
		if typeof(dato) != TYPE_STRING or String(dato).is_empty():
			errores.append("folio_invalido")
			continue
		var folio := String(dato)
		if not leido_hoy.has(folio):
			errores.append("folio_no_leido:" + folio)
	return errores


## Limpia estado viejo o manipulado sin inventar sustitutos.
##
## Se conservan orden y duplicados; solo se descartan entradas que no sean
## folios leídos hoy y todo lo que exceda los tres huecos.
static func normalizar(leido_hoy: Array, seleccion: Array) -> Array:
	var limpia := []
	for dato in seleccion:
		if limpia.size() >= MAX_DOCUMENTOS:
			break
		if typeof(dato) != TYPE_STRING:
			continue
		var folio := String(dato)
		if folio.is_empty() or not leido_hoy.has(folio):
			continue
		limpia.append(folio)
	return limpia


## Sustituye la selección completa solo si es válida.
static func establecer(jornada: Dictionary, seleccion: Array) -> bool:
	var leido_hoy: Array = jornada.get("leido_hoy", [])
	if not validar(leido_hoy, seleccion).is_empty():
		return false
	jornada["seleccion_nocturna"] = seleccion.duplicate()
	return true


## Inyecta la memoria en las opciones del sueño sin pisar otras políticas
## (cantidad de escenas, prioridad de vistas, mapa degradado, etc.).
static func opciones_sueno(jornada: Dictionary, base: Dictionary = {}) -> Dictionary:
	var opciones := base.duplicate(true)
	opciones["seleccion_nocturna"] = normalizar(
		jornada.get("leido_hoy", []), jornada.get("seleccion_nocturna", [])
	)
	return opciones
