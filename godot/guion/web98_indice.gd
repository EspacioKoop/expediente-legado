## Índice declarativo de la web ficticia del OS98 (#660 / #667 / #661).
##
## Este modelo no navega Internet ni toca el host. Resuelve catálogos locales con
## estado explícito de campaña: día narrativo, conocimiento adquirido y URLs
## simuladas que están caídas. El navegador de #537 lo consume sin crear otro
## renderer o protocolo.
class_name Web98Indice
extends RefCounted

const RUTA_CATALOGO := "res://datos/web98_indice.json"
const RUTA_AMATEUR := "res://datos/web98_amateur.json"

var _categorias: Array[Dictionary] = []
var _recursos: Array[Dictionary] = []
var _por_id: Dictionary = {}
var _por_url: Dictionary = {}
var _contexto: Dictionary = {}


func _init(ruta: String = RUTA_CATALOGO) -> void:
	_cargar_catalogo(ruta)


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)


func catalogo() -> Array[Dictionary]:
	return _recursos.duplicate(true)


func categorias() -> Array[Dictionary]:
	return _categorias.duplicate(true)


func recursos_visibles() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for recurso in _recursos:
		if _es_visible(recurso):
			resultado.append(_materializar_recurso(recurso))
	return resultado


## Búsqueda pequeña e intencionalmente imperfecta: todos los tokens deben estar
## presentes, y la prioridad declarada rompe empates de forma reproducible.
func buscar(consulta: String) -> Array[Dictionary]:
	var tokens := _tokens(consulta)
	var resultado: Array[Dictionary] = []
	if tokens.is_empty():
		return resultado
	for recurso in _recursos:
		if not _es_visible(recurso) or not bool(recurso.get("indexado", true)):
			continue
		var puntuacion := _puntuacion(recurso, tokens)
		if puntuacion < 0:
			continue
		var copia := _materializar_recurso(recurso)
		copia["puntuacion_busqueda"] = puntuacion
		resultado.append(copia)
	resultado.sort_custom(_orden_busqueda)
	return resultado


