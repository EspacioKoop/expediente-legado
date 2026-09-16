## Catálogo de anomalías como aplicación de consulta del escritorio OS98 (#149).
##
## Esta capa solo presenta la memoria que ya mantiene CatalogoAnomalias. Las
## entradas desconocidas se muestran bloqueadas sin filtrar origen, id interno,
## representación ni condición de descubrimiento.
class_name CatalogoAnomaliasSiga
extends HSplitContainer

const RUTA_TEXTOS := "res://datos/catalogo_anomalias_textos.json"

var _estado: Dictionary = {}
var _firma_estado := ""
var _textos: Dictionary = {}

var _lista: ItemList
var _progreso: Label
var _titulo: Label
var _origen: Label
var _descripcion: RichTextLabel
var _representacion: Label


static func texto(clave: String) -> String:
	return String(_cargar_textos().get(clave, clave))


static func _cargar_textos() -> Dictionary:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
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
	var izquierda := VBoxContainer.new()
	izquierda.name = "Indice"
	izquierda.custom_minimum_size = Vector2(235, 0)
	izquierda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(izquierda)

	var cabecera := Label.new()
	cabecera.name = "TituloIndice"
	cabecera.text = _t("titulo_indice")
	izquierda.add_child(cabecera)

	_progreso = Label.new()
	_progreso.name = "Progreso"
	_progreso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izquierda.add_child(_progreso)

	_lista = ItemList.new()
	_lista.name = "Entradas"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.select_mode = ItemList.SELECT_SINGLE
	_lista.item_selected.connect(_seleccionar)
	izquierda.add_child(_lista)

	var leyenda := Label.new()
	leyenda.name = "Leyenda"
	leyenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leyenda.text = _t("leyenda")
	izquierda.add_child(leyenda)

	var derecha := VBoxContainer.new()
	derecha.name = "Ficha"
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(derecha)

	_titulo = Label.new()
	_titulo.name = "TituloFicha"
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(_titulo)

	_origen = Label.new()
	_origen.name = "Origen"
	_origen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(_origen)

	_descripcion = RichTextLabel.new()
	_descripcion.name = "Descripcion"
	_descripcion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_descripcion.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_descripcion.fit_content = false
	_descripcion.selection_enabled = true
	derecha.add_child(_descripcion)

	_representacion = Label.new()
	_representacion.name = "Representacion"
	_representacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(_representacion)


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
	_titulo.text = String(entrada.get("titulo", _t("titulo_fallback")))
	_origen.text = _t("origen_material") % String(entrada.get("origen_tipo", _t("origen_fallback")))
	_descripcion.text = String(entrada.get("descripcion", _t("descripcion_fallback")))
	_representacion.text = (
		_t("representacion_archivada")
		% String(entrada.get("nota_visual", _t("representacion_fallback")))
	)


func _mostrar_bloqueada() -> void:
	_titulo.text = _t("titulo_bloqueada")
	_origen.text = _t("origen_vacio")
	_descripcion.text = _t("descripcion_bloqueada")
	_representacion.text = _t("representacion_vacia")


func _mostrar_vuelta_completa() -> void:
	_titulo.text = _t("titulo_vuelta_completa")
	_origen.text = _t("origen_vuelta_completa")
	_descripcion.text = _t("descripcion_vuelta_completa")
	_representacion.text = _t("representacion_vuelta_completa")


func _mostrar_espera() -> void:
	_titulo.text = _t("titulo_espera")
	_origen.text = ""
	_descripcion.text = _t("descripcion_espera")
	_representacion.text = ""


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
