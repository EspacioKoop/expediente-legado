class_name PresenciaSalaPanel
extends PanelContainer

signal crear_sala_solicitada(codigo: String)
signal unirse_sala_solicitada(codigo: String)
signal salir_sala_solicitada
signal cerrar_solicitado

const RUTA_TEXTOS := "res://datos/presencia_sala_textos.json"
const CODIGO_LONGITUD := 6
const ALFABETO := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var _textos: Dictionary = {}
var _codigo: LineEdit
var _estado: Label
var _crear: Button
var _unirse: Button
var _salir: Button
var _normalizando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = EstiloSiga.tema()
	custom_minimum_size = Vector2(520.0, 300.0)
	_textos = _cargar_textos()
	_montar()
	visible = false


func abrir(codigo_inicial: String = "") -> void:
	_codigo.text = normalizar_codigo(codigo_inicial)
	_estado.text = _texto("ayuda")
	visible = true
	(_salir if not _codigo.text.is_empty() else _crear).grab_focus.call_deferred()


func cerrar() -> void:
	visible = false
	_estado.text = ""


func mostrar_estado(status: String, detalles: Dictionary = {}) -> void:
	match status:
		"connecting":
			_estado.text = _texto("conectando")
		"joining":
			_estado.text = _texto("conectando")
		"online":
			_estado.text = _texto("online") % String(detalles.get("room_id", _codigo.text))
		"reconnecting":
			_estado.text = _texto("reconectando")
		"unconfigured":
			_estado.text = _texto("sin_endpoint")
		"invalid_room_id":
			_estado.text = _texto("codigo_invalido")
		"closed", "inactive":
			_estado.text = _texto("cerrada")
		_:
			_estado.text = _texto("error")


func codigo_actual() -> String:
	return normalizar_codigo(_codigo.text)


static func normalizar_codigo(valor: String) -> String:
	var mayusculas := valor.strip_edges().to_upper()
	var salida := ""
	for indice in range(mayusculas.length()):
		var caracter := mayusculas.substr(indice, 1)
		if ALFABETO.contains(caracter):
			salida += caracter
			if salida.length() >= CODIGO_LONGITUD:
				break
	return salida


static func codigo_valido(valor: String) -> bool:
	var codigo := normalizar_codigo(valor)
	return codigo.length() == CODIGO_LONGITUD and codigo == valor.strip_edges().to_upper()


static func generar_codigo() -> String:
	var bytes := Crypto.new().generate_random_bytes(CODIGO_LONGITUD)
	var salida := ""
	for byte in bytes:
		salida += ALFABETO.substr(int(byte) % ALFABETO.length(), 1)
	return salida


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or not evento.is_pressed() or evento.is_echo():
		return
	var cancelar := evento.is_action("ui_cancel")
	if InputMap.has_action("cancelar"):
		cancelar = cancelar or evento.is_action("cancelar")
	if cancelar:
		get_viewport().set_input_as_handled()
		cerrar_solicitado.emit()


func _montar() -> void:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 20)
	add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)

	var titulo := Label.new()
	titulo.text = _texto("titulo")
	titulo.accessibility_name = titulo.text
	caja.add_child(titulo)

	var descripcion := Label.new()
	descripcion.text = _texto("descripcion")
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(descripcion)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	caja.add_child(fila)

	var etiqueta := Label.new()
	etiqueta.text = _texto("codigo")
	fila.add_child(etiqueta)

	_codigo = LineEdit.new()
	_codigo.name = "CodigoSala"
	_codigo.max_length = CODIGO_LONGITUD * 2
	_codigo.placeholder_text = _texto("placeholder")
	_codigo.accessibility_name = _texto("codigo")
	_codigo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_codigo.text_changed.connect(_al_codigo_cambiado)
	_codigo.text_submitted.connect(func(_texto_enviado: String): _unirse_sala())
	fila.add_child(_codigo)

	_estado = Label.new()
	_estado.name = "EstadoSala"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.accessibility_live = AccessibilityServer.LIVE_POLITE
	caja.add_child(_estado)

	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_END
	botones.add_theme_constant_override("separation", 8)
	caja.add_child(botones)

	var volver := _boton("VolverSala", _texto("volver"))
	volver.pressed.connect(func(): cerrar_solicitado.emit())
	botones.add_child(volver)

	_salir = _boton("SalirSala", _texto("salir"))
	_salir.pressed.connect(func(): salir_sala_solicitada.emit())
	botones.add_child(_salir)

	_unirse = _boton("UnirseSala", _texto("unirse"))
	_unirse.pressed.connect(_unirse_sala)
	botones.add_child(_unirse)

	_crear = _boton("CrearSala", _texto("crear"))
	_crear.pressed.connect(_crear_sala)
	botones.add_child(_crear)


func _boton(nombre: String, texto: String) -> Button:
	var boton := Button.new()
	boton.name = nombre
	boton.text = texto
	boton.accessibility_name = texto
	boton.focus_mode = Control.FOCUS_ALL
	return boton


func _crear_sala() -> void:
	var codigo := generar_codigo()
	_codigo.text = codigo
	_estado.text = _texto("conectando")
	crear_sala_solicitada.emit(codigo)


func _unirse_sala() -> void:
	var codigo := normalizar_codigo(_codigo.text)
	_codigo.text = codigo
	if not codigo_valido(codigo):
		_estado.text = _texto("codigo_invalido")
		_codigo.grab_focus.call_deferred()
		return
	_estado.text = _texto("conectando")
	unirse_sala_solicitada.emit(codigo)


func _al_codigo_cambiado(valor: String) -> void:
	if _normalizando:
		return
	var normalizado := normalizar_codigo(valor)
	if normalizado == valor:
		return
	_normalizando = true
	_codigo.text = normalizado
	_codigo.caret_column = normalizado.length()
	_normalizando = false


func _cargar_textos() -> Dictionary:
	if not FileAccess.file_exists(RUTA_TEXTOS):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS))
	return datos if datos is Dictionary else {}


func _texto(clave: String) -> String:
	return String(_textos.get(clave, clave))
