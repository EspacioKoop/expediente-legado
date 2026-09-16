## Prueba headless aislada de páginas personales, webrings y guestbooks (#661).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var indice := Web98Indice.new()
	indice.configurar_contexto({"dia": 1, "conocimiento": [], "urls_caidas": []})

	var amateur := _ids_por_tipo(indice.catalogo(), "amateur")
	_comprobar(amateur.size() >= 8, "hay al menos ocho páginas amateur declaradas")
	_comprobar(
		_ids_por_tipo(indice.catalogo(), "webring").size() >= 2,
		"hay al menos dos índices de webring",
	)
	_comprobar(
		_ids_por_tipo(indice.catalogo(), "guestbook").size() >= 2,
		"hay guestbooks declarativos separados",
	)

	var pagina := indice.resolver_url("http://usuarios.red98/~jubilacion/")
	_comprobar(pagina["estado"] == "ok", "una página personal abre en el índice común")
	_comprobar(
		int(pagina["recurso"].get("contador_actual", -1)) == 1842,
		"el contador parte de un valor declarativo estable",
	)
	var enlaces := indice.enlaces_desde("pagina-jubilacion")
	var titulos := _titulos(enlaces)
	_comprobar(_contiene(titulos, "Anterior"), "el miembro expone navegación anterior")
	_comprobar(_contiene(titulos, "Índice"), "el miembro expone navegación al índice")
	_comprobar(_contiene(titulos, "Siguiente"), "el miembro expone navegación siguiente")

	var ring_a := indice.resolver_url("http://anillos.red98/aficiones/")
	var ring_b := indice.resolver_url("http://anillos.red98/caseras/")
	_comprobar(ring_a["estado"] == "ok", "el primer webring tiene índice navegable")
	_comprobar(ring_b["estado"] == "ok", "el segundo webring tiene índice navegable")
	var muerto := _destino_por_url(
		indice.enlaces_desde("ring-aficiones-index"), "http://usuarios.red98/~acuario/"
	)
	_comprobar(not muerto.is_empty(), "el índice conserva un miembro ausente")
	_comprobar(
		indice.resolver_url(String(muerto.get("url", "")))["estado"] == "no_encontrado",
		"el miembro ausente termina en el 404 simulado normal",
	)

	var libro_dia1 := indice.resolver_url("http://usuarios.red98/~jubilacion/visitas.html")
	_comprobar(
		libro_dia1["recurso"]["entradas_guestbook"].size() == 2,
		"el guestbook del día 1 solo muestra firmas ya fechadas",
	)
	_comprobar(
		not String(libro_dia1["recurso"]["snippet"]).contains("<form"),
		"el guestbook no introduce formulario HTML ni escritura libre",
	)

	indice.configurar_contexto({"dia": 2, "conocimiento": [], "urls_caidas": []})
	var libro_dia2 := indice.resolver_url("http://usuarios.red98/~jubilacion/visitas.html")
	_comprobar(
		libro_dia2["recurso"]["entradas_guestbook"].size() == 3,
		"una firma posterior aparece por jornada narrativa",
	)
	var antigua := indice.resolver_url("http://usuarios.red98/~ondas/")
	_comprobar(antigua["estado"] == "ok", "la URL antigua sigue resolviendo como página mudada")
	_comprobar(
		String(antigua["recurso"]["snippet"]).contains("http://usuarios.red98/~ondasfm/"),
		"la página mudada declara su nueva dirección",
	)
	_comprobar(
		indice.resolver_url("http://usuarios.red98/~ondasfm/")["estado"] == "ok",
		"la nueva dirección existe desde la jornada de mudanza",
	)
	_comprobar(
		not _ids(indice.buscar("radio")).has("pagina-radio"),
		"la nueva URL no aparece en búsqueda si está declarada como no indexada",
	)

	indice.configurar_contexto({"dia": 3, "conocimiento": [], "urls_caidas": []})
	var contador_dia3 := int(
		indice.resolver_url("http://usuarios.red98/~jubilacion/")["recurso"].get(
			"contador_actual", -1
		)
	)
	_comprobar(contador_dia3 == 1864, "el contador avanza de forma determinista con la jornada")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _ids_por_tipo(recursos: Array[Dictionary], tipo: String) -> Array[String]:
	var resultado: Array[String] = []
	for recurso in recursos:
		if String(recurso.get("tipo", "")) == tipo:
			resultado.append(String(recurso.get("id", "")))
	return resultado


func _ids(recursos: Array[Dictionary]) -> Array[String]:
	var resultado: Array[String] = []
	for recurso in recursos:
		resultado.append(String(recurso.get("id", "")))
	return resultado


func _titulos(recursos: Array[Dictionary]) -> Array[String]:
	var resultado: Array[String] = []
	for recurso in recursos:
		resultado.append(String(recurso.get("titulo", "")))
	return resultado


func _contiene(textos: Array[String], aguja: String) -> bool:
	for texto in textos:
		if texto.contains(aguja):
			return true
	return false


func _destino_por_url(recursos: Array[Dictionary], url: String) -> Dictionary:
	for recurso in recursos:
		if String(recurso.get("url", "")) == url:
			return recurso
	return {}


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
