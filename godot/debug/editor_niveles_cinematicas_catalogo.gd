## Controles de catálogo exclusivos del editor de cinemáticas.
extends RefCounted

const CONTRATO := preload("res://debug/editor_niveles_cinematicas_contrato.gd")
const ESPACIOS_CATALOGO := preload("res://guion/espacios_catalogo.gd")
const MODELOS := preload("res://guion/modelos.gd")
const ASSETS := preload("res://debug/editor_niveles_cinematicas_assets.gd")

## Cuántos assets se vuelcan en el desplegable de una vez. El proyecto tiene
## cientos y un `OptionButton` con todos no se navega: el filtro es la
## herramienta y el scroll no. El conteo dice siempre cuántos hay detrás.
const MAXIMO_VISIBLE := 300

const ETIQUETA_TODAS := "(todas)"
const ETIQUETA_TODOS := "(todos)"


static func selector_escenario(texto: TextEdit, estado: Label) -> Dictionary:
	var fila := HBoxContainer.new()
	var selector := OptionButton.new()
	for fase in ESPACIOS_CATALOGO.POR_FASE.keys():
		selector.add_item(String(fase))
	fila.add_child(selector)
	var boton := Button.new()
	boton.text = "Cargar escenario"
	boton.pressed.connect(
		func():
			var fase := selector.get_item_text(selector.selected)
			var escenario := CONTRATO.escenario_catalogado_json(fase)
			if escenario.is_empty():
				estado.text = "El catálogo no contiene el escenario '%s'" % fase
				return
			texto.text = JSON.stringify(escenario, "  ")
			estado.text = "Escenario '%s' preparado; pulsa Aplicar para usarlo en el plano" % fase
	)
	fila.add_child(boton)
	return {"fila": fila, "selector": selector}


## La biblioteca de objetos del plano: TODO el contenido 3D del proyecto.
##
## Antes aquí había cinco nombres escritos a mano. Ahora se indexa el árbol de
## assets y se filtra por carpeta, tipo y texto, porque «todos los assets» solo
## es cierto si la lista la hace el disco y no una tabla que alguien tiene que
## recordar ampliar. Lo que se escribe en el documento es la ruta `res://…`, que
## el runtime resuelve igual que el editor.
static func biblioteca_decorado(texto: TextEdit, estado: Label) -> Dictionary:
	var al_agregar := func(ruta: String) -> void:
		var resultado := CONTRATO.agregar_asset_a_decorado(texto.text, ruta)
		if not String(resultado.get("error", "")).is_empty():
			estado.text = resultado["error"]
			return
		texto.text = JSON.stringify(resultado["decorado"], "  ")
		estado.text = (
			"Añadido '%s' al decorado; pulsa Aplicar para previsualizarlo" % ruta.get_file()
		)
	var al_agregar_personaje := func(ruta: String) -> void:
		var resultado := CONTRATO.agregar_personaje_a_decorado(texto.text, ruta)
		if not String(resultado.get("error", "")).is_empty():
			estado.text = resultado["error"]
			return
		texto.text = JSON.stringify(resultado["decorado"], "  ")
		estado.text = "Personaje añadido; edita pos/giro en el decorado y pulsa Aplicar"
	return _biblioteca("Añadir al decorado", al_agregar, al_agregar_personaje)


## Inserta el asset elegido, refresca el documento y deja su tamaño editable.
static func anadir_a_nivel(editor: Window, ruta: String) -> void:
	var selector: OptionButton = editor.get("_biblioteca_mueble")
	if ruta.is_empty():
		ruta = ruta_seleccionada(selector)
	if ruta.is_empty() or selector == null or selector.item_count == 0:
		return
	var contrato := CONTRATO
	var indice: int = contrato.agregar_mueble_a_nivel(editor.get("_doc_actual"), ruta)
	if indice < 0:
		editor.get("_estado").text = "No se pudo colocar '%s': no es una pieza 3D" % ruta
		return
	editor.set("_editando_indice", indice)
	editor.call("_refrescar_lista")
	editor.get("_lista").select(indice)
	editor.call("_refrescar_detalle")
	editor.call("_refrescar_diagnostico")
	editor.get("_estado").text = (
		"Asset '%s' añadido; ajusta su transformación y guarda" % ruta.get_file()
	)


