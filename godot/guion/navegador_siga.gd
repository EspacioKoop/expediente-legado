## Navegador corporativo simulado del escritorio OS98 (#537).
##
## Consume exclusivamente modelos Web98 locales: no interpreta HTML, no realiza
## peticiones de red y no conoce el host. Historial/favoritos son estado local de
## aplicación; la disponibilidad sigue dependiendo del estado narrativo recibido.
class_name NavegadorSiga
extends VBoxContainer

signal estado_cambiado(estado: Dictionary)
signal paquete_software_obtenido(id: String)

const URL_INICIO := "http://intranet.dgai/"
const TEXTURA_CABECERAS_PRENSA := preload("res://arte/os98/prensa_cabeceras_98.svg")
const TEXTURA_WEB_CABECERAS := preload("res://arte/os98/web_cabeceras_sitios_98.svg")
const TEXTURA_WEB_NAVEGACION := preload("res://arte/os98/web_navegacion_sitios_98.svg")
const TEXTURA_WEB_MODULOS := preload("res://arte/os98/web_modulos_sitios_98.svg")
const TEXTURA_WEB_BADGES := preload("res://arte/os98/web_badges_88x31.svg")
const TEXTURA_WEB_DECORACION := preload("res://arte/os98/web_decoracion_sitios_98.svg")
const SITIOS_WEB_VISUALES := {
	"marcador-98": {"fila": 0, "modulo": 0},
	"meteo-red": {"fila": 1, "modulo": 1},
	"byte-local": {"fila": 2, "modulo": 2},
	"butaca-7": {"fila": 3, "modulo": 3},
	"tablón-clasificados": {"fila": 4, "modulo": 4},
}
const MODULO_WEB_PERSONAL := 5
const ESCALA_TEXTO_MIN := 0.8
const ESCALA_TEXTO_MAX := 1.6
const ESCALA_TEXTO_PASO := 0.2

var _indice := Web98Indice.new()
var _prensa := Web98Prensa.new()
var _bbs := Bbs98Modelo.new()
var _contexto: Dictionary = {"dia": 1, "conocimiento": [], "urls_caidas": []}
var _historial: Array[String] = []
var _indice_historial := -1
var _favoritos: Array[String] = []
var _resultado_actual: Dictionary = {}
var _escala_texto := 1.0

var _atras: Button
var _adelante: Button
var _direccion: LineEdit
var _favorito: Button
var _cabecera_prensa: TextureRect
var _cabecera_sitio: TextureRect
var _navegacion_sitio: TextureRect
var _modulo_sitio: TextureRect
var _badge_web: TextureRect
var _decoracion_web: TextureRect
var _pagina: RichTextLabel
var _enlaces: ItemList
var _historial_lista: ItemList
var _favoritos_lista: ItemList
var _busqueda: LineEdit
var _cache: Button
var _descargar_software: Button
var _paquete_software_actual := ""


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)
	_indice.configurar_contexto(_contexto)
	_prensa.configurar_contexto(_contexto)
	_bbs.configurar_contexto(_contexto)
	if is_node_ready() and not url_actual().is_empty():
		_resolver_sin_historial(url_actual())


func configurar_estado(estado: Dictionary) -> void:
	_historial = _lista_strings(estado.get("historial", []))
	_favoritos = _lista_strings(estado.get("favoritos", []))
	_indice_historial = clampi(
		int(estado.get("indice_historial", _historial.size() - 1)), -1, _historial.size() - 1
	)
	_escala_texto = clampf(
		float(estado.get("escala_texto", 1.0)), ESCALA_TEXTO_MIN, ESCALA_TEXTO_MAX
	)
	if is_node_ready():
		_aplicar_escala_texto()
		_refrescar_laterales()
		if _indice_historial >= 0:
			_resolver_sin_historial(_historial[_indice_historial])


func exportar_estado() -> Dictionary:
	return {
		"historial": _historial.duplicate(),
		"indice_historial": _indice_historial,
		"favoritos": _favoritos.duplicate(),
		"escala_texto": _escala_texto,
	}


func historial() -> Array[String]:
	return _historial.duplicate()


func favoritos() -> Array[String]:
	return _favoritos.duplicate()


func escala_texto() -> float:
	return _escala_texto


