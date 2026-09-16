## Navegador corporativo simulado del escritorio OS98 (#537).
##
## Consume exclusivamente Web98Indice: no interpreta HTML, no realiza peticiones de
## red y no conoce el host. Historial/favoritos son estado local de aplicación;
## la disponibilidad de recursos sigue dependiendo del estado narrativo recibido.
class_name NavegadorSiga
extends VBoxContainer

signal estado_cambiado(estado: Dictionary)

const URL_INICIO := "http://intranet.dgai/"

var _indice := Web98Indice.new()
var _contexto: Dictionary = {"dia": 1, "conocimiento": [], "urls_caidas": []}
var _historial: Array[String] = []
var _indice_historial := -1
var _favoritos: Array[String] = []
var _resultado_actual: Dictionary = {}

var _atras: Button
var _adelante: Button
var _direccion: LineEdit
var _favorito: Button
var _pagina: RichTextLabel
var _enlaces: ItemList
var _historial_lista: ItemList
var _favoritos_lista: ItemList
var _busqueda: LineEdit
var _cache: Button


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)
	_indice.configurar_contexto(_contexto)
	if is_node_ready() and not url_actual().is_empty():
		_resolver_sin_historial(url_actual())


func configurar_estado(estado: Dictionary) -> void:
	_historial = _lista_strings(estado.get("historial", []))
	_favoritos = _lista_strings(estado.get("favoritos", []))
	_indice_historial = clampi(
		int(estado.get("indice_historial", _historial.size() - 1)), -1, _historial.size() - 1
	)
	if is_node_ready():
		_refrescar_laterales()
		if _indice_historial >= 0:
			_resolver_sin_historial(_historial[_indice_historial])


func exportar_estado() -> Dictionary:
	return {
		"historial": _historial.duplicate(),
		"indice_historial": _indice_historial,
		"favoritos": _favoritos.duplicate(),
	}


func historial() -> Array[String]:
	return _historial.duplicate()


func favoritos() -> Array[String]:
	return _favoritos.duplicate()


func url_actual() -> String:
	if _indice_historial >= 0 and _indice_historial < _historial.size():
		return _historial[_indice_historial]
	return String(_resultado_actual.get("url", ""))


func navegar(url: String, registrar_historial: bool = true) -> Dictionary:
	var limpia := url.strip_edges()
	if limpia.is_empty():
		return {}
	if not limpia.contains("://"):
		limpia = "http://" + limpia
	var resultado := _indice.resolver_url(limpia)
	_resultado_actual = resultado.duplicate(true)
	if registrar_historial:
		if _indice_historial + 1 < _historial.size():
			_historial = _historial.slice(0, _indice_historial + 1)
		_historial.append(limpia)
		_indice_historial = _historial.size() - 1
		_emitir_estado()
	if is_node_ready():
		_renderizar(resultado)
		_refrescar_laterales()
	return resultado.duplicate(true)


func buscar(consulta: String) -> Array[Dictionary]:
	return _indice.buscar(consulta)


func ir_atras() -> void:
	if _indice_historial <= 0:
		return
	_indice_historial -= 1
	_resolver_sin_historial(_historial[_indice_historial])
	_emitir_estado()


func ir_adelante() -> void:
	if _indice_historial < 0 or _indice_historial + 1 >= _historial.size():
		return
	_indice_historial += 1
	_resolver_sin_historial(_historial[_indice_historial])
	_emitir_estado()


func alternar_favorito_actual() -> void:
	var url := url_actual()
	if url.is_empty():
		return
	if _favoritos.has(url):
		_favoritos.erase(url)
	else:
		_favoritos.append(url)
	_emitir_estado()
	if is_node_ready():
		_refrescar_laterales()


func _ready() -> void:
	custom_minimum_size = Vector2(620, 410)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_indice.configurar_contexto(_contexto)
	_construir_interfaz()
	if _indice_historial >= 0 and _indice_historial < _historial.size():
		_resolver_sin_historial(_historial[_indice_historial])
	else:
		navegar(URL_INICIO)


