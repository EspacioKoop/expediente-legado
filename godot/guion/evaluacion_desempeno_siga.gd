## Historial de evaluaciones de desempeño como aplicación de consulta (#150).
##
## Solo presenta sellos ya persistidos por EvaluacionDesempeno. No recalcula
## vidas cerradas, no guarda nada y no concede recompensas: la vista puede
## abrirse y cerrarse tantas veces como se quiera sin cambiar Partida.
class_name EvaluacionDesempenoSiga
extends HSplitContainer

const CATEGORIAS := [
	{"id": "productividad", "texto": "EVALUACION_CATEGORIA_PRODUCTIVIDAD"},
	{"id": "precipitacion", "texto": "EVALUACION_CATEGORIA_PRECIPITACION"},
	{"id": "cuidado_gato", "texto": "EVALUACION_CATEGORIA_GATO"},
	{"id": "liquidez", "texto": "EVALUACION_CATEGORIA_LIQUIDEZ"},
	{"id": "exploracion_onirica", "texto": "EVALUACION_CATEGORIA_SUENO"},
	{"id": "dependencia_dinero", "texto": "EVALUACION_CATEGORIA_DEPENDENCIA_DINERO"},
]

var _estado: Dictionary = {}
var _firma_estado := ""

var _lista: ItemList
var _vida: Label
var _motivo: Label
var _rangos: Dictionary = {}


func configurar_estado(estado: Dictionary) -> void:
	_estado = estado
	_firma_estado = ""
	if is_node_ready():
		_refrescar()


func _ready() -> void:
	custom_minimum_size = Vector2(560, 360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_offset = 300
	_construir_interfaz()
	_refrescar()


func _process(_delta: float) -> void:
	if _firma_actual() != _firma_estado:
		_refrescar()


func _construir_interfaz() -> void:
	var izquierda := VBoxContainer.new()
	izquierda.name = "IndiceEvaluaciones"
	izquierda.custom_minimum_size = Vector2(280, 0)
	izquierda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(izquierda)

	var cabecera := Label.new()
	cabecera.name = "CabeceraEvaluaciones"
	cabecera.text = tr("EVALUACION_CABECERA")
	izquierda.add_child(cabecera)

	var ayuda := Label.new()
	ayuda.name = "AyudaEvaluaciones"
	ayuda.text = tr("EVALUACION_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izquierda.add_child(ayuda)

	_lista = ItemList.new()
	_lista.name = "Vidas"
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.select_mode = ItemList.SELECT_SINGLE
	_lista.item_selected.connect(_seleccionar)
	izquierda.add_child(_lista)

	var derecha := VBoxContainer.new()
	derecha.name = "DetalleEvaluacion"
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	derecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(derecha)

	_vida = Label.new()
	_vida.name = "VidaSeleccionada"
	derecha.add_child(_vida)

	_motivo = Label.new()
	_motivo.name = "MotivoCierre"
	_motivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(_motivo)

	derecha.add_child(HSeparator.new())

	var rejilla := GridContainer.new()
	rejilla.name = "Categorias"
	rejilla.columns = 2
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rejilla.add_theme_constant_override("h_separation", 18)
	rejilla.add_theme_constant_override("v_separation", 8)
	derecha.add_child(rejilla)

	for categoria in CATEGORIAS:
		var id := String(categoria["id"])
		var etiqueta := Label.new()
		etiqueta.text = tr(String(categoria["texto"]))
		rejilla.add_child(etiqueta)

		var rango := Label.new()
		rango.name = "Rango_%s" % id
		rango.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rango.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(rango)
		_rangos[id] = rango

	var nota := Label.new()
	nota.name = "NotaComparacion"
	nota.text = tr("EVALUACION_NOTA_COMPARACION")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nota.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	derecha.add_child(nota)


func _refrescar() -> void:
	if _lista == null:
		return

	var vuelta_seleccionada := _vuelta_seleccionada()
	var historial := EvaluacionDesempeno.historial(_estado)
	_lista.clear()

	if historial.is_empty():
		_lista.add_item(tr("EVALUACION_VACIO"))
		_lista.set_item_disabled(0, true)
		_mostrar_vacio()
		_firma_estado = _firma_actual()
		return

	for indice_historial in range(historial.size() - 1, -1, -1):
		var registro: Dictionary = historial[indice_historial]
		var evaluacion: Dictionary = registro.get("evaluacion", {})
		var indice := (
			_lista
			. add_item(
				(
					tr("EVALUACION_FILA")
					% [
						int(registro.get("vuelta", 0)),
						_texto_rango(String(evaluacion.get("productividad", ""))),
						_texto_rango(String(evaluacion.get("precipitacion", ""))),
					]
				)
			)
		)
		_lista.set_item_metadata(indice, registro.duplicate(true))
		if int(registro.get("vuelta", 0)) == vuelta_seleccionada:
			_lista.select(indice)

	var seleccion := _lista.get_selected_items()
	if seleccion.is_empty():
		_lista.select(0)
		_seleccionar(0)
	else:
		_seleccionar(seleccion[0])
	_firma_estado = _firma_actual()


func _seleccionar(indice: int) -> void:
	if indice < 0 or indice >= _lista.item_count:
		return
	var metadata: Variant = _lista.get_item_metadata(indice)
	if not metadata is Dictionary:
		_mostrar_vacio()
		return
	var registro := metadata as Dictionary
	var evaluacion: Variant = registro.get("evaluacion", {})
	if not evaluacion is Dictionary:
		_mostrar_vacio()
		return

	_vida.text = tr("EVALUACION_VIDA") % int(registro.get("vuelta", 0))
	_motivo.text = (tr("EVALUACION_MOTIVO") % _texto_motivo(String(registro.get("motivo", "otro"))))
	for categoria in CATEGORIAS:
		var id := String(categoria["id"])
		var etiqueta: Label = _rangos[id]
		etiqueta.text = _texto_rango(String((evaluacion as Dictionary).get(id, "")))


func _mostrar_vacio() -> void:
	_vida.text = tr("EVALUACION_SIN_SELECCION")
	_motivo.text = tr("EVALUACION_VACIO_AYUDA")
	for id in _rangos:
		var etiqueta: Label = _rangos[id]
		etiqueta.text = "—"


func _vuelta_seleccionada() -> int:
	if _lista == null:
		return -1
	var seleccion := _lista.get_selected_items()
	if seleccion.is_empty():
		return -1
	var metadata: Variant = _lista.get_item_metadata(seleccion[0])
	if metadata is Dictionary:
		return int((metadata as Dictionary).get("vuelta", -1))
	return -1


func _texto_motivo(motivo: String) -> String:
	match motivo:
		"reasignacion":
			return tr("EVALUACION_MOTIVO_REASIGNACION")
		"final_narrativo":
			return tr("EVALUACION_MOTIVO_FINAL")
		_:
			return tr("EVALUACION_MOTIVO_OTRO")


func _texto_rango(rango: String) -> String:
	match rango:
		EvaluacionDesempeno.BAJA:
			return tr("EVALUACION_RANGO_BAJA")
		EvaluacionDesempeno.MEDIA:
			return tr("EVALUACION_RANGO_MEDIA")
		EvaluacionDesempeno.ALTA:
			return tr("EVALUACION_RANGO_ALTA")
		_:
			return tr("EVALUACION_RANGO_SIN_DATOS")


func _firma_actual() -> String:
	return JSON.stringify(_estado.get(EvaluacionDesempeno.CLAVE_HISTORIAL, []))