func ajustar_escala_texto(delta: float) -> void:
	_escala_texto = clampf(
		snappedf(_escala_texto + delta, ESCALA_TEXTO_PASO),
		ESCALA_TEXTO_MIN,
		ESCALA_TEXTO_MAX,
	)
	if is_node_ready():
		_aplicar_escala_texto()
	_emitir_estado()


func recargar() -> Dictionary:
	var url := url_actual()
	if url.is_empty():
		return {}
	_resolver_sin_historial(url)
	return _resultado_actual.duplicate(true)


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
	var url_indice := limpia
	var hilo_bbs := ""
	var marcador_hilo := limpia.find("#hilo=")
	if marcador_hilo >= 0:
		url_indice = limpia.substr(0, marcador_hilo)
		hilo_bbs = limpia.substr(marcador_hilo + 6).strip_edges()
	var resultado := _indice.resolver_url(url_indice)
	if not hilo_bbs.is_empty() and String(resultado.get("estado", "")) == "ok":
		var recurso_bbs: Dictionary = resultado.get("recurso", {})
		if String(recurso_bbs.get("tipo", "")) == "bbs":
			resultado["bbs_hilo_id"] = hilo_bbs
	_resultado_actual = resultado.duplicate(true)
	if registrar_historial:
		var repite_actual := (
			_indice_historial >= 0
			and _indice_historial < _historial.size()
			and _historial[_indice_historial].to_lower() == limpia.to_lower()
		)
		if not repite_actual:
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
	_prensa.configurar_contexto(_contexto)
	_bbs.configurar_contexto(_contexto)
	_construir_interfaz()
	_aplicar_escala_texto()
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
	_atras.tooltip_text = tr("NAVEGADOR_ATRAS")
	_atras.pressed.connect(ir_atras)
	barra.add_child(_atras)

	_adelante = Button.new()
	_adelante.text = ">"
	_adelante.tooltip_text = tr("NAVEGADOR_ADELANTE")
	_adelante.pressed.connect(ir_adelante)
	barra.add_child(_adelante)

	var boton_recargar := Button.new()
	boton_recargar.text = tr("NAVEGADOR_RECARGAR")
	boton_recargar.tooltip_text = tr("NAVEGADOR_ATAJO_RECARGAR")
	boton_recargar.pressed.connect(recargar)
	barra.add_child(boton_recargar)

	var inicio := Button.new()
	inicio.text = tr("NAVEGADOR_INICIO")
	inicio.pressed.connect(func() -> void: navegar(URL_INICIO))
	barra.add_child(inicio)

	_direccion = LineEdit.new()
	_direccion.placeholder_text = tr("NAVEGADOR_DIRECCION")
	_direccion.tooltip_text = tr("NAVEGADOR_ATAJO_DIRECCION")
	_direccion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_direccion.text_submitted.connect(func(texto: String) -> void: navegar(texto))
	barra.add_child(_direccion)

	var ir := Button.new()
	ir.text = tr("NAVEGADOR_IR")
	ir.pressed.connect(func() -> void: navegar(_direccion.text))
	barra.add_child(ir)

	_favorito = Button.new()
	_favorito.text = tr("NAVEGADOR_FAVORITO")
	_favorito.pressed.connect(alternar_favorito_actual)
	barra.add_child(_favorito)

	var texto_menos := Button.new()
	texto_menos.text = tr("NAVEGADOR_TEXTO_MENOS")
	texto_menos.pressed.connect(func() -> void: ajustar_escala_texto(-ESCALA_TEXTO_PASO))
	barra.add_child(texto_menos)

	var texto_mas := Button.new()
	texto_mas.text = tr("NAVEGADOR_TEXTO_MAS")
	texto_mas.pressed.connect(func() -> void: ajustar_escala_texto(ESCALA_TEXTO_PASO))
	barra.add_child(texto_mas)

	_cache = Button.new()
	_cache.text = tr("NAVEGADOR_CACHE")
	_cache.visible = false
	_cache.pressed.connect(_abrir_cache_actual)
	barra.add_child(_cache)

	var barra_busqueda := HBoxContainer.new()
	add_child(barra_busqueda)
	var etiqueta := Label.new()
	etiqueta.text = tr("NAVEGADOR_BUSCAR_ETIQUETA")
	barra_busqueda.add_child(etiqueta)
	_busqueda = LineEdit.new()
	_busqueda.tooltip_text = tr("NAVEGADOR_ATAJO_BUSCAR")
	_busqueda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_busqueda.text_submitted.connect(_mostrar_busqueda)
	barra_busqueda.add_child(_busqueda)
	var boton_buscar := Button.new()
	boton_buscar.text = tr("NAVEGADOR_BUSCAR")
	boton_buscar.pressed.connect(func() -> void: _mostrar_busqueda(_busqueda.text))
	barra_busqueda.add_child(boton_buscar)

	var cuerpo := HSplitContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(cuerpo)

	var principal := VBoxContainer.new()
	principal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(principal)

	_cabecera_sitio = TextureRect.new()
	_cabecera_sitio.custom_minimum_size = Vector2(468, 72)
	_cabecera_sitio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cabecera_sitio.visible = false
	principal.add_child(_cabecera_sitio)

	_navegacion_sitio = TextureRect.new()
	_navegacion_sitio.custom_minimum_size = Vector2(468, 24)
	_navegacion_sitio.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_navegacion_sitio.visible = false
	principal.add_child(_navegacion_sitio)

	_cabecera_prensa = TextureRect.new()
	_cabecera_prensa.custom_minimum_size = Vector2(468, 60)
	_cabecera_prensa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cabecera_prensa.visible = false
	principal.add_child(_cabecera_prensa)

	var visual_web := HBoxContainer.new()
	visual_web.alignment = BoxContainer.ALIGNMENT_CENTER
	visual_web.add_theme_constant_override("separation", 12)
	principal.add_child(visual_web)

	_modulo_sitio = TextureRect.new()
	_modulo_sitio.custom_minimum_size = Vector2(220, 100)
	_modulo_sitio.visible = false
	visual_web.add_child(_modulo_sitio)

	_badge_web = TextureRect.new()
	_badge_web.custom_minimum_size = Vector2(88, 31)
	_badge_web.visible = false
	visual_web.add_child(_badge_web)

	_decoracion_web = TextureRect.new()
	_decoracion_web.custom_minimum_size = Vector2(468, 28)
	_decoracion_web.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_decoracion_web.visible = false
	principal.add_child(_decoracion_web)

	_pagina = RichTextLabel.new()
	_pagina.bbcode_enabled = true
	_pagina.fit_content = false
	_pagina.selection_enabled = true
	_pagina.focus_mode = Control.FOCUS_ALL
	_pagina.size_flags_vertical = Control.SIZE_EXPAND_FILL
	principal.add_child(_pagina)

	_descargar_software = Button.new()
	_descargar_software.name = "DescargarSoftware"
	_descargar_software.visible = false
	_descargar_software.pressed.connect(_obtener_software_actual)
	principal.add_child(_descargar_software)

	var etiqueta_enlaces := Label.new()
	etiqueta_enlaces.text = tr("NAVEGADOR_ENLACES")
	principal.add_child(etiqueta_enlaces)
	_enlaces = ItemList.new()
	_enlaces.custom_minimum_size = Vector2(0, 110)
	_enlaces.item_activated.connect(_activar_enlace)
	principal.add_child(_enlaces)

	var lateral := VBoxContainer.new()
	lateral.custom_minimum_size = Vector2(190, 0)
	cuerpo.add_child(lateral)
	var etiqueta_historial := Label.new()
	etiqueta_historial.text = tr("NAVEGADOR_HISTORIAL")
	lateral.add_child(etiqueta_historial)
	_historial_lista = ItemList.new()
	_historial_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_historial_lista.item_activated.connect(_activar_historial)
	lateral.add_child(_historial_lista)
	var etiqueta_favoritos := Label.new()
	etiqueta_favoritos.text = tr("NAVEGADOR_FAVORITOS")
	lateral.add_child(etiqueta_favoritos)
	_favoritos_lista = ItemList.new()
	_favoritos_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_favoritos_lista.item_activated.connect(_activar_favorito)
	lateral.add_child(_favoritos_lista)


