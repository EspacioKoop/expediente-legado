## Pantalla opcional para ordenar los documentos ya disponibles de un expediente.
##
## La UI no decide si el orden es correcto: delega toda la evaluación en
## ReconstruccionExpediente. Seleccionar una tarjeta activa el modo mover; con
## teclado o mando, ui_up/ui_down la desplazan y ui_accept sale o entra en ese
## modo. Los botones Subir/Bajar ofrecen la misma operación con ratón.
extends Control

signal cerrada

var caso: Dictionary = {}
var estado: Dictionary = {}
var visibles: Array = []
var guardar: Callable

var _orden: Array = []
var _tarjetas_por_id: Dictionary = {}
var _botones_tarjeta: Array = []
var _indice_mover := -1

var _lista: VBoxContainer
var _estado: Label
var _subir: Button
var _bajar: Button
var _validar: Button
var _volver: Button


func _ready() -> void:
	theme = EstiloSiga.tema()
	EstiloSiga.declarar_bisel(self, EstiloSiga.PAPEL)
	_preparar_orden()
	_construir()
	_refrescar_tarjetas()
	_refrescar_resultado(ReconstruccionExpediente.validar(caso, _orden))
	if not _botones_tarjeta.is_empty():
		_botones_tarjeta[0].call_deferred("grab_focus")
	else:
		_volver.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrada.emit()


func _draw() -> void:
	EstiloSiga.dibujar_bisel(self, Rect2(Vector2.ZERO, size), EstiloSiga.PAPEL, true)


func _preparar_orden() -> void:
	var tarjetas := ReconstruccionExpediente.tarjetas(caso, visibles)
	for tarjeta in tarjetas:
		var id := String(tarjeta.get("id", ""))
		if id.is_empty():
			continue
		_tarjetas_por_id[id] = tarjeta

	var mejor := ReconstruccionExpediente.mejor_guardado(estado, String(caso.get("id", "")))
	for id_bruto in mejor.get("orden", []):
		var id := String(id_bruto)
		if _tarjetas_por_id.has(id) and not _orden.has(id):
			_orden.append(id)
	for tarjeta in tarjetas:
		var id := String(tarjeta.get("id", ""))
		if not id.is_empty() and not _orden.has(id):
			_orden.append(id)


func _construir() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 12
	raiz.offset_top = 12
	raiz.offset_right = -12
	raiz.offset_bottom = -12
	raiz.add_theme_constant_override("separation", 8)
	add_child(raiz)

	raiz.add_child(_titulo("RECONSTRUCCIÓN DEL EXPEDIENTE"))
	raiz.add_child(
		_linea(
			(
				"Seleccione una tarjeta y use ↑/↓ para moverla. "
				+ "La puntuación mide coherencia con los documentos disponibles."
			)
		)
	)

	var hueco := PanelContainer.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hueco.add_theme_stylebox_override("panel", _hundido(EstiloSiga.BLANCO))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hueco.add_child(scroll)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 4)
	scroll.add_child(_lista)
	raiz.add_child(hueco)

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 6)
	_subir = _boton("Subir")
	_subir.pressed.connect(func(): _mover_seleccion(-1))
	acciones.add_child(_subir)
	_bajar = _boton("Bajar")
	_bajar.pressed.connect(func(): _mover_seleccion(1))
	acciones.add_child(_bajar)
	_validar = _boton("Validar coherencia")
	_validar.pressed.connect(_validar_y_guardar)
	acciones.add_child(_validar)
	_volver = _boton("Volver al expediente")
	_volver.pressed.connect(func(): cerrada.emit())
	acciones.add_child(_volver)
	raiz.add_child(acciones)

	_estado = _linea("")
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_estado)


func _refrescar_tarjetas() -> void:
	for hijo in _lista.get_children():
		hijo.queue_free()
	_botones_tarjeta.clear()

	for i in _orden.size():
		var boton := _boton(_rotulo_tarjeta(i))
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.pressed.connect(_seleccionar_para_mover.bind(i))
		boton.gui_input.connect(_entrada_tarjeta.bind(i, boton))
		_lista.add_child(boton)
		_botones_tarjeta.append(boton)

	_refrescar_controles()