func directorio(categoria: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for recurso in _recursos:
		if String(recurso.get("categoria", "")) != categoria:
			continue
		if _es_visible(recurso):
			resultado.append(_materializar_recurso(recurso))
	resultado.sort_custom(_orden_directorio)
	return resultado


## Resuelve tanto la URL canónica como sus mirrors declarativos. Una URL caída
## no afecta automáticamente a otras copias ni a la caché.
func resolver_url(url: String) -> Dictionary:
	var clave := _normalizar_url(url)
	var referencia: Variant = _por_url.get(clave, {})
	if not referencia is Dictionary or (referencia as Dictionary).is_empty():
		return {"estado": "no_encontrado", "url": url}
	var recurso_id := String((referencia as Dictionary).get("recurso_id", ""))
	var recurso: Variant = _por_id.get(recurso_id, {})
	if not recurso is Dictionary or not _es_visible(recurso as Dictionary):
		return {"estado": "no_encontrado", "url": url}
	var cache_disponible := (recurso as Dictionary).get("cache", null) is Dictionary
	if _url_caida(clave):
		return {
			"estado": "caido",
			"url": url,
			"recurso_id": recurso_id,
			"cache_disponible": cache_disponible,
		}
	return {
		"estado": "ok",
		"url": url,
		"url_origen": String((recurso as Dictionary).get("url", "")),
		"via": String((referencia as Dictionary).get("via", "origen")),
		"recurso": _materializar_recurso(recurso as Dictionary),
	}


## La caché representa una copia ya almacenada dentro de la ficción. Por eso su
## lectura ignora que el origen esté caído o haya dejado de publicarse, pero sí
## respeta el conocimiento de campaña para no filtrar recursos restringidos.
func cache_de(recurso_id: String) -> Dictionary:
	var recurso: Variant = _por_id.get(recurso_id, {})
	if not recurso is Dictionary or not _cumple_conocimiento(recurso as Dictionary):
		return {"estado": "no_encontrado", "recurso_id": recurso_id}
	var cache: Variant = (recurso as Dictionary).get("cache", null)
	if not cache is Dictionary:
		return {"estado": "sin_cache", "recurso_id": recurso_id}
	return {
		"estado": "ok",
		"recurso_id": recurso_id,
		"url_origen": String((recurso as Dictionary).get("url", "")),
		"cache": (cache as Dictionary).duplicate(true),
	}


## Grafo local para páginas personales, webrings y directorios. Además de los
## enlaces históricos por id acepta enlaces rotulados y URLs deliberadamente
## rotas. Estas últimas siguen siendo locales: el navegador las resuelve a su 404.
func enlaces_desde(recurso_id: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var origen: Variant = _por_id.get(recurso_id, {})
	if not origen is Dictionary or not _es_visible(origen as Dictionary):
		return resultado
	for destino_id in (origen as Dictionary).get("enlaces", []):
		_anadir_destino(resultado, String(destino_id), "")
	for enlace_valor in (origen as Dictionary).get("enlaces_rotulados", []):
		if not enlace_valor is Dictionary:
			continue
		var enlace := enlace_valor as Dictionary
		_anadir_destino(
			resultado,
			String(enlace.get("destino_id", "")),
			String(enlace.get("etiqueta", "")),
		)
	for enlace_valor in (origen as Dictionary).get("enlaces_url", []):
		if not enlace_valor is Dictionary:
			continue
		var enlace := enlace_valor as Dictionary
		var destino_url := String(enlace.get("url", ""))
		if destino_url.is_empty():
			continue
		var enlace_virtual := {
			"id": "",
			"url": destino_url,
			"titulo": String(enlace.get("titulo", destino_url)),
			"categoria": "personal",
			"tipo": "enlace_virtual",
		}
		resultado.append(enlace_virtual)
	return resultado


func _anadir_destino(resultado: Array[Dictionary], destino_id: String, etiqueta: String) -> void:
	var destino: Variant = _por_id.get(destino_id, {})
	if not destino is Dictionary or not _es_visible(destino as Dictionary):
		return
	var copia := _materializar_recurso(destino as Dictionary)
	if not etiqueta.is_empty():
		copia["titulo"] = etiqueta
	resultado.append(copia)


func _materializar_recurso(recurso: Dictionary) -> Dictionary:
	var copia := recurso.duplicate(true)
	var dia := maxi(1, int(_contexto.get("dia", 1)))

	for variante_valor in recurso.get("variantes", []):
		if not variante_valor is Dictionary:
			continue
		var variante := variante_valor as Dictionary
		if dia < maxi(1, int(variante.get("desde_dia", 1))):
			continue
		for clave in variante:
			if String(clave) != "desde_dia":
				copia[clave] = variante[clave]

	if copia.has("contador_base"):
		copia["contador_actual"] = (
			int(copia.get("contador_base", 0))
			+ maxi(0, dia - 1) * int(copia.get("contador_incremento_dia", 0))
		)

	var entradas_visibles: Array = []
	for entrada_valor in copia.get("entradas_guestbook", []):
		if not entrada_valor is Dictionary:
			continue
		var entrada := entrada_valor as Dictionary
		if dia >= maxi(1, int(entrada.get("visible_desde_dia", 1))):
			entradas_visibles.append(entrada.duplicate(true))
	if copia.has("entradas_guestbook"):
		copia["entradas_guestbook"] = entradas_visibles

	if String(copia.get("tipo", "")) in ["amateur", "guestbook", "webring"]:
		copia["snippet"] = _presentar_amateur(copia, dia)

	return copia


func _presentar_amateur(recurso: Dictionary, dia: int) -> String:
	var bloques: Array[String] = []
	var estilo: Dictionary = recurso.get("estilo", {})
	var banner := String(estilo.get("banner", "")).strip_edges()
	var icono := String(estilo.get("icono", "")).strip_edges()
	var separador := String(estilo.get("separador", "")).strip_edges()
	if not banner.is_empty():
		bloques.append("[center][b]%s %s[/b][/center]" % [icono, banner])
	var cuerpo := String(recurso.get("cuerpo", "")).strip_edges()
	if not cuerpo.is_empty():
		bloques.append(cuerpo)
	if recurso.has("contador_actual"):
		var formato_contador := String(recurso.get("contador_formato", "%05d"))
		bloques.append(
			"[center]%s[/center]" % (formato_contador % int(recurso.get("contador_actual", 0)))
		)
	var entradas: Variant = recurso.get("entradas_guestbook", [])
	if entradas is Array and not (entradas as Array).is_empty():
		var firmas: Array[String] = []
		var titulo_guestbook := String(recurso.get("guestbook_titulo", "")).strip_edges()
		if not titulo_guestbook.is_empty():
			firmas.append("[b]%s[/b]" % titulo_guestbook)
		for entrada_valor in entradas as Array:
			if not entrada_valor is Dictionary:
				continue
			var entrada := entrada_valor as Dictionary
			var fecha := String(entrada.get("fecha", ""))
			var autor := String(entrada.get("autor", ""))
			var texto_entrada := String(entrada.get("texto", ""))
			firmas.append("%s · [b]%s[/b]\n%s" % [fecha, autor, texto_entrada])
		bloques.append("\n\n".join(firmas))
	var firma := String(recurso.get("firma", "")).strip_edges()
	if not firma.is_empty():
		bloques.append(firma)
	var actualizacion := String(recurso.get("ultima_actualizacion", "")).strip_edges()
	if not actualizacion.is_empty():
		var formato_actualizacion := String(recurso.get("actualizacion_formato", "%s"))
		bloques.append(formato_actualizacion % actualizacion)

	var movido_a := String(recurso.get("movido_a", ""))
	var movido_desde := int(recurso.get("movido_desde_dia", 0))
	if not movido_a.is_empty() and movido_desde > 0 and dia >= movido_desde:
		var destino: Variant = _por_id.get(movido_a, {})
		if destino is Dictionary and _es_visible(destino as Dictionary):
			var mensaje := String(recurso.get("mensaje_mudanza", "")).strip_edges()
			if not mensaje.is_empty():
				bloques = [mensaje, String((destino as Dictionary).get("url", ""))]

	var base := String(recurso.get("snippet", "")).strip_edges()
	if not base.is_empty():
		bloques.push_front(base)
	var texto := "\n\n".join(bloques)
	if not separador.is_empty():
		texto = ("\n%s\n" % separador).join(bloques)
	var color := String(estilo.get("texto", "")).strip_edges()
	var fondo := String(estilo.get("fondo", "")).strip_edges()
	if not color.is_empty():
		texto = "[color=%s]%s[/color]" % [color, texto]
	if not fondo.is_empty():
		texto = "[bgcolor=%s]%s[/bgcolor]" % [fondo, texto]
	return texto


func _puntuacion(recurso: Dictionary, tokens: PackedStringArray) -> int:
	var titulo := _tokens(String(recurso.get("titulo", "")))
	var snippet := _tokens(String(recurso.get("snippet", "")))
	var etiquetas_texto := ""
	for termino in recurso.get("terminos", []):
		etiquetas_texto += " " + String(termino)
	var etiquetas := _tokens(etiquetas_texto)
	var puntuacion := int(recurso.get("prioridad", 0))
	for token in tokens:
		var encontrado := false
		if titulo.has(token):
			puntuacion += 30
			encontrado = true
		if etiquetas.has(token):
			puntuacion += 20
			encontrado = true
		if snippet.has(token):
			puntuacion += 5
			encontrado = true
		if not encontrado:
			return -1
	return puntuacion


func _es_visible(recurso: Dictionary) -> bool:
	return _cumple_conocimiento(recurso) and _disponible_en_dia(recurso)


func _cumple_conocimiento(recurso: Dictionary) -> bool:
	var conocido: Variant = _contexto.get("conocimiento", [])
	if not conocido is Array:
		conocido = []
	for clave in recurso.get("requiere_conocimiento", []):
		if not (conocido as Array).has(String(clave)):
			return false
	return true


func _disponible_en_dia(recurso: Dictionary) -> bool:
	var dia := maxi(1, int(_contexto.get("dia", 1)))
	var desde := maxi(1, int(recurso.get("disponible_desde_dia", 1)))
	var hasta := int(recurso.get("disponible_hasta_dia", 0))
	if dia < desde:
		return false
	return hasta <= 0 or dia <= hasta


func _url_caida(url_normalizada: String) -> bool:
	var caidas: Variant = _contexto.get("urls_caidas", [])
	if not caidas is Array:
		return false
	for url in caidas as Array:
		if _normalizar_url(String(url)) == url_normalizada:
			return true
	return false


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
		"~": " ",
	}
	for origen in reemplazos:
		normal = normal.replace(String(origen), String(reemplazos[origen]))
	while normal.contains("  "):
		normal = normal.replace("  ", " ")
	return normal.strip_edges()


func _normalizar_url(url: String) -> String:
	return url.strip_edges().to_lower()


func _orden_busqueda(a: Dictionary, b: Dictionary) -> bool:
	var puntuacion_a := int(a.get("puntuacion_busqueda", 0))
	var puntuacion_b := int(b.get("puntuacion_busqueda", 0))
	if puntuacion_a != puntuacion_b:
		return puntuacion_a > puntuacion_b
	return String(a.get("id", "")) < String(b.get("id", ""))


func _orden_directorio(a: Dictionary, b: Dictionary) -> bool:
	var orden_a := int(a.get("orden_directorio", 999))
	var orden_b := int(b.get("orden_directorio", 999))
	if orden_a != orden_b:
		return orden_a < orden_b
	return String(a.get("titulo", "")) < String(b.get("titulo", ""))


func _cargar_catalogo(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return
	for valor in (datos as Dictionary).get("categorias", []):
		if valor is Dictionary:
			_categorias.append((valor as Dictionary).duplicate(true))
	for valor in (datos as Dictionary).get("recursos", []):
		if valor is Dictionary:
			_registrar_recurso((valor as Dictionary).duplicate(true))
	if ruta == RUTA_CATALOGO:
		_cargar_recursos_extra(RUTA_AMATEUR)
		_cargar_bbs()
		_anexar_enlaces(
			"directorio-red98",
			["ring-aficiones-index", "ring-caseras-index", "pagina-gatos", "byte-local-bbs"],
		)
	_cargar_cabeceras_prensa()
	_anexar_enlaces_prensa()


func _cargar_recursos_extra(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return
	for valor in (datos as Dictionary).get("recursos", []):
		if valor is Dictionary:
			_registrar_recurso((valor as Dictionary).duplicate(true))


func _cargar_bbs() -> void:
	var bbs := Bbs98Modelo.new()
	for recurso in bbs.recursos_web_catalogo():
		_registrar_recurso(recurso)


func _cargar_cabeceras_prensa() -> void:
	var prensa := Web98Prensa.new()
	for cabecera in prensa.cabeceras():
		var recurso := {
			"id": String(cabecera.get("recurso_id", "")),
			"url": String(cabecera.get("url", "")),
			"titulo": String(cabecera.get("nombre", "")),
			"snippet": String(cabecera.get("snippet", "")),
			"categoria": "actualidad",
			"terminos": cabecera.get("terminos", []).duplicate(true),
			"prioridad": int(cabecera.get("prioridad", 60)),
			"orden_directorio": int(cabecera.get("orden_directorio", 50)),
			"indexado": true,
			"disponible_desde_dia": 1,
			"disponible_hasta_dia": 0,
			"requiere_conocimiento": [],
			"mirrors": [],
			"enlaces": [],
			"cache": null,
			"tipo": "prensa",
			"cabecera_id": String(cabecera.get("id", "")),
		}
		_registrar_recurso(recurso)


func _anexar_enlaces_prensa() -> void:
	var prensa_ids: Array[String] = []
	for recurso in _recursos:
		if String(recurso.get("tipo", "")) == "prensa":
			prensa_ids.append(String(recurso.get("id", "")))
	for origen_id in ["portal-dgai", "directorio-red98"]:
		_anexar_enlaces(origen_id, prensa_ids)
	for prensa_id in prensa_ids:
		var destinos := ["portal-dgai"]
		for otro_id in prensa_ids:
			if otro_id != prensa_id:
				destinos.append(otro_id)
		_anexar_enlaces(prensa_id, destinos)


func _anexar_enlaces(recurso_id: String, nuevos: Array) -> void:
	var recurso: Variant = _por_id.get(recurso_id, {})
	if not recurso is Dictionary:
		return
	var enlaces: Array = []
	var declarados: Variant = (recurso as Dictionary).get("enlaces", [])
	if declarados is Array:
		enlaces = (declarados as Array).duplicate()
	for destino_id in nuevos:
		var destino := String(destino_id)
		if not destino.is_empty() and _por_id.has(destino) and not enlaces.has(destino):
			enlaces.append(destino)
	(recurso as Dictionary)["enlaces"] = enlaces


func _registrar_recurso(recurso: Dictionary) -> void:
	var recurso_id := String(recurso.get("id", ""))
	var url := String(recurso.get("url", ""))
	if recurso_id.is_empty() or url.is_empty() or _por_id.has(recurso_id):
		return
	_recursos.append(recurso)
	_por_id[recurso_id] = recurso
	_registrar_url(url, recurso_id, "origen")
	for mirror in recurso.get("mirrors", []):
		_registrar_url(String(mirror), recurso_id, "mirror")


func _registrar_url(url: String, recurso_id: String, via: String) -> void:
	var clave := _normalizar_url(url)
	if clave.is_empty() or _por_url.has(clave):
		return
	_por_url[clave] = {"recurso_id": recurso_id, "via": via}
