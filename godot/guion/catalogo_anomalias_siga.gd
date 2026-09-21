## Catálogo de anomalías como aplicación de consulta del escritorio OS98 (#149).
##
## Esta capa solo presenta la memoria que ya mantiene CatalogoAnomalias. Las
## entradas desconocidas se muestran bloqueadas sin filtrar origen, id interno,
## representación ni condición de descubrimiento.
class_name CatalogoAnomaliasSiga
extends HSplitContainer

const RUTA_TEXTOS := "res://datos/catalogo_anomalias_textos.json"
const RUTA_VISUALES := "res://datos/catalogo_anomalias_visuales.json"

# Identidad local del Catálogo (#791): conserva el marco OS98 común, pero la
# superficie interior deja de ser otra ventana gris de SIGA. Índice oscuro de
# archivo + ficha marfil; sin cambiar datos, desbloqueos ni navegación.
const COLOR_INDICE := Color("1f2b2d")
const COLOR_INDICE_BORDE := Color("526b63")
const COLOR_INDICE_TEXTO := Color("edf3e8")
const COLOR_ACENTO := Color("87b493")
const COLOR_SELECCION := Color("34594d")
const COLOR_FICHA := Color("e7eadf")
const COLOR_PAPEL := Color("f7f6ed")
const COLOR_TINTA := Color("1a2522")
const COLOR_TINTA_SUAVE := Color("52615b")

var _estado: Dictionary = {}
var _firma_estado := ""
var _textos: Dictionary = {}
var _visuales: Dictionary = {}
var _texturas_visuales: Dictionary = {}

var _lista: ItemList
var _progreso: Label
var _titulo: Label
var _origen: Label
var _variantes: Label
var _recompensa_visual: TextureRect
var _descripcion: RichTextLabel
var _representacion: Label


static func texto(clave: String) -> String:
	return String(_cargar_textos().get(clave, clave))


static func _cargar_textos() -> Dictionary:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	if datos is Dictionary:
		return (datos as Dictionary).duplicate(true)
	return {}


static func _cargar_visuales() -> Dictionary:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_VISUALES))
	if datos is Dictionary:
		return (datos as Dictionary).duplicate(true)
	return {}


func configurar_estado(estado: Dictionary) -> void:
	_estado = estado
	_firma_estado = ""
	if is_node_ready():
		_refrescar()