func _rotulo_tarjeta(indice: int) -> String:
	var id := String(_orden[indice])
	var tarjeta: Dictionary = _tarjetas_por_id.get(id, {})
	var fecha := String(tarjeta.get("fecha", ""))
	if fecha.is_empty():
		fecha = "s/f"
	var marca := "↕ " if _indice_mover == indice else ""
	return (
		"%s%d. Folio %s · %s · %s"
		% [marca, indice + 1, tarjeta.get("folio", id), tarjeta.get("tipo", ""), fecha]
	)


func _seleccionar_para_mover(indice: int) -> void:
	_indice_mover = -1 if _indice_mover == indice else indice
	_refrescar_rotulos()
	_refrescar_controles()


func _entrada_tarjeta(event: InputEvent, indice: int, boton: Button) -> void:
	if _indice_mover != indice:
		return
	if event.is_action_pressed("ui_up"):
		boton.accept_event()
		_mover_seleccion(-1)
	elif event.is_action_pressed("ui_down"):
		boton.accept_event()
		_mover_seleccion(1)
	elif event.is_action_pressed("ui_cancel"):
		boton.accept_event()
		_indice_mover = -1
		_refrescar_rotulos()
		_refrescar_controles()


func _mover_seleccion(delta: int) -> void:
	if _indice_mover < 0 or _indice_mover >= _orden.size():
		return
	var destino := clampi(_indice_mover + delta, 0, _orden.size() - 1)
	if destino == _indice_mover:
		return
	var id = _orden.pop_at(_indice_mover)
	_orden.insert(destino, id)
	_indice_mover = destino
	_refrescar_tarjetas()
	_refrescar_resultado(ReconstruccionExpediente.validar(caso, _orden))
	if _indice_mover < _botones_tarjeta.size():
		_botones_tarjeta[_indice_mover].call_deferred("grab_focus")


func _refrescar_rotulos() -> void:
	for i in _botones_tarjeta.size():
		_botones_tarjeta[i].text = _rotulo_tarjeta(i)


func _refrescar_controles() -> void:
	_subir.disabled = _indice_mover <= 0
	_bajar.disabled = _indice_mover < 0 or _indice_mover >= _orden.size() - 1
	_validar.disabled = _orden.size() < 2
	_actualizar_vecinos_foco()


func _validar_y_guardar() -> void:
	var intento := ReconstruccionExpediente.guardar_mejor(
		estado, String(caso.get("id", "")), caso, _orden
	)
	var nota := ""
	if intento.get("actualizado", false):
		if guardar.is_valid() and bool(guardar.call()):
			nota = "Mejor reconstrucción guardada."
		elif guardar.is_valid():
			nota = "No se pudo escribir la partida; el resultado sigue en memoria."
		else:
			nota = "Resultado actualizado en memoria."
	else:
		nota = "El mejor resultado guardado sigue siendo superior o equivalente."
	_refrescar_resultado(intento.get("resultado", {}), nota)


func _refrescar_resultado(resultado: Dictionary, nota: String = "") -> void:
	var clave := String(resultado.get("estado", ReconstruccionExpediente.DATO_AUSENTE))
	var rotulo := "DATO AUSENTE"
	if clave == ReconstruccionExpediente.COMPATIBLE:
		rotulo = "ORDEN COMPATIBLE"
	elif clave == ReconstruccionExpediente.CONTRADICCION:
		rotulo = "CONTRADICCIÓN"

	var cobertura := int(round(float(resultado.get("cobertura", 0.0)) * 100.0))
	var texto := (
		"%s · Coherencia %d · Cobertura %d%% · Rango %s"
		% [
			rotulo,
			int(resultado.get("puntuacion", 0)),
			cobertura,
			String(resultado.get("rango", "incompleto")).capitalize(),
		]
	)
	var detalle := _detalle_discrepancias(resultado.get("discrepancias", []))
	if not detalle.is_empty():
		texto += "\n" + detalle
	if not nota.is_empty():
		texto += "\n" + nota
	_estado.text = texto