func _resolver_sin_historial(url: String) -> void:
	var url_indice := url
	var hilo_bbs := ""
	var marcador_hilo := url.find("#hilo=")
	if marcador_hilo >= 0:
		url_indice = url.substr(0, marcador_hilo)
		hilo_bbs = url.substr(marcador_hilo + 6).strip_edges()
	_resultado_actual = _indice.resolver_url(url_indice)
	if not hilo_bbs.is_empty() and String(_resultado_actual.get("estado", "")) == "ok":
		var recurso_bbs: Dictionary = _resultado_actual.get("recurso", {})
		if String(recurso_bbs.get("tipo", "")) == "bbs":
			_resultado_actual["bbs_hilo_id"] = hilo_bbs
	if is_node_ready():
		_renderizar(_resultado_actual)
		_refrescar_laterales()


func _recorte_atlas(atlas: Texture2D, region: Rect2) -> AtlasTexture:
	var textura := AtlasTexture.new()
	textura.atlas = atlas
	textura.region = region
	textura.filter_clip = true
	return textura


func _ocultar_visuales_web() -> void:
	if _cabecera_sitio != null:
		_cabecera_sitio.visible = false
	if _navegacion_sitio != null:
		_navegacion_sitio.visible = false
	if _cabecera_prensa != null:
		_cabecera_prensa.visible = false
	if _modulo_sitio != null:
		_modulo_sitio.visible = false
	if _badge_web != null:
		_badge_web.visible = false
	if _decoracion_web != null:
		_decoracion_web.visible = false


