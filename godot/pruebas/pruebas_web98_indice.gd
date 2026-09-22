## Prueba headless aislada del índice, prensa y navegador web ficticio del OS98.
## Cubre #537 / #660 / #667.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var indice := Web98Indice.new()
	indice.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})

	_comprobar(indice.catalogo().size() >= 16, "el catálogo incorpora la red y cuatro cabeceras")
	_comprobar(indice.categorias().size() >= 5, "existen categorías de directorio")
	_comprobar(indice.buscar("").is_empty(), "una consulta vacía no devuelve toda la red")
	_comprobar(
		indice.buscar("coño").is_empty(),
		"la búsqueda no confunde una palabra con una subcadena de economía",
	)

	var informatica := indice.buscar("informática")
	_comprobar(not informatica.is_empty(), "normaliza tildes al buscar")
	_comprobar(informatica[0]["id"] == "byte-local", "Byte Local responde a informática")
	var primera_busqueda := _ids(indice.buscar("shareware"))
	var segunda_busqueda := _ids(indice.buscar("shareware"))
	_comprobar(
		primera_busqueda == segunda_busqueda,
		"la misma consulta y estado producen el mismo orden",
	)

	var prensa_ids := _ids(indice.buscar("prensa"))
	_comprobar(prensa_ids.size() == 4, "las cuatro cabeceras son descubribles desde el índice")
	_comprobar(
		_ids(indice.enlaces_desde("portal-dgai")).has("prensa-la-plaza"),
		"el portal institucional enlaza el ecosistema de prensa",
	)
	var portada_resuelta := indice.resolver_url("http://laplaza.red98/")
	_comprobar(portada_resuelta["estado"] == "ok", "una cabecera tiene URL navegable")
	_comprobar(
		portada_resuelta["recurso"]["tipo"] == "prensa",
		"el índice marca la cabecera para el renderer especializado",
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

	_probar_prensa()
	_probar_navegador()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_prensa() -> void:
	var prensa := Web98Prensa.new()
	_comprobar(prensa.cabeceras().size() == 4, "existen exactamente cuatro cabeceras")
	_comprobar(prensa.hechos().size() >= 2, "la prensa tiene hechos para más de una jornada")

	var hecho_id := "turnos-atencion-planta4"
	var hecho := prensa.hecho(hecho_id)
	var tratamientos := prensa.tratamientos_de(hecho_id)
	_comprobar(tratamientos.size() == 4, "un mismo hecho tiene cuatro tratamientos editoriales")
	var titulares: Array[String] = []
	var datos_base := _ids_datos(hecho)
	for tratamiento in tratamientos:
		var titular := String(tratamiento.get("titular", ""))
		_comprobar(not titular.is_empty(), "cada tratamiento declara titular")
		_comprobar(not titulares.has(titular), "cada cabecera encuadra el hecho con titular propio")
		titulares.append(titular)
		for dato_id in tratamiento.get("datos_destacados", []):
			_comprobar(
				datos_base.has(String(dato_id)),
				"todo dato destacado procede del hecho compartido",
			)
		for dato_id in tratamiento.get("omisiones", []):
			_comprobar(
				datos_base.has(String(dato_id)),
				"toda omisión declarada referencia un dato real del hecho",
			)

	prensa.configurar_contexto({"dia": 1})
	for cabecera in prensa.cabeceras():
		var portada_dia1 := prensa.portada(String(cabecera.get("id", "")))
		_comprobar(portada_dia1["estado"] == "ok", "cada cabecera produce portada")
		_comprobar(portada_dia1["articulos"].size() == 1, "la portada del día 1 es temporal")
		_comprobar(
			portada_dia1["articulos"][0]["hecho_id"] == hecho_id,
			"las cuatro cabeceras parten del mismo hecho el día 1",
		)
		_comprobar(
			portada_dia1["articulos"][0]["hecho"]["datos"] == hecho["datos"],
			"el tratamiento no sustituye la base factual compartida",
		)

	var estado := {"historias_cartas": {"el-sol": "centrista"}}
	var elecciones_antes := Prometeo.conteo_elecciones_ideologicas(estado)
	prensa.configurar_contexto({"dia": 1})
	_comprobar(
		prensa.registrar_exposicion_portada(estado, "la-plaza") == 1,
		"leer una portada registra una exposición por el hecho mostrado",
	)
	_comprobar(
		prensa.registrar_exposicion_portada(estado, "la-plaza") == 0,
		"releer la misma portada no duplica exposición",
	)
	var exposiciones: Array = estado.get(Prometeo.CLAVE_EXPOSICION_IDEOLOGICA, [])
	_comprobar(exposiciones.size() == 1, "la exposición de prensa queda en su canal propio")
	_comprobar(
		String(exposiciones[0].get("fuente", "")) == "prensa:la-plaza",
		"la exposición conserva la fuente concreta sin rotularla en pantalla",
	)
	_comprobar(
		Prometeo.conteo_elecciones_ideologicas(estado) == elecciones_antes,
		"leer prensa no modifica las elecciones ideológicas de la vuelta",
	)

	prensa.configurar_contexto({"dia": 2})
	for cabecera in prensa.cabeceras():
		var portada_dia2 := prensa.portada(String(cabecera.get("id", "")))
		_comprobar(portada_dia2["articulos"].size() == 1, "la portada cambia con la jornada")
		_comprobar(
			portada_dia2["articulos"][0]["hecho_id"] == "licitacion-terminales-registro",
			"el día 2 publica el hecho correspondiente sin usar reloj real",
		)


func _probar_navegador() -> void:
	var navegador := NavegadorSiga.new()
	navegador.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})
	_comprobar(
		navegador.navegar(NavegadorSiga.URL_INICIO)["estado"] == "ok",
		"el navegador abre el portal de inicio mediante Web98Indice",
	)
	_comprobar(
		navegador.buscar("shareware")[0]["id"] == "byte-local",
		"la búsqueda del navegador delega en el índice",
	)
	var prensa := navegador.navegar("http://laplaza.red98/")
	_comprobar(prensa["estado"] == "ok", "el navegador abre una cabecera declarativa")
	_comprobar(prensa["recurso"]["tipo"] == "prensa", "conserva el tipo de renderer de prensa")
	navegador.navegar("http://byte.local/")
	_comprobar(navegador.historial().size() == 3, "registra navegación en historial")
	navegador.navegar("http://byte.local/")
	_comprobar(
		navegador.historial().size() == 3,
		"no duplica consecutivamente la misma URL en historial",
	)
	_comprobar(navegador.url_actual() == "http://byte.local/", "expone la URL actual")
	navegador.ir_atras()
	_comprobar(
		navegador.url_actual() == "http://laplaza.red98/", "Atrás recupera la visita anterior"
	)
	navegador.ir_adelante()
	_comprobar(
		navegador.url_actual() == "http://byte.local/", "Adelante recupera la visita siguiente"
	)
	navegador.alternar_favorito_actual()
	_comprobar(navegador.favoritos().has("http://byte.local/"), "permite marcar favoritos")

	var historial_antes_recarga := navegador.historial()
	var recargado := navegador.recargar()
	_comprobar(recargado["estado"] == "ok", "recargar vuelve a resolver la página actual")
	_comprobar(
		navegador.historial() == historial_antes_recarga,
		"recargar no contamina el historial de navegación",
	)

	var escala_inicial := navegador.escala_texto()
	navegador.ajustar_escala_texto(NavegadorSiga.ESCALA_TEXTO_PASO)
	_comprobar(
		is_equal_approx(
			navegador.escala_texto(),
			escala_inicial + NavegadorSiga.ESCALA_TEXTO_PASO,
		),
		"el navegador permite ampliar el texto",
	)
	for _paso in range(10):
		navegador.ajustar_escala_texto(NavegadorSiga.ESCALA_TEXTO_PASO)
	_comprobar(
		is_equal_approx(navegador.escala_texto(), NavegadorSiga.ESCALA_TEXTO_MAX),
		"el escalado de texto respeta un máximo legible",
	)

	var estado := navegador.exportar_estado()
	var restaurado := NavegadorSiga.new()
	restaurado.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})
	restaurado.configurar_estado(estado)
	_comprobar(restaurado.historial() == navegador.historial(), "restaura historial persistible")
	_comprobar(restaurado.favoritos() == navegador.favoritos(), "restaura favoritos persistibles")
	_comprobar(
		is_equal_approx(restaurado.escala_texto(), navegador.escala_texto()),
		"restaura la escala de texto persistible",
	)
	_comprobar(
		restaurado.navegar("http://intranet.dgai/diag/enlace13/")["estado"] == "no_encontrado",
		"el navegador no salta el gating de conocimiento",
	)
	restaurado.configurar_contexto(
		{"dia": 1, "conocimiento": [], "urls_caidas": ["http://byte.local/"]}
	)
	_comprobar(
		restaurado.navegar("http://byte.local/")["estado"] == "caido",
		"propaga estados de servidor simulado sin tocar la red real",
	)
	navegador.free()
	restaurado.free()


func _ids(recursos: Array[Dictionary]) -> Array[String]:
	var resultado: Array[String] = []
	for recurso in recursos:
		resultado.append(String(recurso.get("id", "")))
	return resultado


func _ids_datos(hecho: Dictionary) -> Array[String]:
	var resultado: Array[String] = []
	for dato_valor in hecho.get("datos", []):
		if dato_valor is Dictionary:
			resultado.append(String((dato_valor as Dictionary).get("id", "")))
	return resultado


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
