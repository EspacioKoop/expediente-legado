## Superficie Godot del Parte de incidencias (#381).
##
## El envío externo es deliberadamente simple: prepara y copia el parte y, si
## existe una URL HTTP(S) configurada al empaquetar, abre ese formulario. Así el
## juego no necesita credenciales ni un cliente de red propio en este vertical.
class_name ParteIncidenciasApp
extends PanelContainer

signal volver

var _categoria: OptionButton
var _titulo: LineEdit
var _descripcion: TextEdit
var _pasos_rotulo: Label
var _pasos: TextEdit
var _esperado: TextEdit
var _observado: TextEdit
var _diagnostico: CheckButton
var _diagnostico_previa: TextEdit
var _accion_externa: Button
var _estado: Label
var _configuracion: Dictionary = {}
var _reduccion_movimiento := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(820, 620)
	_montar()
	visible = false


func abrir(preferencias: Dictionary) -> void:
	_configuracion = ParteIncidencias.cargar_configuracion()
	_reduccion_movimiento = bool(preferencias.get("reduccion_movimiento", false))
	_reiniciar()
	visible = true
	_categoria.grab_focus()


func cerrar() -> void:
	visible = false
	volver.emit()


func _montar() -> void:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 20)
	add_child(margen)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 580)
	margen.add_child(scroll)

	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 8)
	scroll.add_child(caja)

	var cabecera := Label.new()
	cabecera.text = "PARTE DE INCIDENCIAS · SIGA-98"
	caja.add_child(cabecera)

	var ayuda := Label.new()
	ayuda.text = (
		"Describa el problema. El diagnóstico técnico solo se adjunta si marca la casilla."
	)
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(ayuda)

	_rotulo(caja, "Categoría")
	_categoria = OptionButton.new()
	for categoria in ParteIncidencias.CATEGORIAS:
		_categoria.add_item(String(categoria).capitalize())
	_categoria.item_selected.connect(_al_cambiar_categoria)
	caja.add_child(_categoria)

	_rotulo(caja, "Título breve")
	_titulo = LineEdit.new()
	_titulo.placeholder_text = "Qué ocurrió"
	_titulo.max_length = 120
	caja.add_child(_titulo)

	_rotulo(caja, "Descripción")
	_descripcion = _area(caja, "Qué estaba haciendo y qué ocurrió", 88)

	_pasos_rotulo = _rotulo(caja, "Pasos para reproducir")
	_pasos = _area(caja, "1. …\n2. …", 80)

	_rotulo(caja, "Esperado")
	_esperado = _area(caja, "Qué esperaba que ocurriera", 58)

	_rotulo(caja, "Observado")
	_observado = _area(caja, "Qué ocurrió realmente", 58)

	_diagnostico = CheckButton.new()
	_diagnostico.text = "Adjuntar diagnóstico técnico filtrado"
	_diagnostico.tooltip_text = (
		"Incluye solo build, Godot, plataforma genérica, escena, renderer y reducción de movimiento."
	)
	_diagnostico.toggled.connect(_actualizar_diagnostico)
	caja.add_child(_diagnostico)

	_diagnostico_previa = TextEdit.new()
	_diagnostico_previa.editable = false
	_diagnostico_previa.custom_minimum_size.y = 112
	_diagnostico_previa.visible = false
	caja.add_child(_diagnostico_previa)

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	caja.add_child(acciones)

	_accion_externa = Button.new()
	_accion_externa.pressed.connect(_copiar_y_abrir)
	acciones.add_child(_accion_externa)

	var guardar := Button.new()
	guardar.text = "Guardar copia local"
	guardar.pressed.connect(_guardar)
	acciones.add_child(guardar)

	var volver_boton := Button.new()
	volver_boton.text = "Volver"
	volver_boton.pressed.connect(cerrar)
	acciones.add_child(volver_boton)

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_estado)


func _rotulo(caja: VBoxContainer, texto: String) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	caja.add_child(rotulo)
	return rotulo


func _area(caja: VBoxContainer, placeholder: String, alto: float) -> TextEdit:
	var area := TextEdit.new()
	area.placeholder_text = placeholder
	area.custom_minimum_size.y = alto
	area.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	caja.add_child(area)
	return area


func _reiniciar() -> void:
	_categoria.select(0)
	_titulo.clear()
	_descripcion.clear()
	_pasos.clear()
	_esperado.clear()
	_observado.clear()
	_diagnostico.button_pressed = false
	_diagnostico_previa.visible = false
	_diagnostico_previa.text = ""
	_estado.text = ParteIncidencias.texto_fallback(_configuracion)
	var url := ParteIncidencias.url_configurada(_configuracion)
	_accion_externa.text = (
		"Copiar y abrir formulario" if not url.is_empty() else "Copiar parte"
	)
	_al_cambiar_categoria(_categoria.selected)


func _al_cambiar_categoria(_indice: int) -> void:
	var es_bug := _categoria_actual() == "bug"
	_pasos_rotulo.visible = es_bug
	_pasos.visible = es_bug


func _actualizar_diagnostico(activo: bool) -> void:
	_diagnostico_previa.visible = activo
	if not activo:
		_diagnostico_previa.text = ""
		return
	_diagnostico_previa.text = ParteIncidencias.formatear_diagnostico(_diagnostico_actual())


func _categoria_actual() -> String:
	if _categoria.selected < 0 or _categoria.selected >= ParteIncidencias.CATEGORIAS.size():
		return "otro"
	return String(ParteIncidencias.CATEGORIAS[_categoria.selected])


func _campos() -> Dictionary:
	return {
		"categoria": _categoria_actual(),
		"titulo": _titulo.text,
		"descripcion": _descripcion.text,
		"pasos": _pasos.text if _categoria_actual() == "bug" else "",
		"esperado": _esperado.text,
		"observado": _observado.text,
	}


func _diagnostico_actual() -> Dictionary:
	if not _diagnostico.button_pressed:
		return {}
	var escena := ""
	if get_tree().current_scene != null:
		escena = get_tree().current_scene.scene_file_path
	return ParteIncidencias.diagnostico(escena, _reduccion_movimiento)


func _preparar_parte() -> String:
	if _titulo.text.strip_edges().is_empty() or _descripcion.text.strip_edges().is_empty():
		_estado.text = "Faltan título y descripción para tramitar el parte."
		return ""
	return ParteIncidencias.compilar(_campos(), _diagnostico_actual())


func _copiar_y_abrir() -> void:
	var parte := _preparar_parte()
	if parte.is_empty():
		return
	DisplayServer.clipboard_set(parte)
	var url := ParteIncidencias.url_configurada(_configuracion)
	if url.is_empty():
		_estado.text = "Parte copiado. " + ParteIncidencias.texto_fallback(_configuracion)
		return
	var error := OS.shell_open(url)
	if error == OK:
		_estado.text = "Parte copiado. Se ha abierto el formulario externo; péguelo allí."
	else:
		_estado.text = "No se pudo abrir el formulario. El parte sigue copiado al portapapeles."


func _guardar() -> void:
	var parte := _preparar_parte()
	if parte.is_empty():
		return
	var ruta := ParteIncidencias.guardar_local(parte)
	if ruta.is_empty():
		_estado.text = "No se pudo guardar la copia local. Puede copiar el parte."
	else:
		_estado.text = "Copia local guardada: %s" % ruta.get_file()