func _construir_interfaz() -> void:
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 4)
	add_child(barra)

	_atras = Button.new()
	_atras.text = "<"
	_atras.tooltip_text = "Atrás"
	_atras.pressed.connect(ir_atras)
	barra.add_child(_atras)

	_adelante = Button.new()
	_adelante.text = ">"
	_adelante.tooltip_text = "Adelante"
	_adelante.pressed.connect(ir_adelante)
	barra.add_child(_adelante)

	var inicio := Button.new()
	inicio.text = "Inicio"
	inicio.pressed.connect(func() -> void: navegar(URL_INICIO))
	barra.add_child(inicio)

	_direccion = LineEdit.new()
	_direccion.placeholder_text = "Dirección"
	_direccion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_direccion.text_submitted.connect(func(texto: String) -> void: navegar(texto))
	barra.add_child(_direccion)

	var ir := Button.new()
	ir.text = "Ir"
	ir.pressed.connect(func() -> void: navegar(_direccion.text))
	barra.add_child(ir)

	_favorito = Button.new()
	_favorito.text = "Favorito"
	_favorito.pressed.connect(alternar_favorito_actual)
	barra.add_child(_favorito)

	_cache = Button.new()
	_cache.text = "Ver caché"
	_cache.visible = false
	_cache.pressed.connect(_abrir_cache_actual)
	barra.add_child(_cache)

	var barra_busqueda := HBoxContainer.new()
	add_child(barra_busqueda)
	var etiqueta := Label.new()
	etiqueta.text = "Buscar:"
	barra_busqueda.add_child(etiqueta)
	_busqueda = LineEdit.new()
	_busqueda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_busqueda.text_submitted.connect(_mostrar_busqueda)
	barra_busqueda.add_child(_busqueda)
	var boton_buscar := Button.new()
	boton_buscar.text = "Buscar"
	boton_buscar.pressed.connect(func() -> void: _mostrar_busqueda(_busqueda.text))
	barra_busqueda.add_child(boton_buscar)

	var cuerpo := HSplitContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(cuerpo)

	var principal := VBoxContainer.new()
	principal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(principal)

	_pagina = RichTextLabel.new()
	_pagina.bbcode_enabled = true
	_pagina.fit_content = false
	_pagina.selection_enabled = true
	_pagina.size_flags_vertical = Control.SIZE_EXPAND_FILL
	principal.add_child(_pagina)

	var etiqueta_enlaces := Label.new()
	etiqueta_enlaces.text = "Enlaces"
	principal.add_child(etiqueta_enlaces)
	_enlaces = ItemList.new()
	_enlaces.custom_minimum_size = Vector2(0, 110)
	_enlaces.item_activated.connect(_activar_enlace)
	principal.add_child(_enlaces)

	var lateral := VBoxContainer.new()
	lateral.custom_minimum_size = Vector2(190, 0)
	cuerpo.add_child(lateral)
	var etiqueta_historial := Label.new()
	etiqueta_historial.text = "Historial"
	lateral.add_child(etiqueta_historial)
	_historial_lista = ItemList.new()
	_historial_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_historial_lista.item_activated.connect(_activar_historial)
	lateral.add_child(_historial_lista)
	var etiqueta_favoritos := Label.new()
	etiqueta_favoritos.text = "Favoritos"
	lateral.add_child(etiqueta_favoritos)
	_favoritos_lista = ItemList.new()
	_favoritos_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_favoritos_lista.item_activated.connect(_activar_favorito)
	lateral.add_child(_favoritos_lista)


func _resolver_sin_historial(url: String) -> void:
	_resultado_actual = _indice.resolver_url(url)
	if is_node_ready():
		_renderizar(_resultado_actual)
		_refrescar_laterales()


