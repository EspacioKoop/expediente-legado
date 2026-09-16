## Prueba headless aislada del índice web ficticio del OS98 (#660 / #667).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var indice := Web98Indice.new()
	indice.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})

	_comprobar(indice.catalogo().size() >= 12, "el catálogo tiene una red pequeña pero no trivial")
	_comprobar(indice.categorias().size() >= 5, "existen categorías de directorio")
	_comprobar(indice.buscar("").is_empty(), "una consulta vacía no devuelve toda la red")

	var informatica := indice.buscar("informática")
	_comprobar(not informatica.is_empty(), "normaliza tildes al buscar")
	_comprobar(informatica[0]["id"] == "byte-local", "Byte Local responde a informática")
	var primera_busqueda := _ids(indice.buscar("shareware"))
	var segunda_busqueda := _ids(indice.buscar("shareware"))
	_comprobar(
		primera_busqueda == segunda_busqueda,
		"la misma consulta y estado producen el mismo orden",
	)

	_comprobar(indice.buscar("enlace13").is_empty(), "enlace13 no se filtra antes de conocerlo")
	_comprobar(
		indice.resolver_url("http://intranet.dgai/diag/enlace13/")["estado"] == "no_encontrado",
		"una URL restringida tampoco revela el recurso por acceso directo",
	)
	indice.configurar_contexto({"dia": 1, "conocimiento": ["enlace13"], "urls_caidas": []})
	var restringido := indice.buscar("enlace13")
	_comprobar(restringido.size() == 1, "el conocimiento habilita el resultado restringido")
	_comprobar(restringido[0]["id"] == "diagnostico-enlace13", "habilita el recurso correcto")

	indice.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})
	var origen := indice.resolver_url("http://byte.local/")
	var mirror := indice.resolver_url("http://mirror.red98/byte-local/")
	_comprobar(origen["estado"] == "ok" and origen["via"] == "origen", "resuelve el origen")
	_comprobar(mirror["estado"] == "ok" and mirror["via"] == "mirror", "resuelve el mirror")
	_comprobar(
		origen["recurso"]["id"] == mirror["recurso"]["id"],
		"origen y mirror apuntan al mismo recurso"
	)

	indice.configurar_contexto(
		{"dia": 1, "conocimiento": [], "urls_caidas": ["http://byte.local/"]}
	)
	origen = indice.resolver_url("http://byte.local/")
	mirror = indice.resolver_url("http://mirror.red98/byte-local/")
	_comprobar(origen["estado"] == "caido", "el origen puede estar caído de forma declarativa")
	_comprobar(origen["cache_disponible"], "el error informa de que existe caché")
	_comprobar(mirror["estado"] == "ok", "caer el origen no derriba el mirror")
	_comprobar(
		indice.cache_de("byte-local")["estado"] == "ok", "la caché sobrevive al servidor caído"
	)

	indice.configurar_contexto({"dia": 3, "conocimiento": [], "urls_caidas": []})
	_comprobar(
		(
			indice.resolver_url("http://archivo.red98/modem/guia-33k.html")["estado"]
			== "no_encontrado"
		),
		"un recurso puede salir de publicación por jornada",
	)
	_comprobar(
		indice.cache_de("archivo-modem")["estado"] == "ok",
		"la copia guardada sigue disponible después de retirar el origen",
	)

	indice.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})
	_comprobar(
		not _ids(indice.buscar("libro visitas")).has("guestbook-becario"),
		"una página no indexada no aparece mágicamente en búsqueda",
	)
	_comprobar(
		_ids(indice.enlaces_desde("pagina-becario")).has("guestbook-becario"),
		"la misma página sí se descubre siguiendo un enlace",
	)
	var personales := _ids(indice.directorio("personal"))
	_comprobar(personales.has("pagina-becario"), "el directorio incluye la página del becario")
	_comprobar(personales.has("pagina-telefono"), "el directorio incluye la página de centralita")
	_comprobar(
		indice.cache_de("portal-dgai")["estado"] == "sin_cache",
		"no todos los recursos inventan caché"
	)
	_comprobar(
		indice.resolver_url("http://no-existe.red98/")["estado"] == "no_encontrado",
		"las URLs desconocidas producen un 404 simulado",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _ids(recursos: Array[Dictionary]) -> Array[String]:
	var resultado: Array[String] = []
	for recurso in recursos:
		resultado.append(String(recurso.get("id", "")))
	return resultado


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