func _region_badge(recurso: Dictionary, via: String) -> Rect2:
	if via == "mirror":
		return Rect2(0, 31, 88, 31)
	match String(recurso.get("categoria", "")):
		"institucional":
			return Rect2(88, 31, 88, 31)
		"archivo":
			return Rect2(176, 31, 88, 31)
		"personal":
			return Rect2(176, 0, 88, 31)
	return Rect2(264, 31, 88, 31)


func _preparar_visuales_recurso(recurso: Dictionary, via: String) -> void:
	_decoracion_web.texture = _recorte_atlas(
		TEXTURA_WEB_DECORACION,
		Rect2(0, 0, 468, 28),
	)
	_decoracion_web.visible = true
	_badge_web.texture = _recorte_atlas(TEXTURA_WEB_BADGES, _region_badge(recurso, via))
	_badge_web.visible = true

	var recurso_id := String(recurso.get("id", ""))
	var visual: Variant = SITIOS_WEB_VISUALES.get(recurso_id, null)
	if visual is Dictionary:
		var fila := int((visual as Dictionary).get("fila", 0))
		var modulo := int((visual as Dictionary).get("modulo", 0))
		_cabecera_sitio.texture = _recorte_atlas(
			TEXTURA_WEB_CABECERAS,
			Rect2(0, fila * 72, 468, 72),
		)
		_navegacion_sitio.texture = _recorte_atlas(
			TEXTURA_WEB_NAVEGACION,
			Rect2(0, fila * 24, 468, 24),
		)
		_modulo_sitio.texture = _recorte_atlas(
			TEXTURA_WEB_MODULOS,
			Rect2((modulo % 2) * 220, floori(float(modulo) / 2.0) * 100, 220, 100),
		)
		_cabecera_sitio.visible = true
		_navegacion_sitio.visible = true
		_modulo_sitio.visible = true
	elif String(recurso.get("categoria", "")) == "personal":
		_modulo_sitio.texture = _recorte_atlas(
			TEXTURA_WEB_MODULOS,
			Rect2(
				(MODULO_WEB_PERSONAL % 2) * 220,
				floori(float(MODULO_WEB_PERSONAL) / 2.0) * 100,
				220,
				100,
			),
		)
		_modulo_sitio.visible = true


func _mostrar_decoracion_busqueda() -> void:
	_decoracion_web.texture = _recorte_atlas(
		TEXTURA_WEB_DECORACION,
		Rect2(0, 0, 468, 28),
	)
	_decoracion_web.visible = true
	_badge_web.texture = _recorte_atlas(TEXTURA_WEB_BADGES, Rect2(0, 0, 88, 31))
	_badge_web.visible = true


