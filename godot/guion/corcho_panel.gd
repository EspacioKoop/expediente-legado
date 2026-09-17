## Interfaz propia del corcho de conceptos (#785).
##
## El tablón de la pared es de tamaño real y no se reordena ahí: al usarlo se
## abre esta vista, que dibuja el mismo estado (`Corcho`) a escala de pantalla.
##
## - Ratón: arrastrar una ficha la mueve; pulsar dos fichas pone o quita hilo.
## - Teclado y mando: las direcciones eligen ficha, Intro/A la marca para el
##   hilo, M/X la coge (las direcciones la mueven) y la suelta, Esc/B cierra.
##
## Todo cambio va directo a la jornada; quien la abre guarda y vuelve a pintar
## la pared al recibir `cerrado`.
class_name CorchoPanel
extends Control

signal cambiado
signal cerrado

const TITULO := "Corcho de conceptos"
const AYUDA_RATON := "Arrastra una ficha para moverla · Pulsa dos fichas para poner o quitar hilo"
const AYUDA_MANDO := "Flechas: elegir · Intro/A: hilo · M/X: coger y soltar · Esc/B: cerrar"
const VACIO := "Aún no hay fichas. Los conceptos que descubras en el archivo acabarán aquí."
const CERRAR := "Cerrar"
const PASO_TECLADO := 0.05
const UMBRAL_ARRASTRE := 6.0
const COLOR_CORCHO := Color(0.55, 0.36, 0.21)
const COLOR_MARCO := Color(0.25, 0.14, 0.075)
const COLOR_PAPEL := Color(0.90, 0.86, 0.72)
const COLOR_SELECCION := Color(0.98, 0.86, 0.40)
const COLOR_HILO := Color(0.62, 0.06, 0.05)
const COLOR_TINTA := Color(0.12, 0.10, 0.09)
const TECLA_COGER := KEY_M
const BOTON_COGER := JOY_BUTTON_X

var _jornada: Dictionary = {}
var _conceptos: Dictionary = {}
var _botones := {}
var _seleccion := ""
var _cogida := ""
var _arrastre := ""
var _origen_arrastre := Vector2.ZERO
var _desplazamiento_arrastre := Vector2.ZERO
var _arrastrando := false

var _tablon: Control
var _hilos: Control
var _vacio: Label
var _cerrar: Button


func configurar(jornada: Dictionary, conceptos: Dictionary) -> void:
	_jornada = jornada
	_conceptos = conceptos
	_montar()
	_montar_fichas()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_montar()
	_colocar_todo()
	call_deferred("_enfocar_inicial")


func seleccion() -> String:
	return _seleccion


func cogida() -> String:
	return _cogida


func boton_de(id: String) -> Button:
	return _botones.get(id) as Button


func cerrar() -> void:
	cerrado.emit()


func _montar() -> void:
	if _tablon != null:
		return
	resized.connect(_colocar_todo)
	var fondo := ColorRect.new()
	fondo.name = "Fondo"
	fondo.color = Color(0.03, 0.025, 0.02, 0.82)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.text = TITULO
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
	titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	titulo.offset_top = 14
	add_child(titulo)

	_cerrar = Button.new()
	_cerrar.name = "Cerrar"
	_cerrar.theme = EstiloSiga.tema()
	_cerrar.text = CERRAR
	_cerrar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_cerrar.offset_left = -130
	_cerrar.offset_top = 12
	_cerrar.offset_right = -12
	_cerrar.focus_mode = Control.FOCUS_NONE
	_cerrar.pressed.connect(cerrar)
	add_child(_cerrar)

	_tablon = Control.new()
	_tablon.name = "Tablon"
	_tablon.mouse_filter = Control.MOUSE_FILTER_PASS
	_tablon.draw.connect(_dibujar_tablon)
	add_child(_tablon)

	_hilos = Control.new()
	_hilos.name = "Hilos"
	_hilos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hilos.draw.connect(_dibujar_hilos)

	_vacio = Label.new()
	_vacio.name = "Vacio"
	_vacio.text = VACIO
	_vacio.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
	_vacio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vacio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vacio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablon.add_child(_vacio)

	var ayuda := VBoxContainer.new()
	ayuda.name = "Ayuda"
	ayuda.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ayuda.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ayuda.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ayuda.offset_bottom = -12
	ayuda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ayuda)
	for texto in [AYUDA_RATON, AYUDA_MANDO]:
		var linea := Label.new()
		linea.text = texto
		linea.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		linea.add_theme_color_override("font_color", Color(0.86, 0.80, 0.68))
		ayuda.add_child(linea)