func _detalle_discrepancias(discrepancias: Array) -> String:
	var lineas: Array = []
	for discrepancia in discrepancias:
		if typeof(discrepancia) != TYPE_DICTIONARY:
			continue
		if discrepancia.get("tipo") == ReconstruccionExpediente.CONTRADICCION:
			(
				lineas
				. append(
					(
						"Contradicción: folio %s aparece antes que folio %s."
						% [
							_folio_de(String(discrepancia.get("anterior", ""))),
							_folio_de(String(discrepancia.get("actual", ""))),
						]
					)
				)
			)
		elif discrepancia.get("tipo") == ReconstruccionExpediente.DATO_AUSENTE:
			lineas.append(
				"Dato ausente en folio %s." % _folio_de(String(discrepancia.get("id", "")))
			)
	return "\n".join(lineas)


func _folio_de(id: String) -> String:
	var tarjeta: Dictionary = _tarjetas_por_id.get(id, {})
	return String(tarjeta.get("folio", id))


func _actualizar_vecinos_foco() -> void:
	var controles: Array = []
	for boton in _botones_tarjeta:
		controles.append(boton)
	if not _subir.disabled:
		controles.append(_subir)
	if not _bajar.disabled:
		controles.append(_bajar)
	if not _validar.disabled:
		controles.append(_validar)
	controles.append(_volver)
	if controles.is_empty():
		return

	for i in controles.size():
		var actual: Control = controles[i]
		var anterior: Control = controles[(i - 1 + controles.size()) % controles.size()]
		var siguiente: Control = controles[(i + 1) % controles.size()]
		actual.focus_neighbor_top = actual.get_path_to(anterior)
		actual.focus_neighbor_left = actual.focus_neighbor_top
		actual.focus_neighbor_bottom = actual.get_path_to(siguiente)
		actual.focus_neighbor_right = actual.focus_neighbor_bottom
		actual.focus_next = actual.focus_neighbor_bottom
		actual.focus_previous = actual.focus_neighbor_top


func _boton(texto: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	_hacer_enfocable(boton)
	return boton


func _hacer_enfocable(control: BaseButton) -> void:
	control.focus_mode = Control.FOCUS_ALL
	var foco := StyleBoxFlat.new()
	foco.bg_color = Color(0, 0, 0, 0)
	foco.border_width_left = 2
	foco.border_width_top = 2
	foco.border_width_right = 2
	foco.border_width_bottom = 2
	foco.border_color = EstiloSiga.NEGRO
	foco.content_margin_left = 3
	foco.content_margin_top = 2
	foco.content_margin_right = 3
	foco.content_margin_bottom = 2
	control.add_theme_stylebox_override("focus", foco)


func _titulo(texto: String) -> Control:
	var barra := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = EstiloSiga.AZUL_TITULO
	caja.set_corner_radius_all(0)
	caja.content_margin_left = 6
	caja.content_margin_top = 3
	caja.content_margin_bottom = 3
	barra.add_theme_stylebox_override("panel", caja)
	var etiqueta := _linea(texto)
	etiqueta.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	etiqueta.add_theme_font_override("font", theme.get_font("title_font", "Label"))
	barra.add_child(etiqueta)
	return barra


func _linea(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", EstiloSiga.NEGRO)
	etiqueta.add_theme_font_size_override("font_size", 14)
	return etiqueta


func _hundido(fondo: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.set_corner_radius_all(0)
	caja.border_width_top = EstiloSiga.GROSOR
	caja.border_width_left = EstiloSiga.GROSOR
	caja.border_width_bottom = EstiloSiga.GROSOR
	caja.border_width_right = EstiloSiga.GROSOR
	caja.border_color = EstiloSiga.GRIS_OSCURO
	caja.content_margin_left = 8
	caja.content_margin_right = 8
	caja.content_margin_top = 6
	caja.content_margin_bottom = 6
	return caja
