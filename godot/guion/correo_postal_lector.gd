## Lector diegético del correo recién retirado del buzón (#672).
##
## Es una ventana transitoria: recibe una copia del resultado de CorreoPostal,
## no posee estado de jornada y no crea una segunda bandeja de tareas.
class_name CorreoPostalLector
extends Window

signal cerrada

const RUTA_TEXTOS := "res://datos/correo_postal_presentacion.json"

var _textos: Dictionary = {}
var _titulo: Label
var _cabecera: Label
var _contenido: RichTextLabel
var _detalle: Label
var _cerrar_boton: Button


func _init() -> void:
	visible = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_textos = _cargar_textos()
	theme = EstiloSiga.tema()
	title = String(_textos.get("ventana_titulo", "Correo postal"))
	size = Vector2i(720, 500)
	exclusive = true
	transient = true
	close_requested.connect(_cerrar)
	_construir()


static func modelo_resultado(resultado: Dictionary) -> Dictionary:
	var pieza = resultado.get("pieza", {})
	if not pieza is Dictionary or pieza.is_empty():
		return modelo_vacio()

	var textos := _cargar_textos()
	var categoria_id := String(pieza.get("categoria", "")).strip_edges()
	var categorias = textos.get("categorias", {})
	var categoria := categoria_id.replace("_", " ").capitalize()
	if categorias is Dictionary:
		categoria = String(categorias.get(categoria_id, categoria))

	var cabecera: Array[String] = []
	var remitente := String(pieza.get("remitente", "")).strip_edges()
	if not remitente.is_empty():
		cabecera.append(String(textos.get("remitente", "De: %s")) % remitente)
	var dia := int(pieza.get("fecha", 0))
	if dia > 0:
		cabecera.append(String(textos.get("dia", "Día %d")) % dia)
	if not categoria.is_empty():
		cabecera.append(String(textos.get("categoria", "Categoría: %s")) % categoria)

	var detalle := ""
	var objeto = pieza.get("objeto", {})
	if bool(resultado.get("objeto_agregado", false)) and objeto is Dictionary:
		var nombre_objeto := String(objeto.get("nombre", objeto.get("id", "objeto")))
		detalle = String(textos.get("objeto_recogido", "Contenido: %s")) % nombre_objeto

	return {
		"vacio": false,
		"titulo": String(pieza.get("asunto", "")).strip_edges(),
		"cabecera": " · ".join(cabecera),
		"contenido": String(pieza.get("contenido", "")).strip_edges(),
		"detalle": detalle,
	}


static func modelo_vacio() -> Dictionary:
	var textos := _cargar_textos()
	return {
		"vacio": true,
		"titulo": String(textos.get("titulo_vacio", "Buzón del portal")),
		"cabecera": "",
		"contenido": String(textos.get("cuerpo_vacio", "No hay correo nuevo.")),
		"detalle": "",
	}


func abrir(resultado: Dictionary) -> void:
	_mostrar_modelo(modelo_resultado(resultado))
	popup_centered()
	_enfocar.call_deferred()


func abrir_vacio() -> void:
	_mostrar_modelo(modelo_vacio())
	popup_centered()
	_enfocar.call_deferred()


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.72, 0.69, 0.58)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	add_child(margen)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)

	_titulo = Label.new()
	_titulo.name = "CorreoPostalTitulo"
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_titulo)

	_cabecera = Label.new()
	_cabecera.name = "CorreoPostalCabecera"
	_cabecera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_cabecera)

	columna.add_child(HSeparator.new())

	_contenido = RichTextLabel.new()
	_contenido.name = "CorreoPostalContenido"
	_contenido.bbcode_enabled = false
	_contenido.fit_content = false
	_contenido.scroll_active = true
	_contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_contenido.custom_minimum_size.y = 250
	columna.add_child(_contenido)

	_detalle = Label.new()
	_detalle.name = "CorreoPostalDetalle"
	_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_detalle)

	_cerrar_boton = Button.new()
	_cerrar_boton.name = "CorreoPostalCerrar"
	_cerrar_boton.text = String(_textos.get("cerrar", "Cerrar"))
	_cerrar_boton.pressed.connect(_cerrar)
	columna.add_child(_cerrar_boton)


func _mostrar_modelo(modelo: Dictionary) -> void:
	_titulo.text = String(modelo.get("titulo", ""))
	_cabecera.text = String(modelo.get("cabecera", ""))
	_cabecera.visible = not _cabecera.text.is_empty()
	_contenido.text = String(modelo.get("contenido", ""))
	_detalle.text = String(modelo.get("detalle", ""))
	_detalle.visible = not _detalle.text.is_empty()


func _enfocar() -> void:
	if is_instance_valid(_cerrar_boton):
		_cerrar_boton.grab_focus()


func _cerrar() -> void:
	cerrada.emit()


func _unhandled_input(evento: InputEvent) -> void:
	# Fallback equivalente al de HistoriaApp: ui_accept no incluye mando en todas
	# las versiones del motor que soporta el proyecto.
	if evento is InputEventJoypadButton and evento.pressed:
		if evento.button_index == JOY_BUTTON_A:
			var boton := gui_get_focus_owner() as Button
			set_input_as_handled()
			if boton != null and not boton.disabled:
				boton.pressed.emit()
		elif evento.button_index == JOY_BUTTON_B:
			set_input_as_handled()
			_cerrar()
	elif evento.is_action_pressed("cancelar") or evento.is_action_pressed("ui_cancel"):
		set_input_as_handled()
		_cerrar()


static func _cargar_textos() -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return datos if datos is Dictionary else {}
