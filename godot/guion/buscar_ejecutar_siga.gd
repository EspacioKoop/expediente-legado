## Superficies Buscar y Ejecutar del escritorio OS98 (#538).
##
## Todo se resuelve contra catálogos internos y contexto narrativo explícito.
## Ejecutar solo reconoce aplicaciones, rutas y URLs declaradas; no interpreta
## comandos arbitrarios ni delega trabajo al sistema anfitrión.
class_name BuscarEjecutarSiga
extends VBoxContainer

signal abrir_aplicacion(id: String)
signal abrir_ruta(ruta: String)
signal abrir_url(url: String)
signal abrir_ayuda
signal abrir_reconstruccion(caso_id: String, registro_id: String)

var _modo := "buscar"
var _apps: Array[Dictionary] = []
var _contexto: Dictionary = {}
var _documentos: Array[Dictionary] = []
var _entrada: LineEdit
var _lista: ItemList
var _detalle: Label
var _estado: Label
var _resultados: Array[Dictionary] = []


func configurar(
	modo: String,
	apps: Array[Dictionary],
	contexto: Dictionary,
	documentos: Array[Dictionary] = [],
) -> void:
	_modo = "ejecutar" if modo == "ejecutar" else "buscar"
	_apps = apps.duplicate(true)
	_contexto = contexto.duplicate(true)
	_documentos = documentos.duplicate(true)


func _ready() -> void:
	custom_minimum_size = Vector2(500, 330)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _modo == "ejecutar":
		_construir_ejecutar()
	else:
		_construir_buscar()
	_entrada.grab_focus()


func buscar(consulta: String) -> Array[Dictionary]:
	var normalizada := _normalizar(consulta)
	var resultado: Array[Dictionary] = []
	if normalizada.is_empty():
		return resultado

	for app in _apps:
		var titulo := String(app.get("titulo", ""))
		var id := String(app.get("id", ""))
		var alias_texto := " "
		for alias in app.get("aliases", []):
			alias_texto += " " + String(alias)
		if _coincide(normalizada, "%s %s %s" % [titulo, id, alias_texto]):
			var resultado_app := {
				"tipo": "aplicacion",
				"titulo": titulo,
				"detalle": "Aplicación instalada",
				"destino": id,
			}
			resultado.append(resultado_app)

	for documento in _documentos:
		var reconstruccion: Dictionary = documento.get("reconstruccion", {})
		if reconstruccion.is_empty():
			continue
		var bolsa_documento := (
			"%s %s %s %s %s"
			% [
				String(documento.get("folio", "")),
				String(documento.get("tipo", "")),
				String(documento.get("caso_titulo", "")),
				String(documento.get("contenido", "")),
				_texto_fragmentos(reconstruccion.get("fragmentos", [])),
			]
		)
		if not _coincide(normalizada, bolsa_documento):
			continue
		var resultado_reconstruccion := {
			"tipo": "reconstruccion",
			"titulo": "%s · %s" % [tr("VISOR_RECONSTRUIR"), String(documento.get("folio", ""))],
			"detalle":
			(
				"%s · %s"
				% [
					String(documento.get("caso_titulo", "")),
					String(reconstruccion.get("titulo", "")),
				]
			),
			"destino": String(documento.get("registro", "")),
			"caso": String(documento.get("caso", "")),
		}
		resultado.append(resultado_reconstruccion)

	var explorador := ExploradorSigaModelo.new()
	explorador.configurar_contexto(_contexto)
	var pendientes: Array[String] = [ExploradorSigaModelo.RUTA_RAIZ]
	var visitadas: Dictionary = {}
	while not pendientes.is_empty():
		var ruta := String(pendientes.pop_front())
		if visitadas.has(ruta):
			continue
		visitadas[ruta] = true
		for entrada in explorador.listar_ruta(ruta):
			if not explorador.puede_acceder(entrada):
				continue
			var tipo := String(entrada.get("tipo", ""))
			var ruta_entrada := String(entrada.get("ruta", ""))
			if tipo == "carpeta" and not ruta_entrada.is_empty():
				pendientes.append(ruta_entrada)
			var nombre := String(entrada.get("nombre", ""))
			if not _coincide(normalizada, "%s %s %s" % [nombre, ruta_entrada, tipo]):
				continue
			var destino := ruta_entrada
			var accion := "Abrir carpeta"
			if tipo != "carpeta":
				destino = explorador.ruta_padre(ruta_entrada)
				accion = "Abrir ubicación"
			var resultado_ruta := {
				"tipo": "ruta",
				"titulo": nombre,
				"detalle": "%s · %s" % [accion, ruta_entrada],
				"destino": destino,
			}
			resultado.append(resultado_ruta)

	var web := Web98Indice.new()
	web.configurar_contexto(_contexto)
	for recurso in web.buscar(consulta):
		var resultado_web := {
			"tipo": "url",
			"titulo": String(recurso.get("titulo", recurso.get("url", "Web98"))),
			"detalle": String(recurso.get("url", "")),
			"destino": String(recurso.get("url", "")),
		}
		resultado.append(resultado_web)

	if _coincide(normalizada, "ayuda sistema comandos buscar ejecutar"):
		var resultado_ayuda := {
			"tipo": "ayuda",
			"titulo": "Ayuda del sistema",
			"detalle": "Uso del escritorio y comandos disponibles",
			"destino": "",
		}
		resultado.append(resultado_ayuda)
	return resultado