func _montar_fichas() -> void:
	for boton in _botones.values():
		boton.queue_free()
	_botones.clear()
	if _hilos.get_parent() != null:
		_tablon.remove_child(_hilos)
	var fichas: Dictionary = Corcho.estado(_jornada)["fichas"]
	var ids := []
	for id in fichas:
		if _conceptos.has(String(id)):
			ids.append(String(id))
	for id in ids:
		var boton := Button.new()
		boton.name = "Ficha_%s" % id.validate_node_name()
		boton.tooltip_text = String(_conceptos[id].get("nombre", id))
		boton.clip_contents = true
		boton.focus_mode = Control.FOCUS_ALL
		boton.gui_input.connect(_entrada_ficha.bind(id))
		boton.focus_entered.connect(_actualizar_estilos)
		boton.focus_exited.connect(_actualizar_estilos)
		# El nombre va en una etiqueta propia: el texto de un Button hace crecer
		# el botón con cada línea y una ficha larga pisaba a la de debajo.
		var nombre := Label.new()
		nombre.name = "Nombre"
		nombre.text = boton.tooltip_text
		nombre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		nombre.offset_left = 6
		nombre.offset_right = -6
		nombre.offset_top = 12
		nombre.offset_bottom = -2
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nombre.max_lines_visible = 3
		nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nombre.clip_text = true
		nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nombre.add_theme_color_override("font_color", COLOR_TINTA)
		boton.add_child(nombre)
		_tablon.add_child(boton)
		_botones[id] = boton
	# Los hilos van encima del papel, hasta las chinchetas.
	_tablon.add_child(_hilos)
	_vacio.visible = ids.is_empty()
	_colocar_todo()
	_actualizar_estilos()


func _colocar_todo() -> void:
	if _tablon == null:
		return
	var disponible := size - Vector2(80, 190)
	var escala_px := minf(disponible.x / Corcho.AREA.x, disponible.y / Corcho.AREA.y)
	escala_px = maxf(escala_px, 120.0)
	var tam := Corcho.AREA * escala_px
	_tablon.size = tam
	_tablon.position = Vector2((size.x - tam.x) * 0.5, 70.0 + (disponible.y - tam.y) * 0.5)
	_hilos.size = tam
	_vacio.size = tam
	var fuente := clampi(int(escala_px * 0.045), 10, 20)
	for id in _botones:
		var boton: Button = _botones[id]
		boton.size = Corcho.TAM_FICHA * escala_px
		boton.get_node("Nombre").add_theme_font_size_override("font_size", fuente)
		if id != _arrastre or not _arrastrando:
			boton.position = _a_pixeles(_posicion(id)) - boton.size * 0.5
	_tablon.queue_redraw()
	_hilos.queue_redraw()


func _escala_px() -> float:
	return _tablon.size.x / Corcho.AREA.x


func _a_pixeles(pos: Vector2) -> Vector2:
	return _tablon.size * 0.5 + Vector2(pos.x, -pos.y) * _escala_px()


func _a_logico(px: Vector2) -> Vector2:
	var relativo := (px - _tablon.size * 0.5) / _escala_px()
	return Vector2(relativo.x, -relativo.y)