static func biblioteca_nivel(al_agregar: Callable) -> Dictionary:
	return _biblioteca("Añadir al nivel", al_agregar)


static func _biblioteca(
	texto_boton: String, al_agregar: Callable, al_agregar_personaje: Callable = Callable()
) -> Dictionary:
	var columna := VBoxContainer.new()
	var filtros := HBoxContainer.new()
	var carpetas := OptionButton.new()
	carpetas.tooltip_text = "Carpeta del proyecto"
	var tipos := OptionButton.new()
	tipos.tooltip_text = "Tipo de asset"
	var buscador := LineEdit.new()
	buscador.placeholder_text = "Buscar asset…"
	buscador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filtros.add_child(carpetas)
	filtros.add_child(tipos)
	filtros.add_child(buscador)

	var fila := HBoxContainer.new()
	var selector := OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(selector)
	var boton := Button.new()
	boton.name = "BotonAnadirAsset"
	boton.text = texto_boton
	fila.add_child(boton)
	var copiar := Button.new()
	copiar.name = "BotonCopiarRutaAsset"
	copiar.text = "Copiar ruta"
	fila.add_child(copiar)
	var boton_personaje := Button.new()
	boton_personaje.name = "BotonAnadirPersonaje"
	boton_personaje.text = "Añadir personaje"
	boton_personaje.visible = false
	boton_personaje.disabled = not al_agregar_personaje.is_valid()
	fila.add_child(boton_personaje)
	var conteo := Label.new()
	conteo.name = "ConteoAssets"
	fila.add_child(conteo)
	var tipo_asset := Label.new()
	tipo_asset.name = "TipoAssetSeleccionado"
	var vista_previa := TextureRect.new()
	vista_previa.name = "VistaPreviaAsset"
	vista_previa.custom_minimum_size = Vector2(160, 90)
	vista_previa.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	vista_previa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var vista_fuente := Label.new()
	vista_fuente.name = "VistaPreviaFuente"
	vista_fuente.text = "Aa ÁÉ 0123 · Expediente SIGA-98"
	vista_fuente.add_theme_font_size_override("font_size", 24)
	vista_fuente.visible = false
	var audio := AudioStreamPlayer.new()
	var reproducir := Button.new()
	reproducir.name = "BotonReproducirAsset"
	reproducir.text = "▶ Reproducir audio"
	reproducir.visible = false

	columna.add_child(filtros)
	columna.add_child(fila)
	columna.add_child(tipo_asset)
	columna.add_child(vista_previa)
	columna.add_child(vista_fuente)
	columna.add_child(reproducir)
	columna.add_child(audio)

	var todos: Array = ASSETS.indice()
	_poblar_opciones(carpetas, ASSETS.carpetas(todos), ETIQUETA_TODAS)
	_poblar_opciones(tipos, ASSETS.tipos(todos), ETIQUETA_TODOS)

	var actualizar_previa := func(_indice: int = 0):
		var ruta := ruta_seleccionada(selector)
		var tipo := ASSETS.tipo_de(ruta)
		tipo_asset.text = "%s · %s" % [tipo, ruta]
		vista_previa.texture = null
		vista_previa.visible = tipo == "imagen"
		vista_fuente.visible = tipo == "fuente"
		reproducir.visible = tipo == "audio"
		boton_personaje.visible = (
			al_agregar_personaje.is_valid()
			and not CONTRATO.modelo_personaje_desde_ruta(ruta).is_empty()
		)
		audio.stop()
		if tipo == "imagen":
			var recurso: Resource = load(ruta)
			if recurso is Texture2D:
				vista_previa.texture = recurso
		elif tipo == "fuente":
			var recurso_fuente: Resource = load(ruta)
			if recurso_fuente is Font:
				vista_fuente.add_theme_font_override("font", recurso_fuente)
		elif tipo == "audio":
			var recurso_audio: Resource = load(ruta)
			if recurso_audio is AudioStream:
				audio.stream = recurso_audio

	var refrescar := func():
		var carpeta := _valor_opcion(carpetas, ETIQUETA_TODAS)
		var tipo := _valor_opcion(tipos, ETIQUETA_TODOS)
		var encontrados: Array = ASSETS.filtrar(carpeta, tipo, buscador.text, false)
		selector.clear()
		for indice in mini(encontrados.size(), MAXIMO_VISIBLE):
			var entrada: Dictionary = encontrados[indice]
			var ruta := String(entrada.get("ruta", ""))
			selector.add_item(ASSETS.etiqueta(entrada))
			selector.set_item_metadata(selector.item_count - 1, ruta)
			selector.set_item_tooltip(selector.item_count - 1, ruta)
		selector.disabled = selector.item_count == 0
		boton.disabled = selector.disabled
		copiar.disabled = selector.disabled
		if selector.item_count > 0:
			selector.select(0)
			actualizar_previa.call(0)
		else:
			tipo_asset.text = ""
			vista_previa.visible = false
			vista_fuente.visible = false
			reproducir.visible = false
			boton_personaje.visible = false
		if encontrados.is_empty():
			conteo.text = "sin resultados"
		elif encontrados.size() > MAXIMO_VISIBLE:
			conteo.text = "%d de %d (afina el filtro)" % [MAXIMO_VISIBLE, encontrados.size()]
		else:
			conteo.text = "%d assets" % encontrados.size()

	carpetas.item_selected.connect(func(_indice: int): refrescar.call())
	tipos.item_selected.connect(func(_indice: int): refrescar.call())
	buscador.text_changed.connect(func(_texto: String): refrescar.call())
	selector.item_selected.connect(actualizar_previa)
	reproducir.pressed.connect(func(): audio.play())
	copiar.pressed.connect(
		func():
			var ruta := ruta_seleccionada(selector)
			if not ruta.is_empty():
				DisplayServer.clipboard_set(ruta)
	)
	boton.pressed.connect(
		func():
			var ruta := ruta_seleccionada(selector)
			if ruta.is_empty():
				return
			al_agregar.call(ruta)
	)
	boton_personaje.pressed.connect(
		func():
			var ruta := ruta_seleccionada(selector)
			if ruta.is_empty() or not al_agregar_personaje.is_valid():
				return
			al_agregar_personaje.call(ruta)
	)
	refrescar.call()

	return {
		"fila": columna,
		"selector": selector,
		"boton": boton,
		"boton_personaje": boton_personaje,
		"copiar": copiar,
		"tipo_asset": tipo_asset,
		"vista_previa": vista_previa,
		"vista_fuente": vista_fuente,
		"reproducir": reproducir,
		"audio": audio,
		"buscador": buscador,
		"carpetas": carpetas,
		"tipos": tipos,
		"refrescar": refrescar,
	}


## La ruta del asset elegido. Va en los metadatos porque la etiqueta visible es
## corta a propósito: dos packs distintos traen una `chair.glb` cada uno.
static func ruta_seleccionada(selector: OptionButton) -> String:
	if selector == null or selector.item_count == 0 or selector.selected < 0:
		return ""
	var metadato: Variant = selector.get_item_metadata(selector.selected)
	if metadato is String and not String(metadato).is_empty():
		return String(metadato)
	return selector.get_item_text(selector.selected)


static func _poblar_opciones(
	selector: OptionButton, valores: PackedStringArray, comodin: String
) -> void:
	selector.clear()
	selector.add_item(comodin)
	for valor in valores:
		selector.add_item(valor)
	selector.select(0)


static func _valor_opcion(selector: OptionButton, comodin: String) -> String:
	if selector.selected <= 0:
		return ""
	var valor := selector.get_item_text(selector.selected)
	return "" if valor == comodin else valor