func _renderizar(resultado: Dictionary) -> void:
	var url := url_actual()
	_direccion.text = url
	_atras.disabled = _indice_historial <= 0
	_adelante.disabled = _indice_historial < 0 or _indice_historial + 1 >= _historial.size()
	_favorito.text = "Quitar favorito" if _favoritos.has(url) else "Favorito"
	_enlaces.clear()
	_cache.visible = false

	var estado := String(resultado.get("estado", "no_encontrado"))
	if estado == "ok":
		var recurso: Dictionary = resultado.get("recurso", {})
		var titulo := String(recurso.get("titulo", "Sin título"))
		var snippet := String(recurso.get("snippet", ""))
		var via := String(resultado.get("via", "origen"))
		_pagina.text = (
			"[b]%s[/b]\n%s\n\n%s\n\nCategoría: %s · vía: %s"
			% [
				titulo,
				url,
				snippet,
				String(recurso.get("categoria", "")),
				via,
			]
		)
		for destino in _indice.enlaces_desde(String(recurso.get("id", ""))):
			var indice_item := _enlaces.add_item(String(destino.get("titulo", "Enlace")))
			_enlaces.set_item_metadata(indice_item, String(destino.get("url", "")))
		return
	if estado == "caido":
		_pagina.text = (
			"[b]Servidor no disponible[/b]\n%s\n\nEl servidor simulado no responde." % url
		)
		_cache.visible = bool(resultado.get("cache_disponible", false))
		return
	_pagina.text = (
		"[b]No se puede encontrar la página[/b]\n%s\n\nCompruebe la dirección o vuelva al portal interno."
		% url
	)


func _mostrar_busqueda(consulta: String) -> void:
	var resultados := buscar(consulta)
	_pagina.text = (
		"[b]Resultados para «%s»[/b]\n\n%d coincidencias en el índice local."
		% [consulta, resultados.size()]
	)
	_enlaces.clear()
	for recurso in resultados:
		var indice_item := _enlaces.add_item(
			"%s — %s" % [recurso.get("titulo", ""), recurso.get("snippet", "")]
		)
		_enlaces.set_item_metadata(indice_item, String(recurso.get("url", "")))


func _abrir_cache_actual() -> void:
	var recurso_id := String(_resultado_actual.get("recurso_id", ""))
	var cache := _indice.cache_de(recurso_id)
	if String(cache.get("estado", "")) != "ok":
		return
	var datos: Dictionary = cache.get("cache", {})
	_pagina.text = (
		"[b]%s[/b]\nCopia guardada · día %d\n\n%s\n\n%s"
		% [
			String(datos.get("titulo", "Copia en caché")),
			int(datos.get("capturada_dia", 0)),
			String(datos.get("snippet", "")),
			String(datos.get("cuerpo_resumen", "")),
		]
	)
	_enlaces.clear()


func _activar_enlace(indice_item: int) -> void:
	navegar(String(_enlaces.get_item_metadata(indice_item)))


func _activar_historial(indice_item: int) -> void:
	navegar(String(_historial_lista.get_item_metadata(indice_item)))


func _activar_favorito(indice_item: int) -> void:
	navegar(String(_favoritos_lista.get_item_metadata(indice_item)))


func _refrescar_laterales() -> void:
	if _historial_lista == null or _favoritos_lista == null:
		return
	_historial_lista.clear()
	for url in _historial:
		var indice_item := _historial_lista.add_item(url)
		_historial_lista.set_item_metadata(indice_item, url)
	_favoritos_lista.clear()
	for url in _favoritos:
		var indice_item := _favoritos_lista.add_item(url)
		_favoritos_lista.set_item_metadata(indice_item, url)


func _emitir_estado() -> void:
	estado_cambiado.emit(exportar_estado())


func _lista_strings(valor: Variant) -> Array[String]:
	var resultado: Array[String] = []
	if not valor is Array:
		return resultado
	for item in valor as Array:
		var texto := String(item).strip_edges()
		if not texto.is_empty() and not resultado.has(texto):
			resultado.append(texto)
	return resultado