func _renderizar(resultado: Dictionary) -> void:
	var url := url_actual()
	_direccion.text = url
	_atras.disabled = _indice_historial <= 0
	_adelante.disabled = _indice_historial < 0 or _indice_historial + 1 >= _historial.size()
	_favorito.text = (
		tr("NAVEGADOR_QUITAR_FAVORITO") if _favoritos.has(url) else tr("NAVEGADOR_FAVORITO")
	)
	_enlaces.clear()
	_cache.visible = false
	_descargar_software.visible = false
	_paquete_software_actual = ""
	_ocultar_visuales_web()

	var estado := String(resultado.get("estado", "no_encontrado"))
	if estado == "ok":
		var recurso: Dictionary = resultado.get("recurso", {})
		_preparar_visuales_recurso(recurso, String(resultado.get("via", "origen")))
		var tipo_recurso := String(recurso.get("tipo", ""))
		if tipo_recurso == "prensa":
			_renderizar_prensa(recurso)
		elif tipo_recurso == "bbs":
			_renderizar_bbs(resultado, recurso, url)
		else:
			_renderizar_recurso_generico(resultado, recurso, url)
		_configurar_descarga_software(recurso)
		if tipo_recurso != "bbs":
			_renderizar_enlaces(recurso)
		return
	if estado == "caido":
		_pagina.text = tr("NAVEGADOR_SERVIDOR_CAIDO") % url
		_cache.visible = bool(resultado.get("cache_disponible", false))
		return
	_pagina.text = tr("NAVEGADOR_NO_ENCONTRADO") % url


func _renderizar_recurso_generico(resultado: Dictionary, recurso: Dictionary, url: String) -> void:
	var titulo := String(recurso.get("titulo", tr("NAVEGADOR_SIN_TITULO")))
	var snippet := String(recurso.get("snippet", ""))
	var via := String(resultado.get("via", "origen"))
	_pagina.text = (
		tr("NAVEGADOR_PAGINA_OK")
		% [
			titulo,
			url,
			snippet,
			String(recurso.get("categoria", "")),
			via,
		]
	)


func _renderizar_bbs(resultado: Dictionary, recurso: Dictionary, url: String) -> void:
	var tablon_id := String(recurso.get("tablon_id", recurso.get("id", "")))
	var hilos := _bbs.hilos_de(tablon_id)
	var hilo_id := String(resultado.get("bbs_hilo_id", ""))
	_renderizar_enlaces(recurso)

	if hilo_id.is_empty():
		var bloques: Array[String] = []
		bloques.append("[b]%s[/b]" % String(recurso.get("titulo", tr("NAVEGADOR_SIN_TITULO"))))
		bloques.append(String(recurso.get("snippet", "")))
		bloques.append("Estado: %s" % _estado_tablon_bbs(tablon_id))
		bloques.append("Hilos disponibles: %d" % hilos.size())
		_pagina.text = "\n\n".join(bloques)
		for hilo in hilos:
			var indice_item := (
				_enlaces
				. add_item(
					(
						"[%s] %s · %s"
						% [
							String(hilo.get("estado", "abierto")),
							String(hilo.get("titulo", "")),
							String(hilo.get("fecha_ultimo", "")),
						]
					)
				)
			)
			(
				_enlaces
				. set_item_metadata(
					indice_item,
					"%s#hilo=%s" % [String(recurso.get("url", url)), String(hilo.get("id", ""))],
				)
			)
		return

	var hilo_actual: Dictionary = {}
	for hilo in hilos:
		if String(hilo.get("id", "")) == hilo_id:
			hilo_actual = hilo
			break
	if hilo_actual.is_empty():
		_pagina.text = "[b]Hilo no disponible[/b]\n\nEl hilo no existe o todavía no es visible."
		return

	var volver := _enlaces.add_item("← Volver al tablón")
	_enlaces.set_item_metadata(volver, String(recurso.get("url", url)))
	var bloques_hilo: Array[String] = []
	bloques_hilo.append("[b]%s[/b]" % String(hilo_actual.get("titulo", "")))
	(
		bloques_hilo
		. append(
			(
				"Estado: %s · última actividad: %s"
				% [
					String(hilo_actual.get("estado", "")),
					String(hilo_actual.get("fecha_ultimo", "")),
				]
			)
		)
	)
	for mensaje in _bbs.mensajes_de(hilo_id):
		var autor: Dictionary = mensaje.get("autor", {})
		var nick := String(autor.get("nick", mensaje.get("autor_id", "?")))
		var tipo := String(mensaje.get("tipo", "normal"))
		var estado := String(mensaje.get("estado", "visible"))
		bloques_hilo.append(
			"[b]%s[/b] · %s · %s/%s" % [nick, String(mensaje.get("fecha", "")), tipo, estado]
		)
		var referencia := _bbs.referencia_de_mensaje(String(mensaje.get("id", "")))
		if not referencia.is_empty():
			if String(referencia.get("estado", "")) in ["eliminado", "no_disponible"]:
				bloques_hilo.append("> [mensaje citado no disponible]")
			else:
				var autor_citado: Dictionary = referencia.get("autor", {})
				(
					bloques_hilo
					. append(
						(
							"> %s: %s"
							% [
								String(autor_citado.get("nick", referencia.get("autor_id", "?"))),
								String(referencia.get("texto", "")),
							]
						)
					)
				)
		var texto := String(mensaje.get("texto", ""))
		if texto.is_empty() and estado == "eliminado":
			texto = "[mensaje eliminado]"
		bloques_hilo.append(texto)
		var firma := String(autor.get("firma", "")).strip_edges()
		if not firma.is_empty() and tipo == "normal":
			bloques_hilo.append("-- %s" % firma)
	_pagina.text = "\n\n".join(bloques_hilo)


