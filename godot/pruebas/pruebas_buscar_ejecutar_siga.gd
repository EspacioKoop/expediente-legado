extends SceneTree

const Superficie := preload("res://guion/buscar_ejecutar_siga.gd")
const ReconstruccionUI := preload("res://guion/reconstruccion_documental_siga.gd")

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

	var reconstruccion := {
		"id": "caso1_factura",
		"caso": "caso1@1",
		"registro": "factura@1",
		"folio": "F-1999-00231",
		"titulo": "Lo que afirma la factura",
		"fragmentos": ["Monto: 482000", "Proveedor sin RFC"],
		"planos":
		[
			{"encuadre": "general", "duracion": 1.0, "motivo": "mesa_factura"},
			{"encuadre": "detalle", "duracion": 1.0, "motivo": "sello"},
		],
	}
	var documentos: Array[Dictionary] = [
		{
			"caso": "caso1@1",
			"caso_titulo": "Cierre contable",
			"registro": "factura@1",
			"folio": "F-1999-00231",
			"tipo": "FACTURA",
			"contenido": "Monto 482000. Proveedor sin RFC.",
			"reconstruccion": reconstruccion,
		}
	]

	var buscar := Superficie.new()
	buscar.configurar("buscar", apps, contexto_base, documentos)
	get_root().add_child(buscar)
	await process_frame
	_comprobar(
		buscar.find_child("Consulta", true, false) is LineEdit, "Buscar expone entrada de teclado"
	)
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
	var resultados_evidencia := buscar.buscar("482000")
	_comprobar(
		_contiene_tipo(resultados_evidencia, "reconstruccion"),
		"encuentra reconstrucciones solo en evidencia aportada como leída",
	)
	_comprobar(
		buscar.buscar("solo-no-leido").is_empty(),
		"una evidencia no aportada por el controlador no entra en el índice",
	)
	var apertura := {"caso": "", "registro": ""}
	buscar.abrir_reconstruccion.connect(
		func(caso_id: String, registro_id: String):
			apertura["caso"] = caso_id
			apertura["registro"] = registro_id
	)
	buscar.call("_despachar", resultados_evidencia[0])
	_comprobar(
		apertura["caso"] == "caso1@1" and apertura["registro"] == "factura@1",
		"activar un resultado conserva la procedencia caso/registro",
	)

	var visor := ReconstruccionUI.new()
	visor.configurar(reconstruccion, false)
	get_root().add_child(visor)
	await process_frame
	_comprobar(
		visor.get_node_or_null("Plano3D") is SubViewportContainer,
		"la reconstrucción abre una maqueta 3D real",
	)
	var fuente := visor.get_node_or_null("Fuente") as Label
	_comprobar(
		fuente != null and fuente.text.contains("482000"),
		"la reconstrucción mantiene visibles los fragmentos de procedencia",
	)
	var estado_plano := visor.get_node_or_null("EstadoPlano") as Label
	_comprobar(
		estado_plano != null and estado_plano.text.begins_with("1/2"),
		"la reconstrucción empieza en el primer plano catalogado",
	)
	visor.call("_siguiente")
	_comprobar(
		estado_plano.text.begins_with("2/2"),
		"el jugador puede recorrer los puntos de vista catalogados",
	)
	visor.queue_free()
	buscar.queue_free()

	var ejecutar := Superficie.new()
	ejecutar.configurar("ejecutar", apps, contexto_base)
	get_root().add_child(ejecutar)
	await process_frame
	_comprobar(
		ejecutar.find_child("Comando", true, false) is LineEdit,
		"Ejecutar expone entrada de teclado"
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


func _contiene_tipo(resultados: Array[Dictionary], tipo: String) -> bool:
	for resultado in resultados:
		if String(resultado.get("tipo", "")) == tipo:
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