func _posicion(id: String) -> Vector2:
	var fichas: Dictionary = Corcho.estado(_jornada)["fichas"]
	var datos = fichas.get(id, {})
	if typeof(datos) != TYPE_DICTIONARY:
		return Vector2.ZERO
	var pos = datos.get("pos", [])
	if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
		return Vector2.ZERO
	return Vector2(float(pos[0]), float(pos[1]))


func _enfocar_inicial() -> void:
	if _botones.is_empty():
		return
	(_botones.values()[0] as Button).grab_focus()


## Esc/B se atiende antes que la GUI y que el menú global: dentro del corcho
## deshace el gesto en curso y, sin nada en curso, cierra.
func _input(evento: InputEvent) -> void:
	if not _es_cancelar(evento):
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()
	if not _cogida.is_empty():
		_cogida = ""
		_actualizar_estilos()
	elif not _seleccion.is_empty():
		_seleccion = ""
		_actualizar_estilos()
	else:
		cerrar()


func _es_cancelar(evento: InputEvent) -> bool:
	if not evento.is_pressed() or evento.is_echo():
		return false
	if evento.is_action("ui_cancel"):
		return true
	return InputMap.has_action("cancelar") and evento.is_action("cancelar")


func _entrada_ficha(evento: InputEvent, id: String) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_raton_boton(evento, id)
		_botones[id].accept_event()
		return
	if evento is InputEventMouseMotion and _arrastre == id:
		_raton_movimiento(evento, id)
		_botones[id].accept_event()
		return
	if _es_coger(evento):
		_cogida = "" if _cogida == id else id
		_actualizar_estilos()
		_botones[id].accept_event()
		return
	if _cogida == id:
		var direccion := _direccion(evento)
		if direccion != Vector2.ZERO:
			mover(id, _posicion(id) + direccion * PASO_TECLADO)
			_botones[id].accept_event()
			return
	if evento.is_action_pressed("ui_accept"):
		pulsar(id)
		_botones[id].accept_event()


func _es_coger(evento: InputEvent) -> bool:
	if evento is InputEventKey:
		return evento.pressed and not evento.echo and evento.physical_keycode == TECLA_COGER
	if evento is InputEventJoypadButton:
		return evento.pressed and evento.button_index == BOTON_COGER
	return false


func _direccion(evento: InputEvent) -> Vector2:
	if evento.is_action_pressed("ui_left", true):
		return Vector2.LEFT
	if evento.is_action_pressed("ui_right", true):
		return Vector2.RIGHT
	if evento.is_action_pressed("ui_up", true):
		return Vector2(0, 1)
	if evento.is_action_pressed("ui_down", true):
		return Vector2(0, -1)
	return Vector2.ZERO


func _raton_boton(evento: InputEventMouseButton, id: String) -> void:
	var boton: Button = _botones[id]
	if evento.pressed:
		boton.grab_focus()
		_arrastre = id
		_arrastrando = false
		_origen_arrastre = evento.global_position
		_desplazamiento_arrastre = boton.global_position - evento.global_position
		return
	if _arrastre != id:
		return
	var arrastrado := _arrastrando
	_arrastre = ""
	_arrastrando = false
	if arrastrado:
		var centro := boton.position + boton.size * 0.5
		mover(id, _a_logico(centro))
		_colocar_todo()
	else:
		pulsar(id)


func _raton_movimiento(evento: InputEventMouseMotion, id: String) -> void:
	if not _arrastrando:
		if evento.global_position.distance_to(_origen_arrastre) < UMBRAL_ARRASTRE:
			return
		_arrastrando = true
		_seleccion = ""
		_actualizar_estilos()
	var boton: Button = _botones[id]
	boton.global_position = evento.global_position + _desplazamiento_arrastre
	var centro := boton.position + boton.size * 0.5
	var borde := Corcho.limite() * _escala_px()
	var medio := _tablon.size * 0.5
	centro = centro.clamp(medio - borde, medio + borde)
	boton.position = centro - boton.size * 0.5
	boton.move_to_front()
	_hilos.move_to_front()
	_hilos.queue_redraw()