func _ready() -> void:
	_textos = _cargar_textos()
	_visuales = _cargar_visuales()
	custom_minimum_size = Vector2(560, 360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_offset = 255
	_construir_interfaz()
	_refrescar()


func _process(_delta: float) -> void:
	if _firma_actual() != _firma_estado:
		_refrescar()


func _t(clave: String) -> String:
	return String(_textos.get(clave, clave))


func _construir_interfaz() -> void:
	var panel_indice := PanelContainer.new()
	panel_indice.name = "PanelIndice"
	panel_indice.custom_minimum_size = Vector2(235, 0)
	panel_indice.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_indice.add_theme_stylebox_override(
		"panel", _caja_catalogo(COLOR_INDICE, COLOR_INDICE_BORDE, 10.0)
	)
	add_child(panel_indice)

	var izquierda := VBoxContainer.new()
	izquierda.name = "Indice"
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izquierda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	izquierda.add_theme_constant_override("separation", 8)
	panel_indice.add_child(izquierda)

	var cabecera := Label.new()
	cabecera.name = "TituloIndice"
	cabecera.text = _t("titulo_indice")
	cabecera.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	cabecera.add_theme_font_size_override("font_size", 17)
	cabecera.add_theme_color_override("font_color", COLOR_INDICE_TEXTO)
	izquierda.add_child(cabecera)

	_progreso = Label.new()
	_progreso.name = "Progreso"
	_progreso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_progreso.add_theme_font_override("font", EstiloSiga.fuente_mono())
	_progreso.add_theme_color_override("font_color", COLOR_ACENTO)
	izquierda.add_child(_progreso)

	_lista = ItemList.new()
	_lista.name = "Entradas"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.select_mode = ItemList.SELECT_SINGLE
	_lista.add_theme_font_override("font", EstiloSiga.fuente_mono())
	_lista.add_theme_color_override("font_color", COLOR_INDICE_TEXTO)
	_lista.add_theme_color_override("font_hovered_color", COLOR_INDICE_TEXTO)
	_lista.add_theme_color_override("font_selected_color", Color.WHITE)
	_lista.add_theme_stylebox_override(
		"panel", _caja_catalogo(Color("172123"), COLOR_INDICE_BORDE, 4.0)
	)
	var seleccion := _caja_catalogo(COLOR_SELECCION, COLOR_ACENTO, 4.0)
	for estado in ["selected", "selected_focus", "hovered_selected", "hovered_selected_focus"]:
		_lista.add_theme_stylebox_override(estado, seleccion)
	_lista.item_selected.connect(_seleccionar)
	izquierda.add_child(_lista)

	var leyenda := Label.new()
	leyenda.name = "Leyenda"
	leyenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leyenda.text = _t("leyenda")
	leyenda.add_theme_font_override("font", EstiloSiga.fuente_mono())
	leyenda.add_theme_font_size_override("font_size", 12)
	leyenda.add_theme_color_override("font_color", COLOR_ACENTO)
	izquierda.add_child(leyenda)

	var panel_ficha := PanelContainer.new()
	panel_ficha.name = "PanelFicha"
	panel_ficha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_ficha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_ficha.add_theme_stylebox_override(
		"panel", _caja_catalogo(COLOR_FICHA, COLOR_INDICE_BORDE, 12.0)
	)
	add_child(panel_ficha)

	var derecha := VBoxContainer.new()
	derecha.name = "Ficha"
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	derecha.add_theme_constant_override("separation", 7)
	panel_ficha.add_child(derecha)

	var marca := Label.new()
	marca.name = "MarcaCatalogo"
	marca.text = _t("titulo_app")
	marca.add_theme_font_override("font", EstiloSiga.fuente_mono())
	marca.add_theme_font_size_override("font_size", 11)
	marca.add_theme_color_override("font_color", COLOR_TINTA_SUAVE)
	derecha.add_child(marca)

	_titulo = Label.new()
	_titulo.name = "TituloFicha"
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_titulo.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	_titulo.add_theme_font_size_override("font_size", 20)
	_titulo.add_theme_color_override("font_color", COLOR_TINTA)
	derecha.add_child(_titulo)

	_origen = Label.new()
	_origen.name = "Origen"
	_origen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_origen.add_theme_font_override("font", EstiloSiga.fuente_mono())
	_origen.add_theme_color_override("font_color", COLOR_TINTA_SUAVE)
	derecha.add_child(_origen)

	_variantes = Label.new()
	_variantes.name = "Variantes"
	_variantes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_variantes.add_theme_font_override("font", EstiloSiga.fuente_mono())
	_variantes.add_theme_color_override("font_color", COLOR_TINTA_SUAVE)
	derecha.add_child(_variantes)

	_recompensa_visual = TextureRect.new()
	_recompensa_visual.name = "RecompensaVisual"
	_recompensa_visual.custom_minimum_size = Vector2(0, 144)
	_recompensa_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recompensa_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_recompensa_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_recompensa_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recompensa_visual.visible = false
	derecha.add_child(_recompensa_visual)

	_descripcion = RichTextLabel.new()
	_descripcion.name = "Descripcion"
	_descripcion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_descripcion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_descripcion.fit_content = false
	_descripcion.selection_enabled = true
	_descripcion.add_theme_font_override("normal_font", EstiloSiga.fuente_documento())
	_descripcion.add_theme_color_override("default_color", COLOR_TINTA)
	_descripcion.add_theme_stylebox_override(
		"normal", _caja_catalogo(COLOR_PAPEL, Color("a6ad9d"), 10.0)
	)
	derecha.add_child(_descripcion)

	_representacion = Label.new()
	_representacion.name = "Representacion"
	_representacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_representacion.add_theme_font_override("font", EstiloSiga.fuente_mono())
	_representacion.add_theme_color_override("font_color", COLOR_TINTA_SUAVE)
	derecha.add_child(_representacion)


func _caja_catalogo(fondo: Color, borde: Color, margen: float) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(0)
	caja.content_margin_left = margen
	caja.content_margin_top = margen
	caja.content_margin_right = margen
	caja.content_margin_bottom = margen
	return caja


func _refrescar() -> void:
	if _lista == null:
		return
	var seleccionado := _id_seleccionado()
	var progreso := CatalogoAnomalias.progreso(_estado)
	var total := int(progreso.get("catalogo", 0))
	_progreso.text = (
		_t("progreso")
		% [
			int(progreso.get("descubiertas_total", 0)),
			total,
			int(progreso.get("descubiertas_vuelta", 0)),
			total,
		]
	)

	_lista.clear()
	for entrada in CatalogoAnomalias.catalogo():
		var id := String(entrada.get("id", ""))
		if CatalogoAnomalias.conocida(_estado, id):
			var en_vuelta := CatalogoAnomalias.conocida_en_vuelta(_estado, id)
			var marca := "●" if en_vuelta else "◈"
			var indice := _lista.add_item("%s %s" % [marca, String(entrada.get("titulo", id))])
			_lista.set_item_metadata(indice, {"tipo": "anomalia", "id": id})
			if id == seleccionado:
				_lista.select(indice)
		else:
			var indice := _lista.add_item(_t("entrada_bloqueada"))
			_lista.set_item_metadata(indice, {"tipo": "bloqueada"})

	if bool(progreso.get("vuelta_completa", false)):
		var especial := _lista.add_item(_t("entrada_vuelta_completa"))
		_lista.set_item_metadata(especial, {"tipo": "vuelta-completa"})
		if seleccionado == "@vuelta-completa":
			_lista.select(especial)

	_firma_estado = _firma_actual()
	var seleccion := _lista.get_selected_items()
	if seleccion.is_empty():
		_mostrar_espera()
	else:
		_seleccionar(seleccion[0])


func _seleccionar(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var metadata: Variant = _lista.get_item_metadata(indice)
	if not metadata is Dictionary:
		_mostrar_espera()
		return
	var tipo := String((metadata as Dictionary).get("tipo", ""))
	if tipo == "bloqueada":
		_mostrar_bloqueada()
		return
	if tipo == "vuelta-completa":
		_mostrar_vuelta_completa()
		return
	var id := String((metadata as Dictionary).get("id", ""))
	var entrada := CatalogoAnomalias.ficha(id)
	if entrada.is_empty() or not CatalogoAnomalias.conocida(_estado, id):
		_mostrar_bloqueada()
		return
	_mostrar_ficha(entrada)


func _mostrar_ficha(entrada: Dictionary) -> void:
	var id := String(entrada.get("id", ""))
	var variantes := CatalogoAnomalias.variantes(_estado, id)
	_titulo.text = String(entrada.get("titulo", _t("titulo_fallback")))
	_origen.text = _t("origen_material") % String(entrada.get("origen_tipo", _t("origen_fallback")))
	_variantes.text = _t("variantes_documentales") % variantes.size()
	if variantes.is_empty():
		_variantes.text += "\n" + _t("variantes_ninguna")
	else:
		_variantes.text += "\n" + (_t("variantes_folios") % ", ".join(variantes))
	_mostrar_recompensa(id)
	_descripcion.text = String(entrada.get("descripcion", _t("descripcion_fallback")))
	_representacion.text = (
		_t("representacion_archivada")
		% String(entrada.get("nota_visual", _t("representacion_fallback")))
	)


func _mostrar_bloqueada() -> void:
	_titulo.text = _t("titulo_bloqueada")
	_origen.text = _t("origen_vacio")
	_variantes.text = ""
	_ocultar_recompensa()
	_descripcion.text = _t("descripcion_bloqueada")
	_representacion.text = _t("representacion_vacia")


func _mostrar_vuelta_completa() -> void:
	_titulo.text = _t("titulo_vuelta_completa")
	_origen.text = _t("origen_vuelta_completa")
	_variantes.text = ""
	_mostrar_recompensa("@vuelta-completa")
	_descripcion.text = _t("descripcion_vuelta_completa")
	_representacion.text = _t("representacion_vuelta_completa")


func _mostrar_espera() -> void:
	_titulo.text = _t("titulo_espera")
	_origen.text = ""
	_variantes.text = ""
	_ocultar_recompensa()
	_descripcion.text = _t("descripcion_espera")
	_representacion.text = ""


func _mostrar_recompensa(clave: String) -> void:
	if _recompensa_visual == null:
		return
	var ficha: Variant = _visuales.get(clave, {})
	if not ficha is Dictionary:
		_ocultar_recompensa()
		return
	var ruta := String((ficha as Dictionary).get("ruta", ""))
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		_ocultar_recompensa()
		return
	if not _texturas_visuales.has(ruta):
		_texturas_visuales[ruta] = load(ruta)
	_recompensa_visual.texture = _texturas_visuales[ruta] as Texture2D
	_recompensa_visual.visible = _recompensa_visual.texture != null


func _ocultar_recompensa() -> void:
	if _recompensa_visual == null:
		return
	_recompensa_visual.texture = null
	_recompensa_visual.visible = false


func _id_seleccionado() -> String:
	if _lista == null:
		return ""
	var seleccion := _lista.get_selected_items()
	if seleccion.is_empty():
		return ""
	var metadata: Variant = _lista.get_item_metadata(seleccion[0])
	if not metadata is Dictionary:
		return ""
	var tipo := String((metadata as Dictionary).get("tipo", ""))
	if tipo == "vuelta-completa":
		return "@vuelta-completa"
	if tipo == "anomalia":
		return String((metadata as Dictionary).get("id", ""))
	return ""


func _firma_actual() -> String:
	return (
		"%s|%s"
		% [
			JSON.stringify(_estado.get(CatalogoAnomalias.CLAVE_TOTAL, [])),
			JSON.stringify(_estado.get(CatalogoAnomalias.CLAVE_VUELTA, [])),
		]
	)
