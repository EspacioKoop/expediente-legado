## Superficie de Rebote Postal 98; el mundo queda pausado y se restaura al salir.
class_name RebotePostalApp
extends CanvasLayer

signal cerrado
signal menu_solicitado

const REGLAS := preload("res://guion/rebote_postal.gd")
const TEXTOS := "res://datos/rebote_postal_textos.json"

var modo_consola := false
var juego := REGLAS.new()
var _textos: Dictionary = {}
var _abierto := false
var _pausa_previa := false
var _raton_previo := Input.MOUSE_MODE_VISIBLE
var _izquierda := false
var _derecha := false
var _objetivo := -1.0
var _tablero: Control
var _estado: Label
var _marcador: Label
var _principal: Button
var _lento: CheckButton
var _audio: AudioStreamPlayer
var _sonidos: Dictionary = {}


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_textos = JSON.parse_string(FileAccess.get_file_as_string(TEXTOS))
	_pausa_previa = get_tree().paused
	_raton_previo = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_abierto = true
	juego.nueva()
	_construir_ui()
	_refrescar()
	_principal.grab_focus.call_deferred()


func cerrar() -> void:
	if not _abierto:
		return
	_restaurar()
	cerrado.emit()
	if get_tree().current_scene == self:
		get_tree().quit()
	queue_free()


func _exit_tree() -> void:
	_restaurar()


func _restaurar() -> void:
	if not _abierto:
		return
	_abierto = false
	get_tree().paused = _pausa_previa
	Input.mouse_mode = _raton_previo


func _process(delta: float) -> void:
	var fase_previa := juego.fase
	var eje := Input.get_axis("mover_izquierda", "mover_derecha")
	if _izquierda or _derecha:
		eje = float(_derecha) - float(_izquierda)
	elif not is_zero_approx(eje):
		_objetivo = -1
	elif _objetivo >= 0:
		eje = clampf((_objetivo - juego.pala) / (650.0 * maxf(delta, 0.001)), -1.0, 1.0)
	for evento in juego.avanzar(delta, eje):
		_sonar(evento)
	_refrescar()
	if fase_previa != juego.fase:
		_principal.grab_focus()


func _input(evento: InputEvent) -> void:
	if not _abierto:
		return
	if evento.is_action_pressed("cancelar"):
		cerrar()
		get_viewport().set_input_as_handled()
	elif (
		juego.fase == "jugando"
		and not evento is InputEventMouseButton
		and evento.is_action_pressed("interactuar")
	):
		_accion_principal()
		get_viewport().set_input_as_handled()
	elif (
		juego.fase == "jugando"
		and (evento.is_action("mover_izquierda") or evento.is_action("mover_derecha"))
	):
		# La pala recibe eje analógico; no mover también el foco de los botones.
		get_viewport().set_input_as_handled()


func _notification(que: int) -> void:
	if que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_izquierda = false
		_derecha = false
		_objetivo = -1
		if juego.fase == "jugando":
			juego.pausar()
			_refrescar()


func _accion_principal() -> void:
	match juego.fase:
		"listo":
			juego.tranquilo = _lento.button_pressed
			juego.sacar()
		"jugando", "pausa":
			juego.pausar()
		"nivel_completo":
			juego.siguiente()
		"derrota", "victoria":
			juego.nueva()
	_objetivo = -1
	_refrescar()
	_principal.grab_focus()


func _volver_menu() -> void:
	cerrar()
	menu_solicitado.emit()


func _refrescar() -> void:
	_marcador.text = (
		_texto("marcador") % [juego.nivel, juego.vidas, juego.paquetes.size(), juego.puntos]
	)
	_estado.text = _texto(juego.fase)
	_principal.text = _texto(
		{
			"listo": "sacar",
			"jugando": "pausar",
			"pausa": "continuar",
			"nivel_completo": "siguiente",
			"victoria": "reintentar",
			"derrota": "reintentar"
		}[juego.fase]
	)
	_lento.disabled = juego.fase != "listo"
	_tablero.queue_redraw()


