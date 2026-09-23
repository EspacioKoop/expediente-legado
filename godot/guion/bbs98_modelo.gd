## Modelo declarativo de BBS, foros y tablones archivados del OS98 (#662).
##
## No implementa red ni publicación libre. Todo sale de un catálogo local y se
## filtra con estado narrativo explícito: jornada, conocimiento y plantilla. La
## búsqueda solo acepta términos declarados en el índice de los tablones visibles.
class_name Bbs98Modelo
extends RefCounted

const RUTA_CATALOGO := "res://datos/bbs98.json"

var _tablones: Array[Dictionary] = []
var _usuarios: Array[Dictionary] = []
var _hilos: Array[Dictionary] = []
var _mensajes: Array[Dictionary] = []
var _tablon_por_id: Dictionary = {}
var _usuario_por_id: Dictionary = {}
var _hilo_por_id: Dictionary = {}
var _mensaje_por_id: Dictionary = {}
var _contexto: Dictionary = {}


func _init(ruta: String = RUTA_CATALOGO) -> void:
	_cargar_catalogo(ruta)


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)


func tablones_visibles() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for tablon in _tablones:
		if _es_visible(tablon):
			resultado.append(tablon.duplicate(true))
	resultado.sort_custom(_orden_tablones)
	return resultado


func perfil_usuario(usuario_id: String) -> Dictionary:
	var usuario: Variant = _usuario_por_id.get(usuario_id, {})
	if not usuario is Dictionary:
		return {}
	return (usuario as Dictionary).duplicate(true)


