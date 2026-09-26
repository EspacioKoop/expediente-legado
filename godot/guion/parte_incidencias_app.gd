## Superficie Godot del Parte de incidencias (#381, #1460).
##
## El juego nunca contiene credenciales de GitHub o SMTP. Envía un payload
## filtrado a un gateway HTTP(S) configurable; ese servidor crea el issue y,
## opcionalmente, remite correo. Si el gateway no está configurado o falla,
## abre un GitHub Issue pre-rellenado sin depender del portapapeles.
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
var _enviar: Button
var _estado: Label
var _http: HTTPRequest
var _configuracion: Dictionary = {}
var _reduccion_movimiento := false
var _payload_pendiente: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(820, 620)
	_configuracion = ParteIncidencias.cargar_configuracion()
	_montar()
	visible = false


func abrir(preferencias: Dictionary, diagnostico_por_defecto: bool = false) -> void:
	_reduccion_movimiento = bool(preferencias.get("reduccion_movimiento", false))
	_reiniciar(diagnostico_por_defecto)
	visible = true
	_categoria.grab_focus()


func cerrar() -> void:
	visible = false
	volver.emit()


func _montar() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	_http.request_completed.connect(_al_envio_completado)
	add_child(_http)

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
	cabecera.text = _texto("cabecera")
	caja.add_child(cabecera)

	var ayuda := Label.new()
	ayuda.text = _texto("ayuda")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(ayuda)

	_rotulo(caja, _texto("categoria"))
	_categoria = OptionButton.new()
	for categoria in ParteIncidencias.CATEGORIAS:
		_categoria.add_item(_texto("categoria_" + String(categoria)))
	_categoria.item_selected.connect(_al_cambiar_categoria)
	caja.add_child(_categoria)

	_rotulo(caja, _texto("titulo"))
	_titulo = LineEdit.new()
	_titulo.placeholder_text = _texto("titulo_placeholder")
	_titulo.max_length = 120
	caja.add_child(_titulo)

	_rotulo(caja, _texto("descripcion"))
	_descripcion = _area(caja, _texto("descripcion_placeholder"), 88)

	_pasos_rotulo = _rotulo(caja, _texto("pasos"))
	_pasos = _area(caja, _texto("pasos_placeholder"), 80)

	_rotulo(caja, _texto("esperado"))
	_esperado = _area(caja, _texto("esperado_placeholder"), 58)

	_rotulo(caja, _texto("observado"))
	_observado = _area(caja, _texto("observado_placeholder"), 58)

	_diagnostico = CheckButton.new()
	_diagnostico.text = _texto("diagnostico")
	_diagnostico.tooltip_text = _texto("diagnostico_ayuda")
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

	_enviar = Button.new()
	_enviar.text = _texto("enviar")
	_enviar.pressed.connect(_enviar_reporte)
	EstiloJuego.hacer_primario(_enviar)
	acciones.add_child(_enviar)

	var guardar := Button.new()
	guardar.text = _texto("guardar")
	guardar.pressed.connect(_guardar)
	acciones.add_child(guardar)

	var volver_boton := Button.new()
	volver_boton.text = _texto("volver")
	volver_boton.pressed.connect(cerrar)
	acciones.add_child(volver_boton)

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.accessibility_live = AccessibilityServer.LIVE_POLITE
	caja.add_child(_estado)


func _texto(clave: String) -> String:
	return ParteIncidencias.texto_interfaz(clave, _configuracion)


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


func _reiniciar(diagnostico_por_defecto: bool) -> void:
	_categoria.select(0)
	_titulo.clear()
	_descripcion.clear()
	_pasos.clear()
	_esperado.clear()
	_observado.clear()
	_payload_pendiente.clear()
	_enviar.disabled = false
	_diagnostico.button_pressed = diagnostico_por_defecto
	_actualizar_diagnostico(diagnostico_por_defecto)
	_estado.text = _texto("listo")
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


func _preparar_payload() -> Dictionary:
	if _titulo.text.strip_edges().is_empty() or _descripcion.text.strip_edges().is_empty():
		_estado.text = _texto("faltan")
		return {}
	return ParteIncidencias.crear_payload(_campos(), _diagnostico_actual())


func _enviar_reporte() -> void:
	var payload := _preparar_payload()
	if payload.is_empty():
		return

	var url := ParteIncidencias.url_configurada(_configuracion)
	if url.is_empty():
		_abrir_fallback(payload, _texto("sin_endpoint"))
		return

	_payload_pendiente = payload
	_enviar.disabled = true
	_estado.text = _texto("enviando")
	var cabeceras := PackedStringArray(
		[
			"Content-Type: application/json",
			"Accept: application/json",
		]
	)
	var error := (
		_http
		. request(
			url,
			cabeceras,
			HTTPClient.METHOD_POST,
			JSON.stringify(payload),
		)
	)
	if error != OK:
		_enviar.disabled = false
		_abrir_fallback(payload, _texto("error_envio"))


func _al_envio_completado(
	resultado: int,
	codigo: int,
	_cabeceras: PackedStringArray,
	cuerpo: PackedByteArray,
) -> void:
	_enviar.disabled = false
	if resultado == HTTPRequest.RESULT_SUCCESS and codigo >= 200 and codigo < 300:
		_estado.text = _texto("enviado")
		var datos = JSON.parse_string(cuerpo.get_string_from_utf8())
		if datos is Dictionary:
			var issue_url := String(datos.get("issue_url", "")).strip_edges()
			if issue_url.begins_with("https://github.com/"):
				_estado.text = _texto("enviado_issue") % issue_url
		_payload_pendiente.clear()
		return

	var payload := _payload_pendiente.duplicate(true)
	_payload_pendiente.clear()
	if payload.is_empty():
		_estado.text = _texto("error_envio")
		return
	_abrir_fallback(payload, _texto("error_envio"))


func _abrir_fallback(payload: Dictionary, motivo: String) -> void:
	# Guardar primero evita perder lo escrito aunque el navegador tampoco abra.
	ParteIncidencias.guardar_local(String(payload.get("body", "")))
	var url := ParteIncidencias.url_issue_preparado(payload, _configuracion)
	if url.is_empty():
		_estado.text = _texto("error_sin_fallback")
		return
	var error := OS.shell_open(url)
	_estado.text = _texto("fallback_abierto") if error == OK else motivo


func _guardar() -> void:
	var payload := _preparar_payload()
	if payload.is_empty():
		return
	var ruta := ParteIncidencias.guardar_local(String(payload.get("body", "")))
	if ruta.is_empty():
		_estado.text = _texto("error_guardar")
	else:
		_estado.text = _texto("guardado") % ruta.get_file()