func _construir_ui() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -16
	add_child(_audio)
	var fondo := ColorRect.new()
	fondo.color = Color("171c30")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 28)
	fondo.add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)
	_etiqueta(caja, _texto("titulo"), 36)
	_etiqueta(caja, _texto("reglas"), 20)
	_marcador = _etiqueta(caja, "", 24)
	_tablero = Control.new()
	_tablero.custom_minimum_size = Vector2(320, 200)
	_tablero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tablero.draw.connect(_dibujar)
	_tablero.resized.connect(func(): _tablero.queue_redraw())
	_tablero.gui_input.connect(_al_tablero_input)
	caja.add_child(_tablero)
	_estado = _etiqueta(caja, "", 24)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)
	var izquierda := _boton(fila, "izquierda", func(): pass)
	izquierda.button_down.connect(
		func():
			_izquierda = true
			_objetivo = -1
	)
	izquierda.button_up.connect(func(): _izquierda = false)
	_principal = _boton(fila, "sacar", _accion_principal)
	var derecha := _boton(fila, "derecha", func(): pass)
	derecha.button_down.connect(
		func():
			_derecha = true
			_objetivo = -1
	)
	derecha.button_up.connect(func(): _derecha = false)
	_lento = CheckButton.new()
	_lento.text = _texto("lento")
	fila.add_child(_lento)
	if modo_consola:
		_boton(fila, "menu", _volver_menu)
	_boton(fila, "salir", cerrar)


func _etiqueta(padre: Node, texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", Color("f7e8ca"))
	padre.add_child(etiqueta)
	return etiqueta


func _boton(padre: Node, clave: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = _texto(clave)
	boton.accessibility_name = boton.text
	boton.custom_minimum_size = Vector2(120, 48)
	boton.add_theme_font_size_override("font_size", 20)
	boton.pressed.connect(accion)
	padre.add_child(boton)
	return boton


func _texto(clave: String) -> String:
	var tabla: Dictionary = _textos.get(TranslationServer.get_locale().substr(0, 2), _textos["es"])
	return String(tabla.get(clave, clave))


func _transformacion() -> Vector3:
	var escala := minf(_tablero.size.x / REGLAS.TAMANO.x, _tablero.size.y / REGLAS.TAMANO.y)
	var origen := (_tablero.size - REGLAS.TAMANO * escala) / 2
	return Vector3(origen.x, origen.y, escala)


func _al_tablero_input(evento: InputEvent) -> void:
	var posicion := Vector2.ZERO
	if evento is InputEventScreenDrag:
		posicion = evento.position
	elif evento is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		posicion = evento.position
	else:
		return
	var transformacion := _transformacion()
	_objetivo = clampf(
		(posicion.x - transformacion.x) / maxf(transformacion.z, 0.001), 0, REGLAS.TAMANO.x
	)
	_tablero.accept_event()


func _dibujar() -> void:
	var transformacion := _transformacion()
	_tablero.draw_set_transform(
		Vector2(transformacion.x, transformacion.y), 0, Vector2.ONE * transformacion.z
	)
	_tablero.draw_rect(Rect2(Vector2.ZERO, REGLAS.TAMANO), Color("263448"))
	_tablero.draw_rect(Rect2(Vector2.ZERO, REGLAS.TAMANO), Color("85b7cf"), false, 3)
	for x in range(40, 950, 80):
		_tablero.draw_line(Vector2(x, 420), Vector2(x + 35, 420), Color("364a5b"), 3)
	for paquete in juego.paquetes:
		_tablero.draw_rect(paquete, Color("d9a664"))
		_tablero.draw_rect(paquete, Color("ffe1a3"), false, 2)
		_tablero.draw_line(
			Vector2(paquete.get_center().x, paquete.position.y),
			Vector2(paquete.get_center().x, paquete.end.y),
			Color("875d54"),
			6
		)
		_tablero.draw_rect(
			Rect2(paquete.position + Vector2(8, 8), Vector2(20, 10)), Color("f8e6c3")
		)
	_tablero.draw_rect(
		Rect2(juego.pala - REGLAS.ANCHO_PALA / 2, REGLAS.Y_PALA, REGLAS.ANCHO_PALA, 16),
		Color("ab92ec")
	)
	_tablero.draw_circle(juego.pelota, REGLAS.RADIO + 3, Color("3e6571"))
	_tablero.draw_circle(juego.pelota, REGLAS.RADIO, Color("f7f6d9"))


func _sonar(clave: String) -> void:
	if not _sonidos.has(clave):
		var frecuencia := float(
			{"pala": 330, "paquete": 660, "nivel": 880, "perdida": 110}.get(clave, 440)
		)
		var datos := PackedByteArray()
		for i in range(2205):
			var pulso := 1 if sin(TAU * frecuencia * i / 22050.0) >= 0 else -1
			datos.append(int(128 + 24 * pulso * minf(1.0, minf(i / 80.0, (2205 - i) / 300.0))))
		var sonido := AudioStreamWAV.new()
		sonido.format = AudioStreamWAV.FORMAT_8_BITS
		sonido.mix_rate = 22050
		sonido.data = datos
		_sonidos[clave] = sonido
	if AudioServer.get_bus_index("Efectos") >= 0:
		_audio.bus = "Efectos"
	_audio.stream = _sonidos[clave]
	_audio.play()
