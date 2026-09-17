## Visor legible para publicaciones físicas de 1998 (#674).
##
## Esta capa solo presenta el contrato de Publicaciones98: no duplica catálogo,
## persistencia ni semillas. Mostrar una pieza llama a `hojear()` y cerrar llama
## a `cerrar_tras_lectura()`, de modo que la interfaz no puede inventar progreso.
class_name VisorPublicacion
extends Window

signal cerrada(resultado: Dictionary)

const TAMANOS_TEXTO := [18, 22, 26, 30]
const INDICE_TAMANO_INICIAL := 1

var _jornada: Dictionary = {}
var _item_id := ""
var _publicacion: Dictionary = {}
var _indice_pieza := 0
var _indice_tamano := INDICE_TAMANO_INICIAL
var _cerrada := true

var _titulo: Label
var _tipo: Label
var _contenido: RichTextLabel
var _pagina: Label
var _anterior: Button
var _siguiente: Button
var _menos: Button
var _mas: Button
var _cerrar_boton: Button


func _init() -> void:
	visible = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	title = "Publicación"
	size = Vector2i(820, 620)
	min_size = Vector2i(640, 420)
	exclusive = true
	transient = true
	close_requested.connect(cerrar)
	_construir()


## Abre una publicación y conserva la referencia al mismo Dictionary de Jornada.
## Si no se indica pieza inicial, se empieza por la primera pieza declarada.
func abrir(jornada: Dictionary, item_id: String, pieza_inicial: String = "") -> bool:
	var publicacion := Publicaciones98.por_id(item_id)
	var piezas = publicacion.get("piezas", [])
	if publicacion.is_empty() or typeof(piezas) != TYPE_ARRAY or piezas.is_empty():
		return false

	_jornada = jornada
	_item_id = item_id
	_publicacion = publicacion
	_indice_pieza = _indice_de_pieza(pieza_inicial)
	_cerrada = false
	_mostrar_actual()
	popup_centered()
	_enfocar_lectura.call_deferred()
	return true


func pieza_actual_id() -> String:
	var piezas = _publicacion.get("piezas", [])
	if typeof(piezas) != TYPE_ARRAY or piezas.is_empty():
		return ""
	return String(piezas[_indice_pieza].get("id", ""))


func tamano_texto() -> int:
	return int(TAMANOS_TEXTO[_indice_tamano])


func tiene_foco_lectura() -> bool:
	return is_instance_valid(_contenido) and _contenido.has_focus()


func anterior() -> void:
	if _cerrada or _indice_pieza <= 0:
		return
	_indice_pieza -= 1
	_mostrar_actual()


func siguiente() -> void:
	if _cerrada:
		return
	var piezas = _publicacion.get("piezas", [])
	if typeof(piezas) != TYPE_ARRAY or _indice_pieza >= piezas.size() - 1:
		return
	_indice_pieza += 1
	_mostrar_actual()


func reducir_texto() -> void:
	_indice_tamano = maxi(0, _indice_tamano - 1)
	_aplicar_tamano()


func ampliar_texto() -> void:
	_indice_tamano = mini(TAMANOS_TEXTO.size() - 1, _indice_tamano + 1)
	_aplicar_tamano()


## Cerrar es el gesto cultural deliberado definido por Publicaciones98.
## El resultado se devuelve y también se emite para que la escena dueña pueda
## guardar Jornada o mostrar feedback sin que este visor conozca Partida/Dia.
func cerrar() -> Dictionary:
	if _cerrada:
		return {"ok": true, "id": _item_id, "semilla_activada": false, "repetido": true}
	_cerrada = true
	var resultado := Publicaciones98.cerrar_tras_lectura(_jornada, _item_id)
	hide()
	cerrada.emit(resultado)
	return resultado


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.86, 0.82, 0.69)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	add_child(margen)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	margen.add_child(columna)

	_titulo = Label.new()
	_titulo.name = "PublicacionTitulo"
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_titulo.add_theme_font_size_override("font_size", 24)
	columna.add_child(_titulo)

	_tipo = Label.new()
	_tipo.name = "PublicacionTipo"
	_tipo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_tipo)

	columna.add_child(HSeparator.new())

	_contenido = RichTextLabel.new()
	_contenido.name = "PublicacionContenido"
	_contenido.bbcode_enabled = false
	_contenido.fit_content = false
	_contenido.scroll_active = true
	_contenido.selection_enabled = true
	_contenido.focus_mode = Control.FOCUS_ALL
	_contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_contenido.custom_minimum_size.y = 300
	columna.add_child(_contenido)

	var estado := HBoxContainer.new()
	estado.add_theme_constant_override("separation", 8)
	_pagina = Label.new()
	_pagina.name = "PublicacionPagina"
	_pagina.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	estado.add_child(_pagina)

	_menos = _boton("PublicacionTextoMenos", "A−", reducir_texto)
	_menos.tooltip_text = "Reducir tamaño de lectura"
	estado.add_child(_menos)
	_mas = _boton("PublicacionTextoMas", "A+", ampliar_texto)
	_mas.tooltip_text = "Ampliar tamaño de lectura"
	estado.add_child(_mas)
	columna.add_child(estado)

	var navegacion := HBoxContainer.new()
	navegacion.add_theme_constant_override("separation", 8)
	_anterior = _boton("PublicacionAnterior", "◀ Anterior", anterior)
	_siguiente = _boton("PublicacionSiguiente", "Siguiente ▶", siguiente)
	_cerrar_boton = _boton("PublicacionCerrar", "Cerrar publicación", cerrar)
	_cerrar_boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navegacion.add_child(_anterior)
	navegacion.add_child(_siguiente)
	navegacion.add_child(_cerrar_boton)
	columna.add_child(navegacion)

	_aplicar_tamano()