## Mueve una ficha en coordenadas lógicas del tablón.
func mover(id: String, pos: Vector2) -> bool:
	if not Corcho.mover(_jornada, id, pos):
		return false
	_colocar_todo()
	cambiado.emit()
	return true


## Primer toque marca la ficha; el segundo, sobre otra, pone o quita el hilo.
func pulsar(id: String) -> void:
	if not _botones.has(id):
		return
	if _seleccion.is_empty():
		_seleccion = id
	elif _seleccion == id:
		_seleccion = ""
	else:
		var anterior := _seleccion
		_seleccion = ""
		if Corcho.alternar_enlace(_jornada, anterior, id):
			_hilos.queue_redraw()
			cambiado.emit()
	_actualizar_estilos()


func _actualizar_estilos() -> void:
	for id in _botones:
		var boton: Button = _botones[id]
		var color := COLOR_SELECCION if id == _seleccion else COLOR_PAPEL
		var normal := _estilo(color, Color(0, 0, 0, 0), 0)
		var foco := _estilo(color, Color(0.20, 0.45, 0.95), 3)
		if id == _cogida:
			foco = _estilo(color, Color(0.95, 0.95, 0.95), 4)
			foco.shadow_color = Color(0, 0, 0, 0.55)
			foco.shadow_size = 10
			foco.shadow_offset = Vector2(4, 6)
		for nombre in ["normal", "hover", "pressed", "disabled"]:
			boton.add_theme_stylebox_override(nombre, normal)
		boton.add_theme_stylebox_override("focus", foco)
		boton.add_theme_stylebox_override(
			"hover", _estilo(color.lightened(0.08), Color(0, 0, 0, 0), 0)
		)


func _estilo(fondo: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.content_margin_left = 6
	estilo.content_margin_right = 6
	estilo.content_margin_top = 14
	estilo.content_margin_bottom = 4
	estilo.shadow_color = Color(0, 0, 0, 0.30)
	estilo.shadow_size = 3
	estilo.shadow_offset = Vector2(1, 2)
	if grosor > 0:
		estilo.draw_center = false
	return estilo


func _dibujar_tablon() -> void:
	var marco := 14.0
	_tablon.draw_rect(
		Rect2(Vector2(-marco, -marco), _tablon.size + Vector2(marco, marco) * 2.0), COLOR_MARCO
	)
	_tablon.draw_rect(Rect2(Vector2.ZERO, _tablon.size), COLOR_CORCHO)
	# Grano del corcho: puntos fijos derivados de un hash, sin textura ni azar.
	for i in 700:
		var h := hash(i * 7919 + 785)
		var punto := Vector2(
			float(h & 0xFFFF) / 65535.0 * _tablon.size.x,
			float((h >> 16) & 0xFFFF) / 65535.0 * _tablon.size.y
		)
		var tono := COLOR_CORCHO.darkened(0.05 + float((h >> 8) & 0xFF) / 255.0 * 0.2)
		_tablon.draw_rect(Rect2(punto, Vector2(2, 2)), tono)


func _dibujar_hilos() -> void:
	for enlace in Corcho.estado(_jornada)["enlaces"]:
		if typeof(enlace) != TYPE_ARRAY or enlace.size() != 2:
			continue
		var a := _chincheta(String(enlace[0]))
		var b := _chincheta(String(enlace[1]))
		if a == Vector2.INF or b == Vector2.INF:
			continue
		_hilos.draw_line(a, b, COLOR_HILO, 3.0, true)
	for id in _botones:
		var punto := _chincheta(id)
		_hilos.draw_circle(punto, 6.0, COLOR_HILO.darkened(0.2))
		_hilos.draw_circle(punto + Vector2(-1.5, -1.5), 2.0, Color(1, 0.6, 0.55))


func _chincheta(id: String) -> Vector2:
	var boton := _botones.get(id) as Button
	if boton == null:
		return Vector2.INF
	return boton.position + Vector2(boton.size.x * 0.5, 8.0)