func hilos_de(tablon_id: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var tablon: Variant = _tablon_por_id.get(tablon_id, {})
	if not tablon is Dictionary or not _es_visible(tablon as Dictionary):
		return resultado
	for hilo in _hilos:
		if String(hilo.get("tablon_id", "")) != tablon_id:
			continue
		if _es_visible(hilo):
			resultado.append(hilo.duplicate(true))
	resultado.sort_custom(_orden_hilos)
	return resultado


func mensajes_de(hilo_id: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var hilo: Variant = _hilo_por_id.get(hilo_id, {})
	if not hilo is Dictionary or not _hilo_visible(hilo as Dictionary):
		return resultado
	for mensaje in _mensajes:
		if String(mensaje.get("hilo_id", "")) != hilo_id:
			continue
		if not _es_visible(mensaje):
			continue
		var copia := mensaje.duplicate(true)
		var autor := perfil_usuario(String(mensaje.get("autor_id", "")))
		copia["autor"] = autor
		resultado.append(copia)
	resultado.sort_custom(_orden_mensajes)
	return resultado


## La búsqueda imita un índice pequeño de finales de los noventa: no busca texto
## libre en cada mensaje. Si un término no figura en el índice visible, no hay
## resultados, evitando que el jugador interrogue contenido que aún no conoce.
func buscar(consulta: String) -> Array[Dictionary]:
	var tokens := _tokens(consulta)
	var resultado: Array[Dictionary] = []
	if tokens.is_empty():
		return resultado
	var indexados := terminos_indexados()
	for token in tokens:
		if not indexados.has(token):
			return resultado
	for hilo in _hilos:
		if not _hilo_visible(hilo):
			continue
		var texto := _normalizar_texto(String(hilo.get("titulo", "")))
		for termino in hilo.get("terminos", []):
			texto += " " + _normalizar_texto(String(termino))
		var coincide := true
		for token in tokens:
			if not texto.contains(token):
				coincide = false
				break
		if coincide:
			var copia := hilo.duplicate(true)
			var tablon: Dictionary = _tablon_por_id.get(String(hilo.get("tablon_id", "")), {})
			copia["tablon_nombre"] = String(tablon.get("nombre", ""))
			resultado.append(copia)
	resultado.sort_custom(_orden_hilos)
	return resultado


func terminos_indexados() -> PackedStringArray:
	var resultado := PackedStringArray()
	for tablon in tablones_visibles():
		for termino in tablon.get("terminos_indexados", []):
			var normal := _normalizar_texto(String(termino))
			if not normal.is_empty() and not resultado.has(normal):
				resultado.append(normal)
	resultado.sort()
	return resultado


## Devuelve el mensaje citado aunque sea una lápida eliminada o movida. Nunca
## atraviesa condiciones de campaña: una referencia restringida se representa
## como no disponible en vez de filtrar su contenido.
func referencia_de_mensaje(mensaje_id: String) -> Dictionary:
	var origen: Variant = _mensaje_por_id.get(mensaje_id, {})
	if not origen is Dictionary or not _es_visible(origen as Dictionary):
		return {}
	var citado_id := String((origen as Dictionary).get("cita_mensaje_id", ""))
	if citado_id.is_empty():
		return {}
	var citado: Variant = _mensaje_por_id.get(citado_id, {})
	if not citado is Dictionary:
		return {"id": citado_id, "estado": "no_disponible"}
	if not _es_visible(citado as Dictionary):
		return {"id": citado_id, "estado": "no_disponible"}
	var copia := (citado as Dictionary).duplicate(true)
	copia["autor"] = perfil_usuario(String((citado as Dictionary).get("autor_id", "")))
	return copia


## Contrato para que Web98 pueda incorporar los tablones como destinos sin
## duplicar sus hilos ni mensajes dentro del índice general.
func recursos_web() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for tablon in tablones_visibles():
		resultado.append(_recurso_web_de_tablon(tablon))
	return resultado


## Catálogo completo para que Web98 registre también los tablones que aparecerán
## en jornadas posteriores. La visibilidad la vuelve a resolver Web98 con los
## mismos campos declarativos, evitando congelar el índice al contexto inicial.
func recursos_web_catalogo() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for tablon in _tablones:
		resultado.append(_recurso_web_de_tablon(tablon))
	return resultado


func _recurso_web_de_tablon(tablon: Dictionary) -> Dictionary:
	return {
		"id": String(tablon.get("id", "")),
		"url": String(tablon.get("url", "")),
		"titulo": String(tablon.get("nombre", "")),
		"snippet": String(tablon.get("descripcion", "")),
		"categoria": "comunidad",
		"terminos": tablon.get("terminos_indexados", []).duplicate(true),
		"prioridad": 58,
		"orden_directorio": 50,
		"indexado": true,
		"disponible_desde_dia": int(tablon.get("visible_desde_dia", 1)),
		"disponible_hasta_dia": int(tablon.get("visible_hasta_dia", 0)),
		"requiere_conocimiento": tablon.get("requiere_conocimiento", []).duplicate(true),
		"mirrors": [],
		"enlaces": tablon.get("enlaces_web", []).duplicate(true),
		"cache": null,
		"tipo": "bbs",
		"tablon_id": String(tablon.get("id", "")),
		"paquete_software": String(tablon.get("paquete_software", "")),
	}


func _hilo_visible(hilo: Dictionary) -> bool:
	if not _es_visible(hilo):
		return false
	var tablon: Variant = _tablon_por_id.get(String(hilo.get("tablon_id", "")), {})
	return tablon is Dictionary and _es_visible(tablon as Dictionary)


func _es_visible(elemento: Dictionary) -> bool:
	return (
		_disponible_en_dia(elemento)
		and _contiene_todos(
			_contexto.get("conocimiento", []), elemento.get("requiere_conocimiento", [])
		)
		and _contiene_todos(
			_contexto.get("companeros", []), elemento.get("requiere_companeros", [])
		)
	)


func _disponible_en_dia(elemento: Dictionary) -> bool:
	var dia := maxi(1, int(_contexto.get("dia", 1)))
	var desde := maxi(1, int(elemento.get("visible_desde_dia", 1)))
	var hasta := int(elemento.get("visible_hasta_dia", 0))
	if dia < desde:
		return false
	return hasta <= 0 or dia <= hasta


func _contiene_todos(disponibles: Variant, requeridos: Variant) -> bool:
	if not requeridos is Array:
		return true
	if not disponibles is Array:
		disponibles = []
	for valor in requeridos as Array:
		if not (disponibles as Array).has(String(valor)):
			return false
	return true


func _tokens(consulta: String) -> PackedStringArray:
	return _normalizar_texto(consulta).split(" ", false)


func _normalizar_texto(texto: String) -> String:
	var normal := texto.to_lower().strip_edges()
	var reemplazos := {
		"á": "a",
		"é": "e",
		"í": "i",
		"ó": "o",
		"ú": "u",
		"ü": "u",
		"ñ": "n",
		".": " ",
		",": " ",
		";": " ",
		":": " ",
		"/": " ",
		"\\": " ",
		"-": " ",
		"_": " ",
		"?": " ",
		"!": " ",
		"(": " ",
		")": " ",
		"[": " ",
		"]": " ",
	}
	for origen in reemplazos:
		normal = normal.replace(String(origen), String(reemplazos[origen]))
	while normal.contains("  "):
		normal = normal.replace("  ", " ")
	return normal.strip_edges()


func _orden_tablones(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("nombre", "")) < String(b.get("nombre", ""))


func _orden_hilos(a: Dictionary, b: Dictionary) -> bool:
	var fecha_a := String(a.get("fecha_ultimo", ""))
	var fecha_b := String(b.get("fecha_ultimo", ""))
	if fecha_a != fecha_b:
		return fecha_a > fecha_b
	return String(a.get("id", "")) < String(b.get("id", ""))


func _orden_mensajes(a: Dictionary, b: Dictionary) -> bool:
	var fecha_a := String(a.get("fecha", ""))
	var fecha_b := String(b.get("fecha", ""))
	if fecha_a != fecha_b:
		return fecha_a < fecha_b
	return String(a.get("id", "")) < String(b.get("id", ""))


func _cargar_catalogo(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return
	for valor in (datos as Dictionary).get("tablones", []):
		if not valor is Dictionary:
			continue
		var tablon := (valor as Dictionary).duplicate(true)
		var tablon_id := String(tablon.get("id", ""))
		if tablon_id.is_empty() or _tablon_por_id.has(tablon_id):
			continue
		_tablones.append(tablon)
		_tablon_por_id[tablon_id] = tablon
	for valor in (datos as Dictionary).get("usuarios", []):
		if not valor is Dictionary:
			continue
		var usuario := (valor as Dictionary).duplicate(true)
		var usuario_id := String(usuario.get("id", ""))
		if usuario_id.is_empty() or _usuario_por_id.has(usuario_id):
			continue
		_usuarios.append(usuario)
		_usuario_por_id[usuario_id] = usuario
	for valor in (datos as Dictionary).get("hilos", []):
		if not valor is Dictionary:
			continue
		var hilo := (valor as Dictionary).duplicate(true)
		var hilo_id := String(hilo.get("id", ""))
		if hilo_id.is_empty() or _hilo_por_id.has(hilo_id):
			continue
		if not _tablon_por_id.has(String(hilo.get("tablon_id", ""))):
			continue
		_hilos.append(hilo)
		_hilo_por_id[hilo_id] = hilo
	for valor in (datos as Dictionary).get("mensajes", []):
		if not valor is Dictionary:
			continue
		var mensaje := (valor as Dictionary).duplicate(true)
		var mensaje_id := String(mensaje.get("id", ""))
		if mensaje_id.is_empty() or _mensaje_por_id.has(mensaje_id):
			continue
		if not _hilo_por_id.has(String(mensaje.get("hilo_id", ""))):
			continue
		if not _usuario_por_id.has(String(mensaje.get("autor_id", ""))):
			continue
		_mensajes.append(mensaje)
		_mensaje_por_id[mensaje_id] = mensaje