func _boton(nombre: String, texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.name = nombre
	boton.text = texto
	boton.focus_mode = Control.FOCUS_ALL
	boton.pressed.connect(accion)
	return boton


func _indice_de_pieza(pieza_id: String) -> int:
	if pieza_id.is_empty():
		return 0
	var piezas: Array = _publicacion.get("piezas", [])
	for indice in piezas.size():
		if String(piezas[indice].get("id", "")) == pieza_id:
			return indice
	return 0


func _mostrar_actual() -> void:
	var piezas: Array = _publicacion.get("piezas", [])
	if piezas.is_empty():
		return
	_indice_pieza = clampi(_indice_pieza, 0, piezas.size() - 1)
	var pieza: Dictionary = piezas[_indice_pieza]
	var pieza_id := String(pieza.get("id", ""))
	var lectura := Publicaciones98.hojear(_jornada, _item_id, pieza_id)
	if not bool(lectura.get("ok", false)):
		return

	_titulo.text = String(_publicacion.get("titulo", _item_id))
	_tipo.text = String(pieza.get("titulo", pieza_id))
	_contenido.text = String(pieza.get("texto", ""))
	_contenido.scroll_to_line(0)
	_pagina.text = (
		"%d / %d · %s"
		% [
			_indice_pieza + 1,
			piezas.size(),
			"contenido nuevo" if bool(lectura.get("nueva", false)) else "ya visto",
		]
	)
	_anterior.disabled = _indice_pieza <= 0
	_siguiente.disabled = _indice_pieza >= piezas.size() - 1


func _aplicar_tamano() -> void:
	if not is_instance_valid(_contenido):
		return
	_contenido.add_theme_font_size_override("normal_font_size", tamano_texto())
	_contenido.add_theme_font_size_override("bold_font_size", tamano_texto())


func _enfocar_lectura() -> void:
	if is_instance_valid(_contenido):
		_contenido.grab_focus()


func _activar_foco() -> void:
	var boton := gui_get_focus_owner() as Button
	if boton != null and not boton.disabled:
		boton.pressed.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or not evento.is_pressed() or evento.is_echo():
		return

	if evento is InputEventJoypadButton:
		match evento.button_index:
			JOY_BUTTON_A:
				set_input_as_handled()
				_activar_foco()
			JOY_BUTTON_B:
				set_input_as_handled()
				cerrar()
			JOY_BUTTON_LEFT_SHOULDER:
				set_input_as_handled()
				anterior()
			JOY_BUTTON_RIGHT_SHOULDER:
				set_input_as_handled()
				siguiente()
			JOY_BUTTON_X:
				set_input_as_handled()
				reducir_texto()
			JOY_BUTTON_Y:
				set_input_as_handled()
				ampliar_texto()
		return

	if evento.is_action_pressed("cancelar") or evento.is_action_pressed("ui_cancel"):
		set_input_as_handled()
		cerrar()
		return

	if _contenido.has_focus() and evento.is_action_pressed("ui_left"):
		set_input_as_handled()
		anterior()
		return
	if _contenido.has_focus() and evento.is_action_pressed("ui_right"):
		set_input_as_handled()
		siguiente()
		return

	if evento is InputEventKey:
		match evento.keycode:
			KEY_PAGEUP:
				set_input_as_handled()
				anterior()
			KEY_PAGEDOWN:
				set_input_as_handled()
				siguiente()
			KEY_MINUS, KEY_KP_SUBTRACT:
				set_input_as_handled()
				reducir_texto()
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				set_input_as_handled()
				ampliar_texto()