func _estado_tablon_bbs(tablon_id: String) -> String:
	for tablon in _bbs.tablones_visibles():
		if String(tablon.get("id", "")) == tablon_id:
			return String(tablon.get("estado", ""))
	return ""


func _configurar_descarga_software(recurso: Dictionary) -> void:
	var paquete_id := String(recurso.get("paquete_software", "")).strip_edges()
	if paquete_id.is_empty():
		return
	var paquete := SoftwareSigaModelo.new().ficha(paquete_id)
	if paquete.is_empty():
		return
	_paquete_software_actual = paquete_id
	_descargar_software.text = (
		tr("NAVEGADOR_DESCARGAR_SOFTWARE") % String(paquete.get("nombre", paquete_id))
	)
	_descargar_software.visible = true


func _obtener_software_actual() -> void:
	if _paquete_software_actual.is_empty():
		return
	paquete_software_obtenido.emit(_paquete_software_actual)


func _renderizar_prensa(recurso: Dictionary) -> void:
	var cabecera_id := String(recurso.get("cabecera_id", ""))
	var portada := _prensa.portada(cabecera_id)
	if String(portada.get("estado", "")) != "ok":
		_pagina.text = tr("NAVEGADOR_PRENSA_SIN_ARTICULOS")
		return
	var cabecera: Dictionary = portada.get("cabecera", {})
	var fila := clampi(int(cabecera.get("fila_cabecera", 0)), 0, 3)
	var atlas := AtlasTexture.new()
	atlas.atlas = TEXTURA_CABECERAS_PRENSA
	atlas.region = Rect2(0, fila * 60, 468, 60)
	_cabecera_prensa.texture = atlas
	_cabecera_prensa.visible = true
	_pagina.text = _texto_portada_prensa(portada)
	_registrar_exposicion_prensa(cabecera_id)


func _registrar_exposicion_prensa(cabecera_id: String) -> void:
	var estado := _estado_partida_actual()
	if estado.is_empty():
		return
	_prensa.registrar_exposicion_portada(estado, cabecera_id)


func _texto_portada_prensa(portada: Dictionary) -> String:
	var bloques: Array[String] = []
	bloques.append(tr("NAVEGADOR_PRENSA_EDICION") % int(portada.get("jornada", 1)))
	var articulos: Variant = portada.get("articulos", [])
	if not articulos is Array or (articulos as Array).is_empty():
		bloques.append(tr("NAVEGADOR_PRENSA_SIN_ARTICULOS"))
		return "\n\n".join(bloques)
	for articulo_valor in articulos as Array:
		if not articulo_valor is Dictionary:
			continue
		var articulo := articulo_valor as Dictionary
		var tratamiento: Dictionary = articulo.get("tratamiento", {})
		bloques.append("[b]%s[/b]" % String(tratamiento.get("titular", "")))
		bloques.append(String(tratamiento.get("entradilla", "")))
		var datos: Variant = articulo.get("datos_destacados", [])
		if datos is Array:
			for dato_valor in datos as Array:
				if dato_valor is Dictionary:
					var dato := dato_valor as Dictionary
					bloques.append(
						(
							tr("NAVEGADOR_PRENSA_DATO")
							% [String(dato.get("etiqueta", "")), String(dato.get("valor", ""))]
						)
					)
		var opinion := String(tratamiento.get("opinion", "")).strip_edges()
		if not opinion.is_empty():
			bloques.append(tr("NAVEGADOR_PRENSA_OPINION") % opinion)
	return "\n\n".join(bloques)