func resolver_comando(comando: String) -> Dictionary:
	var limpio := comando.strip_edges()
	if limpio.is_empty():
		return {"estado": "vacio", "mensaje": "Escriba un comando, aplicación, ruta o URL."}

	var normalizado := _normalizar(limpio)
	for prefijo in ["abrir ", "ejecutar ", "run "]:
		if normalizado.begins_with(prefijo):
			limpio = limpio.substr(prefijo.length()).strip_edges()
			normalizado = _normalizar(limpio)
			break

	var resolucion := _resolver_alias_o_ayuda(normalizado)
	if not resolucion.is_empty():
		return resolucion
	resolucion = _resolver_ruta_comando(limpio)
	if not resolucion.is_empty():
		return resolucion
	resolucion = _resolver_url_comando(limpio)
	if not resolucion.is_empty():
		return resolucion
	return {
		"estado": "no_encontrado",
		"mensaje": "Comando no reconocido. Escriba «ayuda» para ver las opciones permitidas.",
	}


func _resolver_alias_o_ayuda(normalizado: String) -> Dictionary:
	if normalizado in ["help", "ayuda", "?"]:
		return {
			"estado": "ok",
			"tipo": "ayuda",
			"destino": "",
			"mensaje": "Comandos: alias de aplicación, ruta conocida o URL Web98 conocida.",
		}
	for app in _apps:
		var id := String(app.get("id", ""))
		var candidatos: Array[String] = [
			_normalizar(id), _normalizar(String(app.get("titulo", "")))
		]
		for alias in app.get("aliases", []):
			candidatos.append(_normalizar(String(alias)))
		if candidatos.has(normalizado):
			return {
				"estado": "ok",
				"tipo": "aplicacion",
				"destino": id,
				"mensaje": "Abriendo %s…" % String(app.get("titulo", id)),
			}
	return {}


func _resolver_ruta_comando(limpio: String) -> Dictionary:
	var explorador := ExploradorSigaModelo.new()
	explorador.configurar_contexto(_contexto)
	var entrada := explorador.resolver_ruta(limpio)
	if entrada.is_empty():
		return {}
	if (
		explorador.es_visible(entrada)
		and explorador.puede_acceder(entrada)
		and String(entrada.get("tipo", "")) == "carpeta"
	):
		return {
			"estado": "ok",
			"tipo": "ruta",
			"destino": String(entrada.get("ruta", "")),
			"mensaje": "Abriendo %s…" % String(entrada.get("nombre", "carpeta")),
		}
	return {"estado": "denegado", "mensaje": "La ruta no está disponible."}


func _resolver_url_comando(limpio: String) -> Dictionary:
	if (
		not limpio.to_lower().begins_with("http://")
		and not limpio.to_lower().begins_with("https://")
	):
		return {}
	var web := Web98Indice.new()
	web.configurar_contexto(_contexto)
	var resolucion := web.resolver_url(limpio)
	if String(resolucion.get("estado", "no_encontrado")) != "no_encontrado":
		return {
			"estado": "ok",
			"tipo": "url",
			"destino": limpio,
			"mensaje": "Abriendo destino Web98…",
		}
	return {"estado": "no_encontrado", "mensaje": "La dirección no figura en Web98."}


