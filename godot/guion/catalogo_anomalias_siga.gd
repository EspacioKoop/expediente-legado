## Catálogo de anomalías como aplicación de consulta del escritorio OS98 (#149).
##
## Esta capa solo presenta la memoria que ya mantiene CatalogoAnomalias. Las
## entradas desconocidas se muestran bloqueadas sin filtrar origen, id interno,
## representación ni condición de descubrimiento.
class_name CatalogoAnomaliasSiga
extends HSplitContainer

var _estado: Dictionary = {}
var _firma_estado := ""

var _lista: ItemList
var _progreso: Label
var _titulo: Label
var _origen: Label
var _descripcion: RichTextLabel
var _representacion: Label


func configurar_estado(estado: Dictionary) -> void:
	_estado = estado
	_firma_estado = ""
	if is_node_ready():
		_refrescar()


func _ready() -> void:
	custom_minimum_size = Vector2(560, 360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_offset = 255
	_construir_interfaz()
	_refrescar()


func _process(_delta: float) -> void:
	if _firma_actual() != _firma_estado:
		_refrescar()


func _construir_interfaz() -> void:
	var izquierda := VBoxContainer.new()
	izquierda.name = "Indice"
	izquierda.custom_minimum_size = Vector2(235, 0)
	izquierda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(izquierda)

	var cabecera := Label.new()
	cabecera.name = "TituloIndice"
	cabecera.text = "CATÁLOGO DE ANOMALÍAS"
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
	leyenda.text = "● vista en esta vuelta   ◈ memoria anterior   □ sin registrar"
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
		"Memoria total: %d/%d\nVuelta actual: %d/%d"
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
			var indice := _lista.add_item("□ Entrada no registrada")
			_lista.set_item_metadata(indice, {"tipo": "bloqueada"})

	if bool(progreso.get("vuelta_completa", false)):
		var especial := _lista.add_item("★ Registro de vuelta completa")
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
	_titulo.text = String(entrada.get("titulo", "Anomalía registrada"))
	_origen.text = "Origen material: %s" % String(entrada.get("origen_tipo", "no clasificado"))
	_descripcion.text = String(entrada.get("descripcion", "Registro observacional sin comentario."))
	_representacion.text = "Representación archivada: %s" % String(
		entrada.get("nota_visual", "sin miniatura disponible")
	)


func _mostrar_bloqueada() -> void:
	_titulo.text = "Entrada no registrada"
	_origen.text = "Origen material: —"
	_descripcion.text = (
		"SIGA no dispone de una observación reconocida para esta entrada. "
		+ "El índice no revela dónde ni cómo encontrarla."
	)
	_representacion.text = "Representación archivada: —"


func _mostrar_vuelta_completa() -> void:
	_titulo.text = "Registro de vuelta completa"
	_origen.text = "Estado: observaciones de esta vida laboral completas"
	_descripcion.text = (
		"Todas las anomalías catalogables de esta vuelta fueron reconocidas. "
		+ "Este apéndice es únicamente documental."
	)
	_representacion.text = "Representación archivada: índice sellado por SIGA"


func _mostrar_espera() -> void:
	_titulo.text = "Seleccione una entrada"
	_origen.text = ""
	_descripcion.text = "El catálogo conserva observaciones reconocidas, no interpretaciones del sueño."
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
	return "%s|%s" % [
		JSON.stringify(_estado.get(CatalogoAnomalias.CLAVE_TOTAL, [])),
		JSON.stringify(_estado.get(CatalogoAnomalias.CLAVE_VUELTA, [])),
	]