func _renderizar_enlaces(recurso: Dictionary) -> void:
	for destino in _indice.enlaces_desde(String(recurso.get("id", ""))):
		var indice_item := _enlaces.add_item(String(destino.get("titulo", tr("NAVEGADOR_ENLACE"))))
		_enlaces.set_item_metadata(indice_item, String(destino.get("url", "")))


func _mostrar_busqueda(consulta: String) -> void:
	var resultados := buscar(consulta)
	_ocultar_visuales_web()
	_mostrar_decoracion_busqueda()
	if resultados.size() == 1:
		_pagina.text = tr("NAVEGADOR_RESULTADO_UNO") % consulta
	else:
		_pagina.text = tr("NAVEGADOR_RESULTADOS") % [consulta, resultados.size()]
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
	_ocultar_visuales_web()
	_decoracion_web.texture = _recorte_atlas(TEXTURA_WEB_DECORACION, Rect2(0, 0, 468, 28))
	_decoracion_web.visible = true
	_badge_web.texture = _recorte_atlas(TEXTURA_WEB_BADGES, Rect2(176, 31, 88, 31))
	_badge_web.visible = true
	_pagina.text = (
		tr("NAVEGADOR_CACHE_PAGINA")
		% [
			String(datos.get("titulo", tr("NAVEGADOR_CACHE_TITULO"))),
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


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	if tecla.ctrl_pressed and tecla.keycode == KEY_L and is_instance_valid(_direccion):
		_direccion.grab_focus()
		_direccion.select_all()
		get_viewport().set_input_as_handled()
		return
	if tecla.ctrl_pressed and tecla.keycode == KEY_F and is_instance_valid(_busqueda):
		_busqueda.grab_focus()
		_busqueda.select_all()
		get_viewport().set_input_as_handled()
		return
	if tecla.alt_pressed and tecla.keycode == KEY_LEFT:
		ir_atras()
		get_viewport().set_input_as_handled()
		return
	if tecla.alt_pressed and tecla.keycode == KEY_RIGHT:
		ir_adelante()
		get_viewport().set_input_as_handled()
		return
	if tecla.keycode == KEY_F5:
		recargar()
		get_viewport().set_input_as_handled()


func _aplicar_escala_texto() -> void:
	if _pagina == null:
		return
	var cuerpo := roundi(16.0 * _escala_texto)
	var lista := roundi(14.0 * _escala_texto)
	_pagina.add_theme_font_size_override("normal_font_size", cuerpo)
	_pagina.add_theme_font_size_override("bold_font_size", cuerpo)
	_pagina.add_theme_font_size_override("italics_font_size", cuerpo)
	_pagina.add_theme_font_size_override("bold_italics_font_size", cuerpo)
	_pagina.add_theme_font_size_override("mono_font_size", cuerpo)
	_enlaces.add_theme_font_size_override("font_size", lista)
	_historial_lista.add_theme_font_size_override("font_size", lista)
	_favoritos_lista.add_theme_font_size_override("font_size", lista)
	_direccion.add_theme_font_size_override("font_size", lista)
	_busqueda.add_theme_font_size_override("font_size", lista)
	if _descargar_software != null:
		_descargar_software.add_theme_font_size_override("font_size", lista)


func _estado_partida_actual() -> Dictionary:
	if not is_inside_tree():
		return {}
	var escena := get_tree().current_scene
	if escena == null:
		return {}
	var partida_actual: Variant = escena.get("partida")
	if partida_actual is Partida:
		return (partida_actual as Partida).estado
	return {}


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
