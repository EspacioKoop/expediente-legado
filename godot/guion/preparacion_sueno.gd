## Preparación de la memoria nocturna (#162).
##
## UI deliberadamente fina: muestra solo folios leídos hoy y edita la selección
## persistente que valida SeleccionNocturna. Los botones estándar conservan
## teclado y mando mediante foco; ui_cancel añade la salida Esc/B.
class_name PreparacionSueno
extends Control

signal confirmada(seleccion: Array)
signal cancelada

var _leidos: Array = []
var _seleccion: Array = []
var _huecos: Array[Button] = []
var _documentos: Array[Button] = []
var _boton_confirmar: Button
var _boton_cancelar: Button
var _aviso: Label
var _sin_documentos: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construir()
	_refrescar()


func configurar(leidos: Array, actual: Array = []) -> void:
	_leidos = leidos.duplicate()
	_seleccion = SeleccionNocturna.normalizar(_leidos, actual)
	if is_node_ready():
		_refrescar()


func seleccion_actual() -> Array:
	return _seleccion.duplicate()


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.015, 0.02, 0.025, 0.94)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)

	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(720, 0)
	marco.theme = EstiloSiga.tema()
	centro.add_child(marco)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	marco.add_child(columna)

	var titulo := Label.new()
	titulo.text = tr("SUENO_PREPARAR_TITULO")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)

	var ayuda := Label.new()
	ayuda.text = tr("SUENO_PREPARAR_AYUDA")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(ayuda)

	var rotulo_huecos := Label.new()
	rotulo_huecos.text = tr("SUENO_PREPARAR_HUECOS")
	columna.add_child(rotulo_huecos)

	var fila_huecos := HBoxContainer.new()
	fila_huecos.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_huecos.add_theme_constant_override("separation", 8)
	columna.add_child(fila_huecos)
	for i in SeleccionNocturna.MAX_DOCUMENTOS:
		var hueco := Button.new()
		hueco.name = "Hueco%d" % (i + 1)
		hueco.custom_minimum_size = Vector2(200, 54)
		hueco.pressed.connect(_quitar_hueco.bind(i))
		fila_huecos.add_child(hueco)
		_huecos.append(hueco)

	var rotulo_documentos := Label.new()
	rotulo_documentos.text = tr("SUENO_PREPARAR_DOCUMENTOS")
	columna.add_child(rotulo_documentos)

	var lista := VBoxContainer.new()
	lista.name = "Documentos"
	lista.add_theme_constant_override("separation", 5)
	columna.add_child(lista)
	for i in _leidos.size():
		_agregar_boton_documento(lista, i, String(_leidos[i]))

	_sin_documentos = Label.new()
	_sin_documentos.text = tr("SUENO_PREPARAR_SIN_DOCUMENTOS")
	lista.add_child(_sin_documentos)

	_aviso = Label.new()
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_aviso)

	var acciones := HBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_END
	acciones.add_theme_constant_override("separation", 8)
	columna.add_child(acciones)

	_boton_cancelar = Button.new()
	_boton_cancelar.name = "Cancelar"
	_boton_cancelar.text = tr("SUENO_PREPARAR_CANCELAR")
	_boton_cancelar.pressed.connect(_emitir_cancelacion)
	acciones.add_child(_boton_cancelar)

	_boton_confirmar = Button.new()
	_boton_confirmar.name = "Confirmar"
	_boton_confirmar.text = tr("SUENO_PREPARAR_CONFIRMAR")
	_boton_confirmar.pressed.connect(_emitir_confirmacion)
	acciones.add_child(_boton_confirmar)


func _agregar_boton_documento(lista: VBoxContainer, indice: int, folio: String) -> void:
	var boton := Button.new()
	boton.name = "Documento%d" % indice
	boton.text = folio
	boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	boton.pressed.connect(_anadir_folio.bind(folio))
	lista.add_child(boton)
	_documentos.append(boton)


func _anadir_folio(folio: String) -> void:
	if _seleccion.size() >= SeleccionNocturna.MAX_DOCUMENTOS:
		return
	if not _leidos.has(folio):
		return
	_seleccion.append(folio)
	_refrescar()


func _quitar_hueco(indice: int) -> void:
	if indice < 0 or indice >= _seleccion.size():
		return
	_seleccion.remove_at(indice)
	_refrescar()


func _emitir_confirmacion() -> void:
	confirmada.emit(_seleccion.duplicate())


func _emitir_cancelacion() -> void:
	cancelada.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	cancelada.emit()
	get_viewport().set_input_as_handled()


func _refrescar() -> void:
	if _huecos.is_empty():
		return

	for i in _huecos.size():
		var hueco := _huecos[i]
		var ocupado := i < _seleccion.size()
		hueco.disabled = not ocupado
		hueco.text = (
			tr("SUENO_PREPARAR_HUECO") % [i + 1, _seleccion[i]]
			if ocupado
			else tr("SUENO_PREPARAR_HUECO_VACIO") % [i + 1]
		)

	for i in _documentos.size():
		var boton := _documentos[i]
		var folio := String(_leidos[i])
		var repeticiones := _seleccion.count(folio)
		boton.disabled = _seleccion.size() >= SeleccionNocturna.MAX_DOCUMENTOS
		boton.text = (
			folio
			if repeticiones == 0
			else tr("SUENO_PREPARAR_REPETIDA") % [folio, repeticiones]
		)

	_sin_documentos.visible = _documentos.is_empty()
	_aviso.text = (
		tr("SUENO_PREPARAR_COMPLETA")
		if _seleccion.size() >= SeleccionNocturna.MAX_DOCUMENTOS
		else ""
	)
	_recalcular_foco()


func _recalcular_foco() -> void:
	var botones: Array[Button] = []
	for boton in _documentos:
		if not boton.disabled:
			botones.append(boton)
	for boton in _huecos:
		if not boton.disabled:
			botones.append(boton)
	botones.append(_boton_confirmar)
	botones.append(_boton_cancelar)

	for i in botones.size():
		var boton := botones[i]
		var anterior := botones[(i - 1 + botones.size()) % botones.size()]
		var siguiente := botones[(i + 1) % botones.size()]
		boton.focus_neighbor_top = boton.get_path_to(anterior)
		boton.focus_neighbor_left = boton.get_path_to(anterior)
		boton.focus_previous = boton.get_path_to(anterior)
		boton.focus_neighbor_bottom = boton.get_path_to(siguiente)
		boton.focus_neighbor_right = boton.get_path_to(siguiente)
		boton.focus_next = boton.get_path_to(siguiente)

	var actual := get_viewport().gui_get_focus_owner() as Button
	if actual == null or actual.disabled or not actual.is_visible_in_tree():
		botones[0].grab_focus.call_deferred()