func _construir_buscar() -> void:
	var titulo := Label.new()
	titulo.text = tr("Buscar")
	add_child(titulo)

	var ayuda := Label.new()
	ayuda.text = tr("Busca aplicaciones, documentos visibles, sitios conocidos y ayuda.")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ayuda)

	var barra := HBoxContainer.new()
	add_child(barra)
	_entrada = LineEdit.new()
	_entrada.name = "Consulta"
	_entrada.placeholder_text = tr("Nombre o término…")
	_entrada.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entrada.text_submitted.connect(_al_buscar_texto)
	barra.add_child(_entrada)
	var boton := Button.new()
	boton.text = tr("Buscar")
	boton.pressed.connect(_realizar_busqueda)
	barra.add_child(boton)

	_lista = ItemList.new()
	_lista.name = "Resultados"
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.item_selected.connect(_mostrar_detalle)
	_lista.item_activated.connect(_activar_resultado)
	add_child(_lista)

	_detalle = Label.new()
	_detalle.name = "Detalle"
	_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detalle.text = tr("Escriba una consulta.")
	add_child(_detalle)


func _construir_ejecutar() -> void:
	var titulo := Label.new()
	titulo.text = tr("Ejecutar…")
	add_child(titulo)

	var ayuda := Label.new()
	ayuda.text = tr(
		"Abra una aplicación, carpeta o dirección Web98 conocida. «ayuda» muestra ejemplos."
	)
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ayuda)

	var barra := HBoxContainer.new()
	add_child(barra)
	_entrada = LineEdit.new()
	_entrada.name = "Comando"
	_entrada.placeholder_text = tr("Ej.: correo, equipo/documentos, http://…")
	_entrada.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entrada.text_submitted.connect(_al_ejecutar_texto)
	barra.add_child(_entrada)
	var boton := Button.new()
	boton.text = tr("Aceptar")
	boton.pressed.connect(_ejecutar_actual)
	barra.add_child(boton)

	_estado = Label.new()
	_estado.name = "Estado"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.text = tr("Solo se aceptan destinos declarados por el escritorio.")
	add_child(_estado)


func _al_buscar_texto(_texto: String) -> void:
	_realizar_busqueda()


func _realizar_busqueda() -> void:
	_resultados = buscar(_entrada.text)
	_lista.clear()
	for resultado in _resultados:
		var indice := _lista.add_item(String(resultado.get("titulo", "Resultado")))
		_lista.set_item_metadata(indice, resultado)
	if _resultados.is_empty():
		_detalle.text = tr("No se encontraron resultados visibles.")
		return
	_lista.select(0)
	_mostrar_detalle(0)


func _mostrar_detalle(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var resultado: Variant = _lista.get_item_metadata(indice)
	if resultado is Dictionary:
		_detalle.text = String((resultado as Dictionary).get("detalle", ""))


func _activar_resultado(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var resultado: Variant = _lista.get_item_metadata(indice)
	if resultado is Dictionary:
		_despachar(resultado as Dictionary)


func _al_ejecutar_texto(_texto: String) -> void:
	_ejecutar_actual()


func _ejecutar_actual() -> void:
	var resultado := resolver_comando(_entrada.text)
	_estado.text = String(resultado.get("mensaje", ""))
	if String(resultado.get("estado", "")) == "ok":
		_despachar(resultado)


func _despachar(resultado: Dictionary) -> void:
	match String(resultado.get("tipo", "")):
		"aplicacion":
			abrir_aplicacion.emit(String(resultado.get("destino", "")))
		"ruta":
			abrir_ruta.emit(String(resultado.get("destino", "")))
		"url":
			abrir_url.emit(String(resultado.get("destino", "")))
		"ayuda":
			abrir_ayuda.emit()
		"reconstruccion":
			abrir_reconstruccion.emit(
				String(resultado.get("caso", "")), String(resultado.get("destino", ""))
			)


func _texto_fragmentos(fragmentos: Array) -> String:
	var texto := ""
	for fragmento in fragmentos:
		if not texto.is_empty():
			texto += " "
		texto += String(fragmento)
	return texto


func _coincide(consulta_normalizada: String, texto: String) -> bool:
	var bolsa := _normalizar(texto)
	for token in consulta_normalizada.split(" ", false):
		if not bolsa.contains(token):
			return false
	return true


func _normalizar(texto: String) -> String:
	var normal := texto.to_lower().strip_edges()
	var reemplazos := {
		"á": "a",
		"é": "e",
		"í": "i",
		"ó": "o",
		"ú": "u",
		"ü": "u",
		"ñ": "n",
		"-": " ",
		"_": " ",
	}
	for origen in reemplazos:
		normal = normal.replace(String(origen), String(reemplazos[origen]))
	while normal.contains("  "):
		normal = normal.replace("  ", " ")
	return normal
