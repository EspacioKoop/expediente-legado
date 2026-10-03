## Arcade autocontenido y selector de la consola de sobremesa.
class_name TurnoSerpienteApp
extends CanvasLayer

signal cerrado
signal rom_solicitada
signal rebote_solicitado

const REGLAS := preload("res://guion/turno_serpiente.gd")
const TEXTOS := "res://datos/turno_serpiente_textos.json"
const DIRECCIONES := {
	"mover_adelante": Vector2i.UP,
	"mover_atras": Vector2i.DOWN,
	"mover_izquierda": Vector2i.LEFT,
	"mover_derecha": Vector2i.RIGHT,
}

var modo_consola := false
var juego := REGLAS.new()
var _textos: Dictionary = {}
var _abierto := false
var _pausa_previa := false
var _raton_previo := Input.MOUSE_MODE_VISIBLE
var _acumulado := 0.0
var _mejor := 0
var _tablero: Control
var _estado: Label
var _marcador: Label
var _principal: Button
var _lento: CheckButton
var _menu_rom: Button
var _menu_rebote: Button
var _audio: AudioStreamPlayer
var _sonidos: Dictionary = {}


func _ready() -> void:
	abrir()


func abrir() -> void:
	if _abierto:
		return
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
	if juego.fase != "jugando":
		return
	var paso := juego.intervalo(_lento.button_pressed)
	# No saltar varias casillas tras una pérdida de foco o un frame lento.
	_acumulado = minf(_acumulado + maxf(delta, 0.0), paso)
	if _acumulado >= paso:
		_acumulado = 0.0
		var resultado := juego.avanzar()
		if resultado != "paso":
			_sonar(resultado)
		_refrescar()


func _input(evento: InputEvent) -> void:
	if not _abierto:
		return
	if evento.is_action_pressed("cancelar"):
		cerrar()
		get_viewport().set_input_as_handled()
		return
	if juego.fase != "jugando" and juego.fase != "pausa":
		return
	for accion in DIRECCIONES:
		if evento.is_action_pressed(accion):
			juego.girar(DIRECCIONES[accion])
			get_viewport().set_input_as_handled()
			return
	# El ratón usa botones, porque interactuar también contiene clic izquierdo.
	if not evento is InputEventMouseButton and evento.is_action_pressed("interactuar"):
		_accion_principal()
		get_viewport().set_input_as_handled()


func _notification(que: int) -> void:
	if que == NOTIFICATION_APPLICATION_FOCUS_OUT and juego.fase == "jugando":
		juego.pausar()
		_acumulado = 0.0
		_refrescar()


func _accion_principal() -> void:
	_sonar("boton")
	match juego.fase:
		"preparado":
			juego.iniciar()
		"jugando", "pausa":
			juego.pausar()
		"nivel_completo":
			juego.siguiente()
		"derrota", "victoria":
			juego.nueva()
	_acumulado = 0.0
	_refrescar()


func _abrir_rom() -> void:
	cerrar()
	rom_solicitada.emit()


func _abrir_rebote() -> void:
	cerrar()
	rebote_solicitado.emit()


func _refrescar() -> void:
	_mejor = maxi(_mejor, juego.puntos)
	_marcador.text = (
		_texto("marcador") % [juego.nivel, juego.recogidos, REGLAS.META, juego.puntos, _mejor]
	)
	_estado.text = _texto(juego.fase)
	var claves := {
		"preparado": "jugar",
		"jugando": "pausar",
		"pausa": "continuar",
		"nivel_completo": "siguiente",
		"derrota": "reintentar",
		"victoria": "reintentar",
	}
	_principal.text = _texto(claves[juego.fase])
	_lento.disabled = juego.fase != "preparado"
	if _menu_rom != null:
		_menu_rom.visible = juego.fase == "preparado" and juego.nivel == 1
	if _menu_rebote != null:
		_menu_rebote.visible = juego.fase == "preparado" and juego.nivel == 1
	_tablero.queue_redraw()
	if juego.fase in ["derrota", "victoria", "nivel_completo"]:
		_principal.grab_focus()


