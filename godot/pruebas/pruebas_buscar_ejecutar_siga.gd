extends SceneTree

const Superficie := preload("res://guion/buscar_ejecutar_siga.gd")

var _fallos := 0
var _pasadas := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var apps: Array[Dictionary] = [
		{"id": "correo", "titulo": "Correo corporativo", "aliases": ["mail", "correo"]},
		{"id": "calculadora", "titulo": "Calculadora", "aliases": ["calc"]},
	]
	var contexto_base := {
		"jornada": 1,
		"dia": 1,
		"credenciales": [],
		"conocimiento": [],
		"urls_caidas": [],
		"memorandum_disponible": false,
		"habilitar_enlace13": false,
		"fase_contaminacion": 0,
	}

	var buscar := Superficie.new()
	buscar.configurar("buscar", apps, contexto_base)
	get_root().add_child(buscar)
	await process_frame
	_comprobar(buscar.get_node_or_null("Consulta") is LineEdit, "Buscar expone entrada de teclado")
	_comprobar(buscar.get_node_or_null("Resultados") is ItemList, "Buscar expone lista activable")
	_comprobar(
		_contiene_titulo(buscar.buscar("correo"), "Correo corporativo"), "encuentra aplicaciones"
	)
	_comprobar(
		_contiene_titulo(buscar.buscar("formulario"), "Formulario de incidencia"),
		"encuentra documentos visibles"
	)
	_comprobar(
		not _contiene_texto(buscar.buscar("acreditacion"), "Memorándum"),
		"no revela documentos ocultos"
	)
	buscar.queue_free()

	var ejecutar := Superficie.new()
	ejecutar.configurar("ejecutar", apps, contexto_base)
	get_root().add_child(ejecutar)
	await process_frame
	_comprobar(
		ejecutar.get_node_or_null("Comando") is LineEdit, "Ejecutar expone entrada de teclado"
	)
	var alias := ejecutar.resolver_comando("mail")
	_comprobar(
		alias.get("tipo") == "aplicacion" and alias.get("destino") == "correo",
		"resuelve alias declarados"
	)
	var ruta := ejecutar.resolver_comando("equipo/documentos")
	_comprobar(ruta.get("tipo") == "ruta", "abre rutas conocidas y visibles")
	var secreta := ejecutar.resolver_comando("equipo/red/acreditaciones")
	_comprobar(secreta.get("estado") != "ok", "deniega rutas sin credenciales")
	var arbitrario := ejecutar.resolver_comando("borrar todo")
	_comprobar(arbitrario.get("estado") == "no_encontrado", "rechaza comandos no catalogados")
	var ayuda := ejecutar.resolver_comando("ayuda")
	_comprobar(ayuda.get("tipo") == "ayuda", "ofrece ayuda accesible")
	ejecutar.queue_free()

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _contiene_titulo(resultados: Array[Dictionary], titulo: String) -> bool:
	for resultado in resultados:
		if String(resultado.get("titulo", "")) == titulo:
			return true
	return false


func _contiene_texto(resultados: Array[Dictionary], texto: String) -> bool:
	for resultado in resultados:
		if String(resultado.get("titulo", "")).contains(texto):
			return true
		if String(resultado.get("detalle", "")).contains(texto):
			return true
	return false


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