func _construir_ui() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -12.0
	add_child(_audio)
	var fondo := ColorRect.new()
	fondo.color = Color("0c151d")
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
	_tablero.custom_minimum_size = Vector2(280, 196)
	_tablero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tablero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablero.draw.connect(_dibujar)
	_tablero.resized.connect(func(): _tablero.queue_redraw())
	caja.add_child(_tablero)
	_estado = _etiqueta(caja, "", 24)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)
	_principal = _boton(fila, "jugar", _accion_principal)
	_lento = CheckButton.new()
	_lento.text = _texto("lento")
	fila.add_child(_lento)
	if modo_consola:
		_menu_rebote = _boton(fila, "rebote", _abrir_rebote)
		_menu_rom = _boton(fila, "roms", _abrir_rom)
	_boton(fila, "salir", cerrar)
	var cruceta := HBoxContainer.new()
	cruceta.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(cruceta)
	for accion in DIRECCIONES:
		_boton(cruceta, accion, func(): juego.girar(DIRECCIONES[accion]))


func _etiqueta(padre: Node, texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", Color("dbecd8"))
	padre.add_child(etiqueta)
	return etiqueta


func _boton(padre: Node, clave: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = _texto(clave)
	boton.accessibility_name = boton.text
	boton.custom_minimum_size = Vector2(110, 48)
	boton.add_theme_font_size_override("font_size", 20)
	boton.pressed.connect(accion)
	padre.add_child(boton)
	return boton


func _texto(clave: String) -> String:
	var idioma := TranslationServer.get_locale().substr(0, 2)
	var tabla: Dictionary = _textos.get(idioma, _textos.get("es", {}))
	return String(tabla.get(clave, clave))


func _sonar(clave: String) -> void:
	if not _sonidos.has(clave):
		var notas: Array = (
			{
				"boton": [440.0],
				"sello": [660.0, 880.0],
				"choque": [220.0, 110.0],
				"nivel": [523.0, 659.0, 784.0],
			}
			. get(clave, [])
		)
		if notas.is_empty():
			return
		var datos := PackedByteArray()
		var muestras := 1764
		for nota in notas:
			for i in range(muestras):
				var envolvente := minf(1.0, minf(float(i) / 80.0, float(muestras - i) / 300.0))
				var pulso := 1.0 if sin(TAU * float(nota) * i / 22050.0) >= 0.0 else -1.0
				datos.append(int(128.0 + 24.0 * pulso * envolvente))
		var sonido := AudioStreamWAV.new()
		sonido.format = AudioStreamWAV.FORMAT_8_BITS
		sonido.mix_rate = 22050
		sonido.data = datos
		_sonidos[clave] = sonido
	# El mixer común mantiene los volúmenes globales, incluido silencio total.
	if AudioServer.get_bus_index("Efectos") >= 0:
		_audio.bus = "Efectos"
	_audio.stream = _sonidos[clave]
	_audio.play()


func _dibujar() -> void:
	var celda := floorf(minf(_tablero.size.x / REGLAS.TAMANO.x, _tablero.size.y / REGLAS.TAMANO.y))
	var origen := (_tablero.size - Vector2(REGLAS.TAMANO) * celda) / 2.0
	_tablero.draw_rect(
		Rect2(origen - Vector2(4, 4), Vector2(REGLAS.TAMANO) * celda + Vector2(8, 8)),
		Color("5cb8ac")
	)
	for y in range(REGLAS.TAMANO.y):
		for x in range(REGLAS.TAMANO.x):
			var color := Color("152c37") if (x + y) % 2 == 0 else Color("18323d")
			_tablero.draw_rect(Rect2(origen + Vector2(x, y) * celda, Vector2.ONE * celda), color)
	for pared in juego.paredes:
		var caja := Rect2(
			origen + Vector2(pared) * celda + Vector2(2, 2), Vector2.ONE * (celda - 4)
		)
		_tablero.draw_rect(caja, Color("97766b"))
		_tablero.draw_line(
			caja.position + Vector2(3, 5),
			caja.end - Vector2(3, caja.size.y - 5),
			Color("e5b993"),
			2
		)
	var centro := origen + (Vector2(juego.sello) + Vector2(0.5, 0.5)) * celda
	_tablero.draw_circle(centro, celda * 0.32, Color("ffc857"))
	_tablero.draw_circle(centro, celda * 0.19, Color("152c37"), false, 2)
	for i in range(juego.cuerpo.size() - 1, -1, -1):
		var pos := origen + Vector2(juego.cuerpo[i]) * celda + Vector2(2, 2)
		var color := Color("e1f8b1") if i == 0 else Color("62c5a5")
		_tablero.draw_rect(Rect2(pos, Vector2.ONE * (celda - 4)), color)
		if i == 0:
			var ojo := (
				pos + Vector2.ONE * (celda - 4) / 2.0 + Vector2(juego.direccion) * celda * 0.18
			)
			_tablero.draw_circle(ojo, maxf(2, celda * 0.09), Color("0c151d"))
